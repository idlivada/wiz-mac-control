import SwiftUI
import AppKit

struct PopoverView: View {
    @Environment(AppState.self) private var app
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            PresetRowView()
            footer
            Divider()
            targetSelector
            powerRow
            offlineNotice

            if app.anyTargetOn {
                VStack(alignment: .leading, spacing: 12) {
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
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .frame(width: 320)
        .animation(.easeInOut(duration: 0.18), value: app.anyTargetOn)
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
        }
    }

    private var targetSelector: some View {
        HStack(spacing: 2) {
            segment(title: "Both", target: .both, dotBulbs: app.bulbs)
            segment(title: app.bulbs[0].name, target: .single(0), dotBulbs: [app.bulbs[0]])
            segment(title: app.bulbs[1].name, target: .single(1), dotBulbs: [app.bulbs[1]])
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.06)))
    }

    private func segment(title: String, target: Target, dotBulbs: [Bulb]) -> some View {
        let selected = app.target == target
        return Button {
            app.target = target
        } label: {
            HStack(spacing: 5) {
                HStack(spacing: 3) {
                    ForEach(dotBulbs) { bulb in
                        Circle()
                            .fill(bulb.isOn ? bulb.lightColor : Color.gray.opacity(0.45))
                            .overlay(Circle().strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.5))
                            .frame(width: 7, height: 7)
                    }
                }
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(selected ? Color(nsColor: .controlBackgroundColor) : .clear)
                    .shadow(color: .black.opacity(selected ? 0.2 : 0), radius: 1, y: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var powerRow: some View {
        HStack {
            Text(powerLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Toggle("Power", isOn: Binding(
                get: { app.anyTargetOn },
                set: { app.setPower($0) }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .labelsHidden()
        }
    }

    private var powerLabel: String {
        switch app.target {
        case .both:
            let onCount = app.bulbs.filter(\.isOn).count
            if onCount == 0 { return "Both bulbs · Off" }
            if onCount == app.bulbs.count { return "Both bulbs · On" }
            return "Both bulbs · \(onCount) of \(app.bulbs.count) on"
        case .single(let i):
            return "\(app.bulbs[i].name) · \(app.bulbs[i].isOn ? "On" : "Off")"
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

extension Bulb {
    /// The color this bulb is currently emitting, for status dots.
    var lightColor: Color {
        whiteMode
            ? ColorMath.kelvinToColor(temp)
            : Color(red: Double(rgb.r) / 255, green: Double(rgb.g) / 255, blue: Double(rgb.b) / 255)
    }
}
