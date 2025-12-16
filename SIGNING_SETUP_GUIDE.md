# Code Signing Setup Guide

## Quick Setup with Free Apple ID (Use Now)

### Step 1: Generate Certificate (Need ANY Mac)

```bash
# On any Mac (friend's, cloud Mac, Apple Store):

# 1. Open Xcode
# 2. Preferences → Accounts
# 3. Click "+" → Add Apple ID
# 4. Sign in with your Apple ID (any free Apple ID)
# 5. Select your account → Manage Certificates
# 6. Click "+" → iOS Development
# 7. Certificate created!
```

### Step 2: Create App ID & Profile

```bash
# Still in Xcode:

# 1. Open your project
# 2. Select project → Target → Signing & Capabilities
# 3. Check "Automatically manage signing"
# 4. Select Team (your Apple ID)
# 5. Xcode creates profile automatically
# 6. Change Bundle ID to: com.yourname.AITrainer
```

### Step 3: Export Certificate

```bash
# In Keychain Access (on Mac):

# 1. Open Keychain Access app
# 2. Find "iPhone Developer: your@email.com"
# 3. Right-click → Export
# 4. Save as: Certificates.p12
# 5. Set password: [remember this]
# 6. Download profile from ~/Library/MobileDevice/Provisioning Profiles/
```

### Step 4: Add to GitHub Secrets

```bash
# In your GitHub repo:

1. Go to: Settings → Secrets and variables → Actions
2. Click "New repository secret"

Add these secrets:
- Name: CERTIFICATE_BASE64
  Value: [base64 of Certificates.p12]
  
- Name: CERTIFICATE_PASSWORD
  Value: [password you set]
  
- Name: PROVISIONING_PROFILE_BASE64
  Value: [base64 of .mobileprovision]
  
- Name: BUNDLE_ID
  Value: com.yourname.AITrainer
```

### Step 5: Convert to Base64 (On Mac)

```bash
# Convert certificate to base64:
base64 -i Certificates.p12 -o certificate.txt

# Convert profile to base64:
base64 -i profile.mobileprovision -o profile.txt

# Copy contents of .txt files to GitHub secrets
```

---

## Upgrade to Paid Certificate (When Approved)

Just repeat the above steps with your Developer account instead of free Apple ID!

The certificates from paid account last 1 year vs 7 days.

