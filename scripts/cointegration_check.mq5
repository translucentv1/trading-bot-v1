//+------------------------------------------------------------------+
//| Cointegration-Pre-Check (Phase 1)                               |
//| Antwort auf AI-Studio-Review (REVIEW_VERBESSERUNG.md, 13.07.)    |
//|                                                                  |
//| Zweck: Bevor wir einen Pair-Trading-EA bauen, pruefen wir, ob    |
//|   zwei Symbole ueberhaupt COINTEGRIERT sind. Pair-Trading (Mean- |
//|   Reversion im Spread) funktioniert nur bei cointegrierten       |
//|   Paaren - Korrelation allein reicht nicht (AI-Studio-Blindstelle|
//|   #2). Ist kein Paar cointegriert, sparen wir uns den EA-Bau.    |
//|                                                                  |
//| Methode: Engle-Granger 2-Schritt                                 |
//|   1) OLS-Regression:  A = alpha + beta * B + e          (beta =  |
//|      Hedge-Ratio = Cov(A,B)/Var(B))                             |
//|   2) Spread = Log(A) - beta * Log(B)  (Log wegen Multiplikativ.) |
//|   3) ADF-Test auf Spread (Augmented Dickey-Fuller):              |
//|      dS_t = alpha + rho*S_{t-1} + phi*dS_{t-1} + u_t            |
//|      H0: rho = 0  (Unit Root = NICHT stationaer = NICHT          |
//|      cointegriert). Teststatistik = t-Wert von rho.              |
//|   4) Vergleich mit MacKinnon-Kritischen Werten (1991):          |
//|      1%=-3.43, 5%=-2.86, 10%=-2.57 fuer 2 Variablen.            |
//|                                                                  |
//| LOOK-AHEAD-FREI (AI-Studio-Blindstelle #7):                      |
//|   Alle Berechnungen verwenden geschlossene Kerzen ab Index 1,    |
//|   NIEMALS Index 0 (die gerade laufende Kerze). Damit ist das     |
//|   Ergebnis identisch zu dem, was ein Live-EA zum Signalzeitpunkt |
//|   gesehen haette.                                                |
//|                                                                  |
//| Ausgabe:                                                         |
//|   - Print() im CSV-Format (Semikolon, Punkt als Dezimaltrenner)  |
//|   - Datei Common\Files\cointegration_result.txt                  |
//|                                                                  |
//| AUFRUF: Im MT5 als SCRIPT auf ein Chart ziehen (Symbol A).       |
//|   InpSymbolB einstellen, Zeitraum/TF im Chart. Laeuft nur einmal.|
//|   VOR Phase 2 (Pair-Trading-EA) fuer alle 15 Paar-Kombinationen  |
//|   des 6er-Korbs laufen lassen.                                   |
//+------------------------------------------------------------------+
#property copyright "Phase 3 - Forschung (Cointegration-Pre-Check)"
#property version   "1.00"
#property strict
#property description "Engle-Granger Cointegration-Test (OLS + ADF)."
#property description "Look-Ahead-frei (Kerzen ab Index 1). Vor Pair-Trading-EA pruefen."

//--- Eingaben -------------------------------------------------------
input group "--- Symbole ---"
input string  InpSymbolA     = "";        // Symbol A (leer = aktuelles Chart-Symbol)
input string  InpSymbolB     = "GBPUSD";  // Symbol B
input bool    InpUseLog      = true;      // Log-Preise verwenden (empfohlen)

//--- Fenster / Zeitreihe -------------------------------------------
input group "--- Zeitreihe ---"
input ENUM_TIMEFRAMES InpTF  = PERIOD_H1; // Zeitebene
input int     InpLookback    = 2000;      // Anzahl geschlossene Kerzen (Index 1..N)

//--- ADF-Lag --------------------------------------------------------
input group "--- ADF-Test ---"
input int     InpADFLag      = 1;         // Augmented-DF Lag-Ordnung (0..3)

//--- Kritische Werte (MacKinnon 1991, 2 Variable) ------------------
input group "--- Kritische Werte (MacKinnon 1991) ---"
input double  InpCrit1pct    = -3.43;     // 1%-Schwelle
input double  InpCrit5pct    = -2.86;     // 5%-Schwelle
input double  InpCrit10pct   = -2.57;     // 10%-Schwelle

//+------------------------------------------------------------------+
//| Helfer: geschlossene Schlusskurse sammeln (ab Index 1)           |
//+------------------------------------------------------------------+
bool CollectCloses(string sym, ENUM_TIMEFRAMES tf, int n, double &arr[])
  {
   if(!SymbolSelect(sym, true))
     {
      Print("Fehler: Symbol '", sym, "' nicht verfuegbar / nicht in Market Watch.");
      return(false);
     }
   ArrayResize(arr, n);
   // iClose(...,1)=zuletzt geschlossen, ..., iClose(...,n)=aelteste. Wir
   // wollen chronologisch (aelteste zuerst) fuer die Differenzen-Bildung.
   double tmp[];
   ArrayResize(tmp, n);
   int got = CopyClose(sym, tf, 1, n, tmp);
   if(got < n)
     {
      Print("Fehler: nur ", got, " von ", n, " Kerzen fuer '", sym,
            "' (zu wenig Historie?). Brauche >= ", n + InpADFLag + 5, ".");
      return(false);
     }
   // CopyClose liefert zeitlich aufsteigend (Index 0 = aelteste der Stichprobe).
   // Da wir mit Start-Index 1 kopieren, ist tmp[0] = Close[1] (juengste geschl.).
   // Fuer die Regression ist die Reihenfolge egal, fuer dS muessen wir aber
   // konsistent bleiben -> wir drehen zu chronologisch (alt->neu) um.
   for(int i = 0; i < n; i++)
      arr[i] = tmp[n - 1 - i];
   return(true);
  }

//+------------------------------------------------------------------+
//| OLS: y = alpha + beta*x. Liefert beta, alpha, Residuen.          |
//| Ein-Pass (vermeidet numerische Probleme).                        |
//+------------------------------------------------------------------+
void OLS(const double &y[], const double &x[], int n,
         double &beta, double &alpha, double &resid[])
  {
   double meanY = 0.0, meanX = 0.0;
   for(int i = 0; i < n; i++) { meanY += y[i]; meanX += x[i]; }
   meanY /= n; meanX /= n;

   double cov = 0.0, varX = 0.0;
   for(int i = 0; i < n; i++)
     {
      double dy = y[i] - meanY;
      double dx = x[i] - meanX;
      cov  += dy * dx;
      varX += dx * dx;
     }
   beta  = (varX > 0.0) ? cov / varX : 0.0;
   alpha = meanY - beta * meanX;

   ArrayResize(resid, n);
   for(int i = 0; i < n; i++)
      resid[i] = y[i] - (alpha + beta * x[i]);
  }

//+------------------------------------------------------------------+
//| ADF-Regression: dS_t = c + rho*S_{t-1} + sum(phi_j*dS_{t-j}) + u|
//| Liefert t-Wert von rho (Teststatistik) und p-Wert-Naeherung.     |
//+------------------------------------------------------------------+
double ADF_tstat(const double &S[], int n, int lag,
                 double &rho_out, double &seRho_out)
  {
   rho_out = 0.0; seRho_out = 0.0;
   if(n - lag - 1 < 10) return(0.0);   // zu wenig Daten

   int T = n - lag - 1;                // Anzahl Beobachtungen
   int k = 2 + lag;                    // Regressoren: const, S_{t-1}, lags

   // Abhaengige Variable y = dS_t = S[t] - S[t-1]  fuer t = lag+1 .. n-1
   // Regressoren je Zeile t:
   //   x0 = 1 (Konstante)
   //   x1 = S[t-1]
   //   x2.. = dS_{t-1}, dS_{t-2}, ..., dS_{t-lag}
   double y[];
   ArrayResize(y, T);
   // Designmatrix flach (1D), Index [row*k + col] - MQL5 erlaubt keinen
   // Mischzugriff auf 2D-Arrays, deshalb 1D.
   double X[];
   ArrayResize(X, T * k);

   // dS-Feld (Differenzen) vorab
   double dS[];
   ArrayResize(dS, n);
   dS[0] = 0.0;
   for(int i = 1; i < n; i++) dS[i] = S[i] - S[i-1];

   int row = 0;
   for(int t = lag + 1; t < n; t++)
     {
      y[row] = dS[t];                  // = S[t]-S[t-1]
      X[row*k + 0] = 1.0;              // Konstante
      X[row*k + 1] = S[t-1];           // S_{t-1} (Level)
      for(int j = 1; j <= lag; j++)
         X[row*k + 1 + j] = dS[t - j]; // verzögerte Differenz
      row++;
     }

   // Normalgleichungen:  b = (X'X)^{-1} X'y   (per Gauss-Jordan)
   double XtX[];
   ArrayResize(XtX, k * k);
   double Xty[];
   ArrayResize(Xty, k);
   for(int a = 0; a < k; a++)
     {
      Xty[a] = 0.0;
      for(int b = 0; b < k; b++) XtX[a*k + b] = 0.0;
     }
   for(int r = 0; r < T; r++)
     {
      for(int a = 0; a < k; a++)
        {
         Xty[a] += X[r*k + a] * y[r];
         for(int b = 0; b < k; b++)
            XtX[a*k + b] += X[r*k + a] * X[r*k + b];
        }
     }

   // Invertiere XtX (k klein, maximal 6) via Gauss-Jordan mit Pivot
   double inv[];
   ArrayResize(inv, k * k);
   if(!InvertMatrix(XtX, k, inv))
     {
      Print("ADF: Matrix singulaer (k=", k, ") - kein Ergebnis.");
      return(0.0);
     }

   // Koeffizienten b = inv * Xty
   double b[];
   ArrayResize(b, k);
   for(int a = 0; a < k; a++)
     {
      b[a] = 0.0;
      for(int c = 0; c < k; c++) b[a] += inv[a*k + c] * Xty[c];
     }

   // Residuen und Standardfehler
   double rss = 0.0;
   for(int r = 0; r < T; r++)
     {
      double pred = 0.0;
      for(int a = 0; a < k; a++) pred += b[a] * X[r*k + a];
      double e = y[r] - pred;
      rss += e * e;
     }
   double sigma2 = rss / (T - k);
   // Var(rho) = sigma2 * inv[1][1]  (rho ist Index 1)
   double varRho = sigma2 * inv[1*k + 1];
   seRho_out = (varRho > 0.0) ? MathSqrt(varRho) : 0.0;
   rho_out  = b[1];
   if(seRho_out > 0.0) return(b[1] / seRho_out);
   return(0.0);
  }

//+------------------------------------------------------------------+
//| Gauss-Jordan-Invertierung einer k x k Matrix (zeilen-major)      |
//+------------------------------------------------------------------+
bool InvertMatrix(const double &m[], int k, double &inv[])
  {
   double a[];
   ArrayResize(a, k * k * 2);
   // erweiterte Matrix [m | I]
   for(int r = 0; r < k; r++)
     {
      for(int c = 0; c < k; c++) a[r*2*k + c] = m[r*k + c];
      for(int c = 0; c < k; c++) a[r*2*k + k + c] = (r == c) ? 1.0 : 0.0;
     }
   for(int col = 0; col < k; col++)
     {
      // Pivot: betragsgroesstes in Spalte col ab Zeile col
      int piv = col; double best = MathAbs(a[col*2*k + col]);
      for(int r = col + 1; r < k; r++)
        {
         double v = MathAbs(a[r*2*k + col]);
         if(v > best) { best = v; piv = r; }
        }
      if(best < 1e-12) return(false);   // singulaer
      if(piv != col)
         for(int c = 0; c < 2*k; c++)
           {
            double tmp = a[col*2*k + c]; a[col*2*k + c] = a[piv*2*k + c]; a[piv*2*k + c] = tmp;
           }
      double diag = a[col*2*k + col];
      for(int c = 0; c < 2*k; c++) a[col*2*k + c] /= diag;
      for(int r = 0; r < k; r++)
        {
         if(r == col) continue;
         double f = a[r*2*k + col];
         if(f == 0.0) continue;
         for(int c = 0; c < 2*k; c++) a[r*2*k + c] -= f * a[col*2*k + c];
        }
     }
   for(int r = 0; r < k; r++)
      for(int c = 0; c < k; c++) inv[r*k + c] = a[r*2*k + k + c];
   return(true);
  }

//+------------------------------------------------------------------+
//| Hauptprogramm                                                     |
//+------------------------------------------------------------------+
void OnStart()
  {
   string symA = (InpSymbolA == "" ? _Symbol : InpSymbolA);
   string symB = InpSymbolB;

   if(symA == symB)
     {
      Print("Abbruch: SymbolA == SymbolB ('", symA, "').");
      return;
     }

   int n = InpLookback;
   double A[], B[];
   if(!CollectCloses(symA, InpTF, n, A)) return;
   if(!CollectCloses(symB, InpTF, n, B)) return;

   // Optional Log-Transformation
   double yA[], xB[];
   ArrayResize(yA, n); ArrayResize(xB, n);
   for(int i = 0; i < n; i++)
     {
      if(InpUseLog)
        {
         if(A[i] <= 0.0 || B[i] <= 0.0)
           { Print("Abbruch: nicht-positive Preise (Log nicht moeglich)."); return; }
         yA[i] = MathLog(A[i]);
         xB[i] = MathLog(B[i]);
        }
      else
        { yA[i] = A[i]; xB[i] = B[i]; }
     }

   // 1) OLS-Regression -> beta (Hedge-Ratio), Residuen = Spread
   double beta, alpha, spread[];
   OLS(yA, xB, n, beta, alpha, spread);

   // Spread-Statistik
   double sMean = 0.0;
   for(int i = 0; i < n; i++) sMean += spread[i];
   sMean /= n;
   double sVar = 0.0;
   for(int i = 0; i < n; i++) { double d = spread[i] - sMean; sVar += d * d; }
   sVar /= (n - 1);
   double sStd = MathSqrt(sVar);

   // 2) ADF-Test auf Spread
   double rho = 0.0, seRho = 0.0;
   double tADF = ADF_tstat(spread, n, InpADFLag, rho, seRho);

   // Verdict
   string verdict = "NOT_COINTEGRATED";
   if(tADF < InpCrit5pct) verdict = "COINTEGRATED_5pct";
   if(tADF < InpCrit1pct) verdict = "COINTEGRATED_1pct";

   // p-Wert-Naeherung (grob): t-Wert gegen Normalverteilung ist hier falsch,
   // aber als Orientierung notieren wir die Schwelle, unter der t liegt.
   string pApprox = "p>0.10";
   if(tADF < InpCrit10pct) pApprox = "p<0.10";
   if(tADF < InpCrit5pct)  pApprox = "p<0.05";
   if(tADF < InpCrit1pct)  pApprox = "p<0.01";

   // CSV-Zeile (Semikolon, Punkt-Dezimal) - kompatibel zu pool_backtests.py-Stil
   string line = StringFormat("COINTEGRATION_RESULT;%s;%s;%s;%d;%.6f;%.4f;%.2f;%.2f;%.2f;%s;%s",
                              symA, symB, EnumToString(InpTF), n,
                              beta, tADF, InpCrit1pct, InpCrit5pct, InpCrit10pct,
                              pApprox, verdict);

   Print("========================================");
   Print("COINTEGRATION-TEST (Engle-Granger OLS + ADF)");
   Print("  Symbole:    ", symA, " ~ ", symB);
   Print("  TF / N:     ", EnumToString(InpTF), " / ", n, " Kerzen (ab Index 1)");
   Print("  Hedge beta: ", DoubleToString(beta, 6));
   Print("  Spread:     mean=", DoubleToString(sMean, 6),
         " std=", DoubleToString(sStd, 6));
   Print("  ADF:        t=", DoubleToString(tADF, 4),
         " (rho=", DoubleToString(rho, 6), " SE=", DoubleToString(seRho, 6), ")");
   Print("  Kritisch:   1%=", DoubleToString(InpCrit1pct, 2),
         " 5%=", DoubleToString(InpCrit5pct, 2),
         " 10%=", DoubleToString(InpCrit10pct, 2));
   Print("  Verdict:    ", verdict, " (", pApprox, ")");
   Print("CSV> " + line);
   Print("========================================");

   // In Datei schreiben (Common = terminal_data_folder\MQL5\Files oder Common\Files)
   int h = FileOpen("cointegration_result.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h != INVALID_HANDLE)
     {
      FileWrite(h, line);
      FileClose(h);
      Print("Ergebnis nach Common\\Files\\cointegration_result.txt geschrieben.");
     }
   else
      Print("WARNUNG: konnte Ergebnisdatei nicht schreiben.");
  }
//+------------------------------------------------------------------+
