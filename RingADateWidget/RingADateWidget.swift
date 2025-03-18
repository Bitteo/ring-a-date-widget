import SwiftUI
import WidgetKit

@main
struct RingADateWidgetApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Ring-a-Date Widget")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("A digital recreation of the classic Ring-a-Date perpetual calendar")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Preview of the widget
            ZStack {
                Color.white
                    .frame(width: 200, height: 200)
                    .cornerRadius(20)
                    .shadow(radius: 5)
                
                // Sample calendar face with rings
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)
                    let centerX = geometry.size.width / 2
                    let centerY = geometry.size.height / 2
                    
                    // Calendar face with sample rings
                    CalendarPreview(size: size, centerX: centerX, centerY: centerY)
                }
                .frame(width: 200, height: 200)
            }
            
            Spacer()
            
            Text("Add the widget to your home screen to use it")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Text("Customize colors and manually update the date in widget settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

// Preview of the calendar for the main app
struct CalendarPreview: View {
    let size: CGFloat
    let centerX: CGFloat
    let centerY: CGFloat
    
    // Current date components
    let day = Calendar.current.component(.weekday, from: Date()) - 1
    let date = Calendar.current.component(.day, from: Date()) - 1
    let month = Calendar.current.component(.month, from: Date()) - 1
    
    var body: some View {
        ZStack {
            // Days of the week (short form)
            let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            
            // Months (short form)
            let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            
            // Days circle
            ForEach(0..<7) { index in
                Text(days[index])
                    .font(.system(size: size * 0.05))
                    .position(
                        x: centerX + cos(angle(for: index, total: 7)) * size * 0.3,
                        y: centerY + sin(angle(for: index, total: 7)) * size * 0.3
                    )
            }
            
            // Dates circle (1-31)
            ForEach(1...31, id: \.self) { date in
                Text("\(date)")
                    .font(.system(size: size * 0.04))
                    .position(
                        x: centerX + cos(angle(for: date-1, total: 31)) * size * 0.2,
                        y: centerY + sin(angle(for: date-1, total: 31)) * size * 0.2
                    )
            }
            
            // Months circle
            ForEach(0..<12) { index in
                Text(months[index])
                    .font(.system(size: size * 0.05))
                    .position(
                        x: centerX + cos(angle(for: index, total: 12)) * size * 0.4,
                        y: centerY + sin(angle(for: index, total: 12)) * size * 0.4
                    )
            }
            
            // Day ring
            Circle()
                .strokeBorder(Color.black, lineWidth: 3)
                .frame(width: 15, height: 15)
                .position(
                    x: centerX + cos(angle(for: day, total: 7)) * size * 0.3,
                    y: centerY + sin(angle(for: day, total: 7)) * size * 0.3
                )
            
            // Date ring
            Circle()
                .strokeBorder(Color.black, lineWidth: 3)
                .frame(width: 15, height: 15)
                .position(
                    x: centerX + cos(angle(for: date, total: 31)) * size * 0.2,
                    y: centerY + sin(angle(for: date, total: 31)) * size * 0.2
                )
            
            // Month ring
            Circle()
                .strokeBorder(Color.black, lineWidth: 3)
                .frame(width: 15, height: 15)
                .position(
                    x: centerX + cos(angle(for: month, total: 12)) * size * 0.4,
                    y: centerY + sin(angle(for: month, total: 12)) * size * 0.4
                )
        }
    }
}