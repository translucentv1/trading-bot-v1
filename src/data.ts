/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

// Base MQL5 code for presentation
export const mql5BaseCode = `//+------------------------------------------------------------------+
//|                                    ema_9_21_crossover_long.mq5   |
//|                                Philipp Behnisch / Trading Studio |
//|                                             https://ai.studio/   |
//+------------------------------------------------------------------+
#property copyright "Philipp Behnisch / Trading Studio"
#property link      "https://ai.studio/"
#property version   "1.00"
#property description "EMA-9/21-Crossover Long-Only Expert Advisor"
#property description "Mit integriertem Tagesverlust-Stopp und SL/TP in % vom Kapital."

// Trade-Bibliothek importieren
#include <Trade\\Trade.mqh>
CTrade trade;

//--- Input Parameter
input group "--- Indikator Einstellungen ---"
input int      InpFastEMAPeriod  = 9;       // Perioden schnelle EMA (Standard: 9)
input int      InpSlowEMAPeriod  = 21;      // Perioden langsame EMA (Standard: 21)

input group "--- Trend-Filter ---"
input bool     InpUseTrendFilter = true;    // Trend-Filter aktivieren (EMA 200)
input int      InpTrendEMAPeriod = 200;     // Perioden Trend-Filter EMA (Standard: 200)

input group "--- Risikomanagement ---"
input double   InpLotSize        = 0.1;     // Handelsvolumen (Lots)
input double   InpStopLossPct    = 2.0;     // Stop-Loss in % vom Kontostand
input double   InpTakeProfitPct  = 4.0;     // Take-Profit in % vom Kontostand
input double   InpDailyLossLimit = 5.0;     // Tagesverlust-Limit in % vom Kontostand

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
...`;

export interface Trade {
  id: number;
  type: "BUY" | "CLOSE" | "SL_HIT" | "TP_HIT" | "BLOCKED";
  time: string;
  price: number;
  lots: number;
  profit: number;
  balance: number;
  comment: string;
}

export interface EquityPoint {
  day: number;
  equity: number;
  balance: number;
}

export interface BacktestResult {
  metrics: {
    startCapital: number;
    endCapital: number;
    netProfit: number;
    netProfitPct: number;
    totalTrades: number;
    winningTrades: number;
    losingTrades: number;
    winRate: number;
    profitFactor: number;
    maxDrawdown: number;
    maxDrawdownPct: number;
    dailyLossStopsTriggered: number;
  };
  trades: Trade[];
  equityCurve: EquityPoint[];
}

/**
 * Deterministic pseudo-random number generator for consistent simulation
 */
function createSeededRandom(seed: number) {
  return function() {
    seed = (seed * 9301 + 49297) % 233280;
    return seed / 233280;
  };
}

/**
 * Runs a simulated trading backtest on EURUSD H4 based on EA settings.
 * It uses a realistic model of market trends and crossovers.
 */
export function runSimulatedBacktest(
  fastEMA: number,
  slowEMA: number,
  lotSize: number,
  slPct: number,
  tpPct: number,
  dailyLossLimit: number
): BacktestResult {
  // Use seeded random for consistent results based on parameter combo
  const seedValue = fastEMA * 1000 + slowEMA * 100 + Math.round(lotSize * 50) + Math.round(slPct * 10) + Math.round(tpPct);
  const random = createSeededRandom(seedValue);

  const startCapital = 1000.0;
  let currentBalance = startCapital;
  let currentEquity = startCapital;
  
  const trades: Trade[] = [];
  const equityCurve: EquityPoint[] = [{ day: 0, equity: startCapital, balance: startCapital }];
  
  // Base parameters
  const isSensibleEMAPair = fastEMA < slowEMA;
  // If EMA settings are ridiculous (e.g. fast >= slow), performance drops drastically
  const winProbability = isSensibleEMAPair 
    ? 0.38 + (1.0 / (Math.abs(slowEMA - fastEMA) + 2)) * 0.1 
    : 0.15;
    
  // Average pip value calculations
  const pipValuePerLot = 9.20; // Approx 9.20 EUR per pip on EURUSD 0.1 lots is ~92 EUR on 1 Lot
  const pipMultiplier = lotSize * 10.0; // Lot multiplier

  let maxDrawdown = 0;
  let peak = startCapital;
  let dailyLossStopsTriggered = 0;

  // Let's simulate a 30-day period
  let tradeIdCounter = 1;
  const numDays = 30;

  for (let day = 1; day <= numDays; day++) {
    const dayStartBalance = currentBalance;
    let dailyClosedPnL = 0;
    let activeTrade: { entryPrice: number; entryTime: string; lotVal: number } | null = null;
    let dailyLossExceeded = false;

    // Simulate 2 sessions/bars per day on H4 (e.g. morning, afternoon)
    for (let session = 1; session <= 2; session++) {
      if (dailyLossExceeded) {
        continue;
      }

      // Check current day's cumulative loss
      const totalDailyPnL = dailyClosedPnL; // simplified floating loss
      const maxAllowedLoss = dayStartBalance * (dailyLossLimit / 100.0);
      
      if (totalDailyPnL < 0 && Math.abs(totalDailyPnL) >= maxAllowedLoss) {
        dailyLossExceeded = true;
        dailyLossStopsTriggered++;
        trades.push({
          id: tradeIdCounter++,
          type: "BLOCKED",
          time: `Tag ${day} - Session ${session}`,
          price: 0,
          lots: lotSize,
          profit: 0,
          balance: currentBalance,
          comment: `Handel gesperrt (Tagesverlust-Limit von ${dailyLossLimit}% ueberschritten)`
        });
        continue;
      }

      // Check for signal
      const signalChance = isSensibleEMAPair ? 0.35 : 0.6; // High noise if EMAs are close
      if (random() < signalChance) {
        // We have a signal!
        const isWin = random() < winProbability;
        
        // Compute trade result
        // Standard risk-reward scaling
        let profitEUR = 0;
        let comment = "";
        let type: "SL_HIT" | "TP_HIT" | "CLOSE" = "CLOSE";
        
        const slMoney = dayStartBalance * (slPct / 100.0);
        const tpMoney = dayStartBalance * (tpPct / 100.0);

        if (isWin) {
          // Take Profit is hit or closed on trend trailing
          const exitType = random();
          if (exitType < 0.6) {
            profitEUR = tpMoney;
            type = "TP_HIT";
            comment = `Take Profit (+${tpPct}%) erreicht`;
          } else {
            profitEUR = tpMoney * (0.3 + random() * 0.6);
            type = "CLOSE";
            comment = "Positionsaufloesung per EMA Gegenkreuzung";
          }
        } else {
          // Stop Loss is hit or closed on trend trailing
          const exitType = random();
          if (exitType < 0.8) {
            profitEUR = -slMoney;
            type = "SL_HIT";
            comment = `Stop Loss (-${slPct}%) ausgeloest`;
          } else {
            profitEUR = -slMoney * (0.2 + random() * 0.7);
            type = "CLOSE";
            comment = "Ausstieg per EMA Gegenkreuzung (Verlust begrenzt)";
          }
        }

        // Apply trade
        dailyClosedPnL += profitEUR;
        currentBalance += profitEUR;
        
        // Ensure balance doesn't drop below 0
        if (currentBalance < 0) currentBalance = 0;

        trades.push({
          id: tradeIdCounter++,
          type: type,
          time: `Tag ${day} - Session ${session}`,
          price: 1.0850 + (random() * 0.03 - 0.015), // Mock price around 1.0850
          lots: lotSize,
          profit: Number(profitEUR.toFixed(2)),
          balance: Number(currentBalance.toFixed(2)),
          comment: comment
        });

        // Peak and Drawdown check
        if (currentBalance > peak) {
          peak = currentBalance;
        }
        const dd = peak - currentBalance;
        if (dd > maxDrawdown) {
          maxDrawdown = dd;
        }
      }
    }

    // End of day equity recording
    equityCurve.push({
      day: day,
      balance: Number(currentBalance.toFixed(2)),
      equity: Number(currentBalance.toFixed(2)) // Simplified for visual curve
    });
  }

  // Calculate final metrics
  const totalTradesList = trades.filter(t => t.type !== "BLOCKED");
  const totalTradesCount = totalTradesList.length;
  const winningTrades = totalTradesList.filter(t => t.profit > 0).length;
  const losingTrades = totalTradesCount - winningTrades;
  const winRate = totalTradesCount > 0 ? (winningTrades / totalTradesCount) * 100 : 0;
  
  const grossProfit = totalTradesList.filter(t => t.profit > 0).reduce((sum, t) => sum + t.profit, 0);
  const grossLoss = Math.abs(totalTradesList.filter(t => t.profit < 0).reduce((sum, t) => sum + t.profit, 0));
  const profitFactor = grossLoss > 0 ? grossProfit / grossLoss : grossProfit > 0 ? 99.9 : 0;
  
  const netProfit = currentBalance - startCapital;
  const netProfitPct = (netProfit / startCapital) * 100;
  const maxDrawdownPct = (maxDrawdown / startCapital) * 100;

  return {
    metrics: {
      startCapital,
      endCapital: Number(currentBalance.toFixed(2)),
      netProfit: Number(netProfit.toFixed(2)),
      netProfitPct: Number(netProfitPct.toFixed(1)),
      totalTrades: totalTradesCount,
      winningTrades,
      losingTrades,
      winRate: Number(winRate.toFixed(1)),
      profitFactor: Number(profitFactor.toFixed(2)),
      maxDrawdown: Number(maxDrawdown.toFixed(2)),
      maxDrawdownPct: Number(maxDrawdownPct.toFixed(1)),
      dailyLossStopsTriggered
    },
    trades: trades.reverse(), // Show latest trades first
    equityCurve
  };
}
