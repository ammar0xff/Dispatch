# Dispatch

QR-based field-work supervision platform. A supervisor issues QR codes, dispatches tasks to field agents, and watches live worker locations on a map; agents scan QR codes to confirm works on site and report geo-verified completion in real time.

> Merged from `wirya_qr_client` + `wirya_qr_admin` into a single monorepo.

## Repo layout

```
Dispatch/
├── client/   Field agent app (Dart / Flutter)
│   ├── lib/
│   │   ├── screens/     login, dashboard (map), tasks, QR scanner, about, lock-check
│   │   └── utils/       permissions, location service, telegram logger, battery handler
│   ├── android/  ios/  linux/  macos/  web/  windows/
│   └── pubspec.yaml
└── admin/     Supervisor dashboard (Dart / Flutter)
    ├── lib/
    │   ├── models/      user + task model
    │   ├── screens/     dashboard (live users), QR generator, users management, tasks
    │   └── *.dart       main, about, live location, profile edit, lock-check
    ├── android/  ios/  macos/  web/  windows/
    └── pubspec.yaml
```

## What each app does

### client — the field agent's scanner
- Logs in against Firebase, pulls tasks assigned to the logged-in agent.
- **QR scanner** confirms work on site; completion is written back to Firebase.
- Live GPS location streamed to a **Flutter Map** on the dashboard.
- Runs in the background, keeps the screen awake, and pings a **Telegram logger** with activity.
- Handles permission, battery-optimization, and background-service setup.

### admin — the supervisor's dashboard
- **QR generator** produces scannable codes for new agents / sites (name, location, phone, category).
- **User management** creates accounts + assigns named tasks.
- **Live dashboard** watches users on a map and pushes **local notifications** the moment a task is marked done.
- Task list and completion tracking shared with the client through Firebase.

## Stack
- **Flutter / Dart** for both clients.
- **Firebase** (Firestore + Realtime Database, `wirya-qr` project) as the shared backend.

## Build
Each app is a standard Flutter project and builds independently:

```sh
# field agent app
cd client && flutter pub get && flutter run

# supervisor app
cd admin && flutter pub get && flutter run
```

## License
[MIT](LICENSE)