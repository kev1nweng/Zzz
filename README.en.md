[中文版](./README.md)

# Zzz

Zzz is a minimalist macOS menu bar application designed to help you track your remaining time before bedtime with a native and elegant interface.

## Key Features

- Native macOS Experience: Built using SwiftUI and AppKit with system-standard liquid glass materials and transitions.
- Smart Bedtime Algorithm: Automatically handles sleep schedules that cross into the next day (using an 8 AM logic split). It distinguishes between weekday and weekend nights.
- Temporary Override: Quickly set a one-time bedtime for the current night without affecting your recurring settings.
- Menu Bar Display: A real-time countdown directly in your status bar. It includes a compact mode that hides the icon and simplifies the time display (hours only, or minutes when under an hour).
- Desktop Widget: A WidgetKit-powered desktop widget that stays in sync with your main application settings via App Groups.
- Visual Alerts: The countdown turns red when you are within one hour of bedtime or if you have stayed up past your scheduled time.
- Right-click Context Menu: Provides a quick way to quit the application directly from the menu bar.

## Installation

1. Download the Zzz.dmg from the releases or build it from source.
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
