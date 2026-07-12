//
//  ThemeStore.swift
//  xcode-ring-a-date
//
//  Observable wrapper around the shared theme. Every change is persisted to
//  the App Group and pushed to the widget right away.
//

import SwiftUI
import WidgetKit

@MainActor
final class ThemeStore: ObservableObject {
    @Published var theme: CalendarTheme {
        didSet {
            guard theme != oldValue else { return }
            ThemeStorage.save(theme)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @Published private(set) var customPresets: [ThemePreset]

    /// Whether the widget rings follow the date or the user's taps.
    @Published var mode: CalendarMode {
        didSet {
            guard mode != oldValue else { return }
            if mode == .manual {
                // Manual rings start from today, like picking the object up.
                ThemeStorage.saveRingPositions(RingPositions(date: .now))
            }
            ThemeStorage.saveMode(mode)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    init() {
        theme = ThemeStorage.load()
        customPresets = ThemeStorage.loadCustomPresets()
        mode = ThemeStorage.loadMode()
    }

    /// Ring positions to show in the in-app preview: the stored ones in
    /// manual mode, today's in automatic mode.
    var previewPositions: RingPositions {
        mode == .manual ? ThemeStorage.loadRingPositions() : RingPositions(date: .now)
    }

    /// Re-reads state that other processes may have changed (the widget
    /// moves rings through SetRingIntent while the app is in background).
    func refreshExternalState() {
        objectWillChange.send()
    }

    /// The preset matching the current theme, if the user hasn't customized it.
    var selectedPresetID: UUID? {
        (CalendarTheme.presets + customPresets).first { $0.theme == theme }?.id
    }

    /// Saves the current theme as a user preset. Falls back to the suggested
    /// "Palette N" name when the given name is empty.
    func saveCurrentAsPreset(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? ThemeStorage.nextPaletteName() : trimmed
        customPresets.append(ThemePreset(name: finalName, theme: theme))
        ThemeStorage.saveCustomPresets(customPresets)
        ThemeStorage.bumpPaletteCounter()
    }

    func deletePreset(_ preset: ThemePreset) {
        customPresets.removeAll { $0.id == preset.id }
        ThemeStorage.saveCustomPresets(customPresets)
    }

    /// Binding for a single theme color, bridged to `Color` for ColorPicker.
    func binding(for keyPath: WritableKeyPath<CalendarTheme, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: self.theme[keyPath: keyPath]) },
            set: { self.theme[keyPath: keyPath] = $0.hexString }
        )
    }
}
