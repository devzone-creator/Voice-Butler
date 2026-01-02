# Voice Butler - Chrome Web App Setup Guide

## Overview
Voice Butler has been converted from a Flutter mobile app to a Chrome web application. This guide will help you set up and run the application.

## Prerequisites
- Flutter SDK (3.10.0 or higher)
- Chrome browser (recommended for best Web Speech API support)
- Node.js (optional, for local development server)

## Key Changes Made

### 1. Removed Mobile-Only Dependencies
- `speech_to_text` → Replaced with Web Speech API
- `permission_handler` → Replaced with Web Permissions API
- `workmanager` → Replaced with web-compatible timer-based scheduling
- `flutter_local_notifications` → Replaced with Web Notifications API

### 2. Web-Compatible Services
- **VoiceService**: Uses Chrome's Web Speech API via JavaScript bridge
- **NotificationService**: Uses Web Notifications API
- **BackgroundService**: Uses JavaScript timers for scheduling

### 3. Conditional Imports
Services use conditional imports to automatically select the correct implementation:
- Web: `voice_service_web.dart`, `notification_service_web.dart`, `background_service_web_full.dart`
- Mobile: Stub files (can be implemented later if needed)

## Running the Application

### Development Mode
```bash
# Get dependencies
flutter pub get

# Run in Chrome
flutter run -d chrome
```

### Build for Production
```bash
# Build web app
flutter build web

# Serve the built files (in build/web directory)
# You can use any static file server or deploy to hosting service
```

## Chrome Browser Requirements

### Permissions
The app requires the following browser permissions:
1. **Microphone**: For voice input (requested when you first use voice features)
2. **Notifications**: For task reminders (requested when notifications are first used)

### Browser Compatibility
- ✅ Chrome 25+ (recommended)
- ✅ Edge 79+ (Chromium-based)
- ⚠️ Firefox: Limited Web Speech API support
- ❌ Safari: No Web Speech API support

## Important Notes

### HTTPS Requirement
Web Speech API requires HTTPS (or localhost for development). If deploying:
- Use HTTPS for production
- Chrome will block microphone access on HTTP sites (except localhost)

### Testing Voice Features
1. Open Chrome browser
2. Allow microphone permission when prompted
3. Click the voice input button
4. Speak clearly into your microphone
5. The speech will be converted to text automatically

### Troubleshooting

#### Voice Input Not Working
- Ensure you're using Chrome or Edge
- Check microphone permissions in Chrome settings
- Verify you're on HTTPS or localhost
- Try refreshing the page

#### Notifications Not Showing
- Allow notifications when Chrome prompts you
- Check Chrome notification settings
- Ensure you're not in a private/incognito window

#### Build Errors
- Run `flutter clean` and `flutter pub get`
- Ensure Flutter web support is enabled: `flutter config --enable-web`
- Check that all conditional imports are correct

## Project Structure

```
lib/
├── core/
│   ├── services/
│   │   ├── voice_service.dart (conditional export)
│   │   ├── voice_service_web.dart (web implementation)
│   │   ├── notification_service.dart (conditional export)
│   │   ├── notification_service_web.dart (web implementation)
│   │   ├── background_service.dart (conditional export)
│   │   └── background_service_web_full.dart (web implementation)
│   └── ...
web/
├── index.html (includes speech_recognition_bridge.js)
├── manifest.json (PWA manifest)
└── speech_recognition_bridge.js (Web Speech API bridge)
```

## Features Working on Web

✅ Voice input with speech-to-text  
✅ Task creation and management  
✅ AI intent extraction  
✅ Task automation rules  
✅ Activity feed  
✅ Local storage (Hive via IndexedDB)  
✅ Web notifications  
✅ Background scheduling (timer-based)  

## Known Limitations

1. **Background Jobs**: Limited to running only when the app is open (web limitation)
2. **Push Notifications**: Requires service worker for true background notifications
3. **Speech Recognition**: Only works in Chrome/Edge browsers
4. **Offline Support**: Basic offline support via IndexedDB, but AI features require internet

## Next Steps for Production

1. Set up HTTPS hosting
2. Implement Service Worker for better offline support
3. Add push notification support
4. Optimize bundle size
5. Set up analytics
6. Add error tracking

## Support

For issues or questions, refer to:
- Requirements: `.kiro/specs/voice-butler/requirements.md`
- Design: `.kiro/specs/voice-butler/design.md`
- Tasks: `.kiro/specs/voice-butler/tasks.md`

