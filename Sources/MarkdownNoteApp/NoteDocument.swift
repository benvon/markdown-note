import AppKit
import Foundation

final class NoteDocument: NSDocument {
  static let documentType = "net.benvon.markdown-note.document"

  private let sourceTextLock = NSLock()
  nonisolated(unsafe) private var sourceTextStorage: String = ""

  var sourceText: String {
    sourceTextLock.lock()
    defer { sourceTextLock.unlock() }
    return sourceTextStorage
  }

  override class var autosavesInPlace: Bool {
    true
  }

  override init() {
    super.init()
  }

  func replaceSourceText(_ newValue: String) {
    sourceTextLock.lock()
    let didChange = sourceTextStorage != newValue
    if didChange {
      sourceTextStorage = newValue
    }
    sourceTextLock.unlock()

    guard didChange else {
      return
    }

    updateChangeCount(.changeDone)
  }

  override func makeWindowControllers() {
    let controller = DocumentWindowController(document: self)
    addWindowController(controller)
  }

  override func data(ofType typeName: String) throws -> Data {
    let snapshot = sourceText
    guard let data = snapshot.data(using: .utf8) else {
      throw CocoaError(.fileWriteInapplicableStringEncoding)
    }
    return data
  }

  override func read(from data: Data, ofType typeName: String) throws {
    guard let text = String(data: data, encoding: .utf8) else {
      throw CocoaError(.fileReadInapplicableStringEncoding)
    }

    sourceTextLock.lock()
    sourceTextStorage = text
    sourceTextLock.unlock()
  }
}
