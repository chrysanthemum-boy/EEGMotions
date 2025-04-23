# EEG-Controlled Robot Dog System

This project consists of two main components: a robot dog backend system and a mobile EEG application. The system allows users to control a robot dog using brain signals captured through EEG (Electroencephalography).

## System Architecture

### Robot Dog Backend
The backend system is built using Python and runs on a Raspberry Pi 5. It handles:
- Bluetooth communication with the EEG headset
- Robot dog control using the Unitree GO1 API
- Real-time data processing and command execution
- WebSocket server for real-time communication with the mobile app

Key features:
- High-level control of the Unitree GO1 robot dog
- Bluetooth connectivity for EEG data acquisition
- Real-time command processing
- Safety protocols and error handling

### Mobile EEG Application
The mobile application is built using Flutter and provides:
- Real-time EEG data visualization
- User interface for controlling the robot dog
- Connection management with the backend
- Data logging and analysis

Key features:
- Cross-platform support (iOS and Android)
- Real-time EEG signal processing
- Intuitive control interface
- Data visualization and analysis tools

## Getting Started

### Prerequisites
- Raspberry Pi 5
- Unitree GO1 robot dog
- EEG headset with Bluetooth capability
- Flutter development environment
- Python 3.x

### Installation

#### Backend Setup
1. Clone the repository
2. Navigate to the `robot_backend` directory
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Configure the Bluetooth settings
5. Start the backend server:
   ```bash
   python app.py
   ```

#### Mobile App Setup
1. Navigate to the `eeg_app` directory
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Usage
1. Power on the robot dog
2. Start the backend server on the Raspberry Pi
3. Launch the mobile app
4. Connect the EEG headset
5. Use the app interface to control the robot dog

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
