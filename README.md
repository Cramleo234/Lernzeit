# Lernzeit 🎓

Minimalistische Lern-Timer-App für macOS mit Apples **Liquid Glass** Design (macOS 26 „Tahoe").

## Features

- ⏱️ **Stoppuhr & Pomodoro** — frei hochzählen oder mit Fokus-/Pausen-Intervallen lernen (inkl. Benachrichtigungen)
- 📚 **Fächer** — Sessions einem Fach mit eigener Farbe zuordnen
- 📊 **Statistiken** — Lernzeit pro Tag/Woche, 14-Tage-Diagramm, Aufschlüsselung nach Fächern
- 🔥 **Tagesziele & Streaks** — tägliches Lernziel setzen und Serien aufbauen
- 🖥️ **Menüleisten-Timer** — Sessions direkt aus der Menüleiste starten, pausieren und stoppen
- 🧊 **Liquid Glass** — natives Glas-Design mit `glassEffect`, komplett in SwiftUI

Alle Daten bleiben lokal auf deinem Mac (SwiftData).

## Installation über Homebrew

```bash
brew tap cramleo234/tap
brew install --cask lernzeit
```

> **Hinweis:** Die App ist aktuell nicht notarisiert. Falls macOS den Start blockiert,
> installiere mit `brew install --cask --no-quarantine lernzeit` oder erlaube die App
> unter *Systemeinstellungen → Datenschutz & Sicherheit*.

## Voraussetzungen

- macOS 26 (Tahoe) oder neuer

## Selbst bauen

```bash
git clone https://github.com/Cramleo234/Lernzeit.git
cd Lernzeit
xcodebuild -project Lernzeit.xcodeproj -target Lernzeit -configuration Release build
```

Benötigt Xcode 26+.

## Lizenz

[MIT](LICENSE)
