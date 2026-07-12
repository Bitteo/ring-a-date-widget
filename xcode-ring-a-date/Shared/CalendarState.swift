//
//  CalendarState.swift
//  Ring a Date
//
//  Where the rings sit on the board, and whether they move by themselves.
//

import Foundation

/// How the widget keeps its rings up to date.
enum CalendarMode: String, Codable {
    /// The rings jump to today's date at midnight.
    case automatic
    /// Like the physical calendar: the rings stay where the user puts them,
    /// one tap at a time on the widget pegs.
    case manual
}

/// The three ring positions on the board.
struct RingPositions: Codable, Equatable {
    var weekdayIndex: Int  // 0 = sun ... 6 = sat
    var day: Int           // 1...31
    var monthIndex: Int    // 0 = jan ... 11 = dec

    init(weekdayIndex: Int, day: Int, monthIndex: Int) {
        self.weekdayIndex = weekdayIndex
        self.day = day
        self.monthIndex = monthIndex
    }

    init(date: Date) {
        let calendar = Calendar.current
        weekdayIndex = calendar.component(.weekday, from: date) - 1
        day = calendar.component(.day, from: date)
        monthIndex = calendar.component(.month, from: date) - 1
    }

    /// Moves one ring ("weekday", "date" or "month") to a new position.
    /// Out-of-range values wrap around, so "advance by one" call sites
    /// don't have to.
    mutating func set(ring: String, to value: Int) {
        switch ring {
        case "weekday":
            weekdayIndex = ((value % 7) + 7) % 7
        case "date":
            day = (((value - 1) % 31) + 31) % 31 + 1
        case "month":
            monthIndex = ((value % 12) + 12) % 12
        default:
            break
        }
    }
}

extension ThemeStorage {
    static let modeKey = "ringADate.mode"
    static let ringPositionsKey = "ringADate.ringPositions"

    static func loadMode() -> CalendarMode {
        guard let raw = defaults.string(forKey: modeKey),
              let mode = CalendarMode(rawValue: raw) else {
            return .automatic
        }
        return mode
    }

    static func saveMode(_ mode: CalendarMode) {
        defaults.set(mode.rawValue, forKey: modeKey)
    }

    static func loadRingPositions() -> RingPositions {
        guard let data = defaults.data(forKey: ringPositionsKey),
              let positions = try? JSONDecoder().decode(RingPositions.self, from: data) else {
            return RingPositions(date: .now)
        }
        return positions
    }

    static func saveRingPositions(_ positions: RingPositions) {
        guard let data = try? JSONEncoder().encode(positions) else { return }
        defaults.set(data, forKey: ringPositionsKey)
    }
}
