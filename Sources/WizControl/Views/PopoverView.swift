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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    swatchGrid
                    Text(currentHex)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
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

    private static let swatches: [RGB] = [
        RGB(r: 255, g: 0, b: 0), RGB(r: 255, g: 128, b: 0),
        RGB(r: 255, g: 255, b: 0), RGB(r: 0, g: 255, b: 0),
        RGB(r: 0, g: 255, b: 255), RGB(r: 0, g: 0, b: 255),
        RGB(r: 128, g: 0, b: 255), RGB(r: 255, g: 0, b: 255),
    ]

    private var swatchGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(24), spacing: 8), count: 4),
                  alignment: .leading, spacing: 8) {
            ForEach(Self.swatches, id: \.self) { swatch in
                let selected = !app.displayBulb.whiteMode && app.displayBulb.rgb == swatch
                Button {
                    app.setColor(swatch)
                } label: {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(
                            red: Double(swatch.r) / 255,
                            green: Double(swatch.g) / 255,
                            blue: Double(swatch.b) / 255
                        ))
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(
                                    selected ? Color.primary : Color.primary.opacity(0.15),
                                    lineWidth: selected ? 2 : 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var currentHex: String {
        let rgb = app.displayBulb.rgb
        if app.displayBulb.whiteMode {
            return "white \(Int(app.displayBulb.temp)) K"
        }
        return String(format: "#%02X%02X%02X", rgb.r, rgb.g, rgb.b)
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
