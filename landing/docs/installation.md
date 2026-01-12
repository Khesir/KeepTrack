# Installation

This guide will help you install Personal Codex on your system.

## Quick Install

The easiest way to get started is to download the installer for your platform from our [Download page](/download).

## Platform-Specific Instructions

### Windows

1. Download the Windows installer (`.exe`) from the [Download page](/download)
2. Double-click the downloaded file to run the installer
3. Follow the installation wizard
4. Launch Personal Codex from the Start Menu or Desktop shortcut

**Note**: You may see a Windows SmartScreen warning on first launch. This is normal for new applications. Click "More info" and then "Run anyway" to proceed.

### macOS

1. Download the macOS disk image (`.dmg`) from the [Download page](/download)
2. Open the downloaded `.dmg` file
3. Drag the Personal Codex icon to your Applications folder
4. Launch Personal Codex from Applications

**First Launch**: You may see a security warning. If so:
   - Open System Preferences → Security & Privacy
   - Click the "Open Anyway" button
   - Confirm by clicking "Open"

### Linux

#### AppImage (Recommended)

AppImage is the universal package format for Linux and works on most distributions:

1. Download the `.AppImage` file from the [Download page](/download)
2. Make it executable:
   ```bash
   chmod +x Personal-Codex-*.AppImage
   ```
3. Run the application:
   ```bash
   ./Personal-Codex-*.AppImage
   ```

**Optional**: Integrate with your desktop:
```bash
# Move to a standard location
mkdir -p ~/.local/bin
mv Personal-Codex-*.AppImage ~/.local/bin/personal-codex

# Make it available system-wide
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### DEB Package (Debian/Ubuntu)

For Debian-based distributions:

1. Download the `.deb` package from the [Download page](/download)
2. Install using dpkg:
   ```bash
   sudo dpkg -i personal-codex-*.deb
   ```
3. If there are missing dependencies:
   ```bash
   sudo apt-get install -f
   ```
4. Launch from your application menu or run:
   ```bash
   personal-codex
   ```

## First Time Setup

After installing and launching Personal Codex for the first time:

1. **Authentication**
   - Create a new account or sign in
   - You can use email/password or Google authentication

2. **Initial Configuration**
   - Set your preferred currency in Settings
   - Choose your theme (Light/Dark/System)

3. **Start Exploring**
   - Create your first task
   - Set up your financial accounts
   - Try the Pomodoro timer

## System Requirements

Make sure your system meets these minimum requirements:

- **RAM**: 4 GB (8 GB recommended)
- **Storage**: 500 MB available space
- **Internet**: Required for cloud sync and authentication

## Troubleshooting

### Application won't launch

**Windows**: Try running as administrator
**macOS**: Check Security & Privacy settings
**Linux**: Ensure all dependencies are installed

### Can't sign in

- Check your internet connection
- Verify your email and password
- Try resetting your password if needed

### Missing features

Make sure you're running the latest version. Check the [Download page](/download) for updates.

## Next Steps

Now that you have Personal Codex installed, check out the [Quick Start Guide](./quickstart) to learn the basics!
