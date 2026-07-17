import Foundation
import Observation

struct RGB: Codable, Equatable, Hashable {
    var r: Int
    var g: Int
    var b: Int
}

@MainActor
@Observable
final class Bulb: Identifiable {
    let index: Int
    var name: String
    var ip: String {
        didSet { UserDefaults.standard.set(ip, forKey: "bulbIP\(index)") }
    }
    var isOn = true
    var online = true
    var dimming: Double = 75
    var temp: Double = 3200
    var rgb = RGB(r: 255, g: 180, b: 100)
    /// true = white/temperature mode is active, false = color mode
    var whiteMode = true

    nonisolated var id: Int { index }

    init(index: Int, name: String, defaultIP: String) {
        self.index = index
        self.name = name
        self.ip = UserDefaults.standard.string(forKey: "bulbIP\(index)") ?? defaultIP
    }

    var snapshot: BulbSnapshot {
        BulbSnapshot(isOn: isOn, dimming: Int(dimming), whiteMode: whiteMode, temp: Int(temp), rgb: rgb)
    }

    func apply(_ snap: BulbSnapshot) {
        isOn = snap.isOn
        dimming = Double(snap.dimming)
        whiteMode = snap.whiteMode
        temp = Double(snap.temp)
        rgb = snap.rgb
    }
}

struct BulbSnapshot: Codable, Equatable {
    var isOn: Bool
    var dimming: Int
    var whiteMode: Bool
    var temp: Int
    var rgb: RGB
}

struct Preset: Codable, Equatable {
    var name: String
    var snapshots: [BulbSnapshot]
}

enum Target: Hashable {
    case both
    case single(Int)
}
