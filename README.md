# Remind 📅

A simple, unobtrusive reminder application for macOS that lives in your menu bar. 

[![Published on wvw.dev](https://img.shields.io/badge/Published%20on-wvw.dev-blueviolet?style=for-the-badge)](https://wvw.dev/#/productivity/remind)

## Features
- **Menu Bar Integration**: Access your reminders quickly from the menu bar.
- **Integrated Mini Calendar**: Control your schedule at a glance with a built-in calendar view.
- **Two-Way Calendar Synchronization**: Automatically syncs today's meetings *from* your calendar AND pushes manual reminders *to* your calendar.
- **Launch at Login**: Starts automatically when you turn on your Mac.
- **Smart Notifications**: Get notified based on risk levels and due times (15m, 1h, and 3h before).
- **High Capacity**: Supports up to 10 active reminders simultaneously.
- **Turkish Localization**: Friendly empty state messages in Turkish.
- **Persistence**: Reminders are saved automatically across sessions.

## 🚀 How to Use

### Installation
1. Download the latest `Remind.dmg` from the [Releases](https://github.com/gencyigitcan/remind/releases) page.
2. Drag **Remind** to your Applications folder.
3. Open the app. You'll see a 📅 icon (or a number) in your menu bar.

### Calendar Sync & Controls
#### Mini Calendar
Click the menu icon to open the popover. A full mini calendar is now integrated at the top, making it easy to check dates while managing tasks.

#### Fetching Events
Remind automatically pulls in your meetings for the day as high-priority reminders. Calendar-sourced notes are marked with a 📅 icon. If your day is clear, it will show a friendly "Bugün bir program yok" message.

#### Pushing Events
When you manually add a reminder with a **due time** set, Remind will automatically create a corresponding event in your macOS Calendar.

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
