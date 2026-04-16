# Zzz

Zzz is a minimalist macOS menu bar multi-event countdown tool designed to keep you on track with a native and elegant interface.

[中文版](./README.md)

## Key Features

- **Multi-Event Support**: Not just for bedtime anymore! Create multiple custom countdowns for sleep, workouts, hydration, and more.
- **Emoji Icons**: Assign Emoji icons to each event with a built-in search picker for quick identification.
- **Native Experience**: Built with SwiftUI and AppKit, featuring system-standard materials, animations, and typography.
- **Smart Scheduling**: Handles overnight schedules (4:30 AM logic split) to perfectly match late-night habits.
- **Modern UI**: Completely redesigned card-style interface with flexible weekday recurrence settings.
- **Status Bar Display**: Includes a compact mode and smart time simplification as goals approach.
- **Desktop Widget**: Built with WidgetKit, stay updated with your countdowns directly on your desktop.
- **Visual Alerts**: The countdown turns red when approaching or passing your goal.
- **Quick Action**: Right-click the menu bar item to quit the application instantly.

## Installation

1. Download Zzz.dmg from the Releases page or build it from source.
2. Open the DMG and drag Zzz to your Applications folder.
3. Launch the application to see the countdown in your menu bar.

## Development

### Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- XcodeGen

### Building from Source

1. Clone the repository.
2. Install XcodeGen if you haven't already: `brew install xcodegen`.
3. Generate the Xcode project by running: `xcodegen generate`.
4. Open `Zzz.xcodeproj` and build the project using the Zzz scheme.

## License

MIT License
