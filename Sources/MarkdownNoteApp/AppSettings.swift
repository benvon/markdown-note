import AppKit
import Foundation

@MainActor
final class AppSettings {
  static let shared = AppSettings()
  nonisolated static let didChangeNotification = Notification.Name("AppSettings.didChange")

  struct FontOption {
    let label: String
    let value: String
  }

  static let sourceFontOptions: [FontOption] = [
    FontOption(label: "Monospaced System", value: "__monospaced_system__"),
    FontOption(label: "Menlo", value: "Menlo"),
    FontOption(label: "Monaco", value: "Monaco"),
    FontOption(label: "Courier New", value: "Courier New"),
  ]

  static let renderedFontOptions: [FontOption] = [
    FontOption(label: "System", value: "__system__"),
    FontOption(label: "Helvetica Neue", value: "Helvetica Neue"),
    FontOption(label: "Avenir Next", value: "Avenir Next"),
    FontOption(label: "Times New Roman", value: "Times New Roman"),
    FontOption(label: "Georgia", value: "Georgia"),
  ]

  private enum Key {
    static let sourceFontName = "editor.sourceFontName"
    static let renderedFontName = "editor.renderedFontName"
    static let fontSize = "editor.fontSize"
    static let textColor = "editor.textColor"
    static let backgroundColor = "editor.backgroundColor"
    static let secondaryTextColor = "editor.secondaryTextColor"
  }

  private let defaults = UserDefaults.standard

  private init() {
    defaults.register(defaults: [
      Key.sourceFontName: "__monospaced_system__",
      Key.renderedFontName: "__system__",
      Key.fontSize: 14.0,
    ])
  }

  var sourceFontName: String {
    defaults.string(forKey: Key.sourceFontName) ?? "__monospaced_system__"
  }

  var renderedFontName: String {
    defaults.string(forKey: Key.renderedFontName) ?? "__system__"
  }

  var fontSize: CGFloat {
    CGFloat(defaults.double(forKey: Key.fontSize))
  }

  var textColor: NSColor {
    color(forKey: Key.textColor, fallback: .labelColor)
  }

  var backgroundColor: NSColor {
    color(forKey: Key.backgroundColor, fallback: .textBackgroundColor)
  }

  var secondaryTextColor: NSColor {
    color(forKey: Key.secondaryTextColor, fallback: .secondaryLabelColor)
  }

  var appearance: EditorAppearance {
    let size = min(max(fontSize, 10), 30)

    return EditorAppearance(
      sourceFont: makeSourceFont(name: sourceFontName, size: size),
      renderedFont: makeRenderedFont(name: renderedFontName, size: size),
      textColor: textColor,
      backgroundColor: backgroundColor,
      secondaryTextColor: secondaryTextColor
    )
  }

  func update(
    sourceFontName: String,
    renderedFontName: String,
    fontSize: CGFloat,
    textColor: NSColor,
    backgroundColor: NSColor,
    secondaryTextColor: NSColor
  ) {
    defaults.set(sourceFontName, forKey: Key.sourceFontName)
    defaults.set(renderedFontName, forKey: Key.renderedFontName)
    defaults.set(Double(fontSize), forKey: Key.fontSize)
    setColor(textColor, forKey: Key.textColor)
    setColor(backgroundColor, forKey: Key.backgroundColor)
    setColor(secondaryTextColor, forKey: Key.secondaryTextColor)

    NotificationCenter.default.post(name: AppSettings.didChangeNotification, object: nil)
  }

  private func makeSourceFont(name: String, size: CGFloat) -> NSFont {
    switch name {
    case "__monospaced_system__":
      return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    default:
      return NSFont(name: name, size: size)
        ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
  }

  private func makeRenderedFont(name: String, size: CGFloat) -> NSFont {
    switch name {
    case "__system__":
      return NSFont.systemFont(ofSize: size)
    default:
      return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)
    }
  }

  private func setColor(_ color: NSColor, forKey key: String) {
    guard
      let data = try? NSKeyedArchiver.archivedData(
        withRootObject: color.usingColorSpace(.deviceRGB) ?? color,
        requiringSecureCoding: true
      )
    else {
      return
    }

    defaults.set(data, forKey: key)
  }

  private func color(forKey key: String, fallback: NSColor) -> NSColor {
    guard let data = defaults.data(forKey: key),
      let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
    else {
      return fallback
    }

    return color
  }
}
