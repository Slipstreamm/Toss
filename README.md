# Toss - Simple LAN File Sharing

![Toss Logo](assets/icons/icon.png)

Toss is a lightweight, cross-platform application designed for quick and easy file sharing over Local Area Networks (LAN). Share files between your devices without the need for cloud services or internet connectivity.

## Features

- **Direct Device-to-Device Transfer**: Send files directly to other devices on the same network
- **No Internet Required**: Works completely offline on your local network
- **Cross-Platform**: Available for Windows, macOS, Linux, Android, and iOS
- **Simple Interface**: Easy-to-use interface with Send and Receive functionality
- **Customizable Settings**: Configure ports, save locations, and appearance
- **Dark Mode Support**: Choose between light, dark, or system theme
- **Multiple Theme Options**: Select from various color themes or create your own

## How to Use

### Sending Files

1. Open the app and navigate to the "Send" tab
2. Select a file you want to share
3. Enter the IP address of the receiving device
4. Click "Send File"

### Receiving Files

1. Open the app and navigate to the "Receive" tab
2. Click "Start Listening" to begin accepting incoming files
3. Your IP address will be displayed - share this with the sender
4. When a file is received, it will be saved to your default location

### Settings

Customize your experience with various options:

- Change theme and appearance
- Configure server and client ports
- Set default save location for received files
- Enable/disable confirmation dialogs
- Configure auto-start options

## Installation

### Windows

Download and run the installer from the [latest release](https://github.com/Slipstreamm/Toss/releases/latest).

### macOS

Download from the Apple App Store on Apple Silicon devices.

### Linux

Download the AppImage from the [latest release](https://github.com/Slipstreamm/Toss/releases/latest), make it executable, and run.

### Android

Download and install the APK from the [latest release](https://github.com/Slipstreamm/Toss/releases/latest).

### iOS

Download from the Apple App Store or install the IPA using sideloading apps like AltStore.

## Building from Source

### Prerequisites

- Flutter SDK (version 3.7.2 or higher)
- Dart SDK (version 3.7.2 or higher)
- Platform-specific development tools (Android Studio, Xcode, etc.)

### Steps

1. Clone the repository

   ```bash
   git clone https://github.com/Slipstreamm/Toss.git
   ```

2. Navigate to the project directory

   ```bash
   cd Toss
   ```

3. Get dependencies

   ```bash
   flutter pub get
   ```

4. Run the app in debug mode

   ```bash
   flutter run
   ```

5. Build for your platform

   ```bash
   flutter build <platform>
   ```

   Where `<platform>` is one of: apk, appbundle, ios, web, windows, macos, linux

## Privacy

Toss operates entirely on your local network and does not collect or transmit any data outside of your LAN. No user data is collected, stored, or shared with third parties.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Icon Credits

[Paper Waste](https://icons8.com/icon/65653/paper-waste) icon by [Icons8](https://icons8.com)
