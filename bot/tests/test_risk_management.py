"""
Unit-Tests fuer das Risikomanagement-Modul.

Ausfuehren mit:  python -m pytest
"""

import pytest

from bot.risk_management import positionsgroesse, risikobetrag


# --- risikobetrag -------------------------------------------------------------

def test_risikobetrag_einfacher_fall():
    # 1 % von 10.000 EUR sind 100 EUR
    assert risikobetrag(10_000.0, 1.0) == 100.0


def test_risikobetrag_halbes_prozent():
    assert risikobetrag(20_000.0, 0.5) == 100.0


def test_risikobetrag_lehnt_negativen_kontostand_ab():
    with pytest.raises(ValueError):
        risikobetrag(-5_000.0, 1.0)


def test_risikobetrag_lehnt_null_risiko_ab():
    with pytest.raises(ValueError):
        risikobetrag(10_000.0, 0.0)


def test_risikobetrag_lehnt_mehr_als_100_prozent_ab():
    with pytest.raises(ValueError):
        risikobetrag(10_000.0, 101.0)


# --- positionsgroesse ----------------------------------------------------------

def test_positionsgroesse_long_beispiel():
    # 10.000 EUR Konto, 1 % Risiko = 100 EUR.
    # Einstieg 100, Stop 98 -> 2 EUR Verlust pro Stueck -> 50 Stueck.
    groesse = positionsgroesse(10_000.0, 1.0, einstiegspreis=100.0, stop_preis=98.0)
    assert groesse == pytest.approx(50.0)


def test_positionsgroesse_short_gleicher_abstand():
    # Fuer Short (Stop ueber Einstieg) zaehlt derselbe Abstand
    groesse = positionsgroesse(10_000.0, 1.0, einstiegspreis=100.0, stop_preis=102.0)
    assert groesse == pytest.approx(50.0)


def test_positionsgroesse_wird_durch_kontogroesse_begrenzt():
    # Sehr enger Stop (0,1 EUR Abstand) wuerde rechnerisch 1000 Stueck
    # erlauben (Wert 100.000 EUR) - das Konto hat aber nur 10.000 EUR.
    # Ohne Hebel (Standard) muss die Groesse auf 100 Stueck gedeckelt werden.
    groesse = positionsgroesse(10_000.0, 1.0, einstiegspreis=100.0, stop_preis=99.9)
    assert groesse == pytest.approx(100.0)


def test_positionsgroesse_mit_hebel_erlaubt_groessere_position():
    # Gleicher Fall wie oben, aber mit max_hebel=2.0 -> Deckel bei 200 Stueck
    groesse = positionsgroesse(10_000.0, 1.0, einstiegspreis=100.0, stop_preis=99.9, max_hebel=2.0)
    assert groesse == pytest.approx(200.0)


def test_positionsgroesse_lehnt_gleichen_stop_und_einstieg_ab():
    with pytest.raises(ValueError):
        positionsgroesse(10_000.0, 1.0, einstiegspreis=100.0, stop_preis=100.0)


def test_positionsgroesse_lehnt_negative_preise_ab():
    with pytest.raises(ValueError):
        positionsgroesse(10_000.0, 1.0, einstiegspreis=-100.0, stop_preis=98.0)
    with pytest.raises(ValueError):
        positionsgroesse(10_000.0, 1.0, einstiegspreis=100.0, stop_preis=0.0)


def test_positionsgroesse_lehnt_unsinnigen_hebel_ab():
    with pytest.raises(ValueError):
        positionsgroesse(10_000.0, 1.0, einstiegspreis=100.0, stop_preis=98.0, max_hebel=0.0)
