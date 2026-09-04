# 🚀 Dispatch

**QR-based field-work supervision.** A supervisor dispatches tasks and issues QR codes; field agents scan them on site to confirm work, and their live GPS location is reported back in real time. Built as a single monorepo with two Flutter apps sharing one Firebase backend.

<p>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-%2302569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-%230175C2?logo=dart&logoColor=white">
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-%23FFCA28?logo=firebase&logoColor=black">
  <img alt="License" src="https://img.shields.io/badge/License-MIT-green">
</p>

---

## How it works

```
 Supervisor                      │   Firebase (Realtime DB)     │   Field agent
 --------------------------------┼──────────────────────────────┼──────────────────
 qr-generator ── creates QR ────►│                              │
 user mgmt ──── assigns tasks ──►│─────────────────────────────►│  login
 live map ◄────── locations ◄────│◄───── GPS stream ◄───────────│  background svc
 🔔 task-done notification ◄─────│◄───── scan + mark done ◄─────│  QR scanner
```

`admin` issues the work, `client` confirms it happened, and everyone sees it live.

## Monorepo layout

```
Dispatch/
├── client/   🧭 Field-agent app
│   ├── lib/
│   │   ├── screens/   login, dashboard (map), tasks, QR scanner, about, lock-check
│   │   └── utils/     permissions, location service, telegram logger, battery handler
│   └── android/ · ios/ · linux/ · macos/ · web/ · windows/
└── admin/    🎛️ Supervisor dashboard
    ├── lib/
    │   ├── models/    user + task
    │   ├── screens/   dashboard (live users), QR generator, users mgmt, tasks
    │   └── …          about, live location, profile edit, lock-check
    └── android/ · ios/ · macos/ · web/ · windows/
```

## The two apps

### 🧭 `client` — the field agent's scanner
- **Login** against Firebase Realtime DB (username/password).
- **QR scanner** (`mobile_scanner`) confirms work on site; completion writes back to Firebase immediately.
- **Live location** streamed to a **Flutter Map** on the dashboard.
- **Runs in the background** — keeps the screen awake, fires local notifications, and pings a **Telegram logger** with activity.
- Graceful **permission, battery-optimization, and background-service** handling.

### 🎛️ `admin` — the supervisor's dashboard
- **QR generator** (`qr_flutter`) produces scannable codes for new agents / sites — name, location, phone, category.
- **User management** creates accounts and assigns named tasks.
- **Live dashboard** watches every user on a map.
- **Instant alerts** — a local notification fires the moment an agent marks a task done.

## Stack

| Layer | Tool |
|-------|------|
| Clients | Flutter / Dart |
| Backend | Firebase Realtime Database (`wirya-qr` project) |
| Mapping | `flutter_map` + `latlong2` / `geolocator` |
| QR | `mobile_scanner` (client) · `qr_flutter` (admin) |
| Ops | `flutter_background_service`, `wakelock_plus`, Telegram logger |

## Getting started

Each app is a standard Flutter project and builds independently:

```sh
# 🧭 field agent app
cd client
flutter pub get
flutter run

# 🎛️ supervisor app
cd admin
flutter pub get
flutter run
```

Firebase config (project `wirya-qr`) lives in each app's `lib/firebase_options.dart` and `firebase.json`.

## License

[MIT](LICENSE) © 2026 ammar0xff