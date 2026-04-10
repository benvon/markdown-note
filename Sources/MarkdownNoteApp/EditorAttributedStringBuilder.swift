import AppKit
import Foundation
import MarkdownNoteCore

@MainActor
struct EditorAttributedStringBuilder {
  func makeAttributedDisplay(
    from snapshot: RenderSnapshot,
    appearance: EditorAppearance
  ) -> NSAttributedString {
    let attributed = NSMutableAttributedString(string: snapshot.displayText)
    let fullRange = NSRange(location: 0, length: attributed.length)

    let lineHeight =
      appearance.sourceFont.ascender - appearance.sourceFont.descender
      + appearance.sourceFont.leading
    let paragraphStyle = makeParagraphStyle(lineHeight: lineHeight)

    attributed.addAttributes(
      [
        .font: appearance.renderedFont,
        .foregroundColor: appearance.textColor,
        .paragraphStyle: paragraphStyle,
      ],
      range: fullRange
    )

    for segment in snapshot.segments where segment.displayRange.length > 0 {
      attributed.addAttributes(
        attributes(
          for: segment,
          paragraphStyle: paragraphStyle,
          appearance: appearance
        ),
        range: segment.displayRange
      )
    }

    return attributed
  }

  private func makeParagraphStyle(lineHeight: CGFloat) -> NSParagraphStyle {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.minimumLineHeight = lineHeight
    paragraphStyle.maximumLineHeight = lineHeight
    paragraphStyle.lineBreakMode = .byClipping
    return paragraphStyle
  }

  private func attributes(
    for segment: DisplaySegment,
    paragraphStyle: NSParagraphStyle,
    appearance: EditorAppearance
  ) -> [NSAttributedString.Key: Any] {
    if segment.isActive {
      return [
        .font: appearance.sourceFont,
        .foregroundColor: appearance.textColor,
        .paragraphStyle: paragraphStyle,
      ]
    }

    switch segment.kind {
    case .heading:
      let headingFont = NSFontManager.shared.convert(
        appearance.renderedFont,
        toHaveTrait: .boldFontMask
      )
      return [
        .font: headingFont,
        .foregroundColor: appearance.textColor,
        .paragraphStyle: paragraphStyle,
      ]
    case .blockquote:
      let italicFont = NSFontManager.shared.convert(
        appearance.renderedFont,
        toHaveTrait: .italicFontMask
      )
      return [
        .font: italicFont,
        .foregroundColor: appearance.secondaryTextColor,
        .paragraphStyle: paragraphStyle,
      ]
    case .listItem, .paragraph, .blank:
      return [
        .font: appearance.renderedFont,
        .foregroundColor: appearance.textColor,
        .paragraphStyle: paragraphStyle,
      ]
    }
  }
}
