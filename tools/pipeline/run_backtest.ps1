<#
  run_backtest.ps1 -- End-to-End-Backtest-Loop (Ticket 08).
  Ein Kommando: kompilieren -> .ini erzeugen -> Tester-Lauf -> Report parsen ->
  Zeile an backtests.csv -> validate_backtests.py.

  Robust (Ticket 08): Compile-Log-Check, Report-Plausibilitaet, begrenzter Retry,
  lautes Stoppen statt Muell schreiben. Endet strikt vor Live.

  Pfade kommen aus tools/pipeline/config.json (einmal ausfuellen).

  Beispiel:
    pwsh tools/pipeline/run_backtest.ps1 `
      -Symbol US100 -FromDate 2022.01.01 -ToDate 2023.12.31 `
      -Expert ema_mtf_v3.mq5 -Phase wf-is -WfZyklus 1 `
      -Hypothese H-2026-07-US100-ovngap -Strategie ema-cross -Richtung long `
      -ExecTf H1 -BiasTf H4

  HINWEIS: Die Stelle REPORT SUCHEN (unten) haengt von deiner MT5-Version ab.
  Beim ersten echten Lauf pruefen, ob der Report gefunden wird; ggf. Suchpfade
  ergaenzen. Alles andere ist getestet/pfadunabhaengig.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string]$Symbol,
  [Parameter(Mandatory)] [string]$FromDate,   # Format JJJJ.MM.TT
  [Parameter(Mandatory)] [string]$ToDate,
  [string]$Expert   = "ema_mtf_v3.mq5",
  [string]$SetFile  = "",
  [int]   $ForwardMode = 0,                    # 0 kein OOS | 1 1/2 | 2 1/3 | 3 1/4 | 4 Datum
  [string]$ForwardDate = "",
  [string]$Period   = "H1",
  # Metadaten fuer die CSV-Zeile:
  [string]$ExecTf = "", [string]$BiasTf = "", [string]$Richtung = "",
  [string]$Strategie = "", [string]$Hypothese = "", [string]$Phase = "",
  [string]$WfZyklus = "", [string]$Fazit = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot   = (Resolve-Path "$PSScriptRoot/../..").Path
$PipelineDir = $PSScriptRoot
$cfg = Get-Content "$PipelineDir/config.json" -Raw | ConvertFrom-Json

function Need($path, $was) {
  if (-not (Test-Path $path)) { throw "FEHLT: $was nicht gefunden: $path -- config.json pruefen." }
}
Need $cfg.terminal_exe   "terminal64.exe"
Need $cfg.metaeditor_exe "metaeditor64.exe"
Need $cfg.mql5_dir       "MQL5-Ordner"

$ReportDir = Join-Path $RepoRoot $cfg.report_dir
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$stamp     = Get-Date -Format "yyyyMMdd-HHmmss"
$runName   = "$Symbol`_$stamp"
$expertName = [IO.Path]::GetFileNameWithoutExtension($Expert)   # .ini erwartet Namen ohne .ex5
$expertSrc  = Join-Path $cfg.mql5_dir "Experts/$Expert"

# ---------------------------------------------------------------- 1. Kompilieren
Write-Host "[1/5] Kompiliere $Expert ..."
Need $expertSrc "EA-Quelle"
$compileLog = Join-Path $ReportDir "$runName.compile.log"
& $cfg.metaeditor_exe "/compile:$expertSrc" "/log:$compileLog" | Out-Null
Start-Sleep -Seconds 2   # metaeditor schreibt das Log leicht verzoegert
# metaeditor liefert keinen zuverlaessigen Exit-Code -> Log parsen.
$logTxt = ""
if (Test-Path $compileLog) { $logTxt = Get-Content $compileLog -Raw -Encoding Unicode }
if ($logTxt -match "(\d+)\s+error" -and [int]$Matches[1] -gt 0) {
  throw "KOMPILIERFEHLER ($($Matches[1])). Log: $compileLog"
}
Write-Host "      Kompiliert (0 errors)."

# ---------------------------------------------------------------- 2. .ini bauen
Write-Host "[2/5] Erzeuge .ini ..."
$tpl = Get-Content "$PipelineDir/backtest.ini.template" -Raw
$testerInputs = ""   # optional: hier feste Inputs setzen; sonst SetFile nutzen
$iniPath = Join-Path $ReportDir "$runName.ini"
$map = @{
  "EXPERT"         = $expertName
  "SET_FILE"       = $SetFile
  "SYMBOL"         = $Symbol
  "PERIOD"         = $Period
  "MODEL"          = $cfg.model
  "EXECUTION_MODE" = $cfg.execution_mode
  "FROM_DATE"      = $FromDate
  "TO_DATE"        = $ToDate
  "FORWARD_MODE"   = $ForwardMode
  "FORWARD_DATE"   = $ForwardDate
  "DEPOSIT"        = $cfg.deposit
  "CURRENCY"       = $cfg.currency
  "LEVERAGE"       = $cfg.leverage
  "REPORT"         = $runName
  "TESTER_INPUTS"  = $testerInputs
}
foreach ($k in $map.Keys) { $tpl = $tpl -replace "{{\s*$k\s*}}", [string]$map[$k] }
Set-Content -Path $iniPath -Value $tpl -Encoding UTF8
Write-Host "      $iniPath"

# ------------------------------------------------- 3./4. Lauf + Report (mit Retry)
$maxTry = [int]$cfg.max_retries + 1
$reportFile = $null
for ($try = 1; $try -le $maxTry; $try++) {
  Write-Host "[3/5] Tester-Lauf (Versuch $try/$maxTry) ..."
  $p = Start-Process -FilePath $cfg.terminal_exe -ArgumentList "/config:$iniPath" -PassThru
  if (-not $p.WaitForExit([int]$cfg.terminal_timeout_sek * 1000)) {
    try { $p.Kill() } catch {}
    Write-Warning "Timeout nach $($cfg.terminal_timeout_sek)s -- abgebrochen."
  }

  Write-Host "[4/5] Suche Report ..."
  # ---- REPORT SUCHEN (versionsabhaengig -- beim ersten Lauf bestaetigen) ----
  $termDir = Split-Path $cfg.terminal_exe -Parent
  $dataDir = Split-Path $cfg.mql5_dir -Parent
  $candDirs = @($ReportDir, $termDir, $dataDir, (Join-Path $dataDir "Tester"))
  foreach ($d in $candDirs) {
    if (-not (Test-Path $d)) { continue }
    $hit = Get-ChildItem -Path $d -Filter "$runName*" -Include *.htm,*.html,*.xml -Recurse -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($hit) { $reportFile = $hit.FullName; break }
  }
  if ($reportFile -and (Get-Item $reportFile).Length -gt 200) { break }
  $reportFile = $null
  if ($try -lt $maxTry) {
    Write-Warning "Kein plausibler Report -- Pause $($cfg.retry_pause_sek)s, dann Retry."
    Start-Sleep -Seconds ([int]$cfg.retry_pause_sek)
  }
}
if (-not $reportFile) {
  throw "KEIN Report nach $maxTry Versuchen. Demo-Server/Daten pruefen. " +
        "Falls der Lauf lief: Suchpfade unter 'REPORT SUCHEN' an deine MT5-Version anpassen."
}
Write-Host "      Report: $reportFile"

# ---------------------------------------------------------------- 5. Parsen + CSV
Write-Host "[5/5] Parse Report -> backtests.csv ..."
$zeitraum = ($FromDate -replace '\.','' ).Substring(0,6)  # grober Kurzstempel JJJJMM
$meta = @{
  datum      = (Get-Date -Format "yyyy-MM-dd")
  ea_version = $expertName
  zeitraum   = "$($FromDate)_$($ToDate)"
  symbol     = $Symbol; exec_tf = $ExecTf; bias_tf = $BiasTf; richtung = $Richtung
  strategie  = $Strategie; hypothese = $Hypothese; phase = $Phase
  wf_zyklus  = $WfZyklus; fazit = $Fazit
}
$metaPath = Join-Path $ReportDir "$runName.meta.json"
$meta | ConvertTo-Json | Set-Content -Path $metaPath -Encoding UTF8

Push-Location $RepoRoot
try {
  & python "tools/pipeline/parse_report.py" --report $reportFile --meta $metaPath --csv "backtests.csv"
  if ($LASTEXITCODE -ne 0) { throw "parse_report.py hat abgebrochen (siehe Meldung oben)." }
  & python "tools/validate_backtests.py"
} finally { Pop-Location }

Write-Host "FERTIG: Lauf $runName in backtests.csv aufgenommen und validiert."
