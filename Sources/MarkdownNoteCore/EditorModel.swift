import Foundation

public protocol SnapshotGenerating {
  func snapshot(
    for source: String,
    blocks: [MarkdownBlock],
    activeBlockIndex: Int?
  ) -> RenderSnapshot
}

extension MarkdownRenderEngine: SnapshotGenerating {}

public struct SnapshotLocationMapper {
  private let snapshot: RenderSnapshot
  private let sourceLength: Int

  public init(snapshot: RenderSnapshot, sourceLength: Int) {
    self.snapshot = snapshot
    self.sourceLength = max(0, sourceLength)
  }

  public func sourceLocation(forDisplayLocation displayLocation: Int) -> Int {
    guard let firstSegment = snapshot.segments.first else {
      return 0
    }

    let displayLength = (snapshot.displayText as NSString).length

    if displayLocation <= 0 {
      return firstSegment.sourceRange.location
    }

    if displayLocation >= displayLength {
      guard let lastSegment = snapshot.segments.last else {
        return sourceLength
      }
      return NSMaxRange(lastSegment.sourceRange)
    }

    guard let segment = segment(forDisplayLocation: displayLocation) else {
      return min(displayLocation, sourceLength)
    }

    if segment.displayRange.length == 0 {
      return segment.sourceRange.location
    }

    let localDisplayOffset = max(
      0,
      min(
        displayLocation - segment.displayRange.location,
        segment.displayRange.length
      )
    )

    if segment.displayRange.length == segment.sourceRange.length {
      return segment.sourceRange.location + localDisplayOffset
    }

    let ratio = Double(localDisplayOffset) / Double(max(1, segment.displayRange.length))
    let translated =
      segment.sourceRange.location + Int((ratio * Double(segment.sourceRange.length)).rounded())
    return max(segment.sourceRange.location, min(translated, NSMaxRange(segment.sourceRange)))
  }

  public func displayLocation(forSourceLocation sourceLocation: Int) -> Int {
    let boundedSource = max(0, min(sourceLocation, sourceLength))
    let lastSegmentIndex = snapshot.segments.count - 1

    for (index, segment) in snapshot.segments.enumerated() {
      let lowerBound = segment.sourceRange.location
      let upperBound = NSMaxRange(segment.sourceRange)
      let isLastSegment = index == lastSegmentIndex
      let containsSourceLocation: Bool

      if segment.sourceRange.length == 0 {
        containsSourceLocation = boundedSource == lowerBound
      } else {
        containsSourceLocation =
          boundedSource >= lowerBound
          && (boundedSource < upperBound || (isLastSegment && boundedSource == upperBound))
      }

      if containsSourceLocation {
        if segment.sourceRange.length == 0 {
          return segment.displayRange.location
        }

        let localSourceOffset = boundedSource - segment.sourceRange.location

        if segment.sourceRange.length == segment.displayRange.length {
          let boundedOffset = min(localSourceOffset, segment.displayRange.length)
          return segment.displayRange.location + boundedOffset
        }

        let ratio = Double(localSourceOffset) / Double(max(1, segment.sourceRange.length))
        let translated =
          segment.displayRange.location
          + Int((ratio * Double(segment.displayRange.length)).rounded())
        return max(
          segment.displayRange.location,
          min(translated, NSMaxRange(segment.displayRange))
        )
      }
    }

    return boundedSource
  }

  public func isRange(_ range: NSRange, inside activeRange: NSRange?) -> Bool {
    guard let activeRange else {
      return true
    }

    return range.location >= activeRange.location
      && NSMaxRange(range) <= NSMaxRange(activeRange)
  }

  private func segment(forDisplayLocation displayLocation: Int) -> DisplaySegment? {
    for segment in snapshot.segments {
      let lower = segment.displayRange.location
      let upper = NSMaxRange(segment.displayRange)

      if displayLocation >= lower && displayLocation < upper {
        return segment
      }
    }

    return snapshot.segments.last
  }
}

public struct EditorModel {
  public private(set) var sourceText: String
  public private(set) var blocks: [MarkdownBlock] = []
  public private(set) var snapshot: RenderSnapshot = RenderSnapshot(displayText: "", segments: [])
  public private(set) var activeBlockIndex: Int?

  private let snapshotGenerator: any SnapshotGenerating

  public init(
    sourceText: String,
    initialSourceCaret: Int = 0,
    snapshotGenerator: any SnapshotGenerating = MarkdownRenderEngine()
  ) {
    self.sourceText = sourceText
    self.snapshotGenerator = snapshotGenerator
    rebuild(forSourceCaret: initialSourceCaret)
  }

  public mutating func rebuild(forSourceCaret sourceCaret: Int) {
    blocks = BlockResolver.resolveBlocks(in: sourceText)

    let boundedCaret = boundedSourceLocation(sourceCaret)
    activeBlockIndex = BlockResolver.blockIndex(containingUTF16: boundedCaret, in: blocks)

    snapshot = snapshotGenerator.snapshot(
      for: sourceText,
      blocks: blocks,
      activeBlockIndex: activeBlockIndex
    )
  }

  public mutating func moveActiveContext(toDisplayLocation displayLocation: Int) -> Int {
    let sourceCaret = sourceLocation(forDisplayLocation: displayLocation)
    rebuild(forSourceCaret: sourceCaret)
    return sourceCaret
  }

  public func sourceLocation(forDisplayLocation displayLocation: Int) -> Int {
    locationMapper.sourceLocation(forDisplayLocation: displayLocation)
  }

  public func displayLocation(forSourceLocation sourceLocation: Int) -> Int {
    locationMapper.displayLocation(forSourceLocation: sourceLocation)
  }

  public func canEdit(displayRange: NSRange) -> Bool {
    locationMapper.isRange(displayRange, inside: snapshot.activeSegment?.displayRange)
  }

  public mutating func applyDisplayEdit(liveDisplayText: String, selectionDisplayLocation: Int)
    -> Int
  {
    guard let activeSegment = snapshot.activeSegment else {
      let sourceCaret = sourceLocation(forDisplayLocation: selectionDisplayLocation)
      rebuild(forSourceCaret: sourceCaret)
      return sourceCaret
    }

    let oldDisplayLength = (snapshot.displayText as NSString).length
    let newDisplayLength = (liveDisplayText as NSString).length
    let delta = newDisplayLength - oldDisplayLength

    let newActiveLength = max(0, activeSegment.displayRange.length + delta)
    let newActiveRange = NSRange(
      location: activeSegment.displayRange.location, length: newActiveLength)

    let liveDisplay = liveDisplayText as NSString
    guard NSMaxRange(newActiveRange) <= liveDisplay.length else {
      let sourceCaret = sourceLocation(forDisplayLocation: selectionDisplayLocation)
      rebuild(forSourceCaret: sourceCaret)
      return sourceCaret
    }

    let replacementText = liveDisplay.substring(with: newActiveRange)
    sourceText = (sourceText as NSString).replacingCharacters(
      in: activeSegment.sourceRange,
      with: replacementText
    )

    let sourceCaret = sourceCaretAfterEdit(
      selectionDisplayLocation: selectionDisplayLocation,
      activeSegment: activeSegment,
      newActiveLength: newActiveLength
    )

    rebuild(forSourceCaret: sourceCaret)
    return sourceCaret
  }

  private var locationMapper: SnapshotLocationMapper {
    SnapshotLocationMapper(
      snapshot: snapshot,
      sourceLength: (sourceText as NSString).length
    )
  }

  private func boundedSourceLocation(_ sourceCaret: Int) -> Int {
    max(0, min(sourceCaret, (sourceText as NSString).length))
  }

  private func sourceCaretAfterEdit(
    selectionDisplayLocation: Int,
    activeSegment: DisplaySegment,
    newActiveLength: Int
  ) -> Int {
    if selectionDisplayLocation >= activeSegment.displayRange.location {
      let local = selectionDisplayLocation - activeSegment.displayRange.location
      let bounded = max(0, min(local, newActiveLength))
      return activeSegment.sourceRange.location + bounded
    }

    return sourceLocation(forDisplayLocation: selectionDisplayLocation)
  }
}
