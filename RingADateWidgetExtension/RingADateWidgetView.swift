import WidgetKit
import SwiftUI

struct RingADateWidget: Widget {
    private let kind = "RingADateWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: RingADateConfigurationIntent.self, provider: RingADateProvider()) { entry in
            RingADateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ring-a-Date Calendar")
        .description("A digital recreation of the classic Ring-a-Date perpetual calendar.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RingADateWidgetEntryView: View {
    var entry: RingADateProvider.Entry
    
    // Days of the week (short form)
    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Months (short form)
    let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    var body: some View {
        ZStack {
            // Background
            entry.backgroundColor
            
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let calendarSize = size * 0.9
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2
                
                ZStack {
                    // Calendar face
                    CalendarFace(size: calendarSize)
                    
                    // Day ring
                    Ring(position: entry.dayPosition, 
                         totalPositions: 7,
                         radius: calendarSize * 0.3,
                         ringColor: entry.ringColor,
                         centerX: centerX,
                         centerY: centerY)
                    
                    // Date ring
                    Ring(position: entry.datePosition,
                         totalPositions: 31,
                         radius: calendarSize * 0.2,
                         ringColor: entry.ringColor,
                         centerX: centerX,
                         centerY: centerY)
                    
                    // Month ring
                    Ring(position: entry.monthPosition,
                         totalPositions: 12,
                         radius: calendarSize * 0.4,
                         ringColor: entry.ringColor,
                         centerX: centerX,
                         centerY: centerY)
                }
                .frame(width: size, height: size)
                .position(x: centerX, y: centerY)
            }
        }
    }
}

// The calendar face with days, dates, and months
struct CalendarFace: View {
    let size: CGFloat
    
    // Days of the week (short form)
    let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Months (short form)
    let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    var body: some View {
        ZStack {
            // Days circle
            ForEach(0..<7) { index in
                Text(days[index])
                    .font(.system(size: size * 0.05))
                    .position(
                        x: size/2 + cos(angle(for: index, total: 7)) * size * 0.3,
                        y: size/2 + sin(angle(for: index, total: 7)) * size * 0.3
                    )
            }
            
            // Dates circle (1-31)
            ForEach(1...31, id: \.self) { date in
                Text("\(date)")
                    .font(.system(size: size * 0.04))
                    .position(
                        x: size/2 + cos(angle(for: date-1, total: 31)) * size * 0.2,
                        y: size/2 + sin(angle(for: date-1, total: 31)) * size * 0.2
                    )
            }
            
            // Months circle
            ForEach(0..<12) { index in
                Text(months[index])
                    .font(.system(size: size * 0.05))
                    .position(
                        x: size/2 + cos(angle(for: index, total: 12)) * size * 0.4,
                        y: size/2 + sin(angle(for: index, total: 12)) * size * 0.4
                    )
            }
        }
        .frame(width: size, height: size)