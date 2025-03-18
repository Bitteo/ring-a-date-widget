import WidgetKit
import SwiftUI
import Intents

// Widget configuration intent
struct RingADateConfigurationIntent: Identifiable {
    var id: String { "RingADateConfigurationIntent" }
    
    // Background color selection
    var backgroundColor: Color = .white
    
    // Ring color selection
    var ringColor: Color = .black
    
    // Manual date settings
    var manualDay: Int = Calendar.current.component(.weekday, from: Date()) - 1
    var manualDate: Int = Calendar.current.component(.day, from: Date()) - 1
    var manualMonth: Int = Calendar.current.component(.month, from: Date()) - 1
}

// Widget entry model
struct RingADateEntry: TimelineEntry {
    let date: Date
    let configuration: RingADateConfigurationIntent
    
    // Computed properties for ring positions
    var dayPosition: Int { configuration.manualDay }
    var datePosition: Int { configuration.manualDate }
    var monthPosition: Int { configuration.manualMonth }
    
    // Computed properties for colors
    var backgroundColor: Color { configuration.backgroundColor }
    var ringColor: Color { configuration.ringColor }
}

// Widget provider
struct RingADateProvider: IntentTimelineProvider {
    typealias Intent = RingADateConfigurationIntent
    typealias Entry = RingADateEntry
    
    func placeholder(in context: Context) -> RingADateEntry {
        RingADateEntry(
            date: Date(),
            configuration: RingADateConfigurationIntent()
        )
    }
    
    func getSnapshot(for configuration: RingADateConfigurationIntent, in context: Context, completion: @escaping (RingADateEntry) -> Void) {
        let entry = RingADateEntry(
            date: Date(),
            configuration: configuration
        )
        completion(entry)
    }
    
    func getTimeline(for configuration: RingADateConfigurationIntent, in context: Context, completion: @escaping (Timeline<RingADateEntry>) -> Void) {
        // Create a timeline entry for the current date
        let entry = RingADateEntry(
            date: Date(),
            configuration: configuration
        )
        
        // Create a timeline that refreshes once per day at midnight
        let nextMidnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        
        completion(timeline)
    }
}