//
//  RingADateFace.swift
//  Ring a Date
//
//  The calendar face, drawn to match the original board: a row of weekdays,
//  four rows of dates on eight columns, and two rows of months, with wider
//  gaps between the three sections. Rings mark today's weekday, date and month.
//

import SwiftUI

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
    let date: Date
    var layout: RingADateLayout = .full

    static let dayLabels = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
    static let monthLabels = ["jan", "feb", "mar", "apr", "may", "june",
                              "july", "aug", "sep", "oct", "nov", "dec"]

    // Grid proportions, relative to one peg diameter.
    private let columnSpacing: CGFloat = 0.30
    private let rowSpacing: CGFloat = 0.30
    private let sectionGap: CGFloat = 0.95

    private var weekdayIndex: Int { Calendar.current.component(.weekday, from: date) - 1 }
    private var dayOfMonth: Int { Calendar.current.component(.day, from: date) }
    private var monthIndex: Int { Calendar.current.component(.month, from: date) - 1 }

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

        return VStack(alignment: .leading, spacing: spacing) {
            dayRow(cell: cell, width: boardWidth)
                .padding(.bottom, gap - spacing)
            dateGrid(cell: cell)
            monthRows(cell: cell)
                .padding(.top, gap - spacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The seven weekdays, spread across the full width of the board.
    private func dayRow(cell: CGFloat, width: CGFloat) -> some View {
        HStack(spacing: (width - 7 * cell) / 6) {
            ForEach(0..<7, id: \.self) { index in
                gridPeg(Self.dayLabels[index], cell: cell,
                        ring: index == weekdayIndex ? theme.dayRing : nil)
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
                            gridPeg("\(value)", cell: cell,
                                    ring: value == dayOfMonth ? theme.dateRing : nil)
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
                            gridPeg(Self.monthLabels[index], cell: cell,
                                    ring: index == monthIndex ? theme.monthRing : nil)
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

        return HStack(spacing: gap) {
            VStack(spacing: size.height * 0.06) {
                framedPeg(Self.dayLabels[weekdayIndex], side: pegSide, ring: theme.dayRing)
                framedPeg(Self.monthLabels[monthIndex], side: pegSide, ring: theme.monthRing)
            }
            dateGrid(cell: cell)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Compact face (small widget)

    private func compactFace(in size: CGSize) -> some View {
        let side = min(size.width, size.height)
        return VStack(spacing: side * 0.05) {
            framedPeg(Self.dayLabels[weekdayIndex], side: side * 0.26, ring: theme.dayRing)
            framedPeg("\(dayOfMonth)", side: side * 0.38, ring: theme.dateRing)
            framedPeg(Self.monthLabels[monthIndex], side: side * 0.26, ring: theme.monthRing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pegs

    /// A board peg. The ring overflows the cell like the physical one does.
    private func gridPeg(_ label: String, cell: CGFloat, ring: Color?) -> some View {
        ZStack {
            Circle()
                .fill(theme.peg)
            Text(label)
                .font(.system(size: cell * 0.42, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(theme.text)
                .padding(cell * 0.08)
            if let ring {
                Circle()
                    .strokeBorder(ring, lineWidth: cell * 0.18)
                    .frame(width: cell * 1.32, height: cell * 1.32)
            }
        }
        .frame(width: cell, height: cell)
    }

    /// A peg with its ring contained inside the frame, for the compact faces.
    private func framedPeg(_ label: String, side: CGFloat, ring: Color) -> some View {
        ZStack {
            Circle()
                .strokeBorder(ring, lineWidth: side * 0.10)
            Circle()
                .fill(theme.peg)
                .frame(width: side * 0.72, height: side * 0.72)
            Text(label)
                .font(.system(size: side * 0.26, weight: .semibold, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .foregroundStyle(theme.text)
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
