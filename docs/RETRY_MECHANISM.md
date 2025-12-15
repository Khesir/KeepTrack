# Automatic Retry Mechanism for Network Errors

## Overview

The app now includes an intelligent retry mechanism that automatically handles network errors during initialization without requiring user intervention.

## Features

### 🔄 Automatic Retry with Exponential Backoff

When the app encounters a network error during startup, it will:

1. **Detect Network Errors** - Identifies common network-related errors:
   - Connection timeout
   - Socket exceptions
   - Failed host lookup
   - Network unreachable
   - Any error containing "network", "socket", "connection", etc.

2. **Retry Automatically** - Attempts to reconnect up to **5 times**

3. **Exponential Backoff** - Waits progressively longer between retries:
   - Attempt 1: Wait 2 seconds
   - Attempt 2: Wait 4 seconds
   - Attempt 3: Wait 8 seconds
   - Attempt 4: Wait 16 seconds
   - Attempt 5: Wait 32 seconds

4. **Visual Feedback** - Shows a friendly loading screen with:
   - Spinning progress indicator
   - Current retry attempt number
   - Countdown to next retry
   - Clear messaging about what's happening

## User Experience

### Scenario 1: Temporary Network Issue

```
App Launch
  ↓
Network Error (WiFi disconnected)
  ↓
[Retry Screen Shows]
"Connecting to Server..."
"Retry attempt 1 of 5"
"Retrying in 2 seconds..."
  ↓
[User reconnects WiFi]
  ↓
Retry succeeds → App starts normally ✅
```

### Scenario 2: Persistent Network Problem

```
App Launch
  ↓
Network Error (No internet)
  ↓
[Retries 5 times with exponential backoff]
  ↓
Max retries reached
  ↓
[Error Screen Shows]
"Connection Failed"
"Max retry attempts reached"
"Please check your internet connection..."
```

### Scenario 3: Configuration Error (Not Network)

```
App Launch
  ↓
Configuration Error (Wrong credentials)
  ↓
[Error Screen Shows Immediately]
"Failed to Initialize"
"Please check:
1. Supabase credentials are correct
2. Database schema is set up
3. Bootstrap script was run"
```

## Code Structure

### Main Components

**`_initializeAppWithRetry()`**
- Main retry loop
- Handles exponential backoff
- Distinguishes between network and configuration errors

**`_isNetworkError()`**
- Detects network-related errors
- Returns `true` for retryable errors
- Returns `false` for configuration errors

**`_buildRetryingScreen()`**
- Shows loading screen during retry
- Displays retry count and countdown

**`_buildErrorScreen()`**
- Shows final error screen if all retries fail
- Different messages for network vs. configuration errors

## Configuration

You can adjust the retry behavior in `main.dart`:

```dart
const maxRetries = 5;              // Number of retry attempts
const initialDelay = Duration(seconds: 2);  // Initial delay before first retry
```

The delay follows exponential backoff: `initialDelay * 2^(retryCount - 1)`

## Benefits

### For Users:
- ✅ **No manual retry needed** - Automatic reconnection
- ✅ **Clear feedback** - Always know what's happening
- ✅ **Fast recovery** - Quick reconnection when network returns
- ✅ **No data loss** - Safe initialization before app starts

### For Developers:
- ✅ **Robust initialization** - Handles transient network issues
- ✅ **Better debugging** - Clear distinction between error types
- ✅ **Production ready** - Graceful degradation
- ✅ **User friendly** - Professional error handling

## Example Output (Console)

### Successful Retry:
```
🚀 Initializing Supabase...
⚠️  Network error: SocketException: Failed host lookup
⏳ Retrying in 2 seconds... (1/5)

🔄 Retry attempt 1/5...
✅ Supabase initialized
📋 Found 0 previously applied migrations
...
```

### Max Retries Reached:
```
🚀 Initializing Supabase...
⚠️  Network error: SocketException: Failed host lookup
⏳ Retrying in 2 seconds... (1/5)
...
⏳ Retrying in 32 seconds... (5/5)

❌ Failed to initialize app: SocketException: Failed host lookup
[Shows error screen]
```

## When Retry Doesn't Happen

Retry is **skipped** for non-network errors:
- Wrong Supabase credentials
- Database not bootstrapped
- SQL syntax errors
- Migration failures (non-network)
- Any error not matching network patterns

These errors show the error screen immediately since retrying won't help.

## Testing

### Test Network Retry:
1. Disconnect WiFi before launching app
2. Observe retry screen with countdown
3. Reconnect WiFi
4. App should complete initialization

### Test Max Retries:
1. Keep WiFi disconnected
2. Wait for all 5 retries (total ~62 seconds)
3. Error screen should appear

### Test Configuration Error:
1. Put wrong Supabase URL in main.dart
2. Launch app
3. Error screen should appear immediately (no retry)

## Future Enhancements

Potential improvements:
- Add manual retry button on error screen
- Check connectivity before each retry
- Add analytics for retry patterns
- Configurable retry strategy per environment
- Background retry when app is minimized
