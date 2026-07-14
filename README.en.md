# Lernzeit 🎓

[Deutsch](README.md) | **English**

A minimalist study timer for macOS with a modern, translucent glass design.

## Features

- ☀️ **Today dashboard** — daily progress, the active session, weekly goals, and quick start in one place
- ⚡ **Study profiles** — save recurring timers, subjects, and Pomodoro routines and start them with one click
- ⏱️ **Stopwatch, timer & Pomodoro** — count up, count down, or study with complete focus cycles
- ☕ **Flexible Pomodoro cycles** — short and long breaks, a configurable round count, and automatic or manual phase starts
- 📚 **Subjects & weekly goals** — assign sessions to color-coded subjects and set an optional weekly goal for each subject
- 📝 **Notes & history search** — record what you studied and find sessions by subject, note, or study profile
- 📊 **Statistics** — charts, a heatmap, records, week-over-week comparison, and breakdowns by subject and study profile
- 🔥 **Daily goals & streaks** — set a daily study goal, build streaks, and receive a notification when you reach your goal
- 💾 **Local data backup** — export and restore complete JSON backups or save your sessions as CSV
- 🧿 **Ambient progress** — a progress line around the notch on supported Macs and a progress ring in the menu bar icon
- 🪟 **Mini & menu bar timers** — monitor sessions in a compact window and start them from the menu bar or a study profile
- 😴 **Honest timing** — automatically pauses when the screen is locked or the Mac is inactive while Pomodoro breaks continue reliably
- 🧊 **Glass design** — a native translucent interface built entirely with SwiftUI
- 🌙 **Dark theme** — use the system appearance or choose Light or Dark mode

All data stays locally on your Mac using SwiftData.

## Install with Homebrew

```bash
brew tap cramleo234/tap
brew trust cramleo234/tap   # one-time step for taps outside homebrew/core
brew install --cask lernzeit
```

> **About the security prompts:** Homebrew's trust prompt (`brew trust`) is standard
> for third-party taps and only needs to be accepted once. The app is currently not
> notarized because it is not enrolled in the Apple Developer Program. If macOS blocks
> the first launch, you can allow it under
> *System Settings → Privacy & Security → “Open Anyway”*.

## Requirements

- macOS 26 or later

## Build from source

```bash
git clone https://github.com/Cramleo234/Lernzeit.git
cd Lernzeit
xcodebuild -project Lernzeit.xcodeproj -target Lernzeit -configuration Release build
```

Requires Xcode 26 or later. No Apple Developer account is required.

## License

[MIT](LICENSE)

---

Lernzeit is an independent private project. It is not affiliated with, sponsored by,
authorized by, or otherwise associated with Apple Inc. Apple, macOS, and all related
trademarks are the property of Apple Inc.
