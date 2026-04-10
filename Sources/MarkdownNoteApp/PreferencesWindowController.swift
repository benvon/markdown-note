import AppKit
import Foundation

@MainActor
final class PreferencesWindowController: NSWindowController {
  private let sourceFontPopup = NSPopUpButton(frame: .zero, pullsDown: false)
  private let renderedFontPopup = NSPopUpButton(frame: .zero, pullsDown: false)
  private let fontSizeSlider = NSSlider(
    value: 14,
    minValue: 10,
    maxValue: 30,
    target: nil,
    action: nil
  )
  private let fontSizeLabel = NSTextField(labelWithString: "14")

  private let textColorWell = NSColorWell(frame: .zero)
  private let backgroundColorWell = NSColorWell(frame: .zero)
  private let secondaryColorWell = NSColorWell(frame: .zero)

  init() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 460, height: 320),
      styleMask: [.titled, .closable],
      backing: .buffered,
      defer: false
    )
    window.title = "Settings"
    window.isReleasedWhenClosed = false

    super.init(window: window)

    setupUI(in: window)
    loadFromSettings()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func show() {
    guard let window else {
      return
    }

    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func setupUI(in window: NSWindow) {
    let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
    window.contentView = contentView

    let stack = NSStackView()
    stack.orientation = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -20),
    ])

    for option in AppSettings.sourceFontOptions {
      sourceFontPopup.addItem(withTitle: option.label)
      sourceFontPopup.lastItem?.representedObject = option.value
    }

    for option in AppSettings.renderedFontOptions {
      renderedFontPopup.addItem(withTitle: option.label)
      renderedFontPopup.lastItem?.representedObject = option.value
    }

    sourceFontPopup.target = self
    sourceFontPopup.action = #selector(saveFromControls)

    renderedFontPopup.target = self
    renderedFontPopup.action = #selector(saveFromControls)

    fontSizeSlider.target = self
    fontSizeSlider.action = #selector(saveFromControls)

    textColorWell.target = self
    textColorWell.action = #selector(saveFromControls)

    backgroundColorWell.target = self
    backgroundColorWell.action = #selector(saveFromControls)

    secondaryColorWell.target = self
    secondaryColorWell.action = #selector(saveFromControls)

    stack.addArrangedSubview(makeRow(label: "Source Typeface", control: sourceFontPopup))
    stack.addArrangedSubview(makeRow(label: "Rendered Typeface", control: renderedFontPopup))
    stack.addArrangedSubview(makeFontSizeRow())
    stack.addArrangedSubview(makeRow(label: "Text Color", control: textColorWell))
    stack.addArrangedSubview(makeRow(label: "Background Color", control: backgroundColorWell))
    stack.addArrangedSubview(makeRow(label: "Secondary Color", control: secondaryColorWell))
  }

  private func makeRow(label: String, control: NSView) -> NSView {
    let row = NSStackView()
    row.orientation = .horizontal
    row.alignment = .centerY
    row.spacing = 12

    let labelField = NSTextField(labelWithString: label)
    labelField.font = NSFont.systemFont(ofSize: 13, weight: .medium)

    labelField.setContentHuggingPriority(.required, for: .horizontal)
    control.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    row.addArrangedSubview(labelField)
    row.addArrangedSubview(control)
    return row
  }

  private func makeFontSizeRow() -> NSView {
    let sliderStack = NSStackView()
    sliderStack.orientation = .horizontal
    sliderStack.alignment = .centerY
    sliderStack.spacing = 8

    fontSizeLabel.alignment = .right
    fontSizeLabel.frame = NSRect(x: 0, y: 0, width: 40, height: 20)
    fontSizeLabel.setContentHuggingPriority(.required, for: .horizontal)

    sliderStack.addArrangedSubview(fontSizeSlider)
    sliderStack.addArrangedSubview(fontSizeLabel)

    return makeRow(label: "Font Size", control: sliderStack)
  }

  private func loadFromSettings() {
    let settings = AppSettings.shared

    select(popup: sourceFontPopup, value: settings.sourceFontName)
    select(popup: renderedFontPopup, value: settings.renderedFontName)

    fontSizeSlider.doubleValue = Double(settings.fontSize)
    fontSizeLabel.stringValue = String(Int(settings.fontSize.rounded()))

    textColorWell.color = settings.textColor
    backgroundColorWell.color = settings.backgroundColor
    secondaryColorWell.color = settings.secondaryTextColor
  }

  @objc
  private func saveFromControls() {
    fontSizeLabel.stringValue = String(Int(fontSizeSlider.doubleValue.rounded()))

    AppSettings.shared.update(
      sourceFontName: selectedValue(from: sourceFontPopup),
      renderedFontName: selectedValue(from: renderedFontPopup),
      fontSize: CGFloat(fontSizeSlider.doubleValue),
      textColor: textColorWell.color,
      backgroundColor: backgroundColorWell.color,
      secondaryTextColor: secondaryColorWell.color
    )
  }

  private func selectedValue(from popup: NSPopUpButton) -> String {
    guard let raw = popup.selectedItem?.representedObject as? String else {
      return ""
    }

    return raw
  }

  private func select(popup: NSPopUpButton, value: String) {
    let index = popup.indexOfItem(withRepresentedObject: value)

    if index >= 0 {
      popup.selectItem(at: index)
    } else {
      popup.selectItem(at: 0)
    }
  }
}

extension NSPopUpButton {
  fileprivate func indexOfItem(withRepresentedObject value: String) -> Int {
    for index in 0..<numberOfItems {
      if item(at: index)?.representedObject as? String == value {
        return index
      }
    }

    return -1
  }
}
