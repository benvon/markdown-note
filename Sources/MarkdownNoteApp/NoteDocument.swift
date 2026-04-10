import AppKit
import Foundation

private final class SourceTextStorage: @unchecked Sendable {
  private let lock = NSLock()
  private var value: String = ""

  func read() -> String {
    lock.lock()
    defer { lock.unlock() }
    return value
  }

  func updateIfChanged(to newValue: String) -> Bool {
    lock.lock()
    defer { lock.unlock() }

    guard value != newValue else {
      return false
    }

    value = newValue
    return true
  }

  func overwrite(with newValue: String) {
    lock.lock()
    value = newValue
    lock.unlock()
  }
}

final class NoteDocument: NSDocument {
  static let documentType = "net.benvon.markdown-note.document"

  private let sourceStorage = SourceTextStorage()

  var sourceText: String {
    sourceStorage.read()
  }

  override class var autosavesInPlace: Bool {
    true
  }

  override init() {
    super.init()
  }

  func replaceSourceText(_ newValue: String) {
    guard sourceStorage.updateIfChanged(to: newValue) else {
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

    sourceStorage.overwrite(with: text)
  }
}
