[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$FromDate,
  [Parameter(Mandatory)][string]$ToDate,
  [Parameter(Mandatory)][string]$Phase,
  [Parameter(Mandatory)][string]$Hypothese,
  [Parameter(Mandatory)][string]$WindowLetter, # "A" or "B" expected by pool_backtests.py
  [string]$WfZyklus = "1",
  [string]$Expert = "stock_mr_v1.mq5",
  [string]$Strategie = "stock-mr",
  [string]$Period = "D1"
)

$ErrorActionPreference = "Stop"
$PipelineDir = $PSScriptRoot
$RepoRoot = (Resolve-Path "$PipelineDir/../..").Path
$ReportsDir = Join-Path $RepoRoot "reports"

# Die 10 Aktien des Stock-MR Korbs
$Basket = @("AAPL", "AMD", "AMZN", "AVGO", "ADBE", "ABNB", "AXP", "ABT", "AIG", "AEP")

$CommonFiles = "$env:APPDATA\MetaQuotes\Terminal\Common\Files"
$ResultFile = Join-Path $CommonFiles "tester_result.txt"

Write-Host "=== Starte Basket-Lauf ($($Basket.Length) Symbole) fuer Fenster $WindowLetter ($FromDate - $ToDate) ==="

# Alte Korb-Dateien fuer dieses Fenster bereinigen
Remove-Item -Path "$ReportsDir/${Strategie}_*_${WindowLetter}.txt" -ErrorAction SilentlyContinue

foreach ($sym in $Basket) {
    Write-Host "`n---> Symbol: $sym"
    
    # Alte tester_result.txt loeschen, falls vorhanden
    if (Test-Path $ResultFile) { Remove-Item $ResultFile -Force }
    
    # Einzelnen Backtest anstossen. run_backtest.ps1 kuemmert sich um Retry, Kompilieren und HTML Parsing.
    # Wichtig: Die Ergebnisse landen in backtests.csv als einzelne Laeufe.
    & pwsh "$PipelineDir/run_backtest.ps1" -Symbol $sym -FromDate $FromDate -ToDate $ToDate -Expert $Expert -Phase $Phase -WfZyklus $WfZyklus -Hypothese $Hypothese -Strategie $Strategie -Period $Period -ExecTf $Period -Richtung "long"
    
    # Nach dem Lauf die generierte tester_result.txt umbenennen und ins reports-Verzeichnis verschieben
    if (Test-Path $ResultFile) {
        $DestFile = Join-Path $ReportsDir "${Strategie}_${sym}_${WindowLetter}.txt"
        Move-Item -Path $ResultFile -Destination $DestFile -Force
        Write-Host "     Gemerkt: $DestFile"
    } else {
        Write-Warning "Keine tester_result.txt fuer $sym generiert (evtl. 0 Trades / Trendfilter blockiert)."
    }
}

Write-Host "`n=== Korb-Lauf abgeschlossen. Poooling der Ergebnisse... ==="
Push-Location $RepoRoot
try {
    # python script gibt die Ergebnisse für A und B aus (wenn vorhanden)
    & python "tools/pool_backtests.py" $Strategie "reports"
} finally {
    Pop-Location
}
