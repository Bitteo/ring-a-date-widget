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

    @Test func customPresetSurvivesEncoding() throws {
        let preset = ThemePreset(name: "Palette 1", theme: .classic)
        let data = try JSONEncoder().encode([preset])
        let decoded = try JSONDecoder().decode([ThemePreset].self, from: data)
        #expect(decoded == [preset])
    }

    @Test func presetsAreDistinctAndNamed() {
        let presets = CalendarTheme.presets
        #expect(!presets.isEmpty)
        #expect(Set(presets.map(\.id)).count == presets.count)
        #expect(Set(presets.map(\.theme.backgroundHex)).count == presets.count)
        #expect(presets.first?.theme == .classic)
    }

    @Test func ringPositionsFollowTheDate() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 12
        let date = try #require(Calendar.current.date(from: components))
        let positions = RingPositions(date: date)
        #expect(positions.day == 12)
        #expect(positions.monthIndex == 6)
        #expect(positions.weekdayIndex == Calendar.current.component(.weekday, from: date) - 1)
    }

    @Test func ringPositionsSurviveEncoding() throws {
        let positions = RingPositions(weekdayIndex: 1, day: 27, monthIndex: 5)
        let data = try JSONEncoder().encode(positions)
        let decoded = try JSONDecoder().decode(RingPositions.self, from: data)
        #expect(decoded == positions)
    }

    @Test func calendarLabelsMatchTheBoard() {
        #expect(RingADateFace.dayLabels.count == 7)
        #expect(RingADateFace.monthLabels.count == 12)
        #expect(RingADateFace.dayLabels.first == "sun")
        #expect(RingADateFace.monthLabels[5] == "june")
    }
}
