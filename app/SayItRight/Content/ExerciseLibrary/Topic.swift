import Foundation

/// A discussion topic for Build-mode sessions.
struct Topic: Codable, Sendable, Identifiable {
    let id: String
    let titleEN: String
    let titleDE: String
    let promptEN: String
    let promptDE: String
    let domain: TopicDomain
    let level: Int
    let barbaraFavorite: Bool

    func title(for language: String) -> String {
        language == "de" ? titleDE : titleEN
    }

    func prompt(for language: String) -> String {
        language == "de" ? promptDE : promptEN
    }
}

enum TopicDomain: String, Codable, Sendable, CaseIterable {
    case everyday
    case school
    case society
    case technology
}

/// Loads and filters the bundled topic bank.
struct TopicBank: Sendable {
    let topics: [Topic]

    init(topics: [Topic] = []) {
        self.topics = topics
    }

    static func loadFromBundle() -> TopicBank {
        guard let url = Bundle.main.url(forResource: "TopicBank", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let topics = try? JSONDecoder().decode([Topic].self, from: data)
        else {
            return TopicBank()
        }
        return TopicBank(topics: topics)
    }

    func topics(for level: Int, domain: TopicDomain? = nil) -> [Topic] {
        topics.filter { topic in
            topic.level <= level && (domain == nil || topic.domain == domain)
        }
    }

    func randomTopic(for level: Int, domain: TopicDomain? = nil, excluding seen: Set<String> = []) -> Topic? {
        let candidates = topics(for: level, domain: domain).filter { !seen.contains($0.id) }
        return candidates.randomElement()
    }
}
