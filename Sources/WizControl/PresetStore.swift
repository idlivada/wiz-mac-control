import Foundation

enum PresetStore {
    static let slotCount = 5
    private static let key = "presets"

    static func load() -> [Preset?] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let presets = try? JSONDecoder().decode([Preset?].self, from: data),
              presets.count == slotCount
        else {
            return Array(repeating: nil, count: slotCount)
        }
        return presets
    }

    static func save(_ presets: [Preset?]) {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
