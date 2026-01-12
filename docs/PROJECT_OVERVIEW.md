# Keep Track - Personal Codex

**Version:** 0.5.2-alpha.2
**Tagline:** Your personal productivity hub - track finances, tasks, and goals.

---

## Table of Contents

1. [Overview](#overview)
2. [Key Features](#key-features)
3. [Target Audience](#target-audience)
4. [Technology Stack](#technology-stack)
5. [Feature Breakdown](#feature-breakdown)
6. [User Benefits](#user-benefits)
7. [Platform Availability](#platform-availability)
8. [Technical Highlights](#technical-highlights)
9. [Roadmap](#roadmap)
10. [Getting Started](#getting-started)

---

## Overview

**Keep Track** is an all-in-one personal productivity and financial management application that combines powerful task management with comprehensive finance tracking in a single, unified platform. Built with modern technology and thoughtful design, Keep Track helps you take control of your daily tasks, financial health, and long-term goals.

### The Problem We Solve

Most people juggle multiple apps to manage their lives:
- A todo app for tasks
- A spreadsheet for budgets
- Another app for expense tracking
- Sticky notes for reminders
- A separate tool for financial goals

**Keep Track brings everything together.** One app, one login, one comprehensive view of your personal productivity and financial life.

### Our Mission

To provide a **free, open-source, privacy-focused** alternative to expensive productivity and finance SaaS platforms, giving users complete control over their data while offering enterprise-grade features.

---

## Key Features

### 🎯 Task & Project Management
- Organize tasks into projects
- Set priorities and due dates
- Track task status and progress
- Hierarchical task structure (subtasks)
- Pomodoro timer for focused work
- Tag-based organization

### 💰 Comprehensive Finance Tracking
- **Multi-Account Management** - Track checking, savings, cash, and investment accounts
- **Smart Budgeting** - Monthly budgets with income/expense categories
- **Transaction Recording** - Log income, expenses, and transfers with fee support
- **Debt Tracking** - Monitor debts and payment progress
- **Financial Goals** - Set and track savings goals
- **Planned Payments** - Schedule recurring bills and subscriptions
- **Real-time Analytics** - See your financial status at a glance

### 🔐 Privacy & Security
- Google Sign-In authentication
- Self-hosted option available (Supabase)
- Your data stays under your control
- No third-party data sharing

### 📊 Activity Logging
- Complete audit trail of all actions
- Transaction history
- Budget change tracking
- Task completion logs

---

## Target Audience

### Primary Users
- **Budget-conscious individuals** seeking free financial management tools
- **Freelancers and solo entrepreneurs** who need to track both work and finances
- **Students** managing limited budgets and academic tasks
- **Privacy-conscious users** who want control over their personal data
- **Small business owners** tracking business expenses and tasks

### User Personas

**Sarah - Freelance Designer**
- Needs to track client projects and deliverables
- Manages irregular income and expenses
- Wants to set savings goals for equipment purchases

**Mike - College Student**
- Limited budget, needs to track every expense
- Balances coursework with part-time job
- Planning for student loan payments

**Jennifer - Small Business Owner**
- Tracks business and personal finances separately
- Manages recurring payments and subscriptions
- Monitors cash flow across multiple accounts

---

## Technology Stack

### Frontend
- **Flutter 3.9.2+** - Cross-platform UI framework
- **Dart 3.9.2+** - Programming language
- Custom state management (StreamState pattern)
- Custom dependency injection system

### Backend
- **Supabase** - PostgreSQL database + backend services
- **PostgreSQL** - Robust relational database
- RPC functions for complex operations
- Real-time data synchronization

### Authentication
- **Google Sign-In** - Secure OAuth authentication
- Supabase Auth - Session management

### Infrastructure
- 37+ database migrations for schema evolution
- Automatic migration system
- Environment-based configuration (.env)

---

## Feature Breakdown

### 1. Finance Module (7 Sub-Features)

#### Account Management
- Create unlimited accounts (checking, savings, cash, credit cards, investments)
- Real-time balance tracking
- Account-to-account transfers
- Account status monitoring

#### Budget Management
- Monthly budget creation
- Income and expense categories
- Target amount setting
- Real-time surplus/deficit calculation
- One-time vs recurring budgets
- Budget closing with notes and analysis

#### Transaction Recording
- Three transaction types: Income, Expense, Transfer
- Category assignment
- Fee tracking (taxes, service charges)
- Date and description
- Account and budget linking
- Automatic balance updates

#### Debt Tracking
- Record debts with full details
- Link payments to transactions
- Track debt reduction over time
- Status monitoring

#### Financial Goals
- Set savings goals
- Track progress
- Link transactions to goals
- Goal completion tracking

#### Planned Payments
- Schedule recurring payments (bills, subscriptions, rent)
- Multiple frequencies: daily, weekly, biweekly, monthly, quarterly, yearly
- One-time payments
- Payment reminders (upcoming within 7 days)
- Record payment with fees
- Skip payment option
- Installment plans support
- Auto-close on completion

#### Finance Categories
- Customizable income categories
- Customizable expense categories
- Category-wise spending analysis
- Color-coded organization

---

### 2. Task Management Module

#### Projects
- Group related tasks
- Project-level organization
- Visual project cards

#### Tasks
- Create tasks with rich details
- Set priority levels
- Assign due dates
- Task descriptions and notes
- Link to projects
- Hierarchical structure (parent/child tasks)
- Tag-based filtering
- Status tracking (pending, in progress, completed)
- Archive completed tasks

#### Pomodoro Timer
- Focus mode for productivity
- Track time spent on tasks
- Take regular breaks

---

### 3. Home Dashboard
- Quick overview of finances
- Upcoming tasks at a glance
- Budget status summary
- Recent activity feed
- Quick action buttons

---

### 4. Settings & Configuration
- **Currency Settings** - Set local currency preference
- **Account Management** - Configure financial accounts
- **Category Management** - Customize finance categories
- **Budget Settings** - Default budget preferences
- **Theme Settings** - Personalize appearance
- **Activity Logs** - View comprehensive audit trail

---

## User Benefits

### For Personal Finance
✅ **Never Miss a Bill** - Planned payments with reminders
✅ **Stay Within Budget** - Real-time budget tracking
✅ **Track Every Penny** - Comprehensive transaction logging
✅ **Reduce Debt Faster** - Monitor debt reduction progress
✅ **Achieve Financial Goals** - Set and track savings targets
✅ **Multi-Account View** - See all your money in one place

### For Productivity
✅ **Organized Task Management** - Projects and priorities
✅ **Never Forget Tasks** - Due date reminders
✅ **Stay Focused** - Pomodoro timer integration
✅ **Track Progress** - Visual task completion
✅ **Flexible Organization** - Tags and hierarchies

### For Peace of Mind
✅ **Complete Privacy** - Your data under your control
✅ **No Subscription Fees** - Free and open-source
✅ **Cross-Platform Access** - Use on any device
✅ **Offline Capable** - Work without internet
✅ **Audit Trail** - Complete activity history

---

## Platform Availability

Keep Track is available on **all major platforms**:

- ✅ **Android** - Google Play Store (coming soon)
- ✅ **iOS** - Apple App Store (coming soon)
- ✅ **Web** - Browser-based access
- ✅ **Windows** - Desktop application
- ✅ **macOS** - Desktop application
- ✅ **Linux** - Desktop application

**Sync Across Devices** - Access your data from anywhere with automatic synchronization via Supabase.

---

## Technical Highlights

### Built with Modern Architecture
- **Clean Architecture** - Separation of concerns, maintainable codebase
- **Feature-First Structure** - Modular, scalable design
- **Custom Framework** - Zero-dependency state management and DI
- **Production-Ready** - Error handling, logging, migrations

### Advanced Database Design
- **37+ Migrations** - Evolving schema with backwards compatibility
- **RPC Functions** - Atomic multi-table operations
- **Row-Level Security** - User data isolation
- **Real-Time Sync** - Instant updates across devices

### Developer-Friendly
- **Well-Documented** - Comprehensive guides and comments
- **Extensible** - Easy to add new features
- **Type-Safe** - Leverages Dart's strong typing
- **Tested** - Quality assurance built-in

---

## Roadmap

### Current Status (v0.5.2-alpha.2)
✅ Core finance module complete
✅ Task management functional
✅ Google authentication
✅ Multi-platform support
✅ Database migration system
✅ Planned payments with fees and skip

### Coming Soon (v0.6.0-beta)
🔲 Dashboard analytics and charts
🔲 Expense trends and insights
🔲 Export to CSV/PDF
🔲 Dark mode support
🔲 Backup and restore
🔲 Recurring tasks

### Future Features (v1.0)
🔲 Bill splitting and shared expenses
🔲 Investment tracking
🔲 Tax categorization
🔲 Receipt photo attachments
🔲 Customizable reports
🔲 Calendar integration
🔲 Notifications and reminders
🔲 Multi-currency support

---

## Getting Started

### For End Users

**1. Sign Up**
- Download the app for your platform
- Sign in with Google
- Set your local currency

**2. Set Up Finances**
- Create your first account (e.g., Checking Account)
- Set up a monthly budget
- Add your finance categories

**3. Start Tracking**
- Record your first transaction
- Create a planned payment for a recurring bill
- Set a financial goal

**4. Manage Tasks**
- Create a project
- Add tasks with priorities
- Use Pomodoro timer for focus

### For Developers

```bash
# Clone the repository
git clone https://github.com/yourusername/personal_codex.git

# Install dependencies
flutter pub get

# Set up environment variables
cp .env.example .env
# Edit .env with your Supabase credentials

# Run the app
flutter run
```

See [SETUP.md](SETUP.md) for detailed development setup instructions.

---

## Why Choose Keep Track?

### vs. Mint / YNAB
- ✅ **Free Forever** - No subscription fees
- ✅ **Privacy First** - Your data isn't sold to advertisers
- ✅ **Task Management** - Combines productivity with finance
- ✅ **Self-Hosted Option** - Complete control

### vs. Todoist / Asana
- ✅ **Finance Tracking** - All-in-one solution
- ✅ **Free Features** - No premium tiers
- ✅ **Offline Access** - Works without internet

### vs. Excel Spreadsheets
- ✅ **Mobile Friendly** - Native apps for all platforms
- ✅ **Automatic Calculations** - Real-time updates
- ✅ **Better UX** - Beautiful, intuitive interface
- ✅ **Cloud Sync** - Access anywhere

---

## Screenshots & Media

_[Note: Add screenshots here for website development]_

### Suggested Screenshot Sections:
1. **Home Dashboard** - Overview of finances and tasks
2. **Budget View** - Monthly budget with categories
3. **Transaction List** - Income and expense tracking
4. **Planned Payments** - Recurring bill management
5. **Task Board** - Project and task organization
6. **Account Summary** - Multi-account balance view
7. **Analytics** - Financial insights (future)
8. **Mobile Views** - Responsive design showcase

---

## Community & Support

### Open Source
- **License:** [Add your license]
- **Repository:** [Add GitHub URL]
- **Contributions:** Community-driven development

### Get Help
- **Documentation:** Comprehensive guides included
- **Issue Tracker:** Report bugs and request features
- **Community Forum:** [Add forum link if available]

---

## Pricing

**Keep Track is 100% FREE**

No hidden costs, no premium tiers, no advertising.

We believe everyone deserves access to quality financial and productivity tools.

---

## Technical Requirements

### Minimum Requirements
- **Mobile:** Android 6.0+ / iOS 12.0+
- **Desktop:** Windows 10+ / macOS 10.14+ / Linux (modern distro)
- **Web:** Modern browser (Chrome, Firefox, Safari, Edge)

### Recommended
- Internet connection for sync (offline mode available)
- 100MB storage space
- Google account for sign-in

---

## Privacy & Data

### What We Collect
- Email address (for authentication)
- Data you enter (tasks, transactions, budgets)

### What We DON'T Collect
- ❌ Browsing history
- ❌ Location data
- ❌ Contact lists
- ❌ Personal documents

### Data Storage
- Stored securely in Supabase PostgreSQL
- Encrypted in transit and at rest
- You can export or delete your data anytime

### Third-Party Sharing
- **NONE** - We never sell or share your data

---

## About the Project

Keep Track (Personal Codex) is an open-source project built with passion for helping people take control of their personal productivity and finances. We believe in transparency, privacy, and putting users first.

**Built by developers, for everyone.**

---

## Contact & Social

- **Website:** [Add website URL]
- **Email:** [Add contact email]
- **Twitter:** [Add Twitter handle]
- **GitHub:** [Add GitHub organization]

---

## Call to Action

### Ready to Take Control?

**Download Keep Track today** and start managing your finances and tasks in one powerful, free app.

[Download for Android] [Download for iOS] [Download for Windows] [Download for macOS] [Download for Linux] [Use Web App]

---

_Last Updated: January 2026_
_Version: 0.5.2-alpha.2_
