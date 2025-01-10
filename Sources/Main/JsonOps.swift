import SwiftyJSON

func parsePatterns(_ patterns: [String]) -> [[JSONSubscriptType]] {
  patterns.map(
    [JSONSubscriptType].init(fromKeyString:)
  )
}

// MARK: - filterJsonByPatterns

func filterJsonByPatterns(
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

// MARK: - mergePathIndexedJson

func mergePathIndexedJson(
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

// MARK: - removeKeysFromJsonByPatterns

func removeKeysFromJsonByPatterns(_ json: JSON, patterns: [[JSONSubscriptType]]) -> JSON {
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

// MARK: - detectInvariantKeysInJson

func detectInvariantKeysInJson(_ json: JSON) -> [(String, JSON)] {
  var candidates = [DetectInvariantKey: DetectInvariantValue]()
  json.traverse { path, value in
    let (_, last) = path.splitLast()
    if case .key(let key) = last?.jsonKey {
      let candidateKey = DetectInvariantKey(key: key, path: path)
      if let candidateValue = candidates[candidateKey] {
        switch candidateValue {
        case .once(let json), .multiple(let json):
          if json == value {
            candidates[candidateKey] = .multiple(json)
          } else {
            candidates[candidateKey] = .different
          }
        case .different:
          break
        }
      } else {
        candidates[candidateKey] = .once(value)
      }
    }
  }
  return
    candidates
    .filter { key, value in
      switch value {
      case .once(_), .different: return false
      case .multiple(_): return true
      }
    }
    .compactMap { (key, value) -> (String, JSON)? in
      if case .multiple(let json) = value {
        return (key.path.toKeyString(), json)
      }
      return nil
    }
    .sorted { $0.0 < $1.0 }
}

struct DetectInvariantKey {
  let key: String
  let path: [JSONSubscriptType]
}

extension DetectInvariantKey: Equatable {
  static func == (lhs: DetectInvariantKey, rhs: DetectInvariantKey) -> Bool {
    return lhs.key == rhs.key && lhs.path.count == rhs.path.count
  }
}

extension DetectInvariantKey: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(path.count)
  }
}

enum DetectInvariantValue {
  case once(JSON)
  case multiple(JSON)
  case different
}
