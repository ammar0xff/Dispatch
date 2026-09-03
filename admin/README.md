# Dispatch — admin

The supervisor dashboard for **Dispatch** (part of the merged monorepo, `/admin`).

Supervisors generate QR codes for new agents and sites, create user accounts and assign named tasks, watch all workers' live locations on a map, and receive real-time local notifications the moment an agent marks a task done.

## Features
- **QR generator** (qr_flutter) for new agents / sites (name, location, phone, category).
- **User management**: create accounts and assign tasks.
- **Live dashboard**: users on a map with task-completion notifications.
- Task list and completion tracking shared with the client via Firebase.

## Build
```sh
cd admin
flutter pub get
flutter run
```

Firebase config (project `wirya-qr`) lives in `lib/firebase_options.dart` and `firebase.json`.