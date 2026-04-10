// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "markdown-note",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(
      name: "MarkdownNoteCore",
      targets: ["MarkdownNoteCore"]
    ),
    .executable(
      name: "MarkdownNoteApp",
      targets: ["MarkdownNoteApp"]
    ),
  ],
  targets: [
    .target(
      name: "MarkdownNoteCore"
    ),
    .executableTarget(
      name: "MarkdownNoteApp",
      dependencies: ["MarkdownNoteCore"]
    ),
    .testTarget(
      name: "MarkdownNoteCoreTests",
      dependencies: ["MarkdownNoteCore"]
    ),
  ]
)
