import Foundation

/// Thread-safe persistence layer for the learner profile.
actor LearnerProfileStore {
    private let fileURL: URL
    private var profile: LearnerProfile

    init(directory: URL? = nil) async {
        let dir = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = dir.appendingPathComponent("learner-profile.json")

        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder.iso8601.decode(LearnerProfile.self, from: data) {
            self.profile = loaded
        } else {
            self.profile = LearnerProfile.createDefault()
        }
    }

    var current: LearnerProfile { profile }

    func update(_ transform: (inout LearnerProfile) -> Void) async throws {
        transform(&profile)
        try await save()
    }

    func save() async throws {
        let data = try JSONEncoder.iso8601.encode(profile)
        let tempURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString + ".tmp")
        try data.write(to: tempURL, options: .atomic)
        _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
    }

    func reset() async throws {
        profile = LearnerProfile.createDefault()
        try await save()
    }
}

private extension JSONEncoder {
    static let iso8601: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
}

private extension JSONDecoder {
    static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
