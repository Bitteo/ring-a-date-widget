import SwiftUI

struct Ring: View {
    let position: Int
    let totalPositions: Int
    let radius: CGFloat
    let ringColor: Color
    let centerX: CGFloat
    let centerY: CGFloat
    
    // Ring thickness and size
    private let ringThickness: CGFloat = 5
    private let ringSize: CGFloat = 20
    
    var body: some View {
        // Calculate the angle for the current position
        let angle = 2 * .pi * Double(position) / Double(totalPositions) - .pi / 2
        
        // Calculate the position on the circle
        let x = centerX + cos(angle) * radius
        let y = centerY + sin(angle) * radius
        
        // Draw the ring
        Circle()
            .strokeBorder(ringColor, lineWidth: ringThickness)
            .frame(width: ringSize, height: ringSize)
            .position(x: x, y: y)
    }
}

// Helper function to calculate angle for positions
func angle(for position: Int, total: Int) -> Double {
    return 2 * .pi * Double(position) / Double(total) - .pi / 2
}

// Preview
struct Ring_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.white
            Ring(position: 0, totalPositions: 7, radius: 100, ringColor: .black, centerX: 150, centerY: 150)
        }
        .frame(width: 300, height: 300)
        .previewLayout(.sizeThatFits)
    }
}