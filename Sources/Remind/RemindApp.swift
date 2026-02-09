import SwiftUI
import AppKit

// Main Entry Point
@main
struct RemindApp: App {
    // Use the AppDelegate to manage the lifecycle and status bar item
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We don't need a WindowGroup for a menu bar app
        Settings {
            EmptyView()
        }
    }
}

// AppDelegate handles the NSStatusBar and initial setup
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarManager: StatusBarManager?
    var noteStore: NoteStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app doesn't show in the Dock
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize the store
        let store = NoteStore()
        self.noteStore = store
        
        // Connect NotificationManager
        NotificationManager.shared.noteStore = store
        
        // Initialize the status bar manager
        self.statusBarManager = StatusBarManager(noteStore: store)
        
        print("Remind App Started - Check Menu Bar")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Optional cleanup
    }
}
