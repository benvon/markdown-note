import AppKit
import Foundation
import MarkdownNoteCore

@MainActor
final class EditorCoordinator: NSObject {
  private weak var document: NoteDocument?
  private weak var textView: NSTextView?

  private let attributedStringBuilder = EditorAttributedStringBuilder()

  private var editorModel: EditorModel
  private var isApplyingSnapshot = false
  private var appearance = AppSettings.shared.appearance

  init(document: NoteDocument, textView: NSTextView) {
    self.document = document
    self.textView = textView
    self.editorModel = EditorModel(sourceText: document.sourceText)
    super.init()
    configure(textView: textView)
  }

  func loadInitialContent() {
    applyAppearance()
    applySnapshot(sourceCaret: 0)
  }

  private func configure(textView: NSTextView) {
    textView.delegate = self
    textView.isRichText = false
    textView.importsGraphics = false
    textView.allowsImageEditing = false
    textView.isAutomaticQuoteSubstitutionEnabled = false
    textView.isAutomaticDashSubstitutionEnabled = false
    textView.isAutomaticLinkDetectionEnabled = false
    textView.isAutomaticTextReplacementEnabled = false
    textView.usesFindPanel = true
    textView.usesFindBar = true
    textView.allowsUndo = true

    applyAppearance()

    textView.isHorizontallyResizable = true
    textView.isVerticallyResizable = true
    textView.maxSize = NSSize(
      width: CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude
    )
    textView.minSize = NSSize(width: 0, height: 0)
    textView.textContainerInset = NSSize(width: 12, height: 12)

    if let textContainer = textView.textContainer {
      textContainer.widthTracksTextView = false
      textContainer.heightTracksTextView = false
      textContainer.containerSize = NSSize(
        width: CGFloat.greatestFiniteMagnitude,
        height: CGFloat.greatestFiniteMagnitude
      )
      textContainer.lineBreakMode = .byClipping
      textContainer.lineFragmentPadding = 0
    }

    if let scrollView = textView.enclosingScrollView {
      scrollView.hasVerticalScroller = true
      scrollView.hasHorizontalScroller = true
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(settingsDidChangeNotification(_:)),
      name: AppSettings.didChangeNotification,
      object: nil
    )
  }

  private func applySnapshot(sourceCaret: Int?) {
    guard let textView else {
      return
    }

    isApplyingSnapshot = true
    defer { isApplyingSnapshot = false }

    let scrollOrigin = textView.enclosingScrollView?.contentView.bounds.origin

    let attributedDisplay = attributedStringBuilder.makeAttributedDisplay(
      from: editorModel.snapshot,
      appearance: appearance
    )
    textView.textStorage?.setAttributedString(attributedDisplay)

    if let sourceCaret {
      let displayCaret = editorModel.displayLocation(forSourceLocation: sourceCaret)
      textView.setSelectedRange(NSRange(location: displayCaret, length: 0))
    }

    if let scrollOrigin, let scrollView = textView.enclosingScrollView {
      scrollView.contentView.scroll(to: scrollOrigin)
      scrollView.reflectScrolledClipView(scrollView.contentView)
    }
  }

  private func applyAppearance() {
    guard let textView else {
      return
    }

    textView.font = appearance.sourceFont
    textView.textColor = appearance.textColor
    textView.backgroundColor = appearance.backgroundColor
    textView.insertionPointColor = appearance.textColor
  }

  private func handleSettingsChanged() {
    appearance = AppSettings.shared.appearance
    applyAppearance()

    guard let textView else {
      return
    }

    let sourceCaret = editorModel.sourceLocation(
      forDisplayLocation: textView.selectedRange().location
    )
    editorModel.rebuild(forSourceCaret: sourceCaret)
    applySnapshot(sourceCaret: sourceCaret)
  }

  @objc
  private func settingsDidChangeNotification(_ notification: Notification) {
    handleSettingsChanged()
  }

  private func refreshSelectionContextIfNeeded(displayLocation: Int) {
    let sourceCaret = editorModel.sourceLocation(
      forDisplayLocation: displayLocation
    )
    let nextActiveBlock = BlockResolver.blockIndex(
      containingUTF16: sourceCaret, in: editorModel.blocks)

    guard nextActiveBlock != editorModel.activeBlockIndex else {
      return
    }

    editorModel.rebuild(forSourceCaret: sourceCaret)
    applySnapshot(sourceCaret: sourceCaret)
  }
}

extension EditorCoordinator: NSTextViewDelegate {
  func textView(
    _ textView: NSTextView,
    shouldChangeTextIn affectedCharRange: NSRange,
    replacementString: String?
  ) -> Bool {
    if isApplyingSnapshot {
      return true
    }

    if editorModel.canEdit(displayRange: affectedCharRange) {
      return true
    }

    let sourceCaret = editorModel.moveActiveContext(toDisplayLocation: affectedCharRange.location)
    applySnapshot(sourceCaret: sourceCaret)
    return false
  }

  func textDidChange(_ notification: Notification) {
    guard !isApplyingSnapshot, let textView else {
      return
    }

    guard notification.object as AnyObject? === textView else {
      return
    }

    let sourceCaret = editorModel.applyDisplayEdit(
      liveDisplayText: textView.string,
      selectionDisplayLocation: textView.selectedRange().location
    )

    document?.replaceSourceText(editorModel.sourceText)
    applySnapshot(sourceCaret: sourceCaret)
  }

  func textViewDidChangeSelection(_ notification: Notification) {
    guard !isApplyingSnapshot, let textView else {
      return
    }

    guard notification.object as AnyObject? === textView else {
      return
    }

    refreshSelectionContextIfNeeded(displayLocation: textView.selectedRange().location)
  }
}
