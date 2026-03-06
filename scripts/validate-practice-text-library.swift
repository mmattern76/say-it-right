#!/usr/bin/env swift

// validate-practice-text-library.swift
//
// CI-ready validation script for practice text library JSON files.
// Checks schema conformance, ID uniqueness, metadata completeness,
// and content version consistency.
//
// Usage:
//   swift scripts/validate-practice-text-library.swift [path-to-library-dir]
//
// Default path: app/SayItRight/Content/PracticeTexts/
//
// Exit codes:
//   0 — all checks passed
//   1 — validation errors found

import Foundation

// MARK: - Expected Schema Types

struct ValidatedContainer: Codable {
    let contentVersion: String
    let generatedDate: String
    let texts: [ValidatedText]
}

struct ValidatedText: Codable {
    let id: String
    let text: String
    let answerKey: ValidatedAnswerKey
    let metadata: ValidatedMetadata
}

struct ValidatedAnswerKey: Codable {
    let governingThought: String
    let supports: [ValidatedSupport]
    let structuralAssessment: String
    let structuralFlaw: ValidatedFlaw?
    let proposedRestructure: String?
}

struct ValidatedSupport: Codable {
    let label: String
    let evidence: [String]
}

struct ValidatedFlaw: Codable {
    let type: String
    let description: String
    let location: String
}

struct ValidatedMetadata: Codable {
    let qualityLevel: String
    let difficultyRating: Int
    let topicDomain: String
    let language: String
    let wordCount: Int
    let targetLevel: Int
}

// MARK: - Validation

struct ValidationResult {
    var errors: [String] = []
    var warnings: [String] = []
    var textCount: Int = 0
    var contentVersion: String = ""
    var passed: Bool { errors.isEmpty }
}

let validQualityLevels: Set<String> = ["well-structured", "buried-lead", "rambling", "adversarial"]
let validDomains: Set<String> = ["everyday", "school", "society", "technology"]

func validateFile(at path: String, language: String) -> ValidationResult {
    var result = ValidationResult()

    guard FileManager.default.fileExists(atPath: path) else {
        result.errors.append("File not found: \(path)")
        return result
    }

    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        result.errors.append("Could not read file: \(path)")
        return result
    }

    let container: ValidatedContainer
    do {
        container = try JSONDecoder().decode(ValidatedContainer.self, from: data)
    } catch {
        result.errors.append("Schema error in \(path): \(error.localizedDescription)")
        return result
    }

    result.contentVersion = container.contentVersion
    result.textCount = container.texts.count

    let versionParts = container.contentVersion.split(separator: ".")
    if versionParts.count != 3 || versionParts.contains(where: { Int($0) == nil }) {
        result.errors.append("Invalid contentVersion: '\(container.contentVersion)' (expected semver)")
    }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    if dateFormatter.date(from: container.generatedDate) == nil {
        result.errors.append("Invalid generatedDate: '\(container.generatedDate)' (expected yyyy-MM-dd)")
    }

    var seenIDs = Set<String>()
    for text in container.texts {
        if seenIDs.contains(text.id) {
            result.errors.append("Duplicate ID within file: '\(text.id)'")
        }
        seenIDs.insert(text.id)

        if text.id.isEmpty { result.errors.append("Text has empty ID") }
        if text.text.isEmpty { result.errors.append("Text '\(text.id)' has empty text content") }
        if text.answerKey.governingThought.isEmpty {
            result.errors.append("Text '\(text.id)' has empty governing thought")
        }
        if text.answerKey.supports.isEmpty {
            result.errors.append("Text '\(text.id)' has no support groups")
        }
        if !validQualityLevels.contains(text.metadata.qualityLevel) {
            result.errors.append("Text '\(text.id)' has invalid quality level: '\(text.metadata.qualityLevel)'")
        }
        if !validDomains.contains(text.metadata.topicDomain) {
            result.warnings.append("Text '\(text.id)' has non-standard domain: '\(text.metadata.topicDomain)'")
        }
        if text.metadata.language != language {
            result.errors.append("Text '\(text.id)' has language '\(text.metadata.language)' in '\(language)' file")
        }
        if text.metadata.difficultyRating < 1 || text.metadata.difficultyRating > 5 {
            result.errors.append("Text '\(text.id)' has invalid difficulty: \(text.metadata.difficultyRating)")
        }
        if text.metadata.targetLevel < 1 || text.metadata.targetLevel > 4 {
            result.errors.append("Text '\(text.id)' has invalid target level: \(text.metadata.targetLevel)")
        }
        if text.metadata.wordCount <= 0 {
            result.errors.append("Text '\(text.id)' has invalid word count: \(text.metadata.wordCount)")
        }
        if text.metadata.qualityLevel == "adversarial" && text.answerKey.structuralFlaw == nil {
            result.errors.append("Adversarial text '\(text.id)' missing structural flaw")
        }
        if text.metadata.qualityLevel == "rambling" && text.answerKey.proposedRestructure == nil {
            result.errors.append("Rambling text '\(text.id)' missing proposed restructure")
        }
    }

    return result
}

// MARK: - Main

let args = CommandLine.arguments
let baseDir = args.count > 1 ? args[1] : "app/SayItRight/Content/PracticeTexts"

print("Practice Text Library Validator")
print("===============================")
print("Directory: \(baseDir)\n")

var allErrors: [String] = []
var allWarnings: [String] = []
var allIDs = Set<String>()
var crossFileDuplicates: [String] = []

for language in ["en", "de"] {
    let filename = "PracticeTextLibrary_\(language).json"
    let path = "\(baseDir)/\(filename)"

    print("Validating \(filename)...")
    let result = validateFile(at: path, language: language)

    if !result.contentVersion.isEmpty { print("  Content version: \(result.contentVersion)") }
    print("  Texts: \(result.textCount)")
    print("  Errors: \(result.errors.count), Warnings: \(result.warnings.count)")
    for e in result.errors { print("  ERROR: \(e)") }
    for w in result.warnings { print("  WARN: \(w)") }

    allErrors.append(contentsOf: result.errors)
    allWarnings.append(contentsOf: result.warnings)

    if let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
       let container = try? JSONDecoder().decode(ValidatedContainer.self, from: data) {
        for text in container.texts {
            if allIDs.contains(text.id) { crossFileDuplicates.append(text.id) }
            allIDs.insert(text.id)
        }
    }
    print("")
}

if !crossFileDuplicates.isEmpty {
    for id in crossFileDuplicates {
        let msg = "Duplicate ID across files: '\(id)'"
        print("ERROR: \(msg)")
        allErrors.append(msg)
    }
}

print("Summary: \(allIDs.count) texts, \(allErrors.count) errors, \(allWarnings.count) warnings")

if allErrors.isEmpty {
    print("All checks passed.")
    exit(0)
} else {
    print("Validation FAILED with \(allErrors.count) error(s).")
    exit(1)
}
