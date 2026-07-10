# Lernzeit 🎓

[Deutsch](README.md) | **English**

A minimalist study timer for macOS with a modern, translucent glass design.

## Features

- ⏱️ **Stopwatch & Pomodoro** — count up freely or study with focus and break intervals, including notifications and sounds
- 📚 **Subjects** — assign sessions to color-coded subjects; the subject color also appears in timers, rings, and progress lines
- 📝 **Notes** — record what you studied after each session
- 📊 **Statistics** — daily, weekly, and monthly charts; a six-month heatmap; records; your most productive time of day; and breakdowns by subject
- 🔥 **Daily goals & streaks** — set a daily study goal, build streaks, and receive a notification when you reach your goal
- 🧿 **Ambient progress** — a progress line around the notch on supported Macs and a progress ring in the menu bar icon
- 🪟 **Mini timer** — a compact floating timer that stays above other windows
- 🖥️ **Menu bar timer** — start, pause, and stop sessions directly from the menu bar
- 😴 **Honest timing** — automatically pauses when the screen is locked or the Mac is inactive, then resumes automatically
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
