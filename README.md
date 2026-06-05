<div align="center">

<img src="assets/icon/app_icon.png" alt="Keep Track" width="96" height="96"/>

# Keep Track

Personal finance, tasks, and productivity — all offline-first with cloud sync.

[![Flutter](https://img.shields.io/badge/Flutter-3.35-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart)](https://dart.dev)
[![Version](https://img.shields.io/badge/version-0.8.5-informational)]()
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

</div>

---

> **This is a private, invite-only project.** If you have access, welcome — this document covers everything you need to get up and running.

---

## Features

### Finance
- Zero-based budgeting with monthly budget profiles
- Transaction tracking with category breakdown
- Named savings buckets with contribution tracking
- Debt management with payoff schedules
- Savings goals with progress visualization
- Planned/recurring payments
- Subscription tracking
- Multi-currency support
- Transaction attachment photos

### App
- Offline-first — Hive is the local source of truth; syncs to backend when online
- Cloud backup & restore (encrypted, password-protected)
- Google OAuth + email/password authentication
- Dark/light theme
- Desktop title bar with feature flag panel, inbox, and sync status
- Push notifications (Windows/Android)
- Demo mode with sample data

### Platforms
| Platform | Status |
|---|---|
| Windows (x64) | ✅ |
| Android (APK) | ✅ |
| macOS | Builds, not actively tested |
| Linux | Builds, not actively tested |
| Web | Dev only (Chrome) |
| iOS | Not configured |

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | 3.35+ | `flutter --version` to check |
| Dart SDK | 3.9+ | Included with Flutter |
| Git | any | — |
| Python 3 | 3.10+ | For release builds only |
| Inno Setup 6 | 6.x | Windows installer only — [download](https://jrsoftware.org/isdl.php) |

You do **not** need a database, Docker, or any cloud account to run the app locally — it runs fully offline against Hive. To hit the real backend, you need access credentials (see [Environment setup](#environment-setup)).

---

## Getting Started

### 1. Install dependencies

```bash
cd frontend
flutter pub get
```

### 2. Environment setup

Copy the example env or create `frontend/.env`:

```env
API_BASE_URL=https://keep-track-backend.vercel.app/api/v1
GOOGLE_WEB_CLIENT_ID=<ask the project owner>

DEV_BYPASS=false
DEV_EMAIL=dev@personalcodex.app
DEV_PASSWORD=<ask the project owner>
ADMIN_EMAIL=admin@personalcodex.app
ADMIN_PASSWORD=<ask the project owner>
```

Flutter reads this file at compile time via `--dart-define-from-file=.env`. It is **not** read automatically — you must pass the flag when running or building (see below).

To run against localhost instead, change `API_BASE_URL` to `http://localhost:3000/api/v1` and start the backend separately.

### 3. Run the app

```bash
# Windows
flutter run -d windows --dart-define-from-file=.env

# Android (device or emulator connected)
flutter run -d android --dart-define-from-file=.env

# Chrome (web dev)
flutter run -d chrome --dart-define-from-file=.env
```

Or use the VS Code launch config — select **"frontend"** from the Run & Debug panel, which already passes `--dart-define-from-file=.env`.

> **First run tip:** The app starts in offline mode if no credentials are stored. Sign in with email/password or Google OAuth, then all data syncs automatically.

---

## VS Code Launch Configs

Defined in `.vscode/launch.json` at the repo root:

| Config | Backend | Notes |
|---|---|---|
| `frontend` | Reads from `.env` | Default — edit `.env` to switch environments |
| `frontend (dev bypass)` | localhost:3000 | Auto-signs in with `DEV_EMAIL`/`DEV_PASSWORD` |
| `frontend (profile mode)` | — | Performance profiling |
| `frontend (release mode)` | — | Release build smoke test |

---

## Building for Release

The release script at `installers/build_release.py` handles both Windows and Android. It reads `.env`, overrides `API_BASE_URL` to production, syncs the version from `pubspec.yaml`, and compiles.

```bash
cd frontend

# Build both Windows installer and Android APK
python installers/build_release.py

# Windows only
python installers/build_release.py windows

# Android APK only
python installers/build_release.py apk
```

### Windows output
- Raw build: `build/windows/x64/runner/Release/`
- Installer (`.exe`): `installers/KeepTrack-v<version>.exe`

Requires [Inno Setup 6](https://jrsoftware.org/isdl.php) installed at `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`. If not present, the raw build is produced but no installer is compiled.

### Android output
- `build/app/outputs/flutter-apk/KeepTrack-v<version>.apk`

The APK is signed with the debug keystore by default. For a release-signed APK, configure `android/key.properties` and `android/app/build.gradle` with the production keystore before running.

### Manual build commands

```bash
# Windows
flutter build windows --release --dart-define-from-file=.env

# Android APK
flutter build apk --release --dart-define-from-file=.env

# Android App Bundle (Play Store)
flutter build appbundle --release --dart-define-from-file=.env
```

---

## Project Structure

```
lib/
├── core/
│   ├── auth/           # Token storage and refresh logic
│   ├── cache/          # Hive local cache wrappers
│   ├── connectivity/   # Network state detection
│   ├── di/             # Custom service locator (no GetIt)
│   ├── error/          # Failure types and Result<T>
│   ├── feature_flags/  # Debug feature flag panel
│   ├── logging/        # App logger
│   ├── network/        # Dio client, auth interceptor, error mapping
│   ├── routing/        # Named routes
│   ├── settings/       # Persistent app settings (theme, currency, etc.)
│   ├── state/          # StreamState + StreamStateBuilder
│   ├── sync/           # Offline sync manager
│   ├── theme/          # AppStyling — colors, text styles
│   └── ui/             # Shared widgets (toasts, desktop title bar, etc.)
└── features/
    ├── auth/           # Login, Google OAuth, token management
    ├── finance/        # Budgets, transactions, savings, debts, goals
    ├── home/           # Dashboard
    ├── inbox/          # Announcements
    ├── logs/           # Transaction log view
    ├── module_selection/  # Feature/module picker screen
    ├── notifications/  # Push notification settings
    ├── profile/        # User profile
    └── settings/       # App settings, backup/restore, cloud sync
```

Each feature follows the same folder contract:

```
features/<feature>/
├── presentation/
│   ├── screen/     # ScopeScreen entry points
│   ├── section/    # Composed UI regions
│   ├── widget/     # Reusable, domain-logic-free components
│   ├── state/      # StreamState subclasses
│   ├── sheets/     # Bottom sheets
│   └── dialogs/    # Dialog components
├── domain/
│   ├── controller/ # Orchestrates use cases
│   └── repository/ # Abstract interfaces
└── data/
    ├── repository/ # Concrete implementations
    └── datasource/ # Remote (HTTP) and local (Hive)
```

---

## Architecture Notes

- **State management:** `StreamState` + `StreamStateBuilder` only. No BLoC, Riverpod, or ChangeNotifier.
- **DI:** Custom service locator in `core/di/`. No GetIt.
- **Offline-first:** All writes go to Hive first. `core/sync/` reconciles with the backend when the device comes online.
- **Backend:** NestJS REST API at `https://keep-track-backend.vercel.app/api/v1`. All business logic and validation lives there.
- **Auth:** Google OAuth and email/password, both handled by the backend. The Flutter app receives a JWT and stores it via `core/auth/token_storage.dart`.

---

## Feature Flag Panel

On desktop, press **Ctrl+Shift+F** (or click the tune icon in the title bar) to open the feature flag panel. From here you can:

- Toggle **Offline Mode** — disables all backend calls, Hive only
- Toggle **Plus Mode** — simulates a Plus user without a real subscription
- Toggle **Production View** — hides dev-only UI elements
- **Check Backend** — pings `/api/v1/health` and shows a toast; displays the active `API_BASE_URL` so you can confirm which backend you're hitting
- Send a test notification
- Inspect Hive cache contents

---

## Common Issues

**"Connection failed" on login**
The app is hitting `localhost:3000` instead of the backend. Run with `--dart-define-from-file=.env` or use the VS Code `"frontend"` launch config.

**Google Sign-In not working on desktop**
Google OAuth is not supported on Windows/macOS/Linux. Use email/password login on desktop. Google sign-in works on Android and web.

**App starts with no data after fresh install**
Expected. Sign in to restore cloud data, or use Demo Mode (Settings → Demo) to explore with sample data.

**Build fails with "keystore not found"**
The production keystore (`upload-keystore.jks`) is not checked in. Ask the project owner for the signing credentials.
