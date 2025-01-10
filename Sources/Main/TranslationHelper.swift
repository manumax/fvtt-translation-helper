import ArgumentParser
import Foundation
import SwiftyJSON

@main
struct TranslationHelper: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract:
      "A utility designed to assist in translating Foundry VTT packages using the Babele module.",
    subcommands: [Extract.self, Merge.self, DetectInvariantKeys.self, Remove.self]
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

// MARK: -

extension TranslationHelper {
  struct DetectInvariantKeys: ParsableCommand {
    static let configuration =
      CommandConfiguration(
        abstract:
          "Identifies keys with values that remain constant, making them candidates for removal."
      )

    @Option(name: [.short, .customLong("input")])
    var inputFile: String

    mutating func run() throws {
      let inputJson = try openJsonFile(at: inputFile)
      let invariants = detectInvariantKeysInJson(inputJson)
      invariants.forEach { path, value in
        print("\(path): \(value.simplePrint())")
      }
    }
  }
}
