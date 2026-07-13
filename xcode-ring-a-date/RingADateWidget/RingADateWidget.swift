//
//  RingADateWidget.swift
//  RingADateWidgetExtension
//
//  The Ring a Date home screen widget. The face updates itself at midnight;
//  the colors come from the theme the companion app saves in the App Group.
//

import WidgetKit
import SwiftUI

struct RingADateEntry: TimelineEntry {
    let date: Date
    let theme: CalendarTheme
    let positions: RingPositions
    let markerRings: [MarkerRing]
    let interactive: Bool
}

struct RingADateProvider: TimelineProvider {
    func placeholder(in context: Context) -> RingADateEntry {
        RingADateEntry(date: .now, theme: .classic,
                       positions: RingPositions(date: .now),
                       markerRings: [], interactive: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (RingADateEntry) -> Void) {
        completion(RingADateEntry(date: .now, theme: ThemeStorage.load(),
                                  positions: RingPositions(date: .now),
                                  markerRings: ThemeStorage.loadMarkerRings(),
                                  interactive: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RingADateEntry>) -> Void) {
        let theme = ThemeStorage.load()
        let markerRings = ThemeStorage.loadMarkerRings()

        // Manual mode: the rings stay where the user tapped them last; the
        // timeline never advances on its own. Every peg tap runs
        // SetRingIntent, which saves the new positions and reloads us.
        if ThemeStorage.loadMode() == .manual {
            let entry = RingADateEntry(date: .now, theme: theme,
                                       positions: ThemeStorage.loadRingPositions(),
                                       markerRings: markerRings,
                                       interactive: true)
            completion(Timeline(entries: [entry], policy: .never))
            return
        }

        // Automatic mode: one entry now, then one per midnight for a week.
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        var entries = [RingADateEntry(date: .now, theme: theme,
                                      positions: RingPositions(date: .now),
                                      markerRings: markerRings,
                                      interactive: false)]
        for dayOffset in 1...7 {
            if let midnight = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) {
                entries.append(RingADateEntry(date: midnight, theme: theme,
                                              positions: RingPositions(date: midnight),
                                              markerRings: markerRings,
                                              interactive: false))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct RingADateWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: RingADateEntry

    var body: some View {
        RingADateFace(theme: entry.theme, positions: entry.positions,
                      markerRings: entry.markerRings,
                      layout: layout, interactive: entry.interactive)
            .padding(padding)
            .containerBackground(entry.theme.background, for: .widget)
    }

    private var layout: RingADateLayout {
        switch family {
        case .systemSmall: .compact
        case .systemMedium: .split
        default: .full
        }
    }

    private var padding: CGFloat {
        switch family {
        case .systemSmall: 12
        case .systemMedium: 14
        default: 18
        }
    }
}

struct RingADateWidget: Widget {
    let kind = "RingADateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RingADateProvider()) { entry in
            RingADateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ring a Date")
        .description("Il calendario perpetuo ad anelli, sempre aggiornato.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct RingADateWidgetBundle: WidgetBundle {
    var body: some Widget {
        RingADateWidget()
    }
}

#Preview("Small", as: .systemSmall) {
    RingADateWidget()
} timeline: {
    RingADateEntry(date: .now, theme: .classic,
                   positions: RingPositions(date: .now),
                   markerRings: [], interactive: false)
}

#Preview("Medium", as: .systemMedium) {
    RingADateWidget()
} timeline: {
    RingADateEntry(date: .now, theme: .classic,
                   positions: RingPositions(date: .now),
                   markerRings: [], interactive: true)
}

#Preview("Large", as: .systemLarge) {
    RingADateWidget()
} timeline: {
    RingADateEntry(date: .now, theme: .classic,
                   positions: RingPositions(date: .now),
                   markerRings: [], interactive: true)
}
