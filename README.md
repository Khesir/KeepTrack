<div align="center">

# 📊 Keep Track

**Your all-in-one personal management system**

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

- ✅ **Task Management**
  - Create, organize, and track tasks with priorities
  - Set deadlines and due dates
  - Group tasks into projects
  - Archive completed tasks
  - Filter by priority (Urgent, High, Medium, Low)

- ✅ **Finance Tracking**
  - Manage multiple accounts (Bank, Cash, E-Wallet, etc.)
  - Create and monitor budgets by category
  - Track debts with payment schedules
  - Set savings goals with progress tracking
  - Schedule recurring payments
  - Comprehensive transaction history
  - Multi-currency support

- ✅ **Productivity Tools**
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

### 🚀 Future Features

- [ ] **Offline-First Architecture**
  - Local database with SQLite/Hive
  - Background sync when connection is available
  - Conflict resolution for offline changes
  - Queue system for pending operations

- [ ] **Enhanced Task Management**
  - Subtasks and checklists
  - Task templates
  - Recurring tasks
  - Time tracking per task
  - Task dependencies
  - Kanban board view

- [ ] **Advanced Finance**
  - Investment tracking
  - Expense categorization with AI
  - Financial reports and insights
  - Export to CSV/PDF
  - Receipt scanning and storage
  - Bill reminders

- [ ] **Collaboration**
  - Share projects with team members
  - Assign tasks to others
  - Comments and activity feed
  - Real-time collaboration

- [ ] **Integrations**
  - Calendar sync (Google Calendar, Outlook)
  - Import from other apps
  - Export/Import data
  - API for third-party integrations

- [ ] **Customization**
  - Custom themes and color schemes
  - Configurable widgets and dashboard
  - Custom categories and tags
  - Keyboard shortcuts

- [ ] **Analytics & Insights**
  - Productivity metrics
  - Spending patterns
  - Goal progress visualization
  - Custom reports

### 💡 Potential Features

- 🔔 Smart notifications and reminders
- 🎯 Habit tracking
- 📝 Note-taking with markdown support
- 📊 Data visualization with charts
- 🔐 End-to-end encryption
- 🌐 PWA (Progressive Web App) version
- 🤖 AI-powered suggestions
- 📱 Widgets for mobile home screen
- 🔄 Integration with other productivity tools
- 📧 Email notifications for important events

---

## 🚀 Getting Started

### Download

Download the latest version for your platform:

📥 **[Download Latest Release](https://github.com/Khesir/KeepTrack/releases/latest)**

- **Windows**: `.exe` installer
- **macOS**: `.dmg` disk image
- **Linux**: `.AppImage` or `.deb` package

### System Requirements

- **OS**: Windows 10+, macOS 10.15+, or Ubuntu 20.04+
- **RAM**: 4 GB minimum (8 GB recommended)
- **Storage**: 500 MB available space
- **Internet**: Required for cloud sync and authentication

### Installation

#### Windows
1. Download the `.exe` file
2. Run the installer
3. Follow the setup wizard

#### macOS
1. Download the `.dmg` file
2. Open and drag to Applications
3. Right-click and select "Open" if you see a security warning

#### Linux
```bash
# AppImage
chmod +x KeepTrack-*.AppImage
./KeepTrack-*.AppImage

# DEB (Debian/Ubuntu)
sudo dpkg -i keeptrack-*.deb
```

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
