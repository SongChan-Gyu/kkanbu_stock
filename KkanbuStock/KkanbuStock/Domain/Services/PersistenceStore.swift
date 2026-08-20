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
        return try? decoder.decode(AppState.self, from: data)
    }

    func save(_ state: AppState) {
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    func reset() {
        try? FileManager.default.removeItem(at: url)
    }
}
