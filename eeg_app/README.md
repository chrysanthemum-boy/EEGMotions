# EEGMotions - EEG Stress Monitor App

EEGMotions is a Flutter-based mobile application that provides real-time EEG monitoring and stress level analysis. The app integrates with EEG devices via Bluetooth and offers a comprehensive suite of features for emotional wellness monitoring.

## Features

### 1. Real-time EEG Monitoring
- Live EEG data visualization
- Stress level analysis and display
- Multi-channel EEG data processing
- Connection status monitoring

### 2. Robot Dog Integration
- Remote control of robot dog
- Multiple control modes:
  - Freeze mode
  - Dance mode
  - Stop mode
- Network-based communication

### 3. User Interface
- Modern Material Design 3 interface
- Intuitive bottom navigation
- Four main sections:
  - Monitor: Real-time stress monitoring
  - Display: EEG data visualization
  - Robot Dog: Robot control interface
  - Settings: App configuration

### 4. Technical Features
- Bluetooth connectivity for EEG devices
- CoreML integration for stress analysis
- Voice feedback system
- Multi-language support
- Cross-platform compatibility (iOS, Android, Web)

## Getting Started

### Prerequisites
- Flutter SDK (>=2.19.4)
- Dart SDK (>=2.19.4)
- Bluetooth-enabled device
- EEG headset (optional for simulation mode)

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Configuration

### Bluetooth Setup
- Enable Bluetooth on your device
- Grant necessary permissions
- Connect to your EEG device

### Robot Dog Setup
- Ensure robot dog is powered on
- Connect to the same network
- Configure IP address in settings

## Development

### Project Structure
- `lib/`: Main application code
  - `pages/`: UI screens
  - `provider/`: State management
  - `services/`: Core functionality
  - `widgets/`: Reusable components

### Dependencies
- flutter_blue_plus: Bluetooth connectivity
- provider: State management
- http: Network communication
- flutter_localizations: Internationalization

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the repository or contact the development team.
