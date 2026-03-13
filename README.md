# Remind 📅

A simple, unobtrusive reminder application for macOS that lives in your menu bar. 

## Features
- **Menu Bar Integration**: Access your reminders quickly from the menu bar.
- **Calendar Synchronization**: Automatically syncs today's meetings from your macOS Calendar.
- **Smart Notifications**: Get notified based on risk levels and due times (15m, 1h, and 3h before).
- **High Capacity**: Supports up to 10 active reminders simultaneously.
- **Persistence**: Reminders are saved automatically across sessions.
- **Clean Architecture**: Built with SwiftUI and a robust modular patterns.

## 🚀 How to Use

### Installation
1. Download the latest `Remind.dmg` from the [Releases](https://github.com/gencyigitcan/remind/releases) page.
2. Drag **Remind** to your Applications folder.
3. Open the app. You'll see a 📅 icon (or a number) in your menu bar.

### Calendar Sync
When you first open the app or click the menu icon, Remind will request access to your Calendar. Once granted, it will automatically pull in your meetings for the day as high-priority reminders. Calendar-sourced notes are marked with a small 📅 icon.

## 🛠 Tech Stack & Architecture

- **Swift & SwiftUI**: Native macOS development.
- **EventKit**: Deep integration with macOS Calendar events.
- **UserNotifications**: Customized, time-sensitive alerts with snooze/action support.
- **AppKit**: Native menu bar (NSStatusItem) and popover management.

### Core Components
- **CalendarManager**: Handles permissions and fetches `EKEvent` data.
- **NoteStore**: Logic for managing notes, preventing duplicates, and persistence.
- **NotificationManager**: Orchestrates local notifications and action handling.
- **StatusBarManager**: Manages the native macOS menu bar interface.

## 📦 Building from Source

If you want to build the app yourself:

1.  Clone the repository.
2.  Make sure you have Xcode or Swift installed.
3.  Run the build script:
    ```bash
    bash build_remind.sh
    ```
4.  The script will:
    - Build the executable in release mode.
    - Create a signed `.app` bundle.
    - Package everything into a `Remind.dmg`.

## License
MIT License - Copyright (c) 2024
