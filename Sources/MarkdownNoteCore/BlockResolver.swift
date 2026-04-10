import Foundation

public enum MarkdownBlockKind: String, Codable, Sendable {
  case blank
  case heading
  case listItem
  case blockquote
  case paragraph
}

public struct MarkdownBlock: Equatable, Sendable {
  public let nsRange: NSRange
  public let kind: MarkdownBlockKind

  public init(nsRange: NSRange, kind: MarkdownBlockKind) {
    self.nsRange = nsRange
    self.kind = kind
  }
}

public enum BlockResolver {
  private static let orderedListPrefix: NSRegularExpression = {
    guard let regex = try? NSRegularExpression(pattern: #"^\s*\d+\.\s+"#) else {
      fatalError("Invalid ordered list regex")
    }
    return regex
  }()

  private static let unorderedListPrefix: NSRegularExpression = {
    guard let regex = try? NSRegularExpression(pattern: #"^\s*[-*+]\s+"#) else {
      fatalError("Invalid unordered list regex")
    }
    return regex
  }()

  public static func resolveBlocks(in source: String) -> [MarkdownBlock] {
    let text = source as NSString

    if text.length == 0 {
      return [MarkdownBlock(nsRange: NSRange(location: 0, length: 0), kind: .paragraph)]
    }

    var lineRanges: [NSRange] = []
    var lineKinds: [MarkdownBlockKind] = []

    var location = 0
    while location < text.length {
      let lineRange = text.lineRange(for: NSRange(location: location, length: 0))
      let rawLine = text.substring(with: lineRange)
      lineRanges.append(lineRange)
      lineKinds.append(kind(forLine: rawLine))
      location = NSMaxRange(lineRange)
    }

    var blocks: [MarkdownBlock] = []
    var pendingRange: NSRange?
    var pendingKind: MarkdownBlockKind?

    func flushPending() {
      if let range = pendingRange, let kind = pendingKind {
        blocks.append(MarkdownBlock(nsRange: range, kind: kind))
      }
      pendingRange = nil
      pendingKind = nil
    }

    for (index, lineRange) in lineRanges.enumerated() {
      let lineKind = lineKinds[index]

      if lineKind == .blank {
        flushPending()
        blocks.append(MarkdownBlock(nsRange: lineRange, kind: .blank))
        continue
      }

      if lineKind == .heading {
        flushPending()
        blocks.append(MarkdownBlock(nsRange: lineRange, kind: .heading))
        continue
      }

      if let currentKind = pendingKind,
        currentKind == lineKind,
        canMerge(kind: lineKind)
      {
        let mergedLocation = pendingRange?.location ?? lineRange.location
        let mergedEnd = NSMaxRange(lineRange)
        pendingRange = NSRange(location: mergedLocation, length: mergedEnd - mergedLocation)
      } else {
        flushPending()
        pendingRange = lineRange
        pendingKind = lineKind
      }
    }

    flushPending()
    return blocks
  }

  public static func blockIndex(containingUTF16 location: Int, in blocks: [MarkdownBlock]) -> Int? {
    guard !blocks.isEmpty else {
      return nil
    }

    let boundedLocation = max(0, location)

    for (index, block) in blocks.enumerated() {
      let lowerBound = block.nsRange.location
      let upperBound = NSMaxRange(block.nsRange)

      if boundedLocation >= lowerBound && boundedLocation < upperBound {
        return index
      }
    }

    return blocks.indices.last
  }

  private static func canMerge(kind: MarkdownBlockKind) -> Bool {
    switch kind {
    case .listItem, .blockquote, .paragraph:
      return true
    case .blank, .heading:
      return false
    }
  }

  private static func kind(forLine line: String) -> MarkdownBlockKind {
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.isEmpty {
      return .blank
    }

    if trimmed.hasPrefix("#") {
      return .heading
    }

    if trimmed.hasPrefix(">") {
      return .blockquote
    }

    let fullRange = NSRange(location: 0, length: (line as NSString).length)

    if orderedListPrefix.firstMatch(in: line, range: fullRange) != nil {
      return .listItem
    }

    if unorderedListPrefix.firstMatch(in: line, range: fullRange) != nil {
      return .listItem
    }

    return .paragraph
  }
}
