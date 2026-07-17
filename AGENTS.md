# AGENTS.md

## Cursor Cloud specific instructions

**Ring a Date** is a native **iOS/Swift** product (a WidgetKit home-screen widget plus a
SwiftUI companion app), built with **Xcode**. There is a single Xcode project at
`xcode-ring-a-date/xcode-ring-a-date.xcodeproj` — no Swift Package Manager,
CocoaPods, npm, database, or backend service. Setup/signing steps live in
`README.md`.

### Platform requirement (important)

Every source and test file imports Apple-only frameworks (`SwiftUI`, `WidgetKit`,
`AppIntents`, `UIKit`), and the toolchain is `xcodebuild`. **This project can only
be built, run, and tested on macOS with Xcode 16.2+ (targets iOS 18.2+).**

The Cursor Cloud VM is **Linux x86_64 with no Swift/Xcode toolchain**, so it
**cannot build, run, or test this app**. There are no Linux-installable
dependencies for this repo; the startup/update script is intentionally a no-op.
Code changes here can only be verified on a macOS host or macOS-based CI.

### Build / test / run (macOS only)

There is no committed `.xcscheme`; Xcode auto-generates the `xcode-ring-a-date`
scheme (which embeds `RingADateWidgetExtension`). Adjust the simulator name via
`xcrun simctl list devices`.

- Open: `open xcode-ring-a-date/xcode-ring-a-date.xcodeproj`
- Build: `xcodebuild -project xcode-ring-a-date/xcode-ring-a-date.xcodeproj -scheme xcode-ring-a-date -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Test: `xcodebuild test -project xcode-ring-a-date/xcode-ring-a-date.xcodeproj -scheme xcode-ring-a-date -destination 'platform=iOS Simulator,name=iPhone 16'`
- Run: use Xcode (⌘R), then add the widget to the Home Screen (long-press → Edit
  → Add Widget → Ring a Date). Unit tests live in `xcode-ring-a-dateTests/`
  (Swift Testing); UI tests in `xcode-ring-a-dateUITests/` (XCTest).
- Lint: no SwiftLint/lint config in the repo; rely on Xcode warnings /
  Product → Analyze.

### Gotchas

- App and widget share state through App Group `group.jigo.xcode-ring-a-date`. On
  a device this needs a development team + provisioned App Group on **both**
  targets. `ThemeStorage` (in `Shared/CalendarTheme.swift`) falls back to standard
  `UserDefaults` when the group container is unavailable, so the app still runs,
  but the widget won't pick up custom colors until the App Group is active on both
  targets.
- `.cursor/mcp.json` wires up the Xcode MCP bridge (`xcrun mcpbridge`), which only
  works on macOS.
