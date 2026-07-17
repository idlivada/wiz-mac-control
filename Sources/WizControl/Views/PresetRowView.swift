import SwiftUI

struct PresetRowView: View {
    @Environment(AppState.self) private var app

    @State private var renameSlot: Int?
    @State private var renameText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Presets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("right-click to save")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing: 6) {
                ForEach(0..<PresetStore.slotCount, id: \.self) { slot in
                    slotButton(slot)
                }
            }
        }
        .alert("Preset name", isPresented: Binding(
            get: { renameSlot != nil },
            set: { if !$0 { renameSlot = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let slot = renameSlot {
                    app.renamePreset(slot: slot, name: renameText)
                }
                renameSlot = nil
            }
            Button("Cancel", role: .cancel) { renameSlot = nil }
        }
    }

    @ViewBuilder
    private func slotButton(_ slot: Int) -> some View {
        if let preset = app.presets[slot] {
            Button {
                app.loadPreset(slot: slot)
            } label: {
                Text(preset.name)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .help("Load \"\(preset.name)\"")
            .contextMenu {
                Button("Save current settings here") {
                    app.savePreset(slot: slot, name: preset.name)
                }
                Button("Rename…") {
                    renameText = preset.name
                    renameSlot = slot
                }
                Button("Clear", role: .destructive) {
                    app.clearPreset(slot: slot)
                }
            }
        } else {
            Button {
                let name = "Preset \(slot + 1)"
                app.savePreset(slot: slot, name: name)
                renameText = name
                renameSlot = slot
            } label: {
                Image(systemName: "plus")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .help("Save current settings to this slot")
        }
    }
}
