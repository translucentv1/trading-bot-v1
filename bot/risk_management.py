"""
Risikomanagement
=================
Berechnet Positionsgroessen nach dem Prozent-Risiko-Modell: Pro Trade wird
hoechstens ein fester Prozentsatz des Kontos riskiert. Aus dem Abstand
zwischen Einstiegskurs und Stop-Loss ergibt sich, wie gross die Position
sein darf.

Beispiel: 10.000 EUR Konto, 1 % Risiko = 100 EUR duerfen verloren gehen.
Einstieg bei 100 EUR, Stop-Loss bei 98 EUR -> Verlust pro Stueck 2 EUR ->
Position darf hoechstens 50 Stueck gross sein.

Hinweis: Broker- und Webhook-Anbindung folgen erst in Phase 2. Dieses Modul
ist bewusst reine Rechenlogik ohne jede Verbindung nach aussen - dadurch ist
es heute schon vollstaendig testbar.
"""


def risikobetrag(kontostand: float, risiko_prozent: float) -> float:
    """
    Berechnet, wie viel Geld bei einem Trade hoechstens verloren gehen darf.

    kontostand: aktueller Kontostand (z.B. 10000.0)
    risiko_prozent: wie viel Prozent davon riskiert werden (z.B. 1.0 fuer 1 %)
    """
    if kontostand <= 0:
        raise ValueError("Der Kontostand muss groesser als 0 sein.")
    if not 0 < risiko_prozent <= 100:
        raise ValueError("Das Risiko muss zwischen 0 (exklusiv) und 100 Prozent liegen.")
    return kontostand * risiko_prozent / 100


def positionsgroesse(
    kontostand: float,
    risiko_prozent: float,
    einstiegspreis: float,
    stop_preis: float,
    max_hebel: float = 1.0,
) -> float:
    """
    Berechnet die maximale Positionsgroesse (Stueckzahl) nach %-Risiko.

    einstiegspreis: geplanter Kaufkurs
    stop_preis: Kurs, bei dem die Position spaetestens geschlossen wird
    max_hebel: Obergrenze fuer den Positionswert relativ zum Konto.
        1.0 (Standard) = kein Hebel, die Position darf hoechstens so viel
        wert sein wie das Konto selbst.

    Funktioniert fuer Long (Stop unter Einstieg) und Short (Stop ueber
    Einstieg) gleichermassen - entscheidend ist nur der Abstand.
    """
    betrag = risikobetrag(kontostand, risiko_prozent)

    if einstiegspreis <= 0 or stop_preis <= 0:
        raise ValueError("Einstiegspreis und Stop-Preis muessen groesser als 0 sein.")
    if max_hebel <= 0:
        raise ValueError("max_hebel muss groesser als 0 sein.")

    verlust_pro_stueck = abs(einstiegspreis - stop_preis)
    if verlust_pro_stueck == 0:
        raise ValueError("Stop-Preis und Einstiegspreis duerfen nicht gleich sein.")

    groesse = betrag / verlust_pro_stueck

    # Obergrenze: Positionswert darf max_hebel * Kontostand nicht ueberschreiten.
    # Ohne diese Grenze wuerde ein sehr enger Stop rechnerisch riesige
    # Positionen erlauben, die das Konto gar nicht bezahlen koennte.
    max_groesse = (kontostand * max_hebel) / einstiegspreis
    return min(groesse, max_groesse)


if __name__ == "__main__":
    # Testblock: zeigt an einem Beispiel, was das Modul berechnet
    konto = 10_000.0
    risiko = 1.0  # 1 % des Kontos pro Trade
    einstieg = 100.0
    stop = 98.0

    print(f"Kontostand: {konto:.2f} EUR, Risiko pro Trade: {risiko} %")
    print(f"Maximaler Verlust pro Trade: {risikobetrag(konto, risiko):.2f} EUR")
    groesse = positionsgroesse(konto, risiko, einstieg, stop)
    print(
        f"Einstieg {einstieg:.2f} EUR, Stop-Loss {stop:.2f} EUR "
        f"-> Positionsgroesse: {groesse:.2f} Stueck "
        f"(Positionswert {groesse * einstieg:.2f} EUR)"
    )
