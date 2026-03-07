import Foundation

/// Quality level of a practice text, defining how well-structured it is.
enum QualityLevel: String, Codable, Sendable, CaseIterable {
    /// Clean pyramid structure, easy to extract governing thought and supports.
    case wellStructured = "well-structured"
    /// Conclusion exists but is buried in paragraph 2-3 instead of leading.
    case buriedLead = "buried-lead"
    /// No clear structure; the user must identify that structure is missing.
    case rambling
    /// Appears structured but contains a hidden logical flaw.
    case adversarial
}

/// A structural flaw embedded in an adversarial practice text.
struct StructuralFlaw: Codable, Sendable, Equatable {
    /// The type of flaw (e.g. "false_dichotomy", "circular_reasoning", "non_sequitur").
    let type: String
    /// Human-readable description of the flaw.
    let description: String
    /// Where in the text the flaw occurs (e.g. "paragraph 2", "support pillar 3").
    let location: String
    /// Progressive hint tiers for "Spot the gap" exercises.
    let hints: HintTiers?

    init(type: String, description: String, location: String, hints: HintTiers? = nil) {
        self.type = type
        self.description = description
        self.location = location
        self.hints = hints
    }
}

/// 3-tier progressive hints for structural flaw identification.
struct HintTiers: Codable, Sendable, Equatable {
    /// Tier 1: General area hint (e.g., "Look at the grouping").
    let tier1: String
    /// Tier 2: Specific element hint (e.g., "Compare support B and C").
    let tier2: String
    /// Tier 3: Full reveal with explanation.
    let tier3: String
}

/// Answer key for a practice text, describing its pyramid structure.
struct AnswerKey: Codable, Sendable, Equatable {
    /// The main conclusion / governing thought of the text.
    let governingThought: String
    /// Support groups with labels and evidence nodes.
    let supports: [SupportGroup]
    /// Structural assessment explaining the text's architecture.
    let structuralAssessment: String
    /// For adversarial texts: description of the hidden structural flaw.
    let structuralFlaw: StructuralFlaw?
    /// For rambling texts: a proposed restructure showing how the text could be improved.
    let proposedRestructure: String?

    init(
        governingThought: String,
        supports: [SupportGroup],
        structuralAssessment: String,
        structuralFlaw: StructuralFlaw? = nil,
        proposedRestructure: String? = nil
    ) {
        self.governingThought = governingThought
        self.supports = supports
        self.structuralAssessment = structuralAssessment
        self.structuralFlaw = structuralFlaw
        self.proposedRestructure = proposedRestructure
    }
}

/// A labeled support group with evidence nodes.
struct SupportGroup: Codable, Sendable, Equatable {
    /// Label for this support pillar (e.g. "Health impact", "Economic argument").
    let label: String
    /// Evidence nodes supporting this pillar.
    let evidence: [String]
}

/// Metadata about a generated practice text.
struct PracticeTextMetadata: Codable, Sendable, Equatable {
    let qualityLevel: QualityLevel
    let difficultyRating: Int
    let topicDomain: String
    let language: String
    let wordCount: Int
    let targetLevel: Int
}

/// A practice text with its answer key and metadata, used in Break mode exercises.
struct PracticeText: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let text: String
    let answerKey: AnswerKey
    let metadata: PracticeTextMetadata
}
