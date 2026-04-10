import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
final class NoteDocumentController: NSDocumentController {
  static let sharedController = NoteDocumentController()

  private override init() {
    super.init()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override var defaultType: String? {
    NoteDocument.documentType
  }

  override func documentClass(forType typeName: String) -> AnyClass? {
    NoteDocument.self
  }

  override func makeUntitledDocument(ofType typeName: String) throws -> NSDocument {
    NoteDocument()
  }

  override func typeForContents(of url: URL) throws -> String {
    NoteDocument.documentType
  }

  func newDocument() {
    do {
      _ = try openUntitledDocumentAndDisplay(true)
    } catch {
      NSApp.presentError(error)
    }
  }

  func openDocumentWithPanel() {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = [.plainText]

    let response = panel.runModal()
    guard response == .OK, let url = panel.url else {
      return
    }

    openDocument(withContentsOf: url, display: true) { _, _, error in
      if let error {
        NSApp.presentError(error)
      }
    }
  }
}
