import SwiftUI
import AppKit

struct PopoverView: View {
    @Environment(AppState.self) private var app
    @State private var showSettings = false

    var body: some View {
        @Bindable var app = app
        VStack(alignment: .leading, spacing: 12) {
            header

            Picker("Target", selection: $app.target) {
                Text("Both").tag(Target.both)
                Text(app.bulbs[0].name).tag(Target.single(0))
                Text(app.bulbs[1].name).tag(Target.single(1))
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            offlineNotice

            HStack(alignment: .center, spacing: 14) {
                ColorWheelView(
                    rgb: app.displayBulb.rgb,
                    isActive: !app.displayBulb.whiteMode
                ) { app.setColor($0) }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Color")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Drag to pick a color. Moving the temperature slider switches back to white.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            sliders

            Divider()
            PresetRowView()
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 320)
        .onAppear {
            Task { await app.refreshAll() }
        }
    }

    private var header: some View {
        HStack {
            Label("Wiz Control", systemImage: "lightbulb.fill")
                .font(.headline)
            Spacer()
            Button {
                Task { await app.refreshAll() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Re-read bulb state")
            Toggle("Power", isOn: Binding(
                get: { app.displayBulb.isOn },
                set: { app.setPower($0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
            .help("Turn \(app.target == .both ? "both bulbs" : app.displayBulb.name) on or off")
        }
    }

    @ViewBuilder
    private var offlineNotice: some View {
        let offline = app.bulbs.filter { !$0.online }
        if !offline.isEmpty {
            Label(
                "\(offline.map(\.name).joined(separator: ", ")) not responding",
                systemImage: "wifi.exclamationmark"
            )
            .font(.caption)
            .foregroundStyle(.orange)
        }
    }

    private var sliders: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Temperature")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(app.displayBulb.whiteMode ? "\(Int(app.displayBulb.temp)) K" : "—")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Slider(
                        value: Binding(
                            get: { app.displayBulb.temp },
                            set: { app.setTemp($0) }
                        ),
                        in: 2200...6500, step: 100
                    )
                    Image(systemName: "snowflake")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Brightness")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(app.displayBulb.dimming))%")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
                HStack(spacing: 8) {
                    Image(systemName: "sun.min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(
                        value: Binding(
                            get: { app.displayBulb.dimming },
                            set: { app.setDimming($0) }
                        ),
                        in: 10...100, step: 1
                    )
                    Image(systemName: "sun.max.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(!app.displayBulb.isOn && !app.displayBulb.online)
    }

    private var footer: some View {
        @Bindable var app = app
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("Launch at login", isOn: $app.launchAtLogin)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                Spacer()
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Bulb IP addresses")
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .font(.caption)
            }
            if showSettings {
                ForEach(app.bulbs) { bulb in
                    @Bindable var bulb = bulb
                    HStack {
                        Text("\(bulb.name) IP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .leading)
                        TextField("192.168.0.x", text: $bulb.ip)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                }
            }
        }
    }
}
