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

    init() {
        theme = ThemeStorage.load()
    }

    /// The preset matching the current theme, if the user hasn't customized it.
    var selectedPresetID: String? {
        CalendarTheme.presets.first { $0.theme == theme }?.id
    }

    /// Binding for a single theme color, bridged to `Color` for ColorPicker.
    func binding(for keyPath: WritableKeyPath<CalendarTheme, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: self.theme[keyPath: keyPath]) },
            set: { self.theme[keyPath: keyPath] = $0.hexString }
        )
    }
}
