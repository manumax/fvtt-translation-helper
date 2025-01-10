import Testing
import SwiftyJSON

@testable import FvttTranslationHelper

// MARK: - SplitLast

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