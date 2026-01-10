# Supabase Account Linking Behavior

## 🔍 Current Behavior (Default Supabase Settings)

### **Test Case 1: Google First, Then Email/Password**

**Steps:**
1. User signs in with Google (`user@gmail.com`) → ✅ Account created (User ID: `abc123`)
2. User tries to sign up with Email/Password (`user@gmail.com`) → ❌ **ERROR: "User already registered"**

**Result:** Supabase blocks duplicate emails. User must be authenticated and manually add password via `updateUser()`.

---

### **Test Case 2: Email/Password First, Then Google**

**Steps:**
1. User signs up with Email/Password (`user@gmail.com`) → ✅ Account created (User ID: `abc123`)
2. User tries to sign in with Google (`user@gmail.com`) → ⚠️ **Creates NEW account** (User ID: `xyz789`)

**Result:** Supabase creates a **separate account**! This is a problem because:
- User now has TWO accounts with the same email
- Data is not shared between them
- User gets confused

---

## ⚠️ The Problem

By default, Supabase:
- ✅ Blocks Email/Password signup if Google account exists (good)
- ❌ Allows Google OAuth even if Email/Password account exists (creates duplicate)

**This is asymmetric behavior!**

---

## 🔧 Solution Options

### **Option 1: Prevent Duplicate Accounts (Recommended)**

Configure Supabase to block OAuth if email already exists:

**Supabase Dashboard → Authentication → Settings:**
- Enable: **"Confirm email"** for Email/Password
- Disable: **"Enable Automatic Account Linking"** (should be off by default)
- Enable: **"Restrict signup to email domains"** (optional)

**Better: Use Database Trigger**
Create a trigger that checks if email exists before allowing OAuth:

```sql
-- Prevent duplicate OAuth signups if email exists
CREATE OR REPLACE FUNCTION prevent_duplicate_oauth()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM auth.users
    WHERE email = NEW.email
    AND id != NEW.id
  ) THEN
    RAISE EXCEPTION 'Email already registered with a different authentication method. Please sign in with your existing method and link accounts in settings.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER check_duplicate_oauth
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION prevent_duplicate_oauth();
```

---

### **Option 2: Enable Automatic Linking (Not Recommended - Security Risk)**

**Supabase Dashboard → Authentication → Settings:**
- Enable: **"Enable Automatic Account Linking"**

**Security Risk:**
- Attacker could create email/password account with someone's email
- Then link it to victim's Google account
- Gets access to victim's data

**Only use if:**
- Email verification is REQUIRED
- You trust your email verification process
- You understand the security implications

---

### **Option 3: Manual Linking Only (Current Implementation)**

**What we have now:**
- User must be authenticated
- User manually adds password via Auth Settings
- Secure, but requires user action

**Pros:**
✅ Secure - user must be logged in
✅ No risk of account hijacking
✅ Works with our current code

**Cons:**
❌ User can't discover they have two accounts
❌ If user signs in with Google after Email/Password, creates duplicate
❌ Data gets split across accounts

---

## ✅ Recommended Setup

### **1. Prevent Duplicate Accounts**

Add this to your Supabase project:

**SQL Editor → New Query:**
```sql
-- Check if email is already registered with different provider
CREATE OR REPLACE FUNCTION check_email_exists()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if email already exists with a different auth provider
  IF EXISTS (
    SELECT 1 FROM auth.users
    WHERE email = NEW.email
    AND id != NEW.id
  ) THEN
    RAISE EXCEPTION 'This email is already registered. Please sign in with your existing method (Google or Email/Password) and add additional sign-in methods in Settings.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply trigger to prevent duplicate signups
DROP TRIGGER IF EXISTS check_email_uniqueness ON auth.users;
CREATE TRIGGER check_email_uniqueness
  BEFORE INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION check_email_exists();
```

**This will:**
- ✅ Block Email/Password signup if Google account exists
- ✅ Block Google OAuth if Email/Password account exists
- ✅ Force users to use Auth Settings to add methods
- ✅ Prevent data splitting across accounts

---

### **2. Update Login UI to Guide Users**

When user tries to sign up and gets "Email already registered" error:

**Show helpful message:**
```
"This email is already registered with a different sign-in method.
Please sign in with your existing method and add additional
sign-in methods in Profile → Auth Settings."
```

---

## 🧪 Testing After Setup

### **Test Case 1: Google First**
1. Sign in with Google → ✅ Works
2. Try Email/Password signup → ❌ "Email already registered"
3. Sign in with Google → Go to Auth Settings → Add password → ✅ Works

### **Test Case 2: Email/Password First**
1. Sign up with Email/Password → ✅ Works
2. Try Google OAuth → ❌ "Email already registered"
3. Sign in with Email/Password → Go to Auth Settings → ❌ Can't add Google yet (not implemented)

### **Test Case 3: Different Emails**
1. Sign in with Google (`user1@gmail.com`) → ✅ Works
2. Sign up with Email/Password (`user2@gmail.com`) → ✅ Works (different email, different account)

---

## 📊 Summary

| Scenario | Default Behavior | With Trigger | Recommended |
|----------|-----------------|--------------|-------------|
| Google → Email/Password signup | ❌ Error | ❌ Error | ✅ Manual link via Settings |
| Email/Password → Google OAuth | ⚠️ Creates duplicate | ❌ Error | ✅ Manual link via Settings |
| Same email, same provider | ❌ Error | ❌ Error | ✅ Correct |
| Different emails | ✅ Works | ✅ Works | ✅ Correct |

---

## 🎯 Action Items

1. **Add SQL trigger** to prevent OAuth duplicates
2. **Update error messages** to guide users to Auth Settings
3. **Test all scenarios** to ensure no duplicate accounts
4. **Document the flow** for users

---

**Current Status:**
- ❌ Automatic linking: Not enabled (and shouldn't be)
- ✅ Manual linking: Implemented (Google users can add password)
- ⚠️ Duplicate prevention: Not implemented yet (needs SQL trigger)

**Next Step:** Add the SQL trigger to prevent duplicate accounts!
