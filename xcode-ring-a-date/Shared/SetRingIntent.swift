//
//  SetRingIntent.swift
//  Ring a Date
//
//  The intent behind the widget's tappable pegs: moves one ring to a new
//  position. Runs in the widget extension process when a peg is tapped.
//

import AppIntents
import WidgetKit

struct SetRingIntent: AppIntent {
    static var title: LocalizedStringResource = "Sposta anello"
    static var isDiscoverable: Bool = false

    /// One of "weekday", "date" or "month".
    @Parameter(title: "Anello") var ring: String
    /// The target position: weekday 0...6, date 1...31, month 0...11.
    /// Out-of-range values wrap around, so "advance by one" call sites
    /// don't have to.
    @Parameter(title: "Posizione") var value: Int

    init() {}

    init(ring: String, value: Int) {
        self.ring = ring
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        var positions = ThemeStorage.loadRingPositions()
        positions.set(ring: ring, to: value)
        ThemeStorage.saveRingPositions(positions)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
