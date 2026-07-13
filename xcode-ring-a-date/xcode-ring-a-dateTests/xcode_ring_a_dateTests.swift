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

    @Test func ringSettingWrapsAround() {
        var positions = RingPositions(weekdayIndex: 0, day: 1, monthIndex: 0)
        positions.set(ring: "weekday", to: 7)
        #expect(positions.weekdayIndex == 0)
        positions.set(ring: "weekday", to: -1)
        #expect(positions.weekdayIndex == 6)
        positions.set(ring: "date", to: 32)
        #expect(positions.day == 1)
        positions.set(ring: "date", to: 27)
        #expect(positions.day == 27)
        positions.set(ring: "month", to: 12)
        #expect(positions.monthIndex == 0)
        positions.set(ring: "unknown", to: 3)
        #expect(positions == RingPositions(weekdayIndex: 6, day: 27, monthIndex: 0))
    }

    @Test func ringPositionsSurviveEncoding() throws {
        let positions = RingPositions(weekdayIndex: 1, day: 27, monthIndex: 5)
        let data = try JSONEncoder().encode(positions)
        let decoded = try JSONDecoder().decode(RingPositions.self, from: data)
        #expect(decoded == positions)
    }

    @Test func themeWithoutFontStyleDefaultsToNeutral() throws {
        let legacyJSON = """
        {"backgroundHex":"#2F6B52","pegHex":"#265944","textHex":"#F2EFE6","dayRingHex":"#E4B33D","dateRingHex":"#C24D3F","monthRingHex":"#E7E2D6"}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CalendarTheme.self, from: legacyJSON)
        #expect(decoded.fontStyle == .neutral)
    }

    @Test func retiredFontStylesMigrateForward() {
        #expect(CalendarFontStyle.migrated(from: "rounded") == .neutral)
        #expect(CalendarFontStyle.migrated(from: "serif") == .classic)
    }

    @Test func fontStyleSurvivesEncoding() throws {
        var theme = CalendarTheme.classic
        theme.fontStyle = .mono
        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(CalendarTheme.self, from: data)
        #expect(decoded.fontStyle == .mono)
    }

    @Test func markerRingsSurviveEncoding() throws {
        let markers = [
            MarkerRing(day: 12, colorHex: "#9B5DE5"),
            MarkerRing(day: 30, colorHex: "#F15BB5"),
        ]
        let data = try JSONEncoder().encode(markers)
        let decoded = try JSONDecoder().decode([MarkerRing].self, from: data)
        #expect(decoded == markers)
    }

    @Test func unplacedMarkerRingsSurviveEncoding() throws {
        let markers = [
            MarkerRing(day: nil, colorHex: "#9B5DE5"),
            MarkerRing(day: 15, colorHex: "#F15BB5"),
        ]
        let data = try JSONEncoder().encode(markers)
        let decoded = try JSONDecoder().decode([MarkerRing].self, from: data)
        #expect(decoded == markers)
    }

    @Test func legacyPlacedMarkerJSONStillDecodes() throws {
        let legacyJSON = """
        [{"id":"A1B2C3D4-E5F6-7890-ABCD-EF1234567890","day":12,"colorHex":"#9B5DE5"}]
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode([MarkerRing].self, from: legacyJSON)
        #expect(decoded.count == 1)
        #expect(decoded[0].day == 12)
        #expect(decoded[0].colorHex == "#9B5DE5")
    }

    @MainActor
    @Test func placeMarkerSetsDayAndClearsActiveSelection() {
        let store = ThemeStore()
        store.markerRings = []
        let marker = MarkerRing(day: nil, colorHex: "#9B5DE5")
        store.upsertMarker(marker)
        store.activateMarker(id: marker.id)
        store.placeMarker(id: marker.id, on: 21)
        #expect(store.markerRings.first?.day == 21)
        #expect(store.activeMarkerID == nil)
    }

    @Test func calendarLabelsMatchTheBoard() {
        #expect(RingADateFace.dayLabels.count == 7)
        #expect(RingADateFace.monthLabels.count == 12)
        #expect(RingADateFace.dayLabels.first == "sun")
        #expect(RingADateFace.monthLabels[5] == "june")
    }
}
