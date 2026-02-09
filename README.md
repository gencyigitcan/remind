
# Remind

A simple, unobtrusive reminder application for macOS that lives in your menu bar. 

## Features
- **Menu Bar Integration**: Access your reminders quickly from the menu bar.
- **Clean Architecture**: Built with SwiftUI and a robust Clean Architecture pattern.
- **Persistence**: Reminders are saved automatically.
- **Notifications**: Get notified based on risk levels and due times.
- **Due Date Reminders**: Set a specific time for tasks and get notified 15m, 1h, and 3h before.

## Code Overview

### Architecture
This application follows a **Clean Architecture** pattern, leveraging SwiftUI for the UI and `NSStatusBar` for native menu bar integration. The goal is a lightweight, responsive, and persistent reminder system.

#### Core Components

1.  **RemindApp**: The main entry point (`@main`) managing the `NSApplicationDelegate`.
2.  **StatusBarManager**:
    *   Owns the `NSStatusBarItem`.
    *   Manages the `NSPopover` which hosts the SwiftUI view.
    *   Observes the `NoteStore` to update the menu bar title/color dynamically.
3.  **NoteStore**:
    *   Single source of truth for the app's state.
    *   Handles CRUD operations for `Note` objects.
    *   Manages persistence via `UserDefaults` (JSON encoding).
    *   Enforces business logic (max 5 active notes).
4.  **NotificationManager**:
    *   Handles `UNUserNotificationCenter` scheduling.
    *   schedules/cancels notifications based on risk level and snooze status.

### Data Models

#### RiskLevel (Enum)
*   `1 (Green)`: Low priority.
*   `2 (Yellow)`: Moderate.
*   `3 (Orange)`: High.
*   `4 (Red)`: Urgent.
*   `5 (Purple)`: Critical.

#### NoteStatus (Enum)
*   `active`: Currently visible in the list.
*   `completed`: Archived/Done.
*   `snoozed`: Hidden until a specific time.

#### Note (Struct - Identifiable, Codable)
*   `id`: UUID
*   `text`: String
*   `risk`: RiskLevel
*   `status`: NoteStatus
*   `createdAt`: Date
*   `completedAt`: Date?
*   `snoozeUntil`: Date?
*   `dueDate`: Date? (Triggers notifications 15m, 1h, 3h before)

### State Flow
User Action -> SwiftUI View -> NoteStore -> UserDefaults / NotificationManager -> StatusBarController -> macOS Menu Bar

## How to Build

1.  Make sure you have Swift installed.
2.  Run `swift build -c release` to build the executable.
3.  Run `./.build/release/Remind` to start the app.
