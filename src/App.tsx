/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useState, useEffect } from "react";
import { 
  Sliders, 
  TrendingUp, 
  Download, 
  Copy, 
  Check, 
  BookOpen, 
  Play, 
  Cpu, 
  AlertTriangle, 
  DollarSign, 
  FileText, 
  Percent, 
  ShieldAlert, 
  CheckCircle2, 
  RefreshCw,
  Terminal,
  Activity,
  History,
  TrendingDown
} from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { 
  ResponsiveContainer, 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  Tooltip, 
  CartesianGrid 
} from "recharts";
import { runSimulatedBacktest, mql5BaseCode, Trade } from "./data";

export default function App() {
  // --- STATE FOR INPUT PARAMETERS ---
  const [fastEMA, setFastEMA] = useState(9);
  const [slowEMA, setSlowEMA] = useState(21);
  const [lotSize, setLotSize] = useState(0.1);
  const [stopLoss, setStopLoss] = useState(2.0);
  const [takeProfit, setTakeProfit] = useState(4.0);
  const [dailyLimit, setDailyLimit] = useState(5.0);

  // --- UI TABS AND INTERACTIVE STATE ---
  const [activeTab, setActiveTab] = useState<"simulator" | "code" | "ai" | "guide">("simulator");
  const [copied, setCopied] = useState(false);
  const [simLoading, setSimLoading] = useState(false);
  const [simData, setSimData] = useState(() => 
    runSimulatedBacktest(9, 21, 0.1, 2.0, 4.0, 5.0)
  );

  // --- AI ANALYSIS STATE ---
  const [metricsInput, setMetricsInput] = useState({
    netProfit: "142.50",
    winRate: "42.8",
    profitFactor: "1.34",
    maxDrawdown: "7.2",
    totalTrades: "28"
  });
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState<string | null>(null);
  const [aiResult, setAiResult] = useState<{
    evaluation: string;
    riskAssessment: string;
    suggestions: string[];
    refinedCodeSnippet: string;
  } | null>(null);

  // --- DYNAMIC CODE GENERATION ---
  const [customCode, setCustomCode] = useState("");

  useEffect(() => {
    // Generate customized MQL5 code for live preview
    const updatedCode = `//+------------------------------------------------------------------+
//|                                    ema_9_21_crossover_long.mq5   |
//|                                Philipp Behnisch / Trading Studio |
//|                                             https://ai.studio/   |
//+------------------------------------------------------------------+
#property copyright "Philipp Behnisch / Trading Studio"
#property link      "https://ai.studio/"
#property version   "1.00"
#property description "EMA-${fastEMA}/${slowEMA}-Crossover Long-Only Expert Advisor"
#property description "Mit integriertem Tagesverlust-Stopp und SL/TP in % vom Kapital."

// Trade-Bibliothek importieren
#include <Trade\\Trade.mqh>
CTrade trade;

//--- Input Parameter
input group "--- Indikator Einstellungen ---"
input int      InpFastEMAPeriod  = ${fastEMA};       // Perioden schnelle EMA (Standard: ${fastEMA})
input int      InpSlowEMAPeriod  = ${slowEMA};      // Perioden langsame EMA (Standard: ${slowEMA})

input group "--- Trend-Filter ---"
input bool     InpUseTrendFilter = true;    // Trend-Filter aktivieren (EMA 200)
input int      InpTrendEMAPeriod = 200;     // Perioden Trend-Filter EMA (Standard: 200)

input group "--- Risikomanagement ---"
input double   InpLotSize        = ${lotSize.toFixed(2)};     // Handelsvolumen (Lots)
input double   InpStopLossPct    = ${stopLoss.toFixed(1)};     // Stop-Loss in % vom Kontostand
input double   InpTakeProfitPct  = ${takeProfit.toFixed(1)};     // Take-Profit in % vom Kontostand
input double   InpDailyLossLimit = ${dailyLimit.toFixed(1)};     // Tagesverlust-Limit in % vom Kontostand

input group "--- System Einstellungen ---"
input ulong    InpMagicNumber    = 123456;  // Magic Number fuer Identifikation
input int      InpSlippage       = 3;       // Maximaler Slippage (Pips)

//--- Globale Variablen
int      h_fastEMA;           // Handle fuer schnelle EMA
int      h_slowEMA;           // Handle fuer langsame EMA
int      h_trendEMA;          // Handle fuer Trend-Filter EMA
datetime m_last_bar_time;     // Speichert die Zeit der letzten Kerze
bool     m_loss_limit_active; // Flag, ob das Tages-Verlustlimit erreicht wurde
int      m_last_day;          // Tag des Jahres zur Zuruecksetzung des Verlustlimits
double   m_day_start_balance; // Kontostand am Anfang des Handelstages

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

   h_fastEMA = iMA(_Symbol, _Period, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(h_fastEMA == INVALID_HANDLE) return(INIT_FAILED);

   h_slowEMA = iMA(_Symbol, _Period, InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(h_slowEMA == INVALID_HANDLE) return(INIT_FAILED);

   // Trend-EMA Handle initialisieren
   h_trendEMA = INVALID_HANDLE;
   if(InpUseTrendFilter)
     {
      h_trendEMA = iMA(_Symbol, _Period, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(h_trendEMA == INVALID_HANDLE) return(INIT_FAILED);
     }

   m_last_bar_time     = 0;
   m_loss_limit_active = false;
   
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   m_last_day          = tm.day_of_year;
   m_day_start_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   return(INIT_SUCCEEDED);
  }
// ... [Vollstaendiger Code bei Download verfuegbar]`;
    setCustomCode(updatedCode);
  }, [fastEMA, slowEMA, lotSize, stopLoss, takeProfit, dailyLimit]);

  // --- HANDLERS ---
  const handleRunSimulation = () => {
    setSimLoading(true);
    setTimeout(() => {
      const results = runSimulatedBacktest(fastEMA, slowEMA, lotSize, stopLoss, takeProfit, dailyLimit);
      setSimData(results);
      setSimLoading(false);
    }, 600);
  };

  const copyToClipboard = () => {
    // We copy the FULL actual code, not just the preview
    const fullCodeToCopy = mql5BaseCode
      .replace(/InpFastEMAPeriod  = 9;/, `InpFastEMAPeriod  = ${fastEMA};`)
      .replace(/InpSlowEMAPeriod  = 21;/, `InpSlowEMAPeriod  = ${slowEMA};`)
      .replace(/InpLotSize        = 0.1;/, `InpLotSize        = ${lotSize.toFixed(2)};`)
      .replace(/InpStopLossPct    = 2.0;/, `InpStopLossPct    = ${stopLoss.toFixed(1)};`)
      .replace(/InpTakeProfitPct  = 4.0;/, `InpTakeProfitPct  = ${takeProfit.toFixed(1)};`)
      .replace(/InpDailyLossLimit = 5.0;/, `InpDailyLossLimit = ${dailyLimit.toFixed(1)};`);

    navigator.clipboard.writeText(fullCodeToCopy);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDownloadCode = () => {
    const url = `/api/download-ea?fastEMA=${fastEMA}&slowEMA=${slowEMA}&lotSize=${lotSize}&stopLoss=${stopLoss}&takeProfit=${takeProfit}&dailyLimit=${dailyLimit}`;
    window.open(url, "_blank");
  };

  const loadExampleMetrics = () => {
    setMetricsInput({
      netProfit: simData.metrics.netProfit.toFixed(2),
      winRate: simData.metrics.winRate.toFixed(1),
      profitFactor: simData.metrics.profitFactor.toFixed(2),
      maxDrawdown: simData.metrics.maxDrawdownPct.toFixed(1),
      totalTrades: simData.metrics.totalTrades.toString()
    });
  };

  const handleAIAnalysis = async () => {
    setAiLoading(true);
    setAiError(null);
    setAiResult(null);

    try {
      const response = await fetch("/api/analyze-backtest", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          metrics: metricsInput,
          eaCode: customCode
        })
      });

      const data = await response.json();

      if (!response.ok) {
        if (data.error === "API_KEY_MISSING") {
          setAiError("key_missing");
        } else {
          setAiError(data.message || "Analyse fehlgeschlagen.");
        }
        return;
      }

      setAiResult(data);
    } catch (err: any) {
      setAiError("Verbindung zum Server fehlgeschlagen. Bitte pruefen Sie, ob der Server laeuft.");
    } finally {
      setAiLoading(false);
    }
  };

  // --- IN-APP ALERTS & CHECKS ---
  const isBadRR = stopLoss > takeProfit;
  const isTooHighRisk = lotSize > 0.4;
  const isEmaInvalid = fastEMA >= slowEMA;

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 font-sans flex flex-col antialiased">
      {/* HEADER SECTION */}
      <header className="border-b border-slate-800 bg-slate-900/60 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 py-4 flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-emerald-500/10 text-emerald-400 rounded-lg border border-emerald-500/20">
              <Terminal className="h-6 w-6" id="app-logo" />
            </div>
            <div>
              <h1 className="text-xl font-bold tracking-tight text-slate-100 flex items-center gap-2">
                MT5 MQL5 EA Studio
                <span className="text-xs bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded font-medium">
                  DEMO TRADING
                </span>
              </h1>
              <p className="text-xs text-slate-400 font-mono">Hedged EUR Account Companion - 1.000 EUR Capital (1:30)</p>
            </div>
          </div>
          
          <div className="flex items-center gap-2 text-xs font-mono text-slate-400 bg-slate-950 px-3 py-1.5 rounded-md border border-slate-800">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            Algorithmic Trading Stack Active
          </div>
        </div>
      </header>

      {/* MAIN CONTAINER */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* LEFT COLUMN: EA PARAMETERS / INPUTS */}
        <div className="lg:col-span-4 flex flex-col gap-6">
          <section className="bg-slate-900 rounded-xl border border-slate-800 p-5 shadow-xl">
            <div className="flex items-center gap-2 mb-4 border-b border-slate-800 pb-3">
              <Sliders className="h-5 w-5 text-emerald-400" />
              <h2 className="font-semibold text-slate-100">EA Eingabe-Parameter</h2>
            </div>

            <div className="flex flex-col gap-5">
              {/* EMA SETTINGS */}
              <div className="space-y-3">
                <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider font-mono">
                  Indikator Einstellungen
                </span>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-xs text-slate-300">Fast EMA (Period)</label>
                    <input 
                      type="number" 
                      min="2" 
                      max="100"
                      value={fastEMA} 
                      onChange={(e) => setFastEMA(Number(e.target.value))}
                      className="w-full bg-slate-950 border border-slate-800 rounded px-2.5 py-1.5 text-sm font-mono focus:outline-none focus:border-emerald-500 text-emerald-400"
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-xs text-slate-300">Slow EMA (Period)</label>
                    <input 
                      type="number" 
                      min="5" 
                      max="200"
                      value={slowEMA} 
                      onChange={(e) => setSlowEMA(Number(e.target.value))}
                      className="w-full bg-slate-950 border border-slate-800 rounded px-2.5 py-1.5 text-sm font-mono focus:outline-none focus:border-emerald-500 text-emerald-400"
                    />
                  </div>
                </div>
                {isEmaInvalid && (
                  <div className="text-[11px] text-amber-400 flex items-center gap-1 font-mono">
                    <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
                    Warnung: Fast EMA muss kleiner als Slow EMA sein.
                  </div>
                )}
              </div>

              {/* RISK PARAMETERS */}
              <div className="space-y-3 border-t border-slate-850 pt-4">
                <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider font-mono">
                  Risikomanagement
                </span>
                
                <div className="space-y-2">
                  <div className="flex justify-between text-xs">
                    <span className="text-slate-300">Handelsvolumen (Lots)</span>
                    <span className="font-mono text-emerald-400 font-semibold">{lotSize.toFixed(2)} Lots</span>
                  </div>
                  <input 
                    type="range" 
                    min="0.01" 
                    max="1.0" 
                    step="0.01"
                    value={lotSize} 
                    onChange={(e) => setLotSize(Number(e.target.value))}
                    className="w-full accent-emerald-500 h-1 bg-slate-950 rounded-lg cursor-pointer"
                  />
                  <p className="text-[10px] text-slate-400 font-mono">EURUSD Hebel 1:30 | 1 Lot ~ 100K Einheiten</p>
                </div>

                <div className="grid grid-cols-2 gap-4 pt-2">
                  <div className="space-y-1.5">
                    <label className="text-xs text-slate-300">Stop-Loss (%)</label>
                    <div className="relative">
                      <input 
                        type="number" 
                        step="0.1" 
                        min="0.1"
                        value={stopLoss} 
                        onChange={(e) => setStopLoss(Number(e.target.value))}
                        className="w-full bg-slate-950 border border-slate-800 rounded pl-2.5 pr-6 py-1.5 text-sm font-mono focus:outline-none focus:border-emerald-500"
                      />
                      <span className="absolute right-2 top-2 text-xs text-slate-500 font-mono">%</span>
                    </div>
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-xs text-slate-300">Take-Profit (%)</label>
                    <div className="relative">
                      <input 
                        type="number" 
                        step="0.1" 
                        min="0.1"
                        value={takeProfit} 
                        onChange={(e) => setTakeProfit(Number(e.target.value))}
                        className="w-full bg-slate-950 border border-slate-800 rounded pl-2.5 pr-6 py-1.5 text-sm font-mono focus:outline-none focus:border-emerald-500"
                      />
                      <span className="absolute right-2 top-2 text-xs text-slate-500 font-mono">%</span>
                    </div>
                  </div>
                </div>

                <div className="space-y-1.5 pt-1">
                  <div className="flex justify-between text-xs">
                    <span className="text-slate-300">Tagesverlust-Stopp (%)</span>
                    <span className="font-mono text-red-400 font-semibold">{dailyLimit.toFixed(1)}%</span>
                  </div>
                  <div className="relative">
                    <input 
                      type="number" 
                      step="0.5" 
                      min="1"
                      max="20"
                      value={dailyLimit} 
                      onChange={(e) => setDailyLimit(Number(e.target.value))}
                      className="w-full bg-slate-950 border border-slate-800 rounded pl-2.5 pr-6 py-1.5 text-sm font-mono focus:outline-none focus:border-emerald-500"
                    />
                    <span className="absolute right-2 top-2 text-xs text-slate-500 font-mono">%</span>
                  </div>
                </div>
              </div>

              {/* WARNING ALERTS */}
              <div className="border-t border-slate-850 pt-4 flex flex-col gap-2">
                {isBadRR && (
                  <div className="p-3 bg-red-500/10 text-red-400 border border-red-500/20 rounded-lg text-xs flex gap-2">
                    <AlertTriangle className="h-4 w-4 shrink-0 mt-0.5" />
                    <div>
                      <strong className="font-semibold block">Risk/Reward Alarm!</strong>
                      Dein Stop-Loss ({stopLoss}%) ist groesser als dein Take-Profit ({takeProfit}%). Ein Verlusttrade wiegt schwerer als ein Gewinntrade.
                    </div>
                  </div>
                )}
                {isTooHighRisk && (
                  <div className="p-3 bg-amber-500/10 text-amber-400 border border-amber-500/20 rounded-lg text-xs flex gap-2">
                    <ShieldAlert className="h-4 w-4 shrink-0 mt-0.5" />
                    <div>
                      <strong className="font-semibold block">Extrem hohes Volumen!</strong>
                      Ein Lot-Volumen von {lotSize} ist extrem gross fuer ein 1.000 EUR Konto (Hebel 1:30). Eine starke Gegenbewegung kann zum Margin Call fuehren!
                    </div>
                  </div>
                )}
                {!isBadRR && !isTooHighRisk && !isEmaInvalid && (
                  <div className="p-3 bg-emerald-500/5 text-emerald-400 border border-emerald-500/10 rounded-lg text-xs flex gap-2">
                    <CheckCircle2 className="h-4 w-4 shrink-0 mt-0.5" />
                    <div>
                      <strong className="font-semibold block">Parameter im gruenen Bereich</strong>
                      Deine Risiko-Parameter sind ausgeglichen und entsprechen den Trading-Sicherheitsrichtlinien.
                    </div>
                  </div>
                )}
              </div>
            </div>
          </section>

          {/* QUICK SUMMARY CARD */}
          <section className="bg-slate-900 rounded-xl border border-slate-800 p-5">
            <h3 className="font-semibold text-slate-200 mb-3 text-xs font-mono uppercase tracking-wider">
              Tages-Schutzmechanismus
            </h3>
            <div className="grid grid-cols-2 gap-3 text-xs font-mono">
              <div className="bg-slate-950 p-2.5 rounded border border-slate-850">
                <span className="text-slate-500 block mb-0.5">Tagesguthaben:</span>
                <span className="text-slate-200 font-bold">1.000,00 EUR</span>
              </div>
              <div className="bg-slate-950 p-2.5 rounded border border-slate-850">
                <span className="text-slate-500 block mb-0.5">Absoluter Stopp:</span>
                <span className="text-red-400 font-bold font-mono">{(1000 * (dailyLimit / 100.0)).toFixed(2)} EUR</span>
              </div>
            </div>
            <p className="text-[11px] text-slate-400 mt-3 italic leading-relaxed">
              *Wenn dein Gesamt-Drawdown heute diesen Betrag ueberschreitet, schliesst der EA alle Positionen und pausiert bis morgen.
            </p>
          </section>
        </div>

        {/* RIGHT COLUMN: WORKSPACE / SIMULATOR / CODE / ANALYSIS */}
        <div className="lg:col-span-8 flex flex-col gap-6">
          {/* NAVIGATION TABS */}
          <div className="flex border-b border-slate-800 bg-slate-900/40 p-1 rounded-lg">
            <button
              onClick={() => setActiveTab("simulator")}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 text-xs md:text-sm font-medium rounded-md transition-all ${
                activeTab === "simulator"
                  ? "bg-slate-800 text-emerald-400 shadow-md font-semibold"
                  : "text-slate-400 hover:text-slate-200"
              }`}
            >
              <Activity className="h-4 w-4" />
              Backtest-Simulator
            </button>
            <button
              onClick={() => setActiveTab("code")}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 text-xs md:text-sm font-medium rounded-md transition-all ${
                activeTab === "code"
                  ? "bg-slate-800 text-emerald-400 shadow-md font-semibold"
                  : "text-slate-400 hover:text-slate-200"
              }`}
            >
              <FileText className="h-4 w-4" />
              MQL5 Code & Download
            </button>
            <button
              onClick={() => setActiveTab("ai")}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 text-xs md:text-sm font-medium rounded-md transition-all ${
                activeTab === "ai"
                  ? "bg-slate-800 text-emerald-400 shadow-md font-semibold"
                  : "text-slate-400 hover:text-slate-200"
              }`}
            >
              <Cpu className="h-4 w-4" />
              AI Backtest-Analyst
            </button>
            <button
              onClick={() => setActiveTab("guide")}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 text-xs md:text-sm font-medium rounded-md transition-all ${
                activeTab === "guide"
                  ? "bg-slate-800 text-emerald-400 shadow-md font-semibold"
                  : "text-slate-400 hover:text-slate-200"
              }`}
            >
              <BookOpen className="h-4 w-4" />
              MT5 Anleitung
            </button>
          </div>

          {/* TAB CONTENTS */}
          <div className="bg-slate-900 rounded-xl border border-slate-800 p-6 min-h-[500px] shadow-xl flex flex-col justify-between">
            <AnimatePresence mode="wait">
              {activeTab === "simulator" && (
                <motion.div
                  key="simulator-tab"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="space-y-6"
                >
                  <div className="flex justify-between items-center flex-wrap gap-2">
                    <div>
                      <h3 className="font-bold text-lg text-slate-100">Live-Backtest-Simulation</h3>
                      <p className="text-xs text-slate-400">Interaktive Simulation ueber 30 Handelstage auf EURUSD H4</p>
                    </div>
                    <button
                      onClick={handleRunSimulation}
                      disabled={simLoading}
                      className="bg-emerald-500 hover:bg-emerald-600 active:scale-95 disabled:opacity-50 text-slate-950 font-bold text-xs px-4 py-2 rounded-lg flex items-center gap-2 transition-all shadow-lg shadow-emerald-500/10 cursor-pointer"
                    >
                      {simLoading ? (
                        <RefreshCw className="h-4 w-4 animate-spin" />
                      ) : (
                        <Play className="h-4 w-4 fill-current" />
                      )}
                      Simulation ausfuehren
                    </button>
                  </div>

                  {/* METRICS GRID */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="bg-slate-950 p-4 rounded-lg border border-slate-850">
                      <span className="text-xs text-slate-400 block mb-1 font-mono">Netto-Gewinn</span>
                      <span className={`text-lg font-bold font-mono flex items-center gap-1 ${simData.metrics.netProfit >= 0 ? "text-emerald-400" : "text-red-400"}`}>
                        {simData.metrics.netProfit >= 0 ? <TrendingUp className="h-4 w-4" /> : <TrendingDown className="h-4 w-4" />}
                        {simData.metrics.netProfit >= 0 ? "+" : ""}
                        {simData.metrics.netProfit.toFixed(2)} EUR
                        <span className="text-xs font-normal">({simData.metrics.netProfitPct}%)</span>
                      </span>
                    </div>

                    <div className="bg-slate-950 p-4 rounded-lg border border-slate-850">
                      <span className="text-xs text-slate-400 block mb-1 font-mono">Win Rate (Gewinnrate)</span>
                      <span className="text-lg font-bold font-mono text-slate-200">
                        {simData.metrics.winRate}%
                        <span className="text-xs text-slate-500 font-normal block">
                          {simData.metrics.winningTrades} von {simData.metrics.totalTrades} Trades
                        </span>
                      </span>
                    </div>

                    <div className="bg-slate-950 p-4 rounded-lg border border-slate-850">
                      <span className="text-xs text-slate-400 block mb-1 font-mono">Profit Factor</span>
                      <span className={`text-lg font-bold font-mono ${simData.metrics.profitFactor >= 1.5 ? "text-emerald-400" : simData.metrics.profitFactor >= 1.0 ? "text-amber-400" : "text-red-400"}`}>
                        {simData.metrics.profitFactor}
                      </span>
                    </div>

                    <div className="bg-slate-950 p-4 rounded-lg border border-slate-850">
                      <span className="text-xs text-slate-400 block mb-1 font-mono">Max. Drawdown</span>
                      <span className="text-lg font-bold font-mono text-red-400">
                        -{simData.metrics.maxDrawdown.toFixed(2)} EUR
                        <span className="text-xs font-normal">({simData.metrics.maxDrawdownPct}%)</span>
                      </span>
                    </div>
                  </div>

                  {/* EQUITY CURVE CHART */}
                  <div className="bg-slate-950 p-4 rounded-lg border border-slate-850 h-[280px]">
                    <span className="text-xs font-mono font-semibold text-slate-400 mb-3 block">
                      Kapitalkurven-Verlauf (Equity in EUR)
                    </span>
                    <ResponsiveContainer width="100%" height="90%">
                      <LineChart data={simData.equityCurve}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#1E293B" />
                        <XAxis dataKey="day" stroke="#64748B" fontSize={11} tickLine={false} />
                        <YAxis stroke="#64748B" fontSize={11} tickLine={false} domain={["dataMin - 50", "dataMax + 50"]} />
                        <Tooltip 
                          contentStyle={{ backgroundColor: "#020617", borderColor: "#1E293B", color: "#F1F5F9", fontSize: "12px", fontFamily: "monospace" }}
                          labelFormatter={(label) => `Tag ${label}`}
                        />
                        <Line type="monotone" dataKey="equity" stroke="#10B981" strokeWidth={2.5} dot={false} />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>

                  {/* SIMULATED TRADES HISTROY */}
                  <div className="space-y-3">
                    <div className="flex justify-between items-center">
                      <h4 className="text-sm font-semibold text-slate-200 font-mono flex items-center gap-2">
                        <History className="h-4 w-4" />
                        Transaktions-Protokoll (Simulation)
                      </h4>
                      {simData.metrics.dailyLossStopsTriggered > 0 && (
                        <span className="text-[10px] bg-red-500/10 text-red-400 border border-red-500/20 px-2 py-0.5 rounded font-mono">
                          🚨 {simData.metrics.dailyLossStopsTriggered}x Tagesverlust-Limit gegriffen!
                        </span>
                      )}
                    </div>
                    <div className="bg-slate-950 rounded-lg border border-slate-850 divide-y divide-slate-850 max-h-[220px] overflow-y-auto font-mono">
                      {simData.trades.length === 0 ? (
                        <p className="p-4 text-xs text-slate-500 text-center">Keine Trades in diesem Durchlauf generiert.</p>
                      ) : (
                        simData.trades.map((trade) => (
                          <div key={trade.id} className="p-3 flex justify-between items-center text-xs hover:bg-slate-900/50">
                            <div>
                              <div className="flex items-center gap-2">
                                <span className={`px-1.5 py-0.5 rounded text-[10px] font-bold ${
                                  trade.type === "TP_HIT" ? "bg-emerald-500/15 text-emerald-400" :
                                  trade.type === "SL_HIT" ? "bg-red-500/15 text-red-400" :
                                  trade.type === "BLOCKED" ? "bg-red-950 text-red-400 border border-red-500/20" :
                                  "bg-slate-800 text-slate-300"
                                }`}>
                                  {trade.type}
                                </span>
                                <span className="text-slate-400 text-[10px]">{trade.time}</span>
                              </div>
                              <p className="text-[11px] text-slate-300 mt-1">{trade.comment}</p>
                            </div>
                            <div className="text-right">
                              {trade.type !== "BLOCKED" ? (
                                <>
                                  <span className={`font-bold ${trade.profit >= 0 ? "text-emerald-400" : "text-red-400"}`}>
                                    {trade.profit >= 0 ? "+" : ""}{trade.profit.toFixed(2)} EUR
                                  </span>
                                  <span className="text-[10px] text-slate-500 block">Kurs: {trade.price.toFixed(4)}</span>
                                </>
                              ) : (
                                <span className="text-slate-500 text-[10px] italic">Handel ausgesetzt</span>
                              )}
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </div>
                </motion.div>
              )}

              {activeTab === "code" && (
                <motion.div
                  key="code-tab"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="space-y-5"
                >
                  <div className="flex justify-between items-start flex-wrap gap-4">
                    <div>
                      <h3 className="font-bold text-lg text-slate-100">Detaillierter MQL5 Expert Advisor Code</h3>
                      <p className="text-xs text-slate-400">
                        Generiert basierend auf deinen Eingabe-Parametern. Komplett fertig zum Backtesten in MT5.
                      </p>
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={copyToClipboard}
                        className="bg-slate-800 hover:bg-slate-700 active:scale-95 text-slate-200 text-xs px-3.5 py-2 rounded-lg flex items-center gap-2 transition-all cursor-pointer border border-slate-700"
                      >
                        {copied ? (
                          <>
                            <Check className="h-4 w-4 text-emerald-400" />
                            Kopiert!
                          </>
                        ) : (
                          <>
                            <Copy className="h-4 w-4" />
                            Code kopieren
                          </>
                        )}
                      </button>
                      <button
                        onClick={handleDownloadCode}
                        className="bg-emerald-500 hover:bg-emerald-600 active:scale-95 text-slate-950 font-bold text-xs px-3.5 py-2 rounded-lg flex items-center gap-2 transition-all cursor-pointer shadow-lg shadow-emerald-500/10"
                      >
                        <Download className="h-4 w-4" />
                        Download .MQ5
                      </button>
                    </div>
                  </div>

                  {/* SYNTAX PREVIEW */}
                  <div className="relative">
                    <div className="absolute top-3 right-3 bg-slate-900/80 border border-slate-850 px-2 py-1 rounded text-[10px] font-mono text-slate-400">
                      ema_9_21_crossover_long.mq5
                    </div>
                    <pre className="bg-slate-950 border border-slate-850 p-4 rounded-lg text-[11px] font-mono text-slate-300 overflow-x-auto max-h-[380px] leading-relaxed">
                      <code>{customCode}</code>
                    </pre>
                  </div>

                  <div className="p-4 bg-slate-950 border border-slate-850 rounded-lg space-y-2">
                    <span className="text-xs font-semibold text-emerald-400 font-mono block">
                      💡 MQL5 MetaEditor Tipp:
                    </span>
                    <p className="text-xs text-slate-400 leading-relaxed">
                      Der Code enthaelt absichtlich **keine** Umlaute (ae, oe, ue, ss) in den Kommentaren. Dies verhindert fehlerhafte Zeichendarstellung im MetaTrader 5 MetaEditor auf Computern mit unterschiedlichen Spracheinstellungen und sorgt fuer reibungsloses Kompilieren.
                    </p>
                  </div>
                </motion.div>
              )}

              {activeTab === "ai" && (
                <motion.div
                  key="ai-tab"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="space-y-6"
                >
                  <div>
                    <h3 className="font-bold text-lg text-slate-100 flex items-center gap-2">
                      <Cpu className="h-5 w-5 text-emerald-400" />
                      AI Backtest-Analyst (Gemini)
                    </h3>
                    <p className="text-xs text-slate-400">
                      Lass die Gemini-KI deine Backtest-Ergebnisse analysieren und strategische MQL5-Codeoptimierungen vorschlagen.
                    </p>
                  </div>

                  {/* INPUT FIELDS FOR BACKTEST */}
                  <div className="bg-slate-950 p-4 rounded-lg border border-slate-850 space-y-4">
                    <div className="flex justify-between items-center border-b border-slate-850 pb-2">
                      <span className="text-xs font-mono font-semibold text-slate-300">
                        Backtest-Kennzahlen eingeben
                      </span>
                      <button
                        onClick={loadExampleMetrics}
                        className="text-[10px] text-emerald-400 hover:underline flex items-center gap-1 font-mono cursor-pointer"
                      >
                        Aus Simulator auslesen
                      </button>
                    </div>

                    <div className="grid grid-cols-2 md:grid-cols-5 gap-3 font-mono text-xs">
                      <div className="space-y-1">
                        <label className="text-slate-400">Netto-Gewinn (EUR)</label>
                        <input
                          type="text"
                          value={metricsInput.netProfit}
                          onChange={(e) => setMetricsInput({ ...metricsInput, netProfit: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-800 rounded p-1.5 focus:outline-none focus:border-emerald-500"
                        />
                      </div>
                      <div className="space-y-1">
                        <label className="text-slate-400">Win Rate (%)</label>
                        <input
                          type="text"
                          value={metricsInput.winRate}
                          onChange={(e) => setMetricsInput({ ...metricsInput, winRate: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-800 rounded p-1.5 focus:outline-none focus:border-emerald-500"
                        />
                      </div>
                      <div className="space-y-1">
                        <label className="text-slate-400">Profit Factor</label>
                        <input
                          type="text"
                          value={metricsInput.profitFactor}
                          onChange={(e) => setMetricsInput({ ...metricsInput, profitFactor: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-800 rounded p-1.5 focus:outline-none focus:border-emerald-500"
                        />
                      </div>
                      <div className="space-y-1">
                        <label className="text-slate-400">Max. Drawdown (%)</label>
                        <input
                          type="text"
                          value={metricsInput.maxDrawdown}
                          onChange={(e) => setMetricsInput({ ...metricsInput, maxDrawdown: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-800 rounded p-1.5 focus:outline-none focus:border-emerald-500"
                        />
                      </div>
                      <div className="space-y-1">
                        <label className="text-slate-400">Trades Anzahl</label>
                        <input
                          type="text"
                          value={metricsInput.totalTrades}
                          onChange={(e) => setMetricsInput({ ...metricsInput, totalTrades: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-800 rounded p-1.5 focus:outline-none focus:border-emerald-500"
                        />
                      </div>
                    </div>

                    <button
                      onClick={handleAIAnalysis}
                      disabled={aiLoading}
                      className="w-full bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-slate-950 font-bold py-2.5 rounded-lg text-xs flex justify-center items-center gap-2 transition-all cursor-pointer shadow-lg shadow-emerald-500/10"
                    >
                      {aiLoading ? (
                        <>
                          <RefreshCw className="h-4 w-4 animate-spin" />
                          Gemini analysiert Backtest-Performance...
                        </>
                      ) : (
                        <>
                          <Cpu className="h-4 w-4" />
                          Backtest mit Gemini analysieren
                        </>
                      )}
                    </button>
                  </div>

                  {/* AI OUTPUT */}
                  <AnimatePresence mode="wait">
                    {aiLoading && (
                      <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        className="py-12 flex flex-col items-center gap-3"
                      >
                        <div className="w-10 h-10 border-4 border-emerald-500/20 border-t-emerald-500 rounded-full animate-spin"></div>
                        <p className="text-xs text-slate-400 font-mono">Generiere strategische Risiko- & Portfolioanalyse...</p>
                      </motion.div>
                    )}

                    {aiError === "key_missing" && (
                      <motion.div
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="p-5 bg-amber-500/10 border border-amber-500/20 rounded-xl space-y-3"
                      >
                        <div className="flex items-center gap-2 text-amber-400">
                          <AlertTriangle className="h-5 w-5 shrink-0" />
                          <h4 className="font-bold text-sm">Gemini API Key erforderlich</h4>
                        </div>
                        <p className="text-xs text-slate-300 leading-relaxed">
                          Die Live-KI-Analyse erfordert einen Gemini API Key. Da wir deine API Keys extrem sicher server-seitig verwalten, musst du deinen Key im Secrets-Panel deiner Workspace-Einstellungen eintragen.
                        </p>
                        <div className="bg-slate-950 p-3 rounded text-xs font-mono text-slate-400 border border-slate-850">
                          Hinterlege den Wert in: <strong className="text-amber-400 font-semibold">GEMINI_API_KEY</strong>
                        </div>
                        <p className="text-xs text-slate-400 italic">
                          *Keine Sorge! Du kannst den Simulator und den MQL5 Code-Download unbegrenzt und voll funktionsfaehig offline nutzen!
                        </p>
                      </motion.div>
                    )}

                    {aiError && aiError !== "key_missing" && (
                      <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        className="p-4 bg-red-500/10 border border-red-500/20 text-red-400 rounded-lg text-xs"
                      >
                        {aiError}
                      </motion.div>
                    )}

                    {aiResult && (
                      <motion.div
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        className="space-y-5"
                      >
                        {/* ANALYSIS GRID */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                          <div className="bg-slate-950 p-4 rounded-lg border border-slate-850 space-y-2">
                            <span className="text-xs text-emerald-400 font-mono font-semibold flex items-center gap-1.5">
                              <CheckCircle2 className="h-4 w-4" />
                              Performance-Bewertung
                            </span>
                            <p className="text-xs text-slate-300 leading-relaxed">
                              {aiResult.evaluation}
                            </p>
                          </div>

                          <div className="bg-slate-950 p-4 rounded-lg border border-slate-850 space-y-2">
                            <span className="text-xs text-red-400 font-mono font-semibold flex items-center gap-1.5">
                              <ShieldAlert className="h-4 w-4" />
                              Risikomanagement-Check
                            </span>
                            <p className="text-xs text-slate-300 leading-relaxed">
                              {aiResult.riskAssessment}
                            </p>
                          </div>
                        </div>

                        {/* SUGGESTIONS LIST */}
                        <div className="bg-slate-950 p-4 rounded-lg border border-slate-850 space-y-3">
                          <span className="text-xs text-emerald-400 font-mono font-semibold">
                            Strategische Optimierungsvorschlaege
                          </span>
                          <ul className="space-y-2 text-xs text-slate-300 list-disc list-inside">
                            {aiResult.suggestions.map((s, index) => (
                              <li key={index} className="leading-relaxed">{s}</li>
                            ))}
                          </ul>
                        </div>

                        {/* CODE SNIPPET */}
                        <div className="space-y-2">
                          <span className="text-xs text-emerald-400 font-mono font-semibold block">
                            MQL5 Code-Optimierungsbeispiel
                          </span>
                          <pre className="bg-slate-950 border border-slate-850 p-4 rounded-lg text-[10px] font-mono text-slate-300 overflow-x-auto max-h-[220px] leading-relaxed">
                            <code>{aiResult.refinedCodeSnippet}</code>
                          </pre>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </motion.div>
              )}

              {activeTab === "guide" && (
                <motion.div
                  key="guide-tab"
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -10 }}
                  className="space-y-5 text-xs text-slate-300 leading-relaxed"
                >
                  <h3 className="font-bold text-lg text-slate-100 mb-2">Setup-Anleitung fuer MetaTrader 5</h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="bg-slate-950 p-4 rounded-lg border border-slate-850 space-y-3">
                      <span className="text-sm font-semibold text-emerald-400 flex items-center gap-2">
                        <span className="w-5 h-5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs flex items-center justify-center rounded font-mono">1</span>
                        In MT5 einrichten
                      </span>
                      <p className="text-slate-400">
                        Oeffne dein MetaTrader 5 Terminal. Klicke links oben auf **Datei → Dateiordner oeffnen**. Navigiere in das Verzeichnis:
                      </p>
                      <code className="block bg-slate-900 p-2 rounded text-[10px] text-slate-300 font-mono select-all">
                        MQL5\Experts\
                      </code>
                      <p className="text-slate-400">
                        Kopiere deine heruntergeladene `.mq5` Datei genau in diesen Ordner.
                      </p>
                    </div>

                    <div className="bg-slate-950 p-4 rounded-lg border border-slate-850 space-y-3">
                      <span className="text-sm font-semibold text-emerald-400 flex items-center gap-2">
                        <span className="w-5 h-5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs flex items-center justify-center rounded font-mono">2</span>
                        Code kompilieren
                      </span>
                      <p className="text-slate-400">
                        Oeffne den MetaEditor durch Druecken der Taste **F4** in MT5.
                      </p>
                      <p className="text-slate-400">
                        Suche links im Navigator unter „Experts“ deine Datei, doppelklicke sie und druecke oben auf den Knopf **„Kompilieren“** (oder **F7**).
                      </p>
                      <p className="text-emerald-400 font-semibold font-mono">
                        → Status unten muss „0 errors“ anzeigen.
                      </p>
                    </div>

                    <div className="bg-slate-950 p-4 rounded-lg border border-slate-850 space-y-3">
                      <span className="text-sm font-semibold text-emerald-400 flex items-center gap-2">
                        <span className="w-5 h-5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs flex items-center justify-center rounded font-mono">3</span>
                        Strategy Tester (Backtest)
                      </span>
                      <p className="text-slate-400">
                        Druecke in MT5 **Strg+R**, um den Strategy Tester zu oeffnen.
                      </p>
                      <p className="text-slate-400">
                        Waehle den EA aus. Setze das Symbol auf **EURUSD**, den Zeitrahmen auf **H4**, die Einzahlung auf **1000 EUR**, Hebel auf **1:30** und druecke auf Start, um den Backtest durchzufuehren.
                      </p>
                    </div>

                    <div className="bg-slate-950 p-4 rounded-lg border border-slate-850 space-y-3">
                      <span className="text-sm font-semibold text-emerald-400 flex items-center gap-2">
                        <span className="w-5 h-5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs flex items-center justify-center rounded font-mono">4</span>
                        Automatisches Demo-Trading
                      </span>
                      <p className="text-slate-400">
                        Ziehe den EA per Drag & Drop auf ein offenes EURUSD-H4-Chartfenster.
                      </p>
                      <p className="text-slate-400">
                        Aktiviere in der oberen Menueleiste von MT5 den Knopf **„Algo Trading“** (wird gruen). Der EA handelt nun vollkommen automatisiert auf deinem Demo-Konto!
                      </p>
                    </div>
                  </div>

                  <div className="p-4 bg-red-500/10 border border-red-500/20 rounded-lg">
                    <strong className="text-red-400 font-bold block mb-1">
                      ⚠️ Absoluter Sicherheitshinweis:
                    </strong>
                    <p className="text-slate-300 leading-relaxed">
                      Lasse diesen Expert Advisor niemals ungetestet auf einem Live-Konto (Echtgeld) laufen. Nutze die Sicherheits-Reihenfolge: Erst im **MT5 Strategy Tester backtesten**, danach mindestens 4 Wochen auf einem **Demo-Konto paper-traden**, bevor du ueber weitere Schritte nachdenkst!
                    </p>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            {/* LOWER STATS BAR */}
            <div className="border-t border-slate-850 pt-4 mt-6 flex justify-between items-center text-[10px] text-slate-500 font-mono">
              <span>Stack: React + Tailwind CSS v4 + Express + Gemini 3.5</span>
              <span>Made with AI Studio Build</span>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
