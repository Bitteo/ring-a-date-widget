//
//  xcode_ring_a_dateTests.swift
//  xcode-ring-a-dateTests
//

import Testing
import SwiftUI
import Foundation
@testable import xcode_ring_a_date

struct ThemeTests {

    @Test func hexRoundTrip() {
        let samples = ["#2F6B52", "#000000", "#FFFFFF", "#E4B33D", "#17191C"]
        for hex in samples {
            #expect(Color(hex: hex).hexString == hex)
        }
    }

    @Test func invalidHexFallsBackToBlack() {
        #expect(Color(hex: "not-a-color").hexString == "#000000")
        #expect(Color(hex: "#FFF").hexString == "#000000")
    }

    @Test func themeSurvivesEncoding() throws {
        let theme = CalendarTheme.classic
        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(CalendarTheme.self, from: data)
        #expect(decoded == theme)
    }

    @Test func presetsAreDistinctAndNamed() {
        let presets = CalendarTheme.presets
        #expect(!presets.isEmpty)
        #expect(Set(presets.map(\.id)).count == presets.count)
        #expect(Set(presets.map(\.theme.backgroundHex)).count == presets.count)
        #expect(presets.first?.theme == .classic)
    }

    @Test func calendarLabelsMatchTheBoard() {
        #expect(RingADateFace.dayLabels.count == 7)
        #expect(RingADateFace.monthLabels.count == 12)
        #expect(RingADateFace.dayLabels.first == "sun")
        #expect(RingADateFace.monthLabels[5] == "june")
    }
}
