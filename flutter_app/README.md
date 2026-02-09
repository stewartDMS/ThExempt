# ThExempt Flutter App

Simple Flutter mobile app with authentication for ThExempt.

## Features

✅ Login with email/password
✅ Signup with name/email/password
✅ Secure token storage
✅ Auto-login on app restart
✅ Modern UI matching web app theme
✅ Connects to existing Express backend

## Setup

### Prerequisites
- Flutter SDK 3.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- ThExempt backend running on port 5000

### Installation

1. Navigate to the Flutter app directory:
   ```bash
   cd flutter_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. **Configure API URL:**
   
   Open `lib/main.dart` and update the `apiUrl` variable based on your setup:
   
   - **iOS Simulator:** `'http://localhost:5000/api'`
   - **Android Emulator:** `'http://10.0.2.2:5000/api'`
   - **Physical Device:** `'http://YOUR_COMPUTER_IP:5000/api'`
   
   Update it in TWO places:
   - Line 89 (LoginScreen)
   - Line 319 (SignupScreen)

4. Run the app:
   ```bash
   flutter run
   ```

## Usage

1. **Start Backend:**
   ```bash
   cd ..
   npm start
   ```

2. **Run Flutter App:**
   ```bash
   cd flutter_app
   flutter run
   ```

3. **Choose Platform:**
   - Web: `flutter run -d chrome`
   - Android: `flutter run -d android`
   - iOS: `flutter run -d ios`

## Testing

1. **Sign Up:** Create a new account
2. **Login:** Sign in with existing credentials
3. **Home:** View welcome screen with user info
4. **Logout:** Sign out and return to login
5. **Auto-Login:** Close and reopen app (should stay logged in)

## Troubleshooting

### Cannot connect to server

**Problem:** App shows "Cannot connect to server"

**Solutions:**
- Ensure backend is running (`npm start` in main directory)
- Check API URL in `lib/main.dart`:
  - Android emulator CANNOT use `localhost`, use `10.0.2.2` instead
  - Physical devices need your computer's actual IP address
- Run `flutter clean` then `flutter pub get`

### Getting your computer's IP (for physical devices)

**Windows:**
```powershell
ipconfig
# Look for "IPv4 Address"
```

**Mac/Linux:**
```bash
ifconfig
# Look for "inet" under your active connection
```

Then update `apiUrl` to `'http://YOUR_IP:5000/api'`

## Project Structure

```
flutter_app/
├── lib/
│   └── main.dart          # Complete app (auth + UI)
├── pubspec.yaml           # Dependencies
└── README.md              # This file
```

## Next Steps

After authentication is working:
- Add projects feed
- Add create project functionality
- Add video upload
- Add user profiles
- Add user discovery

## Tech Stack

- **Flutter 3.x** - UI framework
- **http** - API calls to Express backend
- **shared_preferences** - Local token storage
- **Material Design 3** - Modern UI components

## API Integration

This app connects to the Express backend at:
- `POST /api/auth/signup` - Create account
- `POST /api/auth/login` - Authenticate user

Auth token is stored locally and sent with future API requests.

## Support

- [Flutter Documentation](https://docs.flutter.dev)
- [Flutter Installation](https://docs.flutter.dev/get-started/install)
- [ThExempt Backend](../server/index.js)
