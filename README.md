# Lernzeit 🎓

**Deutsch** | [English](README.en.md)

Minimalistische Lern-Timer-App für macOS mit modernem, durchscheinendem Glas-Design.

## Features

- ☀️ **Heute-Dashboard** — Tagesfortschritt, laufende Session, Wochenziele und Schnellstart an einem Ort
- ⚡ **Lernprofile** — wiederkehrende Timer, Fächer und Pomodoro-Abläufe speichern und mit einem Klick starten
- ⏱️ **Stoppuhr, Timer & Pomodoro** — frei hochzählen, herunterzählen oder mit vollständigen Fokuszyklen lernen
- ☕ **Flexible Pomodoro-Zyklen** — kurze und lange Pausen, frei wählbare Rundenzahl sowie automatischer oder manueller Phasenstart
- 📚 **Fächer & Wochenziele** — Sessions farbigen Fächern zuordnen und je Fach ein optionales Wochenziel setzen
- 📝 **Notizen & Verlaufssuche** — Lerninhalte festhalten und Sitzungen nach Fach, Notiz oder Lernprofil finden
- 📊 **Statistiken** — Diagramme, Heatmap, Rekorde, Wochenvergleich sowie Auswertungen nach Fach und Lernprofil
- 🔥 **Tagesziele & Streaks** — tägliches Lernziel setzen, Serien aufbauen und Benachrichtigung bei Zielerreichung
- 💾 **Lokale Datensicherung** — vollständige JSON-Backups exportieren und wiederherstellen sowie Sitzungen als CSV sichern
- 🧿 **Ambient-Fortschritt** — Fortschrittslinie um die Notch (auf Macs mit Notch) und Fortschrittsring im Menüleisten-Icon
- 🪟 **Mini- & Menüleisten-Timer** — Sessions kompakt beobachten sowie direkt aus der Menüleiste oder per Lernprofil starten
- 😴 **Ehrliche Zeiten** — automatische Pause bei Bildschirmsperre oder Inaktivität; Pomodoro-Pausen laufen zuverlässig weiter
- 🧊 **Glas-Design** — natives, durchscheinendes Oberflächen-Design, komplett in SwiftUI
- 🌙 **Dark Theme** — Darstellung auf System, Hell oder Dunkel stellen

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
