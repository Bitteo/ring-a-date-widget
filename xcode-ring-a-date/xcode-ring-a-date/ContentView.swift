//
//  ContentView.swift
//  xcode-ring-a-date
//
//  The whole app: a live preview of the widget, the theme palettes and a
//  bottom drawer for color customization.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = ThemeStore()
    @State private var previewFamily: PreviewFamily = .medium
    @State private var presetEditor: PresetEditorMode?
    @State private var presetEditorDetent: PresentationDetent = .paletteEditor
    @State private var showSavePresetSheet = false
    @State private var markerDrawer: MarkerDrawerContext?
    @State private var dateCellFrames: [Int: CGRect] = [:]
    @State private var dragMarkerID: UUID?
    @State private var dragLocation: CGPoint?
    @State private var placementFeedback = 0
    @State private var markerCreationFeedback = 0
    @Environment(\.scenePhase) private var scenePhase

    private var isPlacementActive: Bool {
        store.placementMode || dragMarkerID != nil
    }

    private var canPlaceOnPreview: Bool {
        previewFamily != .small
    }

    var body: some View {
        VStack(spacing: 16) {
            previewSection
            MarkerTray(
                store: store,
                theme: store.theme,
                draggingMarkerID: dragMarkerID,
                onDragChanged: handleMarkerDragChanged,
                onDragEnded: handleMarkerDragEnded,
                onCreateMarker: createMarker
            )
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    presetSection
                    modeSection
                        .padding(.horizontal, 20)
                    footer
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 12)
        .background(Color(uiColor: .systemGroupedBackground))
        .overlay {
            if let dragMarkerID, let dragLocation,
               let marker = store.markerRings.first(where: { $0.id == dragMarkerID }) {
                MarkerDragGhost(marker: marker, theme: store.theme, location: dragLocation)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.refreshExternalState()
            }
        }
        .onChange(of: presetEditor) { _, mode in
            if mode == nil {
                presetEditorDetent = .paletteEditor
            }
        }
        .sheet(item: $presetEditor) { mode in
            PresetEditorSheet(store: store, mode: mode) {
                showSavePresetSheet = true
            }
            .presetEditorPresentation(mode: mode, detent: $presetEditorDetent)
        }
        .sheet(isPresented: $showSavePresetSheet) {
            SavePresetSheet(store: store, defaultName: ThemeStorage.nextPaletteName())
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
                .presentationCornerRadius(24)
        }
        .sheet(item: $markerDrawer) { context in
            MarkerDrawer(
                store: store,
                markerID: context.markerID,
                onDragChanged: { value in
                    dragMarkerID = context.markerID
                    dragLocation = value.location
                },
                onDragEnded: { value in
                    handleMarkerDragEnded(markerID: context.markerID, value: value)
                    markerDrawer = nil
                }
            )
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(24)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: placementFeedback)
        .sensoryFeedback(.impact(weight: .light), trigger: markerCreationFeedback)
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(spacing: 10) {
            Picker("Formato", selection: $previewFamily) {
                ForEach(PreviewFamily.allCases) { family in
                    Text(family.label).tag(family)
                }
            }
            .pickerStyle(.segmented)

            PlacementModeBanner(
                isVisible: isPlacementActive,
                compactPreview: !canPlaceOnPreview,
                onCancel: cancelPlacement
            )

            RingADatePreviewCard(
                theme: store.theme,
                positions: store.previewPositions,
                markerRings: store.markerRings,
                family: previewFamily,
                isPlacementMode: isPlacementActive && canPlaceOnPreview,
                placementHighlight: isPlacementActive && canPlaceOnPreview,
                onDatePlace: canPlaceOnPreview ? placeActiveMarker(on:) : nil,
                onDateLongPress: openMarkerDrawer(for:),
                onDateFramesChange: { dateCellFrames = $0 },
                onPegTap: isPlacementActive ? nil : (
                    store.mode == .manual
                        ? { ring, value in store.moveRing(ring, to: value) }
                        : nil
                )
            )
            .overlay {
                if isPlacementActive && canPlaceOnPreview {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .foregroundStyle(Color.accentColor.opacity(0.55))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .animation(.easeInOut(duration: 0.2), value: store.theme)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: previewFamily)
            .animation(.spring(response: 0.5, dampingFraction: 0.72), value: store.previewPositions)
            .animation(.easeInOut(duration: 0.2), value: store.markerRings)
            .sensoryFeedback(.impact(weight: .light), trigger: store.previewPositions)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Marker placement

    private func createMarker() {
        guard store.createMarker() != nil else { return }
        markerCreationFeedback += 1
    }

    private func cancelPlacement() {
        dragMarkerID = nil
        dragLocation = nil
        store.deactivatePlacement()
    }

    private func placeActiveMarker(on day: Int) {
        guard let markerID = store.activeMarkerID ?? dragMarkerID else { return }
        store.placeMarker(id: markerID, on: day)
        dragMarkerID = nil
        dragLocation = nil
        placementFeedback += 1
    }

    private func handleMarkerDragChanged(markerID: UUID, value: DragGesture.Value) {
        dragMarkerID = markerID
        dragLocation = value.location
        if store.activeMarkerID != markerID {
            store.activateMarker(id: markerID)
        }
    }

    private func handleMarkerDragEnded(markerID: UUID, value: DragGesture.Value) {
        defer {
            dragMarkerID = nil
            dragLocation = nil
        }
        guard canPlaceOnPreview,
              let day = MarkerPlacement.day(at: value.location, in: dateCellFrames) else {
            return
        }
        store.placeMarker(id: markerID, on: day)
        placementFeedback += 1
    }

    private func openMarkerDrawer(for day: Int) {
        guard let marker = store.markerRings.first(where: { $0.day == day }) else { return }
        markerDrawer = MarkerDrawerContext(markerID: marker.id)
    }

    // MARK: - Palettes

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("Palette")
                Spacer()
                Button {
                    openPresetEditor(.new)
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Nuova palette")
            }
            .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.customPresets) { preset in
                        PresetSwatch(preset: preset,
                                     isSelected: store.selectedPresetID == preset.id) {
                            store.theme = preset.theme
                            openPresetEditor(.edit(preset))
                        }
                        .frame(width: 96)
                        .contextMenu {
                            Button("Elimina", systemImage: "trash", role: .destructive) {
                                store.deletePreset(preset)
                            }
                        }
                    }
                    ForEach(CalendarTheme.presets) { preset in
                        PresetSwatch(preset: preset,
                                     isSelected: store.selectedPresetID == preset.id) {
                            store.theme = preset.theme
                            openPresetEditor(.edit(preset))
                        }
                        .frame(width: 96)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Ring mode

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Gli anelli")
            RingModePicker(mode: $store.mode, theme: store.theme)
        }
        .sensoryFeedback(.selection, trigger: store.mode)
    }

    // MARK: - Footer

    private var footer: some View {
        Text("Aggiungi il widget dalla schermata Home: tieni premuto sullo sfondo, tocca Modifica, poi Aggiungi widget e cerca Ring a Date. I colori scelti qui si applicano subito, la data si aggiorna da sola a mezzanotte.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    private func openPresetEditor(_ mode: PresetEditorMode) {
        presetEditorDetent = .paletteEditor
        presetEditor = mode
    }
}

struct RingModePicker: View {
    @Binding var mode: CalendarMode
    let theme: CalendarTheme

    @Namespace private var ringNamespace

    private let pegSize: CGFloat = 56
    private let modes: [CalendarMode] = [.manual, .automatic]

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                HStack(spacing: 36) {
                    ForEach(modes, id: \.self) { option in
                        modePeg(option)
                    }
                }

                Circle()
                    .strokeBorder(ringColor(for: mode), lineWidth: pegSize * 0.18)
                    .frame(width: pegSize * 1.32, height: pegSize * 1.32)
                    .matchedGeometryEffect(
                        id: "mode-ring-\(mode.rawValue)",
                        in: ringNamespace,
                        properties: .position,
                        isSource: false
                    )
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 4)

            VStack(spacing: 6) {
                Text(mode.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())

                Text(mode.displayDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.5, dampingFraction: 0.72), value: mode)
        }
        .padding(18)
        .background {
            ZStack {
                theme.background.opacity(0.22)
                Color(uiColor: .secondarySystemGroupedBackground)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(theme.monthRing.opacity(0.25), lineWidth: 1)
        }
    }

    private func modePeg(_ option: CalendarMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                mode = option
            }
        } label: {
            ZStack {
                Circle()
                    .fill(theme.peg)
                    .frame(width: pegSize, height: pegSize)
                    .matchedGeometryEffect(id: "mode-ring-\(option.rawValue)", in: ringNamespace)

                Image(systemName: option.displayIcon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.text)
                    .symbolEffect(.bounce, value: mode == option)
            }
        }
        .buttonStyle(.plain)
    }

    private func ringColor(for option: CalendarMode) -> Color {
        switch option {
        case .manual: theme.dayRing
        case .automatic: theme.dateRing
        }
    }
}

// MARK: - Preview card

enum PreviewFamily: String, CaseIterable, Identifiable {
    case small, medium, large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small: "Piccolo"
        case .medium: "Medio"
        case .large: "Grande"
        }
    }

    var layout: RingADateLayout {
        switch self {
        case .small: .compact
        case .medium: .split
        case .large: .full
        }
    }
}

/// Mimics the widget's shape and margins on the Home Screen.
struct RingADatePreviewCard: View {
    let theme: CalendarTheme
    let positions: RingPositions
    let markerRings: [MarkerRing]
    let family: PreviewFamily
    var isPlacementMode: Bool = false
    var placementHighlight: Bool = false
    var onDatePlace: ((Int) -> Void)? = nil
    var onDateLongPress: ((Int) -> Void)? = nil
    var onDateFramesChange: (([Int: CGRect]) -> Void)? = nil
    var onPegTap: ((String, Int) -> Void)? = nil

    init(theme: CalendarTheme,
         positions: RingPositions,
         markerRings: [MarkerRing] = [],
         family: PreviewFamily,
         isPlacementMode: Bool = false,
         placementHighlight: Bool = false,
         onDatePlace: ((Int) -> Void)? = nil,
         onDateLongPress: ((Int) -> Void)? = nil,
         onDateFramesChange: (([Int: CGRect]) -> Void)? = nil,
         onPegTap: ((String, Int) -> Void)? = nil) {
        self.theme = theme
        self.positions = positions
        self.markerRings = markerRings
        self.family = family
        self.isPlacementMode = isPlacementMode
        self.placementHighlight = placementHighlight
        self.onDatePlace = onDatePlace
        self.onDateLongPress = onDateLongPress
        self.onDateFramesChange = onDateFramesChange
        self.onPegTap = onPegTap
    }

    var body: some View {
        ZStack {
            // The card keeps its identity across family changes, so its
            // frame morphs smoothly, while the face crossfades between the
            // per-family arrangements.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.background)
            RingADateFace(
                theme: theme,
                positions: positions,
                markerRings: markerRings,
                layout: family.layout,
                onPegTap: onPegTap,
                isPlacementMode: isPlacementMode,
                placementHighlight: placementHighlight,
                onDatePlace: onDatePlace,
                onDateLongPress: onDateLongPress,
                onDateFramesChange: onDateFramesChange
            )
                .padding(padding)
                .id(family)
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(maxWidth: maxWidth)
        .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }

    // Proportions of the real widget frames on the Home Screen.
    private var aspectRatio: CGFloat {
        switch family {
        case .small: 1
        case .medium: 340.0 / 158.0
        case .large: 340.0 / 356.0
        }
    }

    private var maxWidth: CGFloat {
        switch family {
        case .small: 170
        case .medium, .large: 340
        }
    }

    private var padding: CGFloat {
        switch family {
        case .small: 12
        case .medium: 14
        case .large: 18
        }
    }
}

/// One palette tile: the board color with its three ring colors on top.
struct PresetSwatch: View {
    let preset: ThemePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(preset.theme.background)
                    HStack(spacing: 6) {
                        ringDot(preset.theme.dayRing)
                        ringDot(preset.theme.dateRing)
                        ringDot(preset.theme.monthRing)
                    }
                }
                .frame(height: 56)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                                      lineWidth: isSelected ? 2.5 : 1)
                }

                Text(preset.name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func ringDot(_ color: Color) -> some View {
        Circle()
            .strokeBorder(color, lineWidth: 3.5)
            .background(Circle().fill(preset.theme.peg))
            .frame(width: 16, height: 16)
    }
}

// MARK: - Palette editor drawer

enum PresetEditorMode: Identifiable, Equatable {
    case new
    case edit(ThemePreset)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let preset): preset.id.uuidString
        }
    }
}

/// Bottom sheet to customize colors for an existing palette, or step 1 of
/// creating a new one (name and save happen in a second sheet).
struct PresetEditorSheet: View {
    @ObservedObject var store: ThemeStore
    let mode: PresetEditorMode
    var onConfirmNew: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    private var title: String {
        switch mode {
        case .new: "Nuova palette"
        case .edit(let preset): preset.name
        }
    }

    private var showsFooterActions: Bool {
        if case .new = mode { return true }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity)

                ThemeColorGroup(title: "Calendario", store: store, rows: [
                    ("Sfondo", \.backgroundHex),
                    ("Pastiglie", \.pegHex),
                    ("Testo", \.textHex),
                ])

                ThemeColorGroup(title: "Anelli", store: store, rows: [
                    ("Giorno", \.dayRingHex),
                    ("Data", \.dateRingHex),
                    ("Mese", \.monthRingHex),
                ])

                ThemeFontGroup(store: store)
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsFooterActions {
                footerActions
            }
        }
        .background(.clear)
    }

    @ViewBuilder
    private var footerActions: some View {
        Button {
            dismiss()
            DispatchQueue.main.async {
                onConfirmNew?()
            }
        } label: {
            Text("Conferma")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 12))
        .controlSize(.large)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

struct ThemeFontGroup: View {
    @ObservedObject var store: ThemeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Carattere")
                .font(.headline)
                .foregroundStyle(.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CalendarFontStyle.allCases) { style in
                        ThemeFontChip(style: style,
                                      theme: store.theme,
                                      isSelected: store.theme.fontStyle == style) {
                            store.theme.fontStyle = style
                        }
                    }
                }
            }
        }
    }
}

struct ThemeFontChip: View {
    let style: CalendarFontStyle
    let theme: CalendarTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(style.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                HStack(spacing: 8) {
                    fontSample("12", width: 34)
                    fontSample("july", width: 46)
                }
            }
            .padding(12)
            .frame(width: 118, height: 84, alignment: .topLeading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func fontSample(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(style.pegFont(size: 13))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .foregroundStyle(theme.text)
            .frame(width: width, height: 28)
            .background(theme.peg, in: Capsule())
    }
}

struct ThemeColorGroup: View {
    let title: String
    @ObservedObject var store: ThemeStore
    let rows: [(label: String, keyPath: WritableKeyPath<CalendarTheme, String>)]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(rows, id: \.label) { row in
                    ThemeColorCard(label: row.label,
                                   color: store.binding(for: row.keyPath))
                }
            }
        }
    }
}

struct ThemeColorCard: View {
    let label: String
    @Binding var color: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }

            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(labelForeground)
                .padding(12)
                .allowsHitTesting(false)

            colorWheelDecoration
        }
        .frame(height: 84)
        .background {
            ColorPicker("", selection: $color, supportsOpacity: false)
                .labelsHidden()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.02)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var colorWheelDecoration: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                        center: .center
                    ),
                    lineWidth: 2.5
                )
            Circle()
                .fill(color)
                .padding(5)
        }
        .frame(width: 30, height: 30)
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .allowsHitTesting(false)
    }

    private var labelForeground: Color {
        color.isPerceivedLight ? .black.opacity(0.82) : .white.opacity(0.95)
    }
}

private extension Color {
    var isPerceivedLight: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (0.299 * red + 0.587 * green + 0.114 * blue) > 0.6
    }
}

// MARK: - Save palette drawer

/// Step 2 when creating a palette: preview, name field and save button.
struct SavePresetSheet: View {
    @ObservedObject var store: ThemeStore
    let defaultName: String

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @FocusState private var nameFieldFocused: Bool

    init(store: ThemeStore, defaultName: String) {
        self.store = store
        self.defaultName = defaultName
        _name = State(initialValue: defaultName)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Nuova palette")
                .font(.headline)
                .padding(.top, 8)

            RingADatePreviewCard(theme: store.theme, positions: store.previewPositions,
                                 markerRings: store.markerRings,
                                 family: .medium)
                .frame(maxWidth: .infinity)

            TextField(defaultName, text: $name)
                .focused($nameFieldFocused)
                .submitLabel(.done)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: nameFieldFocused) { _, focused in
                    if focused && name == defaultName {
                        name = ""
                    }
                }
        }
        .padding(20)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                store.saveCurrentAsPreset(named: name)
                dismiss()
            } label: {
                Text("Salva")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 12))
            .controlSize(.large)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
        }
        .background(.clear)
    }
}

private extension PresentationDetent {
    /// Ends the palette drawer just above the "Palette" section title.
    static let paletteEditor = PresentationDetent.fraction(0.68)
}

private extension View {
    @ViewBuilder
    func presetEditorPresentation(mode: PresetEditorMode,
                                  detent: Binding<PresentationDetent>) -> some View {
        switch mode {
        case .new:
            self
                .presentationDetents([.paletteEditor])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
                .presentationBackgroundInteraction(.enabled(upThrough: .paletteEditor))
                .presentationCornerRadius(24)
        case .edit:
            self
                .presentationDetents([.paletteEditor, .large], selection: detent)
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
                .presentationBackgroundInteraction(.enabled(upThrough: .paletteEditor))
                .presentationCornerRadius(24)
        }
    }
}

#Preview {
    ContentView()
}
