import Foundation
import Testing

@testable import MarkdownNoteCore

struct BlockResolverTests {
  @Test
  func resolvesHeadingsParagraphsListsAndQuotes() {
    let source = """
      # Title

      first paragraph line
      second paragraph line

      - one
      - two

      > quote line one
      > quote line two
      """

    let blocks = BlockResolver.resolveBlocks(in: source)
    #expect(blocks.count == 7)
    #expect(blocks[0].kind == .heading)
    #expect(blocks[1].kind == .blank)
    #expect(blocks[2].kind == .paragraph)
    #expect(blocks[3].kind == .blank)
    #expect(blocks[4].kind == .listItem)
    #expect(blocks[5].kind == .blank)
    #expect(blocks[6].kind == .blockquote)
  }

  @Test
  func findsContainingBlockByUtf16Location() {
    let source = "line one\n\nline two\n"
    let blocks = BlockResolver.resolveBlocks(in: source)

    let firstLocation = 2
    let thirdBlockLocation = (source as NSString).range(of: "line two").location

    #expect(BlockResolver.blockIndex(containingUTF16: firstLocation, in: blocks) == 0)
    #expect(BlockResolver.blockIndex(containingUTF16: thirdBlockLocation, in: blocks) == 2)
  }
}

struct MarkdownRenderEngineTests {
  @Test
  func keepsActiveBlockAsRawMarkdown() {
    let source = """
      # Title

      - **bold** item
      """

    let blocks = BlockResolver.resolveBlocks(in: source)
    let engine = MarkdownRenderEngine()
    let snapshot = engine.snapshot(for: source, blocks: blocks, activeBlockIndex: 2)

    let active = snapshot.segments.first(where: { $0.isActive })
    #expect(active != nil)

    if let active {
      let activeText = (snapshot.displayText as NSString).substring(with: active.displayRange)
      #expect(activeText.contains("**bold**"))
    }

    #expect(snapshot.displayText.contains("Title"))
    #expect(!snapshot.displayText.contains("# Title"))
  }

  @Test
  func stripsMarkdownFromPassiveListItems() {
    let source = "- [link](https://example.com)\n"
    let blocks = BlockResolver.resolveBlocks(in: source)
    let engine = MarkdownRenderEngine()
    let snapshot = engine.snapshot(for: source, blocks: blocks, activeBlockIndex: nil)

    #expect(snapshot.displayText == "• link\n")
  }

  @Test
  func preservesOrderedListNumbersForPassiveItems() {
    let source = "3. [link](https://example.com)\n"
    let blocks = BlockResolver.resolveBlocks(in: source)
    let engine = MarkdownRenderEngine()
    let snapshot = engine.snapshot(for: source, blocks: blocks, activeBlockIndex: nil)

    #expect(snapshot.displayText == "3. link\n")
  }

  @Test
  func preservesOrderedListPrefixWithoutEscapeArtifacts() {
    let source = "3. **bold** item\n"
    let blocks = BlockResolver.resolveBlocks(in: source)
    let engine = MarkdownRenderEngine()
    let snapshot = engine.snapshot(for: source, blocks: blocks, activeBlockIndex: nil)

    #expect(snapshot.displayText == "3. bold item\n")
    #expect(!snapshot.displayText.contains("\\."))
  }

  @Test
  func normalizesCRLFLineEndingsInPassiveBlocks() {
    let source = "line one\r\nline two\r\n"
    let blocks = BlockResolver.resolveBlocks(in: source)
    let engine = MarkdownRenderEngine()
    let snapshot = engine.snapshot(for: source, blocks: blocks, activeBlockIndex: nil)

    #expect(snapshot.displayText == "line one\nline two\n")
    #expect(!snapshot.displayText.contains("\r"))
  }

  @Test
  func normalizesCRLFLineEndingsInBlankBlocks() {
    let source = "\r\ntext\r\n"
    let blocks = BlockResolver.resolveBlocks(in: source)
    let engine = MarkdownRenderEngine()
    let snapshot = engine.snapshot(for: source, blocks: blocks, activeBlockIndex: nil)

    #expect(snapshot.displayText == "\ntext\n")
    #expect(!snapshot.displayText.contains("\r"))
  }
}

struct RenderInvalidationPlannerTests {
  @Test
  func returnsOldAndNewActiveIndexes() {
    let invalidated = RenderInvalidationPlanner.invalidatedBlockIndexes(
      previousActive: 1, newActive: 4)
    #expect(invalidated == Set([1, 4]))
  }

  @Test
  func handlesSingleActiveIndex() {
    let invalidated = RenderInvalidationPlanner.invalidatedBlockIndexes(
      previousActive: nil, newActive: 2)
    #expect(invalidated == Set([2]))
  }
}

struct SnapshotLocationMapperTests {
  @Test
  func mapsBetweenDisplayAndSourceWithMismatchedRanges() {
    let snapshot = RenderSnapshot(
      displayText: "Title\n",
      segments: [
        DisplaySegment(
          sourceRange: NSRange(location: 0, length: 8),
          displayRange: NSRange(location: 0, length: 6),
          kind: .heading,
          isActive: false
        )
      ]
    )
    let mapper = SnapshotLocationMapper(snapshot: snapshot, sourceLength: 8)

    #expect(mapper.sourceLocation(forDisplayLocation: 0) == 0)
    #expect(mapper.sourceLocation(forDisplayLocation: 5) <= 8)
    #expect(mapper.displayLocation(forSourceLocation: 8) == 6)
    #expect(mapper.displayLocation(forSourceLocation: 0) == 0)
  }

  @Test
  func mapsBoundaryToStartOfNextSegment() {
    let snapshot = RenderSnapshot(
      displayText: "Title\nBody\n",
      segments: [
        DisplaySegment(
          sourceRange: NSRange(location: 0, length: 8),
          displayRange: NSRange(location: 0, length: 6),
          kind: .heading,
          isActive: false
        ),
        DisplaySegment(
          sourceRange: NSRange(location: 8, length: 5),
          displayRange: NSRange(location: 6, length: 5),
          kind: .paragraph,
          isActive: true
        ),
      ]
    )
    let mapper = SnapshotLocationMapper(snapshot: snapshot, sourceLength: 13)

    #expect(mapper.displayLocation(forSourceLocation: 8) == 6)
    #expect(mapper.sourceLocation(forDisplayLocation: 6) == 8)
  }
}

private struct InactiveSnapshotGenerator: SnapshotGenerating {
  func snapshot(
    for source: String,
    blocks: [MarkdownBlock],
    activeBlockIndex: Int?
  ) -> RenderSnapshot {
    let sourceLength = (source as NSString).length
    return RenderSnapshot(
      displayText: "Rendered\n",
      segments: [
        DisplaySegment(
          sourceRange: NSRange(location: 0, length: sourceLength),
          displayRange: NSRange(location: 0, length: 9),
          kind: .paragraph,
          isActive: false
        )
      ]
    )
  }
}

struct EditorModelTests {
  @Test
  func switchesActiveBlockFromDisplayLocation() {
    let source = """
      # Header

      - [item](https://example.com)
      """
    var model = EditorModel(sourceText: source, initialSourceCaret: 0)

    #expect(model.snapshot.displayText.contains("• item"))
    #expect(model.activeBlockIndex == 0)

    let renderedListLocation = (model.snapshot.displayText as NSString).range(of: "• item").location
    let sourceCaret = model.moveActiveContext(toDisplayLocation: renderedListLocation)

    #expect(sourceCaret > 0)
    #expect(model.snapshot.activeSegment != nil)
    #expect(model.snapshot.displayText.contains("- [item](https://example.com)"))
  }

  @Test
  func appliesEditToActiveBlockAndPreservesOtherBlocks() {
    let source = """
      # Header

      - [item](https://example.com)
      """
    var model = EditorModel(sourceText: source, initialSourceCaret: 0)
    let renderedListLocation = (model.snapshot.displayText as NSString).range(of: "• item").location
    _ = model.moveActiveContext(toDisplayLocation: renderedListLocation)

    let activeSegment = model.snapshot.activeSegment
    #expect(activeSegment != nil)

    if let activeSegment {
      let liveDisplay = NSMutableString(string: model.snapshot.displayText)
      liveDisplay.replaceCharacters(
        in: activeSegment.displayRange,
        with: "- [edited](https://example.com)"
      )

      _ = model.applyDisplayEdit(
        liveDisplayText: liveDisplay as String,
        selectionDisplayLocation: activeSegment.displayRange.location + 4
      )

      #expect(model.sourceText.contains("- [edited](https://example.com)"))
      #expect(model.sourceText.contains("# Header"))
    }
  }

  @Test
  func allowsEditsOnlyInsideActiveDisplayRange() {
    let source = """
      # Header

      body
      """
    var model = EditorModel(sourceText: source, initialSourceCaret: 0)
    let bodyLocation = (model.snapshot.displayText as NSString).range(of: "body").location
    _ = model.moveActiveContext(toDisplayLocation: bodyLocation)

    let activeRange = model.snapshot.activeSegment?.displayRange
    #expect(activeRange != nil)
    let disallowedRange = NSRange(location: 0, length: 1)

    if let activeRange {
      #expect(model.canEdit(displayRange: activeRange))
    }
    #expect(!model.canEdit(displayRange: disallowedRange))
  }

  @Test
  func doesNotOverwriteSourceWhenNoActiveSegmentExists() {
    let originalSource = "- **original**\n"
    var model = EditorModel(
      sourceText: originalSource,
      initialSourceCaret: 0,
      snapshotGenerator: InactiveSnapshotGenerator()
    )

    _ = model.applyDisplayEdit(
      liveDisplayText: "Rendered changed\n",
      selectionDisplayLocation: 4
    )

    #expect(model.sourceText == originalSource)
  }
}
