import Foundation

public struct DisplaySegment: Equatable, Sendable {
  public let sourceRange: NSRange
  public let displayRange: NSRange
  public let kind: MarkdownBlockKind
  public let isActive: Bool

  public init(sourceRange: NSRange, displayRange: NSRange, kind: MarkdownBlockKind, isActive: Bool)
  {
    self.sourceRange = sourceRange
    self.displayRange = displayRange
    self.kind = kind
    self.isActive = isActive
  }
}

public struct RenderSnapshot: Equatable, Sendable {
  public let displayText: String
  public let segments: [DisplaySegment]

  public init(displayText: String, segments: [DisplaySegment]) {
    self.displayText = displayText
    self.segments = segments
  }

  public var activeSegment: DisplaySegment? {
    segments.first(where: { $0.isActive })
  }
}

public final class MarkdownRenderEngine {
  public init() {}

  public func snapshot(
    for source: String,
    blocks: [MarkdownBlock],
    activeBlockIndex: Int?
  ) -> RenderSnapshot {
    let text = source as NSString

    var output = String()
    var segments: [DisplaySegment] = []
    var displayLocation = 0

    for (index, block) in blocks.enumerated() {
      let blockSource = text.substring(with: block.nsRange)
      let isActive = index == activeBlockIndex
      let rendered = isActive ? blockSource : renderPassiveBlock(blockSource, kind: block.kind)

      output.append(rendered)

      let displayLength = (rendered as NSString).length
      let displayRange = NSRange(location: displayLocation, length: displayLength)
      segments.append(
        DisplaySegment(
          sourceRange: block.nsRange,
          displayRange: displayRange,
          kind: block.kind,
          isActive: isActive
        )
      )
      displayLocation += displayLength
    }

    return RenderSnapshot(displayText: output, segments: segments)
  }

  public func renderPassiveBlock(_ sourceBlock: String, kind: MarkdownBlockKind) -> String {
    if kind == .blank {
      return sourceBlock
    }

    let source = sourceBlock as NSString
    if source.length == 0 {
      return sourceBlock
    }

    var rendered = String()
    var lineLocation = 0

    while lineLocation < source.length {
      let lineRange = source.lineRange(for: NSRange(location: lineLocation, length: 0))
      let line = source.substring(with: lineRange)
      let trailingNewlineLength: Int
      if line.hasSuffix("\r\n") {
        trailingNewlineLength = 2
      } else if line.hasSuffix("\n") || line.hasSuffix("\r") {
        trailingNewlineLength = 1
      } else {
        trailingNewlineLength = 0
      }

      let content: String
      if trailingNewlineLength > 0 {
        let trimmedScalars = line.unicodeScalars.dropLast(trailingNewlineLength)
        content = String(String.UnicodeScalarView(trimmedScalars))
      } else {
        content = line
      }

      let normalizedContent = renderLine(content, kind: kind)
      rendered.append(normalizedContent)
      if trailingNewlineLength > 0 {
        rendered.append("\n")
      }

      lineLocation = NSMaxRange(lineRange)
    }

    return rendered
  }

  private func renderLine(_ line: String, kind: MarkdownBlockKind) -> String {
    if kind == .listItem {
      return renderListItemLine(line)
    }

    let strippedBlockMarkers = stripBlockSyntax(from: line, kind: kind)
    return renderInlineMarkdown(strippedBlockMarkers)
  }

  private func renderListItemLine(_ line: String) -> String {
    let unordered = line.replacing(/^\s*[-*+]\s+/, with: "")
    if unordered != line {
      return "• " + renderInlineMarkdown(unordered)
    }

    if let orderedMatch = line.firstMatch(of: /^\s*(\d+\.)\s+/) {
      let orderedPrefix = String(orderedMatch.1)
      let orderedContent = String(line[orderedMatch.range.upperBound...])
      return "\(orderedPrefix) " + renderInlineMarkdown(orderedContent)
    }

    return renderInlineMarkdown(line)
  }

  private func stripBlockSyntax(from line: String, kind: MarkdownBlockKind) -> String {
    switch kind {
    case .heading:
      return line.replacing(
        /^\s{0,3}#{1,6}\s*/,
        with: ""
      )
    case .blockquote:
      return line.replacing(
        /^\s{0,3}>\s?/,
        with: ""
      )
    case .listItem:
      return line
    case .blank, .paragraph:
      return line
    }
  }

  private func renderInlineMarkdown(_ text: String) -> String {
    if let rendered = try? AttributedString(markdown: text) {
      return String(rendered.characters)
    }

    return fallbackInlineCleanup(text)
  }

  private func fallbackInlineCleanup(_ text: String) -> String {
    var output = text

    output = output.replacingOccurrences(
      of: #"\[([^\]]+)\]\(([^\)]+)\)"#,
      with: "$1",
      options: .regularExpression
    )
    output = output.replacingOccurrences(
      of: #"\*\*([^*]+)\*\*"#,
      with: "$1",
      options: .regularExpression
    )
    output = output.replacingOccurrences(
      of: #"__([^_]+)__"#,
      with: "$1",
      options: .regularExpression
    )
    output = output.replacingOccurrences(
      of: #"\*([^*]+)\*"#,
      with: "$1",
      options: .regularExpression
    )
    output = output.replacingOccurrences(
      of: #"_([^_]+)_"#,
      with: "$1",
      options: .regularExpression
    )
    output = output.replacingOccurrences(
      of: #"`([^`]+)`"#,
      with: "$1",
      options: .regularExpression
    )

    return output
  }
}
