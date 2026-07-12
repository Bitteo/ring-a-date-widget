//
//  RingADateFace.swift
//  Ring a Date
//
//  The calendar face, drawn to match the original board: a row of weekdays,
//  four rows of dates on eight columns, and two rows of months, with wider
//  gaps between the three sections. Rings mark today's weekday, date and month.
//

import SwiftUI
import WidgetKit
import AppIntents

/// Which arrangement of the calendar face to draw.
enum RingADateLayout {
    /// The whole board: weekday row, date grid and month rows.
    case full
    /// Weekday and month pegs beside the date grid, for wide contexts.
    case split
    /// Weekday, date and month pegs stacked vertically, for small contexts.
    case compact
}

struct RingADateFace: View {
    let theme: CalendarTheme
    let positions: RingPositions
    let layout: RingADateLayout
    /// When true, every peg becomes a Button driving SetRingIntent, so the
    /// rings can be moved by tapping the widget (manual mode).
    let interactive: Bool
    /// In-app counterpart of `interactive`: when set, tapping a peg calls
    /// this with the ring name and target position instead of an AppIntent.
    let onPegTap: ((String, Int) -> Void)?

    /// In the tinted/clear Home Screen modes the system flattens every view
    /// to white through its alpha channel, so theme colors must give way to
    /// translucency: see-through pegs, full-opacity text, accentable rings.
    @Environment(\.widgetRenderingMode) private var renderingMode

    /// Pairs each sliding ring with the peg it currently sits on, so a
    /// position change animates as a slide across the board.
    @Namespace private var ringNamespace

    init(theme: CalendarTheme,
         positions: RingPositions,
         layout: RingADateLayout = .full,
         interactive: Bool = false,
         onPegTap: ((String, Int) -> Void)? = nil) {
        self.theme = theme
        self.positions = positions
        self.layout = layout
        self.interactive = interactive
        self.onPegTap = onPegTap
    }

    init(theme: CalendarTheme, date: Date, layout: RingADateLayout = .full) {
        self.init(theme: theme, positions: RingPositions(date: date), layout: layout)
    }

    static let dayLabels = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
    static let monthLabels = ["jan", "feb", "mar", "apr", "may", "june",
                              "july", "aug", "sep", "oct", "nov", "dec"]

    // Grid proportions, relative to one peg diameter.
    private let columnSpacing: CGFloat = 0.30
    private let rowSpacing: CGFloat = 0.30
    private let sectionGap: CGFloat = 0.95

    private var weekdayIndex: Int { positions.weekdayIndex }
    private var dayOfMonth: Int { positions.day }
    private var monthIndex: Int { positions.monthIndex }

    var body: some View {
        GeometryReader { geometry in
            Group {
                switch layout {
                case .full: fullFace(in: geometry.size)
                case .split: splitFace(in: geometry.size)
                case .compact: compactFace(in: geometry.size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    // MARK: - Full board

    private func fullFace(in size: CGSize) -> some View {
        let widthUnits = 8 + 7 * columnSpacing
        let heightUnits = 7 + 4 * rowSpacing + 2 * sectionGap
        let cell = min(size.width / widthUnits, size.height / heightUnits)
        let spacing = cell * columnSpacing
        let gap = cell * sectionGap
        let boardWidth = 8 * cell + 7 * spacing

        return ZStack {
            VStack(alignment: .leading, spacing: spacing) {
                dayRow(cell: cell, width: boardWidth)
                    .padding(.bottom, gap - spacing)
                dateGrid(cell: cell)
                monthRows(cell: cell)
                    .padding(.top, gap - spacing)
            }
            slidingRing(theme.dayRing, cell: cell, matchID: "weekday-\(weekdayIndex)")
            slidingRing(theme.dateRing, cell: cell, matchID: "date-\(dayOfMonth)")
            slidingRing(theme.monthRing, cell: cell, matchID: "month-\(monthIndex)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The seven weekdays, spread across the full width of the board.
    private func dayRow(cell: CGFloat, width: CGFloat) -> some View {
        HStack(spacing: (width - 7 * cell) / 6) {
            ForEach(0..<7, id: \.self) { index in
                ringPegButton(ring: "weekday", value: index) {
                    gridPeg(Self.dayLabels[index], cell: cell, matchID: "weekday-\(index)")
                }
            }
        }
        .frame(width: width)
    }

    /// Dates 1...31 on four rows of eight columns.
    private func dateGrid(cell: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: cell * rowSpacing) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: cell * columnSpacing) {
                    ForEach(0..<8, id: \.self) { column in
                        let value = row * 8 + column + 1
                        if value <= 31 {
                            ringPegButton(ring: "date", value: value) {
                                gridPeg("\(value)", cell: cell, matchID: "date-\(value)")
                            }
                        } else {
                            Color.clear.frame(width: cell, height: cell)
                        }
                    }
                }
            }
        }
    }

    /// Months on two rows: jan...aug, then sep...dec aligned left.
    private func monthRows(cell: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: cell * rowSpacing) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: cell * columnSpacing) {
                    ForEach(0..<8, id: \.self) { column in
                        let index = row * 8 + column
                        if index < 12 {
                            ringPegButton(ring: "month", value: index) {
                                gridPeg(Self.monthLabels[index], cell: cell, matchID: "month-\(index)")
                            }
                        } else {
                            Color.clear.frame(width: cell, height: cell)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Split face (medium widget)

    private func splitFace(in size: CGSize) -> some View {
        let pegSide = size.height * 0.46
        let gap = size.height * 0.08
        let gridWidthUnits = 8 + 7 * columnSpacing
        let gridHeightUnits = 4 + 3 * rowSpacing
        let cell = min((size.width - pegSide - gap) / gridWidthUnits,
                       size.height / gridHeightUnits)

        // The single day/month pegs can't offer every position, so a tap
        // advances them by one, wrapping around.
        return ZStack {
            HStack(spacing: gap) {
                VStack(spacing: size.height * 0.06) {
                    ringPegButton(ring: "weekday", value: weekdayIndex + 1) {
                        framedPeg(Self.dayLabels[weekdayIndex], side: pegSide, ring: theme.dayRing)
                    }
                    ringPegButton(ring: "month", value: monthIndex + 1) {
                        framedPeg(Self.monthLabels[monthIndex], side: pegSide, ring: theme.monthRing)
                    }
                }
                dateGrid(cell: cell)
            }
            slidingRing(theme.dateRing, cell: cell, matchID: "date-\(dayOfMonth)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Compact face (small widget)

    private func compactFace(in size: CGSize) -> some View {
        let side = min(size.width, size.height)
        return VStack(spacing: side * 0.05) {
            ringPegButton(ring: "weekday", value: weekdayIndex + 1) {
                framedPeg(Self.dayLabels[weekdayIndex], side: side * 0.26, ring: theme.dayRing)
            }
            ringPegButton(ring: "date", value: dayOfMonth + 1) {
                framedPeg("\(dayOfMonth)", side: side * 0.38, ring: theme.dateRing)
            }
            ringPegButton(ring: "month", value: monthIndex + 1) {
                framedPeg(Self.monthLabels[monthIndex], side: side * 0.26, ring: theme.monthRing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Rendering-mode aware styles

    private var isFullColor: Bool { renderingMode == .fullColor }

    private var pegFill: AnyShapeStyle {
        isFullColor ? AnyShapeStyle(theme.peg) : AnyShapeStyle(Color.white.opacity(0.2))
    }

    private var textColor: Color {
        isFullColor ? theme.text : .white
    }

    private func ringColor(_ color: Color) -> Color {
        isFullColor ? color : .white
    }

    // MARK: - Pegs

    /// Wraps a peg in a Button driving SetRingIntent when the face is
    /// interactive, or in a plain button calling `onPegTap` when the app
    /// provides one; otherwise returns the peg untouched.
    @ViewBuilder
    private func ringPegButton<Peg: View>(ring: String, value: Int,
                                          @ViewBuilder peg: () -> Peg) -> some View {
        if interactive {
            Button(intent: SetRingIntent(ring: ring, value: value)) {
                peg()
            }
            .buttonStyle(.plain)
        } else if let onPegTap {
            Button {
                onPegTap(ring, value)
            } label: {
                peg()
            }
            .buttonStyle(.plain)
        } else {
            peg()
        }
    }

    /// A board peg, registered as the geometry source its ring slides to.
    private func gridPeg(_ label: String, cell: CGFloat, matchID: String) -> some View {
        ZStack {
            Circle()
                .fill(pegFill)
            Text(label)
                .font(.system(size: cell * 0.42, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(textColor)
                .padding(cell * 0.08)
        }
        .frame(width: cell, height: cell)
        .matchedGeometryEffect(id: matchID, in: ringNamespace)
    }

    /// One of the three rings, drawn once per board and matched to the peg
    /// it currently sits on: when the position changes, the ring slides
    /// across the board like the physical one.
    private func slidingRing(_ color: Color, cell: CGFloat, matchID: String) -> some View {
        Circle()
            .strokeBorder(ringColor(color), lineWidth: cell * 0.18)
            .frame(width: cell * 1.32, height: cell * 1.32)
            .matchedGeometryEffect(id: matchID, in: ringNamespace,
                                   properties: .position, isSource: false)
            .widgetAccentable()
            .allowsHitTesting(false)
    }

    /// A peg with its ring contained inside the frame, for the compact faces.
    private func framedPeg(_ label: String, side: CGFloat, ring: Color) -> some View {
        ZStack {
            Circle()
                .strokeBorder(ringColor(ring), lineWidth: side * 0.10)
                .widgetAccentable()
            Circle()
                .fill(pegFill)
                .frame(width: side * 0.72, height: side * 0.72)
            Text(label)
                .font(.system(size: side * 0.26, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(textColor)
                .frame(width: side * 0.58)
        }
        .frame(width: side, height: side)
    }
}

#Preview("Full") {
    ZStack {
        CalendarTheme.classic.background
        RingADateFace(theme: .classic, date: .now, layout: .full)
            .padding(24)
    }
    .frame(width: 360, height: 360)
}

#Preview("Split") {
    ZStack {
        CalendarTheme.classic.background
        RingADateFace(theme: .classic, date: .now, layout: .split)
            .padding(16)
    }
    .frame(width: 340, height: 158)
}

#Preview("Compact") {
    ZStack {
        CalendarTheme.classic.background
        RingADateFace(theme: .classic, date: .now, layout: .compact)
            .padding(12)
    }
    .frame(width: 158, height: 158)
}
