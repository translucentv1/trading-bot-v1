//+------------------------------------------------------------------+
//| Cointegration-Pre-Check Phase 1 - Alle 15 Korb-Kombinationen      |
//|                                                                  |
//| Ein einziger Tester-Lauf (Symbol=EURUSD, H1, 2022-2026) berechnet |
//| ALLE 15 Paar-Kombinationen aus dem 6er-Korb und schreibt eine     |
//| einzige Ergebnisdatei mit allen Zeilen. Kein Restart noetig.      |
//|                                                                  |
//| Methode: Engle-Granger OLS + ADF, Look-Ahead-frei (Index ab 1).   |
//| Ausgabe: Common\Files\cointegration_all.txt (CSV, Semikolon).    |
//+------------------------------------------------------------------+
#property copyright "Phase 3 - Forschung (Cointegration Batch)"
#property version   "1.10"
#property strict

input int     InpLookback    = 30000;     // Kerzen ab Index 1 (~4,3 J. H1)
input int     InpADFLag      = 1;         // ADF Lag-Ordnung
input double  InpCrit1pct    = -3.43;     // MacKinnon 1%
input double  InpCrit5pct    = -2.86;     // MacKinnon 5%
input double  InpCrit10pct   = -2.57;     // MacKinnon 10%

// 6er-Korb (fest)
string KORB[] = {"EURUSD","GBPUSD","USDJPY","AUDUSD","USDCAD","XAUUSD"};

//+------------------------------------------------------------------+
bool CollectCloses(string sym, ENUM_TIMEFRAMES tf, int n, double &arr[])
  {
   if(!SymbolSelect(sym, true)) return(false);
   double tmp[]; ArrayResize(tmp, n);
   int got = CopyClose(sym, tf, 1, n, tmp);
   if(got < n) return(false);
   ArrayResize(arr, n);
   for(int i = 0; i < n; i++) arr[i] = tmp[n-1-i];
   return(true);
  }

//+------------------------------------------------------------------+
void OLS(const double &y[], const double &x[], int n,
         double &beta, double &alpha, double &resid[])
  {
   double mY=0,mX=0; for(int i=0;i<n;i++){mY+=y[i];mX+=x[i];} mY/=n;mX/=n;
   double cov=0,vX=0;
   for(int i=0;i<n;i++){double dy=y[i]-mY,dx=x[i]-mX;cov+=dy*dx;vX+=dx*dx;}
   beta=(vX>0)?cov/vX:0; alpha=mY-beta*mX;
   ArrayResize(resid,n); for(int i=0;i<n;i++) resid[i]=y[i]-(alpha+beta*x[i]);
  }

//+------------------------------------------------------------------+
bool InvertMatrix(const double &m[], int k, double &inv[])
  {
   double a[]; ArrayResize(a,k*k*2);
   for(int r=0;r<k;r++){for(int c=0;c<k;c++) a[r*2*k+c]=m[r*k+c];
     for(int c=0;c<k;c++) a[r*2*k+k+c]=(r==c)?1.0:0.0;}
   for(int col=0;col<k;col++)
     {int piv=col;double best=MathAbs(a[col*2*k+col]);
      for(int r=col+1;r<k;r++){double v=MathAbs(a[r*2*k+col]);if(v>best){best=v;piv=r;}}
      if(best<1e-12) return(false);
      if(piv!=col) for(int c=0;c<2*k;c++){double t=a[col*2*k+c];a[col*2*k+c]=a[piv*2*k+c];a[piv*2*k+c]=t;}
      double d=a[col*2*k+col];for(int c=0;c<2*k;c++) a[col*2*k+c]/=d;
      for(int r=0;r<k;r++){if(r==col)continue;double f=a[r*2*k+col];if(f==0)continue;
        for(int c=0;c<2*k;c++) a[r*2*k+c]-=f*a[col*2*k+c];}
     }
   for(int r=0;r<k;r++) for(int c=0;c<k;c++) inv[r*k+c]=a[r*2*k+k+c];
   return(true);
  }

//+------------------------------------------------------------------+
double ADF_tstat(const double &S[], int n, int lag, double &rho_out, double &se_out)
  {
   rho_out=0; se_out=0;
   if(n-lag-1<10) return(0);
   int T=n-lag-1, k=2+lag;
   double y[]; ArrayResize(y,T); double X[]; ArrayResize(X,T*k);
   double dS[]; ArrayResize(dS,n); dS[0]=0;
   for(int i=1;i<n;i++) dS[i]=S[i]-S[i-1];
   int row=0;
   for(int t=lag+1;t<n;t++)
     {y[row]=dS[t]; X[row*k+0]=1.0; X[row*k+1]=S[t-1];
      for(int j=1;j<=lag;j++) X[row*k+1+j]=dS[t-j]; row++;}
   double XtX[]; ArrayResize(XtX,k*k); double Xty[]; ArrayResize(Xty,k);
   for(int a=0;a<k;a++){Xty[a]=0;for(int b=0;b<k;b++) XtX[a*k+b]=0;}
   for(int r=0;r<T;r++) for(int a=0;a<k;a++)
     {Xty[a]+=X[r*k+a]*y[r];
      for(int b=0;b<k;b++) XtX[a*k+b]+=X[r*k+a]*X[r*k+b];}
   double inv[]; ArrayResize(inv,k*k);
   if(!InvertMatrix(XtX,k,inv)) return(0);
   double b[]; ArrayResize(b,k);
   for(int a=0;a<k;a++){b[a]=0;for(int c=0;c<k;c++) b[a]+=inv[a*k+c]*Xty[c];}
   double rss=0;
   for(int r=0;r<T;r++){double p=0;for(int a=0;a<k;a++) p+=b[a]*X[r*k+a];
      double e=y[r]-p; rss+=e*e;}
   double s2=rss/(T-k), vr=s2*inv[1*k+1];
   se_out=(vr>0)?MathSqrt(vr):0; rho_out=b[1];
   return(se_out>0)?b[1]/se_out:0;
  }

//+------------------------------------------------------------------+
string RunTest(string symA, string symB)
  {
   int n = InpLookback;
   double A[], B[];
   if(!CollectCloses(symA, PERIOD_H1, n, A)) return("ERROR;"+symA+";"+symB+";Symbol A fehlgeschlagen");
   if(!CollectCloses(symB, PERIOD_H1, n, B)) return("ERROR;"+symA+";"+symB+";Symbol B fehlgeschlagen");

   double yA[], xB[]; ArrayResize(yA,n); ArrayResize(xB,n);
   for(int i=0;i<n;i++) {yA[i]=MathLog(A[i]); xB[i]=MathLog(B[i]);}

   double beta,alpha,spread[];
   OLS(yA, xB, n, beta, alpha, spread);

   double rho=0, se=0;
   double tADF = ADF_tstat(spread, n, InpADFLag, rho, se);

   string verdict="NOT_COINTEGRATED";
   if(tADF<InpCrit5pct)  verdict="COINTEGRATED_5pct";
   if(tADF<InpCrit1pct)  verdict="COINTEGRATED_1pct";
   string pA="p>0.10";
   if(tADF<InpCrit10pct) pA="p<0.10";
   if(tADF<InpCrit5pct)  pA="p<0.05";
   if(tADF<InpCrit1pct)  pA="p<0.01";

   Print("COINT> ",symA," ~ ",symB," | beta=",DoubleToString(beta,6),
         " | tADF=",DoubleToString(tADF,4)," | ",verdict," (",pA,")");

   return(StringFormat("COINTEGRATION_RESULT;%s;%s;H1;%d;%.6f;%.4f;%.2f;%.2f;%.2f;%s;%s",
            symA, symB, n, beta, tADF, InpCrit1pct, InpCrit5pct, InpCrit10pct, pA, verdict));
  }

//+------------------------------------------------------------------+
int OnInit() { return(INIT_SUCCEEDED); }
void OnTick() {}

//+------------------------------------------------------------------+
double OnTester()
  {
   int total = 0, ok = 0, coint = 0;
   int nSyms = ArraySize(KORB);

   // Zaehle Kombinationen
   for(int i=0;i<nSyms;i++) for(int j=i+1;j<nSyms;j++) total++;
   Print("=== Cointegration-Pre-Check: ",total," Kombinationen ===");

   string lines[];

   for(int i=0;i<nSyms;i++)
     {
      for(int j=i+1;j<nSyms;j++)
        {
         string result = RunTest(KORB[i], KORB[j]);
         ArrayResize(lines, ok+1);
         lines[ok] = result;
         ok++;
         // BUGFIX 13.07.: "NOT_COINTEGRATED" enthaelt den Teilstring
         // "COINTEGRATED" -> vorher wurden ALLE als cointegriert gezaehlt.
         // Positive Verdikte sind COINTEGRATED_1pct/_5pct -> auf "_" pruefen.
         if(StringFind(result,"COINTEGRATED_") >= 0) coint++;
        }
     }

   // Alles in eine Datei
   int h = FileOpen("cointegration_all.txt", FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   if(h != INVALID_HANDLE)
     {
      FileWrite(h, "# Cointegration-Pre-Check | ",total," Kombinationen | ",ok," OK | ",coint," cointegriert");
      for(int i=0;i<ok;i++) FileWrite(h, lines[i]);
      FileClose(h);
      Print("=== Ergebnis geschrieben: Common\\Files\\cointegration_all.txt ===");
      Print("=== Zusammenfassung: ",ok," / ",total," getestet, ",coint," cointegriert ===");
     }
   else Print("FEHLER: Ergebnisdatei konnte nicht geschrieben werden.");

   return((double)coint);  // Anzahl cointegrierter Paare
  }
//+------------------------------------------------------------------+
