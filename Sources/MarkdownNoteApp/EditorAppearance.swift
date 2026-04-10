import AppKit
import Foundation

@MainActor
struct EditorAppearance {
  let sourceFont: NSFont
  let renderedFont: NSFont
  let textColor: NSColor
  let backgroundColor: NSColor
  let secondaryTextColor: NSColor

  static let fallback = EditorAppearance(
    sourceFont: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
    renderedFont: NSFont.systemFont(ofSize: 14),
    textColor: .labelColor,
    backgroundColor: .textBackgroundColor,
    secondaryTextColor: .secondaryLabelColor
  )
}
