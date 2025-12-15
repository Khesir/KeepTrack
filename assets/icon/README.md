# App Icon Setup

## Quick Start

You need to provide two icon images:

### 1. Main Icon: `app_icon.png`
- **Size:** 1024x1024 pixels (recommended)
- **Format:** PNG with transparency
- **What:** Your full app icon design

### 2. Foreground Icon: `app_icon_foreground.png` (Optional, for Android)
- **Size:** 1024x1024 pixels
- **Format:** PNG with transparency
- **What:** Just the icon part (without background) for Android adaptive icons

## How to Create Your Icon

### Option 1: Use an Online Icon Generator (Easiest)
1. Go to https://icon.kitchen or https://appicon.co
2. Upload your design or use their icon maker
3. Download as PNG (1024x1024)
4. Save as `app_icon.png` in this folder

### Option 2: Use a Design Tool
1. **Figma/Canva:**
   - Create 1024x1024 canvas
   - Design your icon
   - Export as PNG

2. **Adobe Photoshop/Illustrator:**
   - Create 1024x1024 artboard
   - Design your icon
   - Export as PNG

### Option 3: Use an Icon Font/Material Icon
If you want to use a Material Design icon:
1. Go to https://fonts.google.com/icons
2. Find an icon (like "inventory_2" for projects)
3. Download SVG
4. Convert to PNG at 1024x1024 using:
   - Online: https://convertio.co/svg-png/
   - Or use Inkscape/GIMP

## Design Guidelines

### Good Icon Design:
- ✅ **Simple** - Recognizable at small sizes
- ✅ **Unique** - Stands out on home screen
- ✅ **Scalable** - Looks good at all sizes
- ✅ **Memorable** - Easy to remember
- ✅ **On-brand** - Matches your app's purpose

### Avoid:
- ❌ Too much detail - won't be visible when small
- ❌ Text in icon - hard to read
- ❌ Complex gradients - may not render well
- ❌ Thin lines - may disappear at small sizes

## Example Ideas for "Personal Codex":

1. **Book/Journal Icon** 📖
   - Represents "codex" (ancient manuscript/book)
   - Simple book outline with your app color

2. **List/Organization Icon** 📋
   - Represents task management
   - Checklist or organized list

3. **Inventory/Box Icon** 📦
   - Represents organizing/collecting
   - Simple box or container

4. **Custom Monogram**
   - Letters "PC" in a circle
   - Modern, minimalist design

## After Creating Your Icon

Once you have your `app_icon.png` file in this folder, run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate all the platform-specific icons!

## Current Configuration

The icon system is configured in `pubspec.yaml`:
- **Android:** ✅ Enabled (with adaptive icon support)
- **iOS:** ✅ Enabled
- **Web:** ✅ Enabled
- **Windows:** ✅ Enabled

**Colors:**
- Background: #1976D2 (Material Blue)
- Theme: #1976D2

You can change these colors in `pubspec.yaml` under `flutter_launcher_icons`.

## Quick Template

Here's a simple template you can use as a starting point:

**For a "Codex/Book" style:**
- Background: Deep blue (#1976D2)
- Icon: White book or list symbol
- Style: Minimal, flat design

**For a "Productivity" style:**
- Background: Material blue
- Icon: Checkmark or task symbol
- Style: Modern, clean

## Need Help?

If you need a quick icon to get started, you can:
1. Use Material Icons from Google Fonts
2. Use free icon packs from Flaticon.com
3. Commission a designer on Fiverr/99designs

## Testing Your Icon

After generating:
1. Build and run your app on a device/emulator
2. Check the home screen icon
3. Make sure it looks good at different sizes
4. Test on both light and dark backgrounds (Android)
