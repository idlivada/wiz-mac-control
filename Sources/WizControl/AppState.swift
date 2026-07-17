import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class AppState {
    var bulbs: [Bulb]
    var target: Target = .both
    var presets: [Preset?]

    var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                launchAtLogin = SMAppService.mainApp.status == .enabled
            }
        }
    }

    @ObservationIgnored private var staged: [Int: [String: Any]] = [:]
    @ObservationIgnored private var flushTasks: [Int: Task<Void, Never>] = [:]

    init() {
        bulbs = [
            Bulb(index: 0, name: "Bulb 1", defaultIP: "192.168.0.29"),
            Bulb(index: 1, name: "Bulb 2", defaultIP: "192.168.0.28"),
        ]
        presets = PresetStore.load()
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: - Targeting

    var targetBulbs: [Bulb] {
        switch target {
        case .both: return bulbs
        case .single(let i): return [bulbs[i]]
        }
    }

    /// True when any bulb in the current target is on (mixed state counts as on).
    var anyTargetOn: Bool {
        targetBulbs.contains(where: \.isOn)
    }

    /// The bulb whose values the controls display (bulb 1 stands in for "Both").
    var displayBulb: Bulb {
        switch target {
        case .both: return bulbs[0]
        case .single(let i): return bulbs[i]
        }
    }

    // MARK: - Control actions

    func setPower(_ on: Bool) {
        for bulb in targetBulbs {
            bulb.isOn = on
            sendNow(["state": on], to: bulb)
        }
    }

    func setDimming(_ value: Double) {
        for bulb in targetBulbs {
            bulb.dimming = value
            bulb.isOn = true
            stage(["dimming": Int(value), "state": true], for: bulb)
        }
    }

    func setTemp(_ value: Double) {
        for bulb in targetBulbs {
            bulb.temp = value
            bulb.whiteMode = true
            bulb.isOn = true
            stage(["temp": Int(value), "state": true], for: bulb)
        }
    }

    func setColor(_ rgb: RGB) {
        for bulb in targetBulbs {
            bulb.rgb = rgb
            bulb.whiteMode = false
            bulb.isOn = true
            stage(["r": rgb.r, "g": rgb.g, "b": rgb.b, "state": true], for: bulb)
        }
    }

    // MARK: - Sending (throttled to one packet per 100 ms per bulb)

    private func stage(_ params: [String: Any], for bulb: Bulb) {
        var merged = staged[bulb.index] ?? [:]
        if params["temp"] != nil {
            for key in ["r", "g", "b"] { merged.removeValue(forKey: key) }
        }
        if params["r"] != nil {
            merged.removeValue(forKey: "temp")
        }
        for (key, value) in params { merged[key] = value }
        staged[bulb.index] = merged

        guard flushTasks[bulb.index] == nil else { return }
        flushTasks[bulb.index] = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(100))
            self?.flush(bulb)
        }
    }

    private func flush(_ bulb: Bulb) {
        flushTasks[bulb.index] = nil
        guard let params = staged.removeValue(forKey: bulb.index), !params.isEmpty else { return }
        if let payload = WizClient.setPilotPayload(params) {
            WizClient.send(payload, to: bulb.ip)
        }
    }

    private func sendNow(_ params: [String: Any], to bulb: Bulb) {
        if let payload = WizClient.setPilotPayload(params) {
            WizClient.send(payload, to: bulb.ip)
        }
    }

    // MARK: - State sync (getPilot)

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for bulb in bulbs {
                group.addTask { @MainActor in await self.refresh(bulb) }
            }
        }
    }

    func refresh(_ bulb: Bulb) async {
        let reply = await WizClient.query(WizClient.getPilotPayload(), to: bulb.ip)
        guard let reply,
              let response = try? JSONDecoder().decode(PilotResponse.self, from: reply),
              let result = response.result
        else {
            bulb.online = false
            return
        }
        bulb.online = true
        if let state = result.state { bulb.isOn = state }
        if let dimming = result.dimming { bulb.dimming = Double(dimming) }
        if let temp = result.temp {
            bulb.temp = Double(temp)
            bulb.whiteMode = true
        } else if let r = result.r, let g = result.g, let b = result.b {
            bulb.rgb = RGB(r: r, g: g, b: b)
            bulb.whiteMode = false
        }
    }

    // MARK: - Presets

    func savePreset(slot: Int, name: String) {
        presets[slot] = Preset(name: name, snapshots: bulbs.map(\.snapshot))
        PresetStore.save(presets)
    }

    func renamePreset(slot: Int, name: String) {
        guard var preset = presets[slot] else { return }
        preset.name = name
        presets[slot] = preset
        PresetStore.save(presets)
    }

    func clearPreset(slot: Int) {
        presets[slot] = nil
        PresetStore.save(presets)
    }

    func loadPreset(slot: Int) {
        guard let preset = presets[slot] else { return }
        for (bulb, snap) in zip(bulbs, preset.snapshots) {
            bulb.apply(snap)
            if snap.isOn {
                var params: [String: Any] = ["state": true, "dimming": snap.dimming]
                if snap.whiteMode {
                    params["temp"] = snap.temp
                } else {
                    params["r"] = snap.rgb.r
                    params["g"] = snap.rgb.g
                    params["b"] = snap.rgb.b
                }
                sendNow(params, to: bulb)
            } else {
                sendNow(["state": false], to: bulb)
            }
        }
    }
}
