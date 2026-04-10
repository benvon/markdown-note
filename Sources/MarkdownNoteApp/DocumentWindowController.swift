import AppKit
import Foundation

@MainActor
final class DocumentWindowController: NSWindowController {
  let noteDocument: NoteDocument

  private let editorTextView = NSTextView(frame: .zero)
  private let scrollView = NSScrollView(frame: .zero)

  private var editorCoordinator: EditorCoordinator?

  init(document: NoteDocument) {
    self.noteDocument = document

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 980, height: 680),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = document.displayName
    window.isReleasedWhenClosed = false
    window.tabbingMode = .preferred

    super.init(window: window)
    shouldCascadeWindows = true

    setupUI(in: window)
    editorCoordinator = EditorCoordinator(document: document, textView: editorTextView)
    editorCoordinator?.loadInitialContent()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI(in window: NSWindow) {
    let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
    contentView.translatesAutoresizingMaskIntoConstraints = false

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.borderType = .noBorder
    scrollView.hasVerticalScroller = true
    scrollView.hasHorizontalScroller = true
    scrollView.autohidesScrollers = true

    editorTextView.translatesAutoresizingMaskIntoConstraints = true
    editorTextView.autoresizingMask = [.width, .height]
    editorTextView.frame = NSRect(origin: .zero, size: contentView.bounds.size)
    editorTextView.minSize = .zero
    editorTextView.maxSize = NSSize(
      width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    editorTextView.isVerticallyResizable = true
    editorTextView.isHorizontallyResizable = true

    scrollView.documentView = editorTextView

    contentView.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    window.contentView = contentView
  }
}
