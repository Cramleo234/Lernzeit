# Lernzeit 🎓

Minimalistische Lern-Timer-App für macOS mit modernem, durchscheinendem Glas-Design.

## Features

- ⏱️ **Stoppuhr & Pomodoro** — frei hochzählen oder mit Fokus-/Pausen-Intervallen lernen (inkl. Benachrichtigungen)
- 📚 **Fächer** — Sessions einem Fach mit eigener Farbe zuordnen
- 📊 **Statistiken** — Lernzeit pro Tag/Woche, 14-Tage-Diagramm, Aufschlüsselung nach Fächern
- 🔥 **Tagesziele & Streaks** — tägliches Lernziel setzen und Serien aufbauen
- 🖥️ **Menüleisten-Timer** — Sessions direkt aus der Menüleiste starten, pausieren und stoppen
- 🧊 **Glas-Design** — natives, durchscheinendes Oberflächen-Design, komplett in SwiftUI

Alle Daten bleiben lokal auf deinem Mac (SwiftData).

## Installation über Homebrew

```bash
brew tap cramleo234/tap
brew install --cask lernzeit
```

> **Hinweis:** Die App ist aktuell nicht notarisiert. Falls macOS den Start blockiert,
> erlaube sie unter *Systemeinstellungen → Datenschutz & Sicherheit*. Alternativ kannst
> du beim Installieren `brew install --cask --no-quarantine lernzeit` verwenden — nutze
> das nur, wenn du der Quelle vertraust (in diesem Fall: dir selbst).

## Voraussetzungen

- macOS 26 oder neuer

## Selbst bauen

```bash
git clone https://github.com/Cramleo234/Lernzeit.git
cd Lernzeit
xcodebuild -project Lernzeit.xcodeproj -target Lernzeit -configuration Release build
```

Benötigt Xcode 26+.

## Lizenz

[MIT](LICENSE)

---

Lernzeit ist ein unabhängiges, privates Projekt und steht in keiner Verbindung zu Apple Inc.
und wird nicht von Apple gesponsert, autorisiert oder unterstützt. Apple, macOS und alle
zugehörigen Marken sind Eigentum von Apple Inc.
