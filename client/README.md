# Dispatch — client

The field-agent app for **Dispatch** (part of the merged monorepo, `/client`).

Field agents log in against Firebase, receive assigned tasks, scan QR codes on site to confirm completion, and stream live GPS location back to the supervisor dashboard. Runs in the background with screen-awake and Telegram logging.

## Features
- Login (username/password against Firebase Realtime DB).
- Dashboard with live location on a **Flutter Map**.
- Task list with pull-to-refresh; completion written back to Firebase.
- **QR scanner** (mobile_scanner) to verify work on site.
- Background service + wakelock + local notifications.
- Telegram activity logger; permission & battery-optimization handling.

## Build
```sh
cd client
flutter pub get
flutter run
```

Firebase config (project `wirya-qr`) lives in `lib/firebase_options.dart` and `firebase.json`.