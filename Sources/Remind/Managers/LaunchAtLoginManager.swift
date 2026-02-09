import ServiceManagement
import SwiftUI

@available(macOS 13.0, *)
class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool = false {
        didSet {
            toggle()
        }
    }
    
    init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    private func toggle() {
        do {
            if isEnabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
            // Revert on failure
            if isEnabled != (SMAppService.mainApp.status == .enabled) {
                print("Reverting UI state due to failure")
            }
        }
    }
}
