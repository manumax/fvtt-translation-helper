import SwiftyJSON
import Testing

@testable import FvttTranslationHelper

@Suite("SwiftJSON Extensions") struct SwiftJSONExtensions {

  // MARK: - splitLast

  @Test func splitEmptyPath() {
    let path = [JSONSubscriptType]()
    let (subpath, last) = path.splitLast()
    #expect(subpath.count == 0)
    #expect(last == nil)
  }

  @Test func splitOneEntryPath() {
    let path: [JSONSubscriptType] = ["path"]
    let (subpath, last) = path.splitLast()
    #expect(subpath.count == 0)
    if let last = last, case .key(let key) = last.jsonKey {
      #expect(key == "path")
    }
  }

  @Test func splitPath() {
    let path: [JSONSubscriptType] = ["path", 1]
    let (subpath, last) = path.splitLast()
    #expect(subpath.count == 1)
    if let last = last, case .index(let index) = last.jsonKey {
      #expect(index == 1)
    }
  }

  // MARK: - traverse

  @Test func traverse() {
    // Arrange
    let json: JSON = [
      "dict": [
        "array": [
          "string",
          0,
          [
            "item3": "nested"
          ],
        ]
      ]
    ]
    // Act
    var traversed = [SwiftyJSON.Type]()
    json.traverse { _, value in
      traversed.append(value.type)
    }
    // Assert
    #expect(
      traversed == [
        .dictionary, .dictionary, .array, .string, .number, .dictionary,
        .string,
      ])
  }

  // MARK: - keyString

  @Test func fromToKeyString() {
    let path: JsonPath = ["dict", "array", 1, "name"]
    let keyString = path.toKeyString()
    let pathFromKeyString = JsonPath.init(fromKeyString: keyString)
    #expect(
      pathFromKeyString.map { $0.jsonKey } == [
        .key("dict"), .key("array"), .index(1), .key("name"),
      ])
    #expect(keyString == "dict~array~1~name")
  }

  // MARK: - match

  @Test(
    "It should match pattern",
    arguments: [
      ("", "", true),
      ("items", "items", true),
      ("items.1", "items", false),
      ("items", "*", true),
      ("1", "*", true),
      ("items~monster~entries~2~names", "items~*~entries~*~names", true),
      ("items~monster~entries~2~names~1", "items~*~entries~*~names", false),
    ])
  func pathShouldMatchPattern(_ fixture: (String, String, Bool)) {
    let (pathAsString, patternAsString, expected) = fixture
    let path = JsonPath.init(fromKeyString: pathAsString)
    let pattern = JsonPath.init(fromKeyString: patternAsString)
    #expect(path.matches([pattern]) == expected)
  }
}
