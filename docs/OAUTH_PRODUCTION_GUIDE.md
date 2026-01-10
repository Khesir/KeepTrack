# OAuth Production Configuration Guide

This guide explains how to handle Google OAuth redirects in production for both web and desktop platforms.

## Overview

Your app uses different OAuth flows depending on the platform:
- **Web**: Supabase OAuth redirect (automatic)
- **Mobile (iOS/Android)**: `google_sign_in` package (native sign-in)
- **Desktop (Windows/macOS/Linux)**: Supabase OAuth redirect (same as web)

## Web Production

### Configuration
Web apps automatically use the current domain for redirects via `Uri.base.toString()`.

**No code changes needed!** Just configure Supabase:

1. Go to Supabase Dashboard → Authentication → URL Configuration
2. Add your production domains to **Redirect URLs**:
   ```
   https://yourdomain.com
   https://www.yourdomain.com
   https://yourdomain.com/**
   ```

3. Update **Site URL** to your production domain:
   ```
   https://yourdomain.com
   ```

### Testing
- **Development**: `http://localhost:PORT` (auto-detected)
- **Production**: `https://yourdomain.com` (auto-detected)

---

## Desktop Production

Desktop apps need special handling because they don't have a web domain. You have two options:

### Option 1: Localhost Redirect (Current Setup) ✅ SIMPLE

**How it works:**
1. User clicks "Sign in with Google"
2. Browser opens Google OAuth page
3. After auth, Google redirects to `http://localhost:54321/auth/callback`
4. Your app listens on port 54321 and receives the callback
5. Supabase processes the OAuth token

**Pros:**
- Simple to implement
- Works in both development and production
- No platform-specific configuration needed

**Cons:**
- Requires your app to run a local web server
- Port 54321 must be available
- Less "native" feeling

**Supabase Configuration:**
Add to Redirect URLs:
```
http://localhost:54321/auth/callback
```

**Implementation Status:**
✅ Already configured in your `.env` file
⚠️ Need to implement local server to handle callback (see below)

---

### Option 2: Custom URL Scheme 🎯 RECOMMENDED FOR PRODUCTION

**How it works:**
1. Register a custom URL scheme (e.g., `personalcodex://`)
2. Browser redirects to `personalcodex://auth/callback`
3. OS opens your app and passes the callback data
4. Supabase processes the OAuth token

**Pros:**
- More professional
- Native app experience
- No local server needed
- Industry standard

**Cons:**
- Requires platform-specific configuration
- Need to use `uni_links` or `app_links` package

**Supabase Configuration:**
Add to Redirect URLs:
```
personalcodex://auth/callback
```

**Platform Configuration:**

#### Windows
Edit `windows/runner/main.cpp` to register the URL scheme:
```cpp
// Add this near the top
#include <shellapi.h>

// Add URL scheme handling
// This requires modifying the Windows registry during installation
```

Or use an installer tool like **Inno Setup** to register the scheme.

#### macOS
Edit `macos/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>personalcodex</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.personalcodex.auth</string>
  </dict>
</array>
```

#### Linux
Create a `.desktop` file that registers the URL scheme.

**Flutter Implementation:**
Add `uni_links` package to handle deep links:

```yaml
# pubspec.yaml
dependencies:
  uni_links: ^0.5.1
```

Update `auth_service.dart`:
```dart
import 'package:uni_links/uni_links.dart';

// Listen for deep links
StreamSubscription? _sub;

void initDeepLinks() {
  _sub = uriLinkStream.listen((Uri? uri) {
    if (uri != null && uri.scheme == 'personalcodex') {
      // Handle OAuth callback
      // Extract access_token from uri.queryParameters
    }
  });
}
```

---

## Recommended Production Setup

### For Web Deployment
1. Deploy to hosting (Vercel, Netlify, Firebase Hosting, etc.)
2. Add production domain to Supabase Redirect URLs
3. Test OAuth flow on production domain

### For Desktop Distribution
**Short-term (MVP/Testing):**
- Use localhost redirect (current setup)
- Document that users need to complete OAuth in browser
- Works immediately without extra setup

**Long-term (Production/Release):**
- Switch to custom URL scheme (`personalcodex://`)
- Better user experience
- More secure
- Industry standard for desktop apps

---

## Supabase Dashboard Setup

Add ALL these URLs to **Authentication → URL Configuration → Redirect URLs**:

```
# Development - Web
http://localhost:3000
http://localhost:3000/**

# Development - Desktop
http://localhost:54321/auth/callback

# Production - Web (replace with your domain)
https://yourdomain.com
https://yourdomain.com/**
https://www.yourdomain.com
https://www.yourdomain.com/**

# Production - Desktop (if using custom URL scheme)
personalcodex://auth/callback
```

---

## Current Status

✅ **Web**: Ready for production (auto-detects domain)
✅ **Desktop**: Works with localhost redirect
⚠️ **Desktop**: Need to implement callback handler or switch to custom URL scheme

## Next Steps

1. **Test current setup** with localhost redirect
2. **Decide**: Keep localhost or switch to custom URL scheme?
3. **If localhost**: Implement local server to handle callbacks
4. **If custom scheme**: Add `uni_links` package and configure platforms
5. **Update Supabase** with all redirect URLs
6. **Test** OAuth on production build

---

## Additional Resources

- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Flutter Deep Linking](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [uni_links package](https://pub.dev/packages/uni_links)
- [app_links package](https://pub.dev/packages/app_links) (newer, recommended)
