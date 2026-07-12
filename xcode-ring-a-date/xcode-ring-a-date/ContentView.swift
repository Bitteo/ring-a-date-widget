//
//  ContentView.swift
//  xcode-ring-a-date
//
//  The whole app: a live preview of the widget, the theme presets and the
//  custom color editor.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = ThemeStore()
    @State private var previewFamily: PreviewFamily = .medium

    var body: some View {
        VStack(spacing: 16) {
            // The preview stays pinned above the scrolling controls, so every
            // color change gives immediate feedback — even while the color
            // picker sheet is open at the bottom of the screen.
            previewSection
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    presetSection
                    colorGroup(title: "Calendario", rows: [
                        ("Sfondo", \.backgroundHex),
                        ("Pastiglie", \.pegHex),
                        ("Testo", \.textHex),
                    ])
                    .padding(.horizontal, 20)
                    colorGroup(title: "Anelli", rows: [
                        ("Giorno", \.dayRingHex),
                        ("Data", \.dateRingHex),
                        ("Mese", \.monthRingHex),
                    ])
                    .padding(.horizontal, 20)
                    footer
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 12)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(spacing: 14) {
            Picker("Formato", selection: $previewFamily) {
                ForEach(PreviewFamily.allCases) { family in
                    Text(family.label).tag(family)
                }
            }
            .pickerStyle(.segmented)

            RingADatePreviewCard(theme: store.theme, family: previewFamily)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .animation(.easeInOut(duration: 0.2), value: store.theme)
                .animation(.easeInOut(duration: 0.25), value: previewFamily)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Presets

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Preset")
                .padding(.horizontal, 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CalendarTheme.presets) { preset in
                        PresetSwatch(preset: preset,
                                     isSelected: store.selectedPresetID == preset.id) {
                            store.theme = preset.theme
                        }
                        .frame(width: 96)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Custom colors

    private func colorGroup(title: String,
                            rows: [(label: String, keyPath: WritableKeyPath<CalendarTheme, String>)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title)
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    if index > 0 {
                        Divider().padding(.leading, 16)
                    }
                    colorRow(row.label, keyPath: row.keyPath)
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func colorRow(_ label: String,
                          keyPath: WritableKeyPath<CalendarTheme, String>) -> some View {
        ColorPicker(label, selection: store.binding(for: keyPath), supportsOpacity: false)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
    let family: PreviewFamily

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.background)
            RingADateFace(theme: theme, date: .now, layout: family.layout)
                .padding(padding)
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

/// One preset tile: the board color with its three ring colors on top.
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

#Preview {
    ContentView()
}
