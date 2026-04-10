import AppKit
import Foundation

@MainActor
final class NoteDocument: NSDocument {
  static let documentType = "net.benvon.markdown-note.document"

  private(set) var sourceText: String = ""

  override class var autosavesInPlace: Bool {
    true
  }

  override init() {
    super.init()
  }

  func replaceSourceText(_ newValue: String) {
    guard sourceText != newValue else {
      return
    }

    sourceText = newValue
    updateChangeCount(.changeDone)
  }

  func loadSourceText(_ newValue: String) {
    sourceText = newValue
    updateChangeCount(.changeCleared)
  }

  override func makeWindowControllers() {
    let controller = DocumentWindowController(document: self)
    addWindowController(controller)
  }

  override func data(ofType typeName: String) throws -> Data {
    guard let data = sourceText.data(using: .utf8) else {
      throw CocoaError(.fileWriteInapplicableStringEncoding)
    }
    return data
  }

  override func read(from data: Data, ofType typeName: String) throws {
    guard let text = String(data: data, encoding: .utf8) else {
      throw CocoaError(.fileReadInapplicableStringEncoding)
    }

    MainActor.assumeIsolated {
      loadSourceText(text)
    }
  }
}
