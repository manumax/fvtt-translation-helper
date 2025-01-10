import SwiftyJSON

// MARK: - SwiftJSON Extensions

typealias NodeCallback = ([JSONSubscriptType], JSON) -> Void
typealias JsonPath = [JSONSubscriptType]

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

  func simplePrint() -> String {
    switch type {
    case .number, .string, .bool:
      return stringValue
    case .array:
      return count == 0 ? "[]" : "[...]"
    case .dictionary:
      return count == 0 ? "{}" : "{...}"
    case .null:
      return "null"
    case .unknown:
      return "unknown"
    }
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
