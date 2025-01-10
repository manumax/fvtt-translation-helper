import Foundation
import SwiftyJSON

// MARK: - File Ops

enum InputOutputError: Error {
  case fileNotFoundOrNotReadable
  case unableToWriteFile
}

func openJsonFile(at path: String) throws -> JSON {
  do {
    let inputFile = URL(fileURLWithPath: path)
    return try JSON(data: Data(contentsOf: inputFile))
  } catch {
    throw InputOutputError.fileNotFoundOrNotReadable
  }
}

func writeJsonFile(_ json: JSON, to path: String) throws {
  let outputFile = URL(fileURLWithPath: path)
  do {
    try json.rawData().write(to: outputFile)
  } catch {
    throw InputOutputError.unableToWriteFile
  }
}

// MARK: - Progress

func progress(completed: Int, total: Int) {
  let progress = "\rProgress: \(completed)/\(total)"
  FileHandle.standardOutput.write(Data(progress.utf8))
  if completed == total {
    FileHandle.standardOutput.write("\nDone.\n".data(using: .utf8)!)
  }
}
