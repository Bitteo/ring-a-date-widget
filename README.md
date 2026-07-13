# Ring a Date

A digital recreation of the classic "Ring a Date" perpetual calendar as an iOS
home screen widget, with a minimal companion app to customize its colors.

## What it does

- **Widget** (small, medium and large): draws the perpetual calendar board —
  a row of weekdays, dates 1–31 on four rows of eight columns, and months on
  two rows — with rings marking today's weekday, date and month.
  - *Large*: the full board, faithful to the original layout and spacing.
  - *Medium*: weekday and month pegs beside the full date grid.
  - *Small*: weekday, date and month pegs stacked, so they stay legible.
- **Two update modes**, chosen in the app:
  - *Automatico*: the rings jump to today's date at midnight.
  - *Manuale*: like the physical object, the rings stay where you put them —
    every peg on the widget is tappable (via an interactive-widget AppIntent)
    and moves its ring there. The small pegs advance their ring by one.
- **App**: a single screen with a live preview of the widget in all three
  sizes, six color palettes (Classico, Avorio, Notte, Terracotta, Oceano,
  Ardesia), user-saved palettes, and a custom editor for every color:
  background, pegs, text and the three rings (day, date, month). Changes
  reach the widget immediately.

## Project structure

```
xcode-ring-a-date/
├── Shared/                      Compiled into both the app and the widget
│   ├── CalendarTheme.swift      Theme model, palettes, App Group storage
│   └── RingADateFace.swift      The calendar face (full/split/compact layouts)
├── xcode-ring-a-date/           App target
│   ├── xcode_ring_a_dateApp.swift
│   ├── ThemeStore.swift         Observable theme + widget reload
│   ├── ContentView.swift        Preview, palettes, color editor
│   └── xcode-ring-a-date.entitlements
└── RingADateWidget/             Widget extension target
    ├── RingADateWidget.swift    Bundle, timeline provider, entry view
    ├── Info.plist
    └── RingADateWidget.entitlements
```

The app and the widget share the theme through the App Group
`group.jigo.xcode-ring-a-date` (see `ThemeStorage` in
`Shared/CalendarTheme.swift`). If the group container is unavailable the code
falls back to standard user defaults, so the app runs even before the
capability is provisioned — but the widget will only pick up custom colors
once the App Group is active on **both** targets.

## Setup

1. Open `xcode-ring-a-date.xcodeproj` in Xcode 16 or later.
2. Select your development team on the `xcode-ring-a-date` and
   `RingADateWidgetExtension` targets (Signing & Capabilities).
3. Make sure the App Group `group.jigo.xcode-ring-a-date` is registered for
   your team. If you need a different identifier, change it in the two
   `.entitlements` files and in `ThemeStorage.appGroupID`.
4. Run the app once, then add the widget from the Home Screen
   (long-press → Edit → Add Widget → Ring a Date).

## Design reference

Based on the classic Ring-a-Date perpetual calendar: a square board of pegs
with three movable rings for the current weekday, date and month.
