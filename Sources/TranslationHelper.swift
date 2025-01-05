import ArgumentParser
import Foundation
import SwiftyJSON

@main
struct TranslationHelper: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract:
            "A utility designed to assist in translating Foundry VTT packages using the Babele module.",
        subcommands: [Extract.self, Merge.self, Remove.self]
    )
}

// MARK: - Extract

extension TranslationHelper {
    struct Extract: ParsableCommand {
        static let configuration =
            CommandConfiguration(
                abstract: "Extracts keys and values from a Babele translation file.")

        @Option(name: [.short, .customLong("input")])
        var inputFile: String

        @Option(name: [.short, .customLong("output")])
        var outputFile: String

        @Option(name: [.short, .customLong("patterns")])
        var pattern: [String] = []

        @Flag(name: [.short, .customLong("remove-empty-strings")])
        var removeEmptyStrings: Bool = false

        mutating func run() throws {
            let inputJson = try openJsonFile(at: inputFile)
            let patterns = parsePatterns(pattern)
            let outputJson = filterJsonByPatterns(
                inputJson,
                patterns: patterns,
                removeEmptyStrings: removeEmptyStrings
            )
            try writeJsonFile(outputJson, to: outputFile)
        }
    }
}

// MARK: - Merge

extension TranslationHelper {
    struct Merge: ParsableCommand {
        static let configuration =
            CommandConfiguration(abstract: "Merges keys and values into a Babele translation file.")

        @Option(name: [.short, .customLong("input")])
        var inputFile: String

        @Option(name: [.short, .customLong("merge-with")])
        var mergeFile: String

        @Option(name: [.short, .customLong("output")])
        var outputFile: String

        func run() throws {
            let inputJson = try openJsonFile(at: inputFile)
            let mergeWithJson = try openJsonFile(at: mergeFile)
            let mergedJson = mergePathIndexedJson(
                mergeWithJson,
                into: inputJson,
                progress: progress(completed:total:)
            )
            try writeJsonFile(mergedJson, to: outputFile)
        }
    }
}

// MARK: - Remove

extension TranslationHelper {
    struct Remove: ParsableCommand {
        static let configuration =
            CommandConfiguration(
                abstract: "Removes unnecessary keys and their corresponding values.")

        @Option(name: [.short, .customLong("input")])
        var inputFile: String

        @Option(name: [.short, .customLong("output")])
        var outputFile: String

        @Option(name: [.short, .customLong("patterns")])
        var pattern: [String]

        func run() throws {
            let inputJson = try openJsonFile(at: inputFile)
            let patterns = parsePatterns(pattern)
            let resultingJson = removeKeysFromJsonByPatterns(inputJson, patterns: patterns)
            try writeJsonFile(resultingJson, to: outputFile)
        }
    }
}

// MARK: - Operations

private func openJsonFile(at path: String) throws -> JSON {
    do {
        let inputFile = URL(fileURLWithPath: path)
        return try JSON(data: Data(contentsOf: inputFile))
    } catch {
        throw TranslationHelperError.fileNotFoundOrNotReadable
    }
}

private func writeJsonFile(_ json: JSON, to path: String) throws {
    let outputFile = URL(fileURLWithPath: path)
    do {
        try json.rawData().write(to: outputFile)
    } catch {
        throw TranslationHelperError.unableToWriteFile
    }
}

private func parsePatterns(_ patterns: [String]) -> [[JSONSubscriptType]] {
    patterns.map(
        [JSONSubscriptType].init(fromKeyString:)
    )
}

private func filterJsonByPatterns(
    _ json: JSON, 
    patterns: [[JSONSubscriptType]], 
    removeEmptyStrings: Bool
) -> JSON {
    var filteredJson = JSON()
    json.traverse { path, value in
        if path.matches(patterns) {
            if removeEmptyStrings, value.type == .string, value.stringValue.isEmpty {
                return
            }
            filteredJson[path.toKeyString()] = value
        }
    }
    return filteredJson
}

private func mergePathIndexedJson(
    _ pathIndexedJson: JSON, into json: JSON, progress: ((Int, Int) -> Void)? = nil
) -> JSON {
    var mergedJson = json
    var currentMergedKeys = 0
    let totalKeysToMerge = pathIndexedJson.count
    pathIndexedJson.forEach { key, value in
        let path = [JSONSubscriptType](fromKeyString: key)
        mergedJson[path] = value
        currentMergedKeys += 1
        progress?(currentMergedKeys, totalKeysToMerge)
    }
    return mergedJson
}

private func removeKeysFromJsonByPatterns(_ json: JSON, patterns: [[JSONSubscriptType]]) -> JSON {
    // Making a copy of the JSON object to avoid mutating the original
    var resultingJson = JSON(json.rawValue)
    json.traverse { path, value in
        if path.matches(patterns) {
            let (subpath, last) = path.splitLast()
            if let last = last, case .key(let key) = last.jsonKey {
                resultingJson[subpath].dictionaryObject?.removeValue(forKey: key)
            }
        }
    }
    return resultingJson
}

// MARK: - Progress

private func progress(completed: Int, total: Int) {
    let progress = "\rProgress: \(completed)/\(total)"
    FileHandle.standardOutput.write(Data(progress.utf8))
    if completed == total {
        FileHandle.standardOutput.write("\nDone.\n".data(using: .utf8)!)
    }
}

// MARK: - Error Handling

enum TranslationHelperError: Error {
    case fileNotFoundOrNotReadable
    case unableToWriteFile
}

// MARK: - SwiftJSON Extensions

typealias NodeCallback = ([JSONSubscriptType], JSON) -> Void

extension JSON {

    func traverse(_ callback: NodeCallback) {
        JSON.traverse(self, callback: callback)
    }

    private static func traverse(
        _ json: JSON, callback: NodeCallback, path: [JSONSubscriptType] = []
    ) {
        switch json.type {
        case .array:
            callback(path, json)
            for (index, value) in json {
                let path = path + [Int(index)!]
                traverse(value, callback: callback, path: path)
            }
        case .dictionary:
            callback(path, json)
            for (key, value) in json {
                let path = path + [key]
                traverse(value, callback: callback, path: path)
            }
        default:
            callback(path, json)
        }
    }

    mutating func removeKey(atPath path: [JSONSubscriptType]) -> JSON? {
        guard path.count > 0 else { return nil }
        let (subpath, last) = path.splitLast()
        guard
            let last = last,
            case .key(let key) = last.jsonKey
        else { return nil }
        return
            (subpath.count == 0
            ? dictionaryObject?.removeValue(forKey: key)
            : self[subpath].dictionaryObject?.removeValue(forKey: key)) as? JSON
    }
}

extension Array where Element == JSONSubscriptType {

    init(fromKeyString key: String) {
        self = key.split(separator: "~").map { token in
            if let index = Int(token) {
                return index
            } else {
                return String(token)
            }
        }
    }

    func toKeyString() -> String {
        map { token in
            switch token.jsonKey {
            case .index(let value):
                return "\(value)"
            case .key(let value):
                return "\(value)"
            }
        }.joined(separator: "~")
    }
}

extension Array where Element == JSONSubscriptType {

    func matches(_ patterns: [[JSONSubscriptType]]) -> Bool {
        guard !patterns.isEmpty else {
            return true
        }

        return patterns.contains { pattern in
            guard pattern.count == count else {
                return false
            }

            for (index, token) in pattern.enumerated() {
                switch (token.jsonKey, self[index].jsonKey) {
                case (.key("*"), _):
                    continue
                case (.key(let lhs), .key(let rhs)) where lhs == rhs:
                    continue
                case (.index(let lhs), .index(let rhs)) where lhs == rhs:
                    continue
                default:
                    return false
                }
            }
            return true
        }
    }
}

extension Array where Element == JSONSubscriptType {

    func splitLast() -> ([JSONSubscriptType], JSONSubscriptType?) {
        switch count {
        case 0: return ([], nil)
        case 1: return ([], self.last!)
        default:
            let lastIndex = count - 1
            return (Array(self[0..<lastIndex]), self[lastIndex])
        }
    }
}
