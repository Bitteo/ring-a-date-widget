//
//  CalendarTheme.swift
//  Ring a Date
//
//  The color theme shared between the app and the widget extension.
//

import SwiftUI
import UIKit

// MARK: - Hex color helpers

extension Color {
    /// Creates a color from a "#RRGGBB" hex string. Falls back to black.
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        var value: UInt64 = 0
        guard cleaned.count == 6, Scanner(string: cleaned).scanHexInt64(&value) else {
            self.init(red: 0, green: 0, blue: 0)
            return
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// "#RRGGBB" representation, clamped to sRGB.
    var hexString: String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func component(_ value: CGFloat) -> Int {
            Int((min(max(value, 0), 1) * 255).rounded())
        }
        return String(format: "#%02X%02X%02X", component(red), component(green), component(blue))
    }
}

// MARK: - Theme model

/// All the colors that make up a calendar face. Stored as hex strings so the
/// theme is Codable and can travel through the shared App Group defaults.
struct CalendarTheme: Codable, Equatable {
    var backgroundHex: String
    var pegHex: String
    var textHex: String
    var dayRingHex: String
    var dateRingHex: String
    var monthRingHex: String

    var background: Color { Color(hex: backgroundHex) }
    var peg: Color { Color(hex: pegHex) }
    var text: Color { Color(hex: textHex) }
    var dayRing: Color { Color(hex: dayRingHex) }
    var dateRing: Color { Color(hex: dateRingHex) }
    var monthRing: Color { Color(hex: monthRingHex) }
}

// MARK: - Presets

struct ThemePreset: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var theme: CalendarTheme
}

extension CalendarTheme {
    /// The green board with yellow/red/ivory rings of the original calendar.
    static let classic = CalendarTheme(
        backgroundHex: "#2F6B52",
        pegHex: "#265944",
        textHex: "#F2EFE6",
        dayRingHex: "#E4B33D",
        dateRingHex: "#C24D3F",
        monthRingHex: "#E7E2D6"
    )

    static let presets: [ThemePreset] = [
        ThemePreset(name: "Classico", theme: .classic),
        ThemePreset(name: "Avorio", theme: CalendarTheme(
            backgroundHex: "#F0EAE0",
            pegHex: "#E1D9C9",
            textHex: "#3B382F",
            dayRingHex: "#D95D39",
            dateRingHex: "#2F6B52",
            monthRingHex: "#E4B33D"
        )),
        ThemePreset(name: "Notte", theme: CalendarTheme(
            backgroundHex: "#17191C",
            pegHex: "#26292E",
            textHex: "#E8E6E1",
            dayRingHex: "#F2A65A",
            dateRingHex: "#7FB7BE",
            monthRingHex: "#D9D4C7"
        )),
        ThemePreset(name: "Terracotta", theme: CalendarTheme(
            backgroundHex: "#B25B38",
            pegHex: "#9E4E2E",
            textHex: "#FBEFE3",
            dayRingHex: "#F4E9DA",
            dateRingHex: "#2E4B3F",
            monthRingHex: "#EFC15C"
        )),
        ThemePreset(name: "Oceano", theme: CalendarTheme(
            backgroundHex: "#14424F",
            pegHex: "#0F3540",
            textHex: "#E4F1F1",
            dayRingHex: "#F2C57C",
            dateRingHex: "#E5E9E4",
            monthRingHex: "#6FB3A8"
        )),
        ThemePreset(name: "Ardesia", theme: CalendarTheme(
            backgroundHex: "#40464C",
            pegHex: "#363B41",
            textHex: "#F1F1EF",
            dayRingHex: "#F5C242",
            dateRingHex: "#E96D5E",
            monthRingHex: "#DDE1E4"
        )),
    ]
}

// MARK: - Shared storage

/// Persists the theme in the App Group so the widget extension can read what
/// the app saves. Falls back to standard defaults when the group is not
/// provisioned, so the app still works before the capability is enabled.
enum ThemeStorage {
    static let appGroupID = "group.jigo.xcode-ring-a-date"
    static let themeKey = "ringADate.theme"
    static let customPresetsKey = "ringADate.customPresets"
    static let paletteCounterKey = "ringADate.paletteCounter"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> CalendarTheme {
        guard let data = defaults.data(forKey: themeKey),
              let theme = try? JSONDecoder().decode(CalendarTheme.self, from: data) else {
            return .classic
        }
        return theme
    }

    static func save(_ theme: CalendarTheme) {
        guard let data = try? JSONEncoder().encode(theme) else { return }
        defaults.set(data, forKey: themeKey)
    }

    // MARK: User-created presets

    static func loadCustomPresets() -> [ThemePreset] {
        guard let data = defaults.data(forKey: customPresetsKey),
              let presets = try? JSONDecoder().decode([ThemePreset].self, from: data) else {
            return []
        }
        return presets
    }

    static func saveCustomPresets(_ presets: [ThemePreset]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        defaults.set(data, forKey: customPresetsKey)
    }

    /// Default name offered for the next preset ("Palette 1", "Palette 2"...).
    /// The counter advances on every creation, even if the user renames.
    static func nextPaletteName() -> String {
        "Palette \(defaults.integer(forKey: paletteCounterKey) + 1)"
    }

    static func bumpPaletteCounter() {
        defaults.set(defaults.integer(forKey: paletteCounterKey) + 1, forKey: paletteCounterKey)
    }
}
