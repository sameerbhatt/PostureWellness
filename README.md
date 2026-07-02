# Posture Wellness

A privacy-first macOS app that monitors your posture while working on your computer.

## Features

- 🎯 **Real-time Posture Analysis** - Uses Apple Vision framework to detect posture issues
- 🔔 **Smart Notifications** - Alerts you when posture deteriorates (configurable sensitivity)
- 📊 **Analytics Dashboard** - Track your posture trends over time
- 🎨 **Visual Feedback** - See exactly what issues were detected with skeletal overlay
- ⚙️ **Highly Configurable** - Adjust thresholds, intervals, and detection parameters
- 🔒 **Privacy First** - All processing happens locally, no data leaves your device, except analytics if chosen

## System Requirements

- macOS 11.0 (Big Sur) or later
- Built-in or external camera
- Recommended: macOS 13.0+ for full Analytics features

## Running the App

The app isn't notarized and Apple won't allow you to open it. You will get the following message - 

`"PostureWellness.app" can't be opened because 
Apple cannot check it for malicious software.`

Follow these steps to run it:
1. Go to System Settings → Privacy & Security
2. Scroll down to see `PostureWellness was blocked"`
3. Click `Open Anyway`
4. Enter the password when prompted
5. Confirm once more in the dialog
6. App starts to runs in the background.

## Building locally

1. Clone this repository
2. Open `PostureWellness.xcodeproj` in Xcode
3. Build and run (⌘R)

## Usage

1. **Grant camera permission** when prompted
2. **App runs in menu bar** - click icon to see status
3. **Automatic monitoring** - analyzes posture every 60 seconds (configurable)
4. **Get notifications** when posture issues detected
5. **View analytics** to track improvement over time

## Configuration

- **Settings Panel:** Click menu bar → Settings
- **Advanced Config:** Edit `posture_config.json` for fine-tuning thresholds
- **Notification Modes:** Silent, Gentle, Active, or Strict

## Architecture
```
PostureWellness/
├── Configuration/      # Config management & thresholds
├── Core/              # Vision analysis & posture calculation
├── Models/            # Data models (PostureReading, Issue)
├── Services/          # Monitoring, notifications, analytics
├── UI/                # SwiftUI views (menu bar, settings, dashboard)
└── Resources/         # Config files, assets
```

## Privacy

- All processing happens on-device
- Camera only activates during brief captures
- No images are stored (deleted after analysis)
- No data sent to external servers, except analytics if chosen

## Development

### Running Tests
```bash
# Run all tests
⌘U in Xcode

# Or via command line
xcodebuild test -scheme PostureWellness
```

### Test Coverage

- Configuration loading & validation
- Posture evaluation logic
- Issue detection & severity levels
- Analytics calculations

## Future Roadmap

- [ ] Exercise recommendations
- [ ] Break reminders
- [ ] Windows port
- [ ] iOS companion app
- [ ] Cloud sync (optional, encrypted)
- [ ] Custom posture profiles

## Feedback & Issues

Found a bug or have a feature request?

- Contributors: open an issue directly on [GitHub Issues](https://github.com/sameerbhatt/PostureWellness/issues)
- Everyone else: submit through this [feedback form](https://forms.gle/W3qZnc3ghGvaRowS6) — no GitHub account needed

## License

MIT License - See [LICENSE](LICENSE) file for details

## Author

Sameer Bhatt

Built with ❤️ for better posture and health
