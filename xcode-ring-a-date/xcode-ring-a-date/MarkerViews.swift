//
//  MarkerViews.swift
//  xcode-ring-a-date
//
//  Tray, draggable rings and marker drawer.
//

import SwiftUI

// MARK: - Tray

struct MarkerTray: View {
    @ObservedObject var store: ThemeStore
    let theme: CalendarTheme
    let draggingMarkerID: UUID?
    let onDragChanged: (UUID, DragGesture.Value) -> Void
    let onDragEnded: (UUID, DragGesture.Value) -> Void
    let onCreateMarker: () -> Void

    var body: some View {
        // At most two markers plus the add chip, so the row always fits:
        // center it instead of scrolling.
        HStack(alignment: .center, spacing: 14) {
            ForEach(store.markerRings) { marker in
                DraggableMarkerRing(
                    marker: marker,
                    theme: theme,
                    style: .tray,
                    isActive: store.activeMarkerID == marker.id,
                    isDragging: draggingMarkerID == marker.id,
                    onTap: { store.activateMarker(id: marker.id) },
                    onDragChanged: { onDragChanged(marker.id, $0) },
                    onDragEnded: { onDragEnded(marker.id, $0) }
                )
                .contextMenu {
                    Button("Elimina", systemImage: "trash", role: .destructive) {
                        store.deleteMarker(marker)
                    }
                }
            }

            if store.markerRings.count < ThemeStorage.maxMarkerRings {
                AddMarkerChip(action: onCreateMarker)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }
}

// MARK: - Draggable ring

struct DraggableMarkerRing: View {
    enum Style {
        case tray
        case drawer

        var pegSize: CGFloat {
            switch self {
            case .tray: 56
            case .drawer: 72
            }
        }

        var ringSize: CGFloat {
            switch self {
            case .tray: 68
            case .drawer: 92
            }
        }

        var ringWidth: CGFloat {
            switch self {
            case .tray: 4
            case .drawer: 5
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .tray: 20
            case .drawer: 28
            }
        }

        /// Diameter reserved for the active-marker accent ring, so selecting a marker never resizes its container.
        var selectionSize: CGFloat { ringSize + 8 }
    }

    let marker: MarkerRing
    let theme: CalendarTheme
    let style: Style
    let isActive: Bool
    var isDragging: Bool = false
    let onTap: () -> Void
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(theme.peg)
                    .frame(width: style.pegSize, height: style.pegSize)

                if let day = marker.day {
                    Text("\(day)")
                        .font(theme.fontStyle.pegFont(size: style.fontSize))
                        .foregroundStyle(theme.text)
                }

                Circle()
                    .strokeBorder(Color(hex: marker.colorHex), lineWidth: style.ringWidth)
                    .frame(width: style.ringSize, height: style.ringSize)

                if isActive {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .frame(width: style.selectionSize, height: style.selectionSize)
                }
            }
            .frame(width: style.selectionSize, height: style.selectionSize)
            .scaleEffect(isActive ? 1.05 : 1)
            .opacity(isDragging ? 0.35 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.72), value: isActive)

            if style == .tray {
                Text(marker.day.map { "Giorno \($0)" } ?? "Da posizionare")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 88)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .gesture(
            DragGesture(minimumDistance: 8, coordinateSpace: .global)
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
        .accessibilityLabel(marker.day.map { "Marcatore giorno \($0)" } ?? "Marcatore da posizionare")
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Add chip

/// A chip the size of a tray marker that creates a new marker when tapped.
/// Drawn as an empty dotted ring with a plus, so it reads as the slot for
/// the next marker sitting to the right of the existing ones. It mirrors
/// the marker chip's ring + caption layout so the two line up in the row.
struct AddMarkerChip: View {
    let action: () -> Void

    private let style = DraggableMarkerRing.Style.tray

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .strokeBorder(
                        Color.secondary.opacity(0.5),
                        style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                    )
                    .frame(width: style.ringSize, height: style.ringSize)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: style.selectionSize, height: style.selectionSize)

                Text("Aggiungi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 88)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Nuovo marcatore")
    }
}

// MARK: - Drawer

struct MarkerDrawerContext: Identifiable {
    let markerID: UUID
    var id: UUID { markerID }
}

struct MarkerDrawer: View {
    @ObservedObject var store: ThemeStore
    let markerID: UUID
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var color: Color
    @State private var isDragging = false

    private var marker: MarkerRing? {
        store.markerRings.first { $0.id == markerID }
    }

    init(store: ThemeStore,
         markerID: UUID,
         onDragChanged: @escaping (DragGesture.Value) -> Void,
         onDragEnded: @escaping (DragGesture.Value) -> Void) {
        self.store = store
        self.markerID = markerID
        self.onDragChanged = onDragChanged
        self.onDragEnded = onDragEnded
        let hex = store.markerRings.first { $0.id == markerID }?.colorHex ?? MarkerRing.defaultColorHex
        _color = State(initialValue: Color(hex: hex))
    }

    var body: some View {
        VStack(spacing: 20) {
            if let marker {
                DraggableMarkerRing(
                    marker: marker,
                    theme: store.theme,
                    style: .drawer,
                    isActive: true,
                    isDragging: isDragging,
                    onTap: {},
                    onDragChanged: {
                        isDragging = true
                        onDragChanged($0)
                    },
                    onDragEnded: {
                        isDragging = false
                        onDragEnded($0)
                    }
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                ColorPicker("Colore anello", selection: $color, supportsOpacity: false)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onChange(of: color) { _, newColor in
                        store.updateMarkerColor(id: markerID, colorHex: newColor.hexString)
                    }

                Button("Rimuovi", systemImage: "trash", role: .destructive) {
                    store.deleteMarker(marker)
                    dismiss()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }
}

// MARK: - Drag ghost

struct MarkerDragGhost: View {
    let marker: MarkerRing
    let theme: CalendarTheme
    let location: CGPoint

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.peg)
                .frame(width: 52, height: 52)
            if let day = marker.day {
                Text("\(day)")
                    .font(theme.fontStyle.pegFont(size: 18))
                    .foregroundStyle(theme.text)
            }
            Circle()
                .strokeBorder(Color(hex: marker.colorHex), lineWidth: 4)
                .frame(width: 64, height: 64)
        }
        .position(location)
        .allowsHitTesting(false)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

// MARK: - Helpers

enum MarkerPlacement {
    static func day(at location: CGPoint, in frames: [Int: CGRect]) -> Int? {
        frames.first { $0.value.contains(location) }?.key
    }
}
