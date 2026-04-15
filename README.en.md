# Zzz

Zzz is a minimalist macOS menu bar countdown tool designed to remind you of your bedtime with a native and elegant interface.

[中文版](./README.md)

## Key Features

- Native Experience: Built with SwiftUI and AppKit, featuring system-standard materials and animations.
- Smart Algorithm: Handles overnight schedules (8 AM logic split) and distinct weekday/weekend settings.
- One-time Override: Quickly set a temporary bedtime for tonight without changing recurring schedules.
- Status Bar Display: Includes a compact mode and smart time simplification when nearing bedtime.
- Desktop Widget: Built with WidgetKit, staying in sync with main app settings via App Groups.
- Visual Alerts: The countdown turns red when you approach or pass your scheduled bedtime.
- Quick Action: Right-click the menu bar item to quit the application instantly.

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
