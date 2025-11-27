# DevQuotes

A modern Flutter application for discovering, sharing, and managing inspirational quotes. Built with Firebase for authentication, data storage, and push notifications.

## Features

- **Authentication**: Sign up and log in with email/password or Google Sign-In
- **Quote Management**: View, add, edit, and delete quotes
- **Categories**: Organize quotes by categories
- **Favorites**: Save your favorite quotes for quick access
- **Search**: Find quotes by keywords or categories
- **Daily Quotes**: Receive daily inspirational quotes via notifications
- **Profile Management**: Update your profile information
- **Settings**: Customize app preferences, including theme and notifications
- **Onboarding**: Guided setup for new users
- **Multi-Platform**: Supports Android, iOS, Web, Linux, macOS, and Windows

## Screenshots

<!-- Add screenshots here -->

## Installation

### Prerequisites

- Flutter SDK (version 3.0 or higher)
- Dart SDK
- Android Studio or Xcode for mobile development
- Firebase account

### Clone the Repository

```bash
git clone https://github.com/yourusername/devquotes-flutter.git
cd devquotes-flutter
```

### Install Dependencies

```bash
flutter pub get
```

## Firebase Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)

2. Add your apps:
   - Android app
   - iOS app
   - Web app

3. Download configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)

4. Configure FlutterFire:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

5. For Google Sign-In:
   - Add SHA-1 fingerprint to Firebase (Android)
   - Configure OAuth client IDs (iOS/Web)

6. For push notifications:
   - Set up APNs for iOS
   - Update Android manifest

## Running the App

### Development

```bash
flutter run
```

### Building for Production

#### Android APK
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## Project Structure

```
lib/
├── core/                 # Core utilities, services, and widgets
├── data/                 # Data layer (models, repositories, data sources)
├── features/             # Feature modules (auth, quotes, settings, etc.)
├── routes/               # App routing
└── main.dart             # App entry point
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

Run tests with:

```bash
flutter test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Powered by [Firebase](https://firebase.google.com/)
- Icons from [Material Design Icons](https://materialdesignicons.com/)

