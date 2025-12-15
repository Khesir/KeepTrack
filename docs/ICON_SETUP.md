# 📱 App Icon Setup Guide

Your app launcher icon configuration is ready! Just follow these steps:

## Steps to Set Up Your App Icon

### 1️⃣ Create Your Icon Image

You need a **1024x1024 PNG** image for your app icon.

**Quick Options:**

**Option A: Use an Online Generator (5 minutes)**
1. Go to https://icon.kitchen
2. Choose a Material icon or upload your design
3. Customize colors (we use Material Blue #1976D2)
4. Download as PNG

**Option B: Use Figma/Canva (15 minutes)**
1. Create 1024x1024 canvas
2. Design your icon
3. Export as PNG

**Option C: Use Material Icon (2 minutes)**
1. Go to https://fonts.google.com/icons
2. Search for an icon (suggestions: `inventory_2`, `menu_book`, `view_list`)
3. Download SVG
4. Convert to PNG at https://convertio.co/svg-png/ (set to 1024x1024)

### 2️⃣ Save Your Icon

Save your icon as:
```
assets/icon/app_icon.png
```

**Optional:** For Android adaptive icons, also create:
```
assets/icon/app_icon_foreground.png
```
(This is just the icon part without background)

### 3️⃣ Generate Platform Icons

Run these commands in your terminal:

```bash
# Get the icon generator package
flutter pub get

# Generate all platform-specific icons
flutter pub run flutter_launcher_icons
```

### 4️⃣ Rebuild Your App

```bash
flutter clean
flutter run
```

Your new icon will now appear on the home screen! 🎉

## What Gets Generated

The tool will automatically create icons for:
- ✅ **Android** - All required sizes + adaptive icon
- ✅ **iOS** - All App Store required sizes
- ✅ **Web** - Favicon and PWA icons
- ✅ **Windows** - Desktop icon

## Current Settings

**Icon Configuration** (in `pubspec.yaml`):
- Primary image: `assets/icon/app_icon.png`
- Android adaptive background: **Material Blue (#1976D2)**
- Adaptive foreground: `assets/icon/app_icon_foreground.png`

## Icon Design Tips

### ✅ DO:
- Keep it simple and recognizable
- Use solid colors
- Make it unique
- Test at small sizes (48x48)
- Ensure good contrast

### ❌ DON'T:
- Use thin lines (won't be visible)
- Add text (too small to read)
- Make it too detailed
- Use photos directly

## Suggested Icon Ideas for "Personal Codex"

1. **📖 Book/Codex Icon**
   - Simple book outline
   - Material Blue background
   - White icon

2. **📋 Task List Icon**
   - Checkmark and list
   - Modern, clean design

3. **📦 Organization/Inventory Icon**
   - Box or container symbol
   - Represents organizing

4. **🔤 Monogram "PC"**
   - Letters "PC" in a circle
   - Minimalist style

## Example Command Flow

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate icons
flutter pub run flutter_launcher_icons

# You should see:
# ✓ Generated Android icons
# ✓ Generated iOS icons
# ✓ Generated Web icons
# ✓ Generated Windows icons

# 3. Clean and rebuild
flutter clean
flutter run
```

## Troubleshooting

**Q: Icons not updating?**
A: Run `flutter clean` then rebuild

**Q: Android adaptive icon not working?**
A: Make sure you created both `app_icon.png` and `app_icon_foreground.png`

**Q: Want to change the background color?**
A: Edit `adaptive_icon_background` in `pubspec.yaml`

**Q: Need different icon for different platforms?**
A: You can specify different `image_path` for each platform in `pubspec.yaml`

## Quick Start Template

Don't have time to design? Use this quick template:

1. Go to https://icon.kitchen
2. Search: "inventory_2" (matches your nav icon)
3. Colors: Background #1976D2, Foreground white
4. Download PNG (1024x1024)
5. Save as `assets/icon/app_icon.png`
6. Run: `flutter pub run flutter_launcher_icons`
7. Done! ✨

## Resources

- **Icon Generator:** https://icon.kitchen
- **Material Icons:** https://fonts.google.com/icons
- **Free Icons:** https://flaticon.com
- **SVG to PNG:** https://convertio.co/svg-png/
- **Icon Design Guide:** https://developer.android.com/distribute/google-play/resources/icon-design-specifications

---

**Note:** The `flutter_launcher_icons` package is already configured in your `pubspec.yaml`. You just need to provide the icon image and run the generation command!
