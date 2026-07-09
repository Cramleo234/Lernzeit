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
- 😴 **Ehrliche Zeiten** — automatische Pause bei Bildschirmsperre oder Inaktivität, automatische Fortsetzung
- 🧊 **Glas-Design** — natives, durchscheinendes Oberflächen-Design, komplett in SwiftUI

Alle Daten bleiben lokal auf deinem Mac (SwiftData).

## Installation über Homebrew

```bash
brew tap cramleo234/tap
brew trust cramleo234/tap   # einmalig — Homebrew fragt bei Taps außerhalb von homebrew/core
brew install --cask lernzeit
```

> **Hinweis zu den Sicherheitsabfragen:** Die Vertrauensabfrage von Homebrew (`brew trust`)
> ist bei allen Dritt-Taps Standard und lässt sich nicht abschalten. Die App selbst ist
> aktuell nicht notarisiert (kein Apple-Developer-Programm) — falls macOS den ersten Start
> blockiert, kannst du sie selbst freigeben unter
> *Systemeinstellungen → Datenschutz & Sicherheit → „Dennoch öffnen"*.

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
