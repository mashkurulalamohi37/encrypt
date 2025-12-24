# 🔐 Encrypted Messenger

A secure, end-to-end encrypted messaging application built with Flutter, featuring Signal Protocol encryption, group chat, and biometric security.

![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

### 🔒 Security & Privacy
- **End-to-End Encryption** using Signal Protocol (E2EE)
- **Biometric Authentication** (Fingerprint/Face unlock)
- **Encrypted Database** with SQLCipher
- **Panic Button** for emergency data wipe
- **Tor Integration** for anonymous communication
- **Perfect Forward Secrecy** with key rotation

### 💬 Messaging
- **Direct Messaging** with real-time encryption
- **Group Chat** with multi-user encryption
- **Message History** with encrypted storage
- **Read Receipts** and timestamps
- **Contact Management** with public key verification

### 🎨 User Interface
- **Premium Dark Theme** with gradients and glassmorphism
- **Modern Material Design** with smooth animations
- **Responsive Layout** optimized for mobile
- **Intuitive Navigation** with tabs and FAB
- **Empty States** with helpful guidance

### 🛡️ Advanced Features
- **Signal Protocol Implementation**
  - X3DH Key Agreement
  - Double Ratchet Algorithm
  - Prekey bundles
  - Session management
- **Group Encryption**
  - Sender Keys Protocol
  - Admin/Member roles
  - Dynamic member management
- **Network Security**
  - WebRTC for P2P communication
  - TURN/STUN server support
  - Tor hidden services

## 📱 Screenshots

*Coming soon*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.27 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Android device with fingerprint sensor (for biometric features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mashkurulalamohi37/encrypt.git
   cd encrypt
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate database code**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

### Core Components

```
lib/
├── core/
│   ├── database/          # Drift database with encryption
│   ├── encryption/        # Signal Protocol implementation
│   ├── security/          # Biometric auth & panic service
│   ├── storage/           # Secure storage service
│   ├── network/           # Tor & WebRTC services
│   └── group/             # Group chat service
├── ui/
│   ├── screens/           # App screens
│   └── theme/             # App theme & styling
└── main.dart              # App entry point
```

### Database Schema

**Direct Messaging:**
- `messages` - Encrypted messages
- `contacts` - User contacts with public keys
- `sessions` - Signal Protocol sessions
- `prekeys` - Prekey bundles
- `signed_prekeys` - Signed prekeys

**Group Chat:**
- `groups` - Group information
- `group_members` - Member management with roles
- `group_messages` - Encrypted group messages

## 🔐 Security Features

### Signal Protocol
The app implements the Signal Protocol for end-to-end encryption:

1. **Key Exchange (X3DH)**
   - Identity keys (long-term)
   - Signed prekeys (medium-term)
   - One-time prekeys (ephemeral)

2. **Double Ratchet**
   - Forward secrecy
   - Break-in recovery
   - Message key derivation

3. **Session Management**
   - Automatic session creation
   - Key rotation
   - Session persistence

### Biometric Lock
- Optional fingerprint/face authentication
- Locks app when backgrounded
- Respects system biometric settings
- Graceful fallback handling

### Data Protection
- SQLCipher encrypted database
- Secure key storage with flutter_secure_storage
- Panic button for emergency wipe
- No plaintext data on disk

## 📚 Documentation

- [Implementation Plan](IMPLEMENTATION_PLAN.md) - Development roadmap
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Production deployment
- [UI Enhancements](UI_ENHANCEMENTS.md) - Design system
- [Group Chat Plan](GROUP_CHAT_PLAN.md) - Group chat architecture
- [Biometric Troubleshooting](BIOMETRIC_TROUBLESHOOTING.md) - Debug guide

## 🛠️ Technologies Used

### Flutter Packages
- **drift** - Type-safe database with encryption
- **libsignal_protocol_dart** - Signal Protocol implementation
- **local_auth** - Biometric authentication
- **flutter_secure_storage** - Secure key storage
- **provider** - State management
- **uuid** - Unique identifiers
- **intl** - Internationalization

### Backend Services
- **Tor** - Anonymous networking
- **WebRTC** - Peer-to-peer communication
- **TURN/STUN** - NAT traversal

## 🎯 Roadmap

### Phase 1: Core Messaging ✅
- [x] Signal Protocol implementation
- [x] Direct messaging
- [x] Encrypted database
- [x] Contact management

### Phase 2: Group Chat ✅
- [x] Group creation
- [x] Multi-user encryption
- [x] Member management
- [x] Admin controls

### Phase 3: Security ✅
- [x] Biometric lock
- [x] Panic button
- [x] Secure storage

### Phase 4: Advanced Features 🚧
- [ ] Voice/video calls
- [ ] File sharing
- [ ] Message reactions
- [ ] Push notifications
- [ ] Multi-device support

### Phase 5: Polish 📋
- [ ] Comprehensive testing
- [ ] Performance optimization
- [ ] Accessibility improvements
- [ ] Localization

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Signal Protocol](https://signal.org/docs/) - Encryption protocol
- [Flutter](https://flutter.dev/) - UI framework
- [Drift](https://drift.simonbinder.eu/) - Database library
- [Tor Project](https://www.torproject.org/) - Anonymous networking

## 📧 Contact

Mashkurulalamohi37 - [@mashkurulalamohi37](https://github.com/mashkurulalamohi37)

Project Link: [https://github.com/mashkurulalamohi37/encrypt](https://github.com/mashkurulalamohi37/encrypt)

---

**⚠️ Security Notice:** This is an educational project. While it implements industry-standard encryption protocols, it has not undergone a professional security audit. Use at your own risk for production applications.

**Made with ❤️ and Flutter**
