<div align="center">

#  Keep Track

> ⚠️ **Disclaimer:** The app icon/image (`/assets/icon/app_icon.png`) is currently a **placeholder** and will be replaced later. It is **not owned** by me.


<img src="assets/icon/app_icon.png" alt="Keep Track App Icon" width="120" height="120"/>

Organize your life with powerful task management, comprehensive finance tracking, and productivity tools - all in one beautiful app.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Powered-3ECF8E?logo=supabase)](https://supabase.com)

[Download Latest Release](https://github.com/Khesir/KeepTrack/releases/latest) • [Documentation](./docs) • [Report Bug](https://github.com/Khesir/KeepTrack/issues) • [Request Feature](https://github.com/Khesir/KeepTrack/issues)

</div>

---

## ✨ Features

### Current Features

- ✅ **Task Management (Base Feature)**
  - Create, organize, and track tasks with priorities
  - Set deadlines and due dates
  - Group tasks into projects
  - Archive completed tasks
  - Filter by priority (Urgent, High, Medium, Low)

- ✅ **Finance Tracking (Base Feature)**
  - Manage multiple accounts (Bank, Cash, E-Wallet, etc.)
  - Create and monitor budgets by category
  - Track debts with payment schedules
  - Set savings goals with progress tracking
  - Schedule recurring payments
  - Comprehensive transaction history
  - Multi-currency support

- ✅ **Productivity Tools (Base Feature)**
  - Built-in Pomodoro timer with customizable durations
  - Focus sessions with automatic break reminders
  - Session statistics and insights

- ✅ **Modern UI/UX**
  - Clean, intuitive interface inspired by modern design principles
  - Full dark mode support
  - Responsive layout for desktop and mobile
  - Smooth animations and transitions

- ✅ **Cloud Sync**
  - Supabase authentication (Email/Password, Google)
  - Real-time data synchronization
  - Access your data from any device

- ✅ **Cross-Platform**
  - Windows (x64)
  - macOS (Intel & Apple Silicon)
  - Linux (AppImage, DEB)
  - Android (APK) - Coming soon
  - iOS - Coming soon
### 🚀 Future Features (Updated)

- [ ] **Offline-First Architecture**
  - Local database with SQLite/Hive
  - Background sync when connection is available
  - Conflict resolution for offline changes
  - Queue system for pending operations

- [ ] **Plugin / Module Management System**
  - Users can extend the app by installing **modules** (managers) not yet implemented
    - Examples: Music Manager, Calendar-based Task Manager, Inventory Manager
  - Each module/plugin is **isolated**:
    - Separate database or table namespace
    - Own migrations, UI screens, and rules
  - Safe offline execution; cross-device sharing via **save files**
  - Community-driven trust:
    - Users can rate, review, and approve modules
    - Highly-rated plugins are displayed as “trusted”
  - **Plugin Workflow**:
    1. User installs module from trusted source/repo  
    2. App validates plugin metadata and runs migrations  
    3. User configures the module (e.g., sets categories, workflow)  
    4. Module is ready for offline use  

- [ ] **Collaboration**
  - Share projects with team members
  - Assign tasks to others
  - Comments and activity feed
  - Real-time collaboration

- [ ] **Customization**
  - Custom themes and color schemes: Users can adjust colors, fonts, and certain visual assets
  - Module layout and dashboard structure are fixed; only the appearance is customizable
  - Keyboard shortcuts


---

### 🧩 Plugin / Module Development System

Keep Track will support **user-created modules** to extend app functionality beyond core features.

#### Key Concepts

- **Modules / Plugins**: Self-contained managers (e.g., calendar, music, inventory)  
- **Isolation**: Each plugin has its own database or table namespace to prevent conflicts  
- **Offline-First Execution**: Plugins run locally on the user device  
- **Save File Sharing**: Cross-device transfer via exported save files, no server execution required  
- **Auto Checks & Updates**: App can validate plugin repositories for:
  - New versions
  - Compatibility with current app version
  - Trust rating from community feedback

#### Workflow for Users

1. Browse the **Plugin Marketplace** (online or offline)  
2. Download and install a trusted plugin/module  
3. App validates the module and applies its database migrations  
4. User configures the module according to their needs  
5. Module is ready for offline use  
6. Users can rate or review modules to help other users identify trusted plugins  

#### Plugin Development Workflow (For Contributors)

1. Create a module following the **Keep Track plugin structure**:
   - **Manifest**: ID, name, version, supported engine version  
   - **Schema**: Database tables, columns, relationships  
   - **UI**: Screens, forms, dashboards  
   - **Rules**: Optional logic, validation, or automation  
2. Package module as a ZIP or repository link  
3. Submit module to the **community marketplace**  
4. Users download, install, and configure the module  

> **Future plan:** Optional signature verification for plugin authenticity and versioning  

---
## 🚀 Getting Started

### System Requirements

#### Windows
- **OS**: Windows 10 or later (64-bit)  
- **RAM**: 4 GB minimum, 8 GB recommended  
- **Storage**: 500 MB available space  
- **Graphics**: DirectX 11 compatible graphics card  

#### Android
- **OS**: Android 8.0 (Oreo) or later  
- **RAM**: 2 GB minimum, 4 GB recommended  
- **Storage**: 200 MB available space  
- **Architecture**: ARM64 or ARMv7  

---

### Installation Instructions

#### Windows
1. Download the `.exe` installer from the latest release above  
2. Run the installer and follow the setup wizard  
3. Launch **Personal Codex** from the Start Menu or Desktop shortcut  

#### Android
1. Download the `.apk` file from the latest release above  
2. If prompted, allow installation from unknown sources in your device settings  
3. Tap the downloaded APK file to install  
4. Open **Personal Codex** from your app drawer  

---

## 🛠️ Development Setup

### Prerequisites

- Flutter SDK (3.19+)
- Dart SDK (3.3+)
- A Supabase account (free tier available)
- Git

### 1. Clone the repository

```bash
git clone https://github.com/Khesir/KeepTrack.git
cd KeepTrack
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Set up Supabase

#### Create a Supabase project

1. Go to [https://supabase.com](https://supabase.com)
2. Create a new project
3. Wait for the project to be ready

#### Run the bootstrap script

This is a **ONE-TIME** setup that enables automatic migrations:

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor** in the sidebar
3. Click **New Query**
4. Copy and paste the contents of `supabase/bootstrap.sql`
5. Click **Run** (or press Cmd/Ctrl + Enter)

The bootstrap script creates:
- The `exec_sql` function (allows automatic migrations)
- The `schema_migrations` table (tracks applied migrations)

### 4. Configure your app

Update `lib/main.dart` with your Supabase credentials:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_PROJECT_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

Find these values in your Supabase project settings under **API**.

### 5. Run the app

```bash
# Desktop
flutter run -d windows  # or macos, linux

# Mobile
flutter run -d android  # or ios
```

The app will automatically:
1. Connect to Supabase
2. Run all pending migrations
3. Set up the database schema
4. Start the app

---

## 📁 Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── di/                  # Dependency injection
│   ├── error/               # Error handling
│   ├── logging/             # Logging system
│   ├── migrations/          # Database migrations
│   ├── routing/             # Navigation
│   ├── settings/            # App settings
│   ├── state/               # State management
│   ├── theme/               # Theming
│   └── ui/                  # Reusable UI components
├── features/                # Feature modules
│   ├── auth/                # Authentication
│   ├── finance/             # Finance tracking
│   │   ├── modules/
│   │   │   ├── account/     # Account management
│   │   │   ├── budget/      # Budget tracking
│   │   │   ├── debt/        # Debt management
│   │   │   ├── goal/        # Savings goals
│   │   │   └── transaction/ # Transaction history
│   │   └── presentation/    # UI screens
│   ├── home/                # Home dashboard
│   ├── module_selection/    # Module picker
│   ├── profile/             # User profile
│   └── tasks/               # Task management
│       ├── domain/          # Business logic
│       ├── presentation/    # UI screens
│       └── state/           # State management
├── shared/                  # Shared code
│   └── infrastructure/      # Infrastructure code
└── main.dart                # App entry point
```

---

## 🗄️ Database Migrations

Keep Track uses **automatic database migrations**. When you start the app:

1. Migration manager checks which migrations have been applied
2. Pending migrations are executed automatically via the `exec_sql` RPC function
3. Successful migrations are recorded in the `schema_migrations` table

No manual SQL execution needed after the initial bootstrap!

See [Migration System Guide](lib/core/migrations/README.md) for more details.

---

## 🏗️ Architecture

- **Clean Architecture** with separation of concerns
- **Custom Dependency Injection** system
- **Custom State Management** using `StreamState`
- **Feature-based organization** for scalability
- **Repository pattern** for data access
- **Automatic migrations** for database schema updates

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to:
- Report bugs
- Suggest features
- Submit pull requests
- Set up your development environment

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev) - Google's UI toolkit
- Powered by [Supabase](https://supabase.com) - Open source Firebase alternative
- Inspired by modern productivity apps and design systems
- Icons from [Material Design](https://material.io/design)

---

## 📞 Support

- 📚 [Documentation](./docs)
- 💬 [GitHub Discussions](https://github.com/Khesir/KeepTrack/discussions)
- 🐛 [Issue Tracker](https://github.com/Khesir/KeepTrack/issues)
- 📧 Email: [Your Email]

---

## 🌟 Star History

If you find Keep Track useful, please consider giving it a star ⭐

[![Star History Chart](https://api.star-history.com/svg?repos=Khesir/KeepTrack&type=Date)](https://star-history.com/#Khesir/KeepTrack&Date)

---

<div align="center">

Made with ❤️ using Flutter & Supabase

[Website](https://yourdomain.com) • [Twitter](https://twitter.com/yourhandle) • [Discord](https://discord.gg/yourserver)

</div>
