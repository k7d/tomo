# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Tomo

Tomo is a native macOS Pomodoro timer app built with Swift/AppKit. It lives in the menu bar (LSUIElement) and shows a floating popup window when clicked. Supports multiple configurable timers with chaining, iCloud sync, and sound notifications.

## Build & Run

```sh
# Generate Xcode project (requires: brew install xcodegen)
xcodegen generate

# Build from command line
xcodebuild -project Tomo.xcodeproj -scheme Tomo -configuration Debug build

# Run the built app (foreground, with stdout/stderr visible in terminal)
~/Library/Developer/Xcode/DerivedData/Tomo-*/Build/Products/Debug/Tomo.app/Contents/MacOS/Tomo
```

There are no unit tests.

## Testing with Peekaboo

Tomo is a menu bar app with no accessibility labels, so manual UI testing uses [Peekaboo](https://github.com/steipete/peekaboo) for macOS automation. Peekaboo requires **Screen Recording** and **Accessibility** permissions (check with `peekaboo permissions`).

```sh
# Build and launch
xcodebuild -project Tomo.xcodeproj -scheme Tomo -configuration Debug build
open ~/Library/Developer/Xcode/DerivedData/Tomo-*/Build/Products/Debug/Tomo.app

# Verify it's running
pgrep -x Tomo

# Screenshot the menu bar to locate Tomo's status item
peekaboo image --app menubar --path /tmp/menubar.png

# Screenshot full screen (retina) to see current state
peekaboo image --mode screen --retina --path /tmp/screen.png

# List menu bar items to find Tomo
peekaboo list menubar

# Click Tomo's menu bar item to open the popup (use coords from screenshot/list)
peekaboo click --coords <x>,<y>

# Once the popup window is open, inspect its UI
peekaboo see --app Tomo

# Click a UI element by ID from the see output
peekaboo click --on <element-id> --app Tomo

# Take a screenshot of the Tomo window
peekaboo image --app Tomo --path /tmp/tomo.png
```

Note: Tomo may not appear in `peekaboo list menubar` by name — look for it visually in a menu bar screenshot. The status item shows a small icon when idle and a colored countdown when a timer is running.

## Architecture

**MVC with singleton state and NotificationCenter-based reactivity.**

- **AppState** (`Tomo/Models/AppState.swift`) — Singleton that owns all state: timer configs, active timer, history. Persists to UserDefaults (keys prefixed with `debug_` in DEBUG builds). Posts `.appStateChanged` notifications on every state change. Runs a 1-second `Timer` on `RunLoop.main` for countdown ticks.

- **StatusBarController** (`Tomo/StatusBarController.swift`) — Manages the NSStatusItem and the floating popup NSWindow. `StatusItemView` renders the menu bar icon with Core Graphics (colored background, countdown text, progress overlay).

- **AppDelegate** (`Tomo/AppDelegate.swift`) — Wires StatusBarController to AppState; handles window show/hide via NSEvent monitors for outside clicks.

- **Views** — `TimersViewController` shows either the active timer (with pause/stop/+5m/restart controls) or the timer selection grid. `ActionButton` is the main custom button component with bezel effect, hover/press states, and optional progress overlay. UI is built programmatically with Auto Layout (no storyboards/xibs/SwiftUI).

- **Settings** — `SettingsViewController` lists timers; `EditTimerViewController` edits individual timer config (name, duration, color, sound, chain-to-next).

- **Models** — `TimerConfig` (Codable config), `StartedTimer` (active timer with timing state), `TimerHistory` (per-day usage tracking), `ColorName`/`Sound` enums.

- **CloudSyncManager** (`Tomo/Sync/CloudSyncManager.swift`) — Syncs timer configs via `NSUbiquitousKeyValueStore`.

## Key Patterns

- All UI uses `translatesAutoresizingMaskIntoConstraints = false` with manual NSLayoutConstraint activation
- Button actions use `ButtonActionHelper` with `objc_setAssociatedObject` to attach closures
- Factory functions in `Helpers.swift` and `TimerButton.swift` for consistent component creation
- Timer state machine: `.done` / `.running` / `.paused`
- Timers can chain via `startNextId` — when one finishes, the next auto-starts
- Window width is fixed at 396pt (`windowWidth` constant in Helpers.swift)
