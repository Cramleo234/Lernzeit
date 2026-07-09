# Lernzeit 🎓

Minimalistische Lern-Timer-App für macOS mit modernem, durchscheinendem Glas-Design.

## Features

- ⏱️ **Stoppuhr & Pomodoro** — frei hochzählen oder mit Fokus-/Pausen-Intervallen lernen (inkl. Benachrichtigungen und Tönen)
- 📚 **Fächer** — Sessions einem Fach mit eigener Farbe zuordnen; die Fachfarbe färbt Timer, Ringe und Fortschrittslinien
- 📝 **Notizen** — nach jeder Session festhalten, was du gelernt hast
- 📊 **Statistiken** — Tages-/Wochen-/Monats-Diagramme, 6-Monats-Heatmap, Rekorde, beste Lern-Tageszeit, Aufschlüsselung nach Fächern
- 🔥 **Tagesziele & Streaks** — tägliches Lernziel setzen, Serien aufbauen, Benachrichtigung bei Zielerreichung
- 🧿 **Ambient-Fortschritt** — Fortschrittslinie um die Notch (auf Macs mit Notch), Fortschrittsring im Menüleisten-Icon, Restzeit am Dock-Icon
- 🪟 **Mini-Timer** — kompakter, schwebender Timer, der über allen Fenstern bleibt
- 🖥️ **Menüleisten-Timer** — Sessions direkt aus der Menüleiste starten, pausieren und stoppen
- 📐 **Widgets** — Tagesfortschritt, Streak und Wochenübersicht direkt auf dem Schreibtisch
- 😴 **Ehrliche Zeiten** — automatische Pause bei Bildschirmsperre oder Inaktivität, automatische Fortsetzung
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

Benötigt Xcode 26+. Kein Apple-Developer-Account nötig.

## Lizenz

[MIT](LICENSE)

---

Lernzeit ist ein unabhängiges, privates Projekt und steht in keiner Verbindung zu Apple Inc.
und wird nicht von Apple gesponsert, autorisiert oder unterstützt. Apple, macOS und alle
zugehörigen Marken sind Eigentum von Apple Inc.
