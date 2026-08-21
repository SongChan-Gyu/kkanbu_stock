import Foundation

struct PersistenceStore {
    private let url: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(filename: String = "kkanbu-state.json") {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        url = folder.appendingPathComponent(filename)
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load() -> AppState? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        if let state = try? decoder.decode(AppState.self, from: data) { return state }
        guard var object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if object["comments"] == nil { object["comments"] = [] }
        if object["takes"] == nil { object["takes"] = [] }
        guard let patched = try? JSONSerialization.data(withJSONObject: object) else { return nil }
        return try? decoder.decode(AppState.self, from: patched)
    }

    func save(_ state: AppState) {
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    func reset() {
        try? FileManager.default.removeItem(at: url)
    }
}
