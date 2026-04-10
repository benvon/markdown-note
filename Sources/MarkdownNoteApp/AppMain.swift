import AppKit
import Foundation

@main
struct MarkdownNoteMain {
  static func main() {
    let app = NSApplication.shared
    let delegate = AppDelegate()

    app.setActivationPolicy(.regular)
    app.delegate = delegate
    app.run()
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let documentController = NoteDocumentController.sharedController
  private lazy var preferencesWindowController = PreferencesWindowController()

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSWindow.allowsAutomaticWindowTabbing = true
    NSApp.windowsMenu = NSMenu(title: "Window")

    buildMainMenu()
    documentController.newDocument()
    NSApp.activate(ignoringOtherApps: true)
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }

  @objc func newDocument(_ sender: Any?) {
    documentController.newDocument()
  }

  @objc func openDocument(_ sender: Any?) {
    documentController.openDocumentWithPanel()
  }

  @objc func saveDocument(_ sender: Any?) {
    currentDocument()?.save(sender)
  }

  @objc func saveDocumentAs(_ sender: Any?) {
    currentDocument()?.saveAs(sender)
  }

  @objc func closeWindow(_ sender: Any?) {
    NSApp.keyWindow?.performClose(sender)
  }

  @objc func openSettings(_ sender: Any?) {
    preferencesWindowController.show()
  }

  private func currentDocument() -> NoteDocument? {
    if let controller = NSApp.keyWindow?.windowController as? DocumentWindowController {
      return controller.noteDocument
    }

    if let controller = NSApp.mainWindow?.windowController as? DocumentWindowController {
      return controller.noteDocument
    }

    return nil
  }

  private func buildMainMenu() {
    let mainMenu = NSMenu(title: "Main")
    mainMenu.addItem(makeAppMenuItem())
    mainMenu.addItem(makeFileMenuItem())
    NSApp.mainMenu = mainMenu
  }

  private func makeAppMenuItem() -> NSMenuItem {
    let appMenuItem = NSMenuItem()
    let appMenu = NSMenu(title: "Markdown Note")
    appMenuItem.submenu = appMenu

    appMenu.addItem(
      withTitle: "About Markdown Note",
      action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
      keyEquivalent: ""
    )
    let settingsItem = NSMenuItem(
      title: "Settings…",
      action: #selector(openSettings(_:)),
      keyEquivalent: ","
    )
    settingsItem.target = self
    appMenu.addItem(settingsItem)
    appMenu.addItem(.separator())
    appMenu.addItem(
      withTitle: "Quit Markdown Note", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    return appMenuItem
  }

  private func makeFileMenuItem() -> NSMenuItem {
    let fileMenuItem = NSMenuItem()
    let fileMenu = NSMenu(title: "File")
    fileMenuItem.submenu = fileMenu

    let newItem = NSMenuItem(title: "New", action: #selector(newDocument(_:)), keyEquivalent: "n")
    newItem.target = self
    fileMenu.addItem(newItem)

    let openItem = NSMenuItem(
      title: "Open…", action: #selector(openDocument(_:)), keyEquivalent: "o")
    openItem.target = self
    fileMenu.addItem(openItem)

    fileMenu.addItem(.separator())

    let saveItem = NSMenuItem(
      title: "Save", action: #selector(saveDocument(_:)), keyEquivalent: "s")
    saveItem.target = self
    fileMenu.addItem(saveItem)

    let saveAsItem = NSMenuItem(
      title: "Save As…", action: #selector(saveDocumentAs(_:)), keyEquivalent: "s")
    saveAsItem.keyEquivalentModifierMask = [.command, .shift]
    saveAsItem.target = self
    fileMenu.addItem(saveAsItem)

    fileMenu.addItem(.separator())

    let closeItem = NSMenuItem(
      title: "Close", action: #selector(closeWindow(_:)), keyEquivalent: "w")
    closeItem.target = self
    fileMenu.addItem(closeItem)
    return fileMenuItem
  }
}
