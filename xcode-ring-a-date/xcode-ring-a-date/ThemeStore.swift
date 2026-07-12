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

    init() {
        theme = ThemeStorage.load()
        customPresets = ThemeStorage.loadCustomPresets()
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
