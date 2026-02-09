import AppKit
import SwiftUI
import Combine

class StatusBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var noteStore: NoteStore
    private var cancellables = Set<AnyCancellable>()

    init(noteStore: NoteStore) {
        self.noteStore = noteStore
        super.init()
        setupStatusBar()
        setupPopover()
        observeStore()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            updateMenuBarText()
        }
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.animates = true
        
        // Inject the store into the SwiftUI view environment
        let contentView = MenuView().environmentObject(noteStore)
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        self.popover = popover
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            // Also refresh snoozed notes when opening
            noteStore.refreshSnoozedNotes()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // Bring app to front
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func observeStore() {
        Publishers.Merge(noteStore.$notes.map { _ in () }, noteStore.$showCountOnly.map { _ in () })
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenuBarText()
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarText() {
        guard let button = statusItem?.button else { return }
        
        let active = noteStore.activeNotes
        
        if active.isEmpty {
            button.title = " Remind"
            // Reset to default color
            button.attributedTitle = NSAttributedString(string: " Remind", attributes: [.foregroundColor: NSColor.labelColor])
            return
        }
        
        guard let highest = active.first else { return }
        let color = NSColor(highest.risk.color)

        if noteStore.showCountOnly {
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: NSFont.systemFont(ofSize: 13, weight: .bold)
            ]
            let text = " \(active.count)"
            button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        } else {
            // Show highest risk note text
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: color,
                .font: NSFont.systemFont(ofSize: 13, weight: .medium)
            ]
            // Truncate if too long
            var cleanText = highest.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Prepend time if available
            if let dueDate = highest.dueDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                let timeString = formatter.string(from: dueDate)
                cleanText = "\(timeString) - \(cleanText)"
            }
            
            if cleanText.count > 25 {
                cleanText = String(cleanText.prefix(25)) + "..."
            }
            
            let attributedString = NSAttributedString(string: " " + cleanText, attributes: attributes)
            button.attributedTitle = attributedString
        }
    }
}
