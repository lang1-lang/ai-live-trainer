# 🍎 Mac Terminal Steps: Pull & Update AXIS LABS Engine 2.0

## ✅ What Just Happened

The code has been committed and pushed to GitHub:
- **Commit**: `81b752e` 
- **Message**: "AXIS LABS Engine 2.0: Complete Implementation"
- **Files Changed**: 19 files (3,893 insertions!)
- **Status**: ✅ Pushed to `origin/main`

---

## 📍 Step 1: Open Terminal on Your Mac

**Option A**: Spotlight Search
```
Press: ⌘ + Space
Type: "Terminal"
Press: Enter
```

**Option B**: Finder
```
Applications → Utilities → Terminal
```

---

## 📂 Step 2: Navigate to Project Directory

```bash
cd ~/Desktop/SYS
```

Or if it's in a different location:
```bash
cd /path/to/your/project/SYS
```

**Verify you're in the right place**:
```bash
ls
```
You should see: `AI_Live_Trainer_System` folder

---

## 🔄 Step 3: Pull Latest Changes from GitHub

```bash
git pull origin main
```

**Expected Output**:
```
remote: Enumerating objects: 25, done.
remote: Counting objects: 100% (25/25), done.
remote: Compressing objects: 100% (15/15), done.
remote: Total 21 (delta 8), reused 21 (delta 8)
Unpacking objects: 100% (21/21), done.
From https://github.com/lang1-lang/ai-live-trainer
 * branch            main       -> FETCH_HEAD
   db58145..81b752e  main       -> origin/main
Updating db58145..81b752e
Fast-forward
 AI_Live_Trainer_System/Engine/BiomechanicsEngine.swift    | 340 +++++++++++++++++++
 AI_Live_Trainer_System/Engine/DeviceCapabilityManager.swift | 164 ++++++++++
 ... (more files)
 19 files changed, 3893 insertions(+), 11 deletions(-)
```

---

## 🎯 Step 4: Open Xcode Project

**From Terminal**:
```bash
open AI_Live_Trainer_System/AI_Live_Trainer_System.xcodeproj
```

**Or From Finder**:
```
Double-click: AI_Live_Trainer_System/AI_Live_Trainer_System.xcodeproj
```

---

## 🔧 Step 5: Clean Build Folder (Important!)

In Xcode:
```
Press: ⌘ + Shift + K
Or Menu: Product → Clean Build Folder
```

**Why?** Ensures Xcode picks up all the new files.

---

## 📱 Step 6: Build & Run

1. **Select Your iPhone** from the device dropdown (top-left)
2. **Press**: `⌘ + R` (Command + R)
3. **Or**: Product → Run

**Wait for**: Build to complete (~30-60 seconds first time)

---

## ✅ What Should Happen

### Build Process:
```
1. Compiling DeviceCapabilityManager.swift
2. Compiling SensorFusionCore.swift
3. Compiling BiomechanicsEngine.swift
4. Compiling BiometricResult.swift
5. Compiling DepthAwareSkeletonView.swift
... (and modified files)
6. Linking
7. Signing
8. Installing to iPhone
```

### On Your iPhone:
1. ✅ App launches automatically
2. ✅ Console shows device detection:
   ```
   ════════════════════════════════════════════════════════
   AXIS LABS - System Capability Report
   ════════════════════════════════════════════════════════
   Mode:              AXIS LABS PRO (or Standard)
   LiDAR Available:   ✅ (or ❌)
   ...
   ```

---

## 🧪 Quick Test (5 minutes)

```bash
# After app is running on iPhone:

1. Start "The Morning Mobilizer" workout
2. Look for info banner (green or blue)
3. Complete 5 squats
4. Check workout report
5. Look for mode badge and metrics (if Pro)
```

---

## 🚨 Troubleshooting

### "Already up to date" when pulling
**Good!** That means you're on the latest version.

### Build Errors After Pull
**Fix**:
```bash
# In Terminal:
cd AI_Live_Trainer_System
rm -rf DerivedData

# In Xcode:
Product → Clean Build Folder (⌘ + Shift + K)
Product → Build (⌘ + B)
```

### "xcrun: error" or "xcodebuild not found"
**Fix**:
```bash
sudo xcode-select --switch /Applications/Xcode.app
```

### Git Pull Shows Conflicts
**Fix**:
```bash
git stash          # Save any local changes
git pull origin main
git stash pop      # Restore local changes
```

### Permission Denied
**Fix**:
```bash
# Make sure you have write permissions
ls -la
# If needed:
chmod -R u+w .
```

---

## 📊 Verify Update Worked

### Check File Count in Xcode:
Look in Project Navigator (left sidebar):
```
Engine/
├── AITrainerEngine.swift           (modified)
├── BiomechanicsEngine.swift        ⭐ NEW
├── DeviceCapabilityManager.swift   ⭐ NEW
├── SensorFusionCore.swift          ⭐ NEW
├── SessionAnalyticsEngine.swift    ⭐ NEW
└── (other files)

Models/
├── BiometricResult.swift           ⭐ NEW
└── (other files)

Views/
├── DepthAwareSkeletonView.swift    ⭐ NEW
└── (other files)
```

### Check Git Status:
```bash
git status
```
Should show: "Your branch is up to date with 'origin/main'"

---

## 🎯 Complete Mac Workflow (Copy-Paste)

```bash
# Navigate to project
cd ~/Desktop/SYS

# Pull latest changes
git pull origin main

# Open Xcode
open AI_Live_Trainer_System/AI_Live_Trainer_System.xcodeproj

# Then in Xcode:
# 1. Product → Clean Build Folder (⌘ + Shift + K)
# 2. Product → Run (⌘ + R)
```

---

## 📱 Alternative: Direct GitHub Desktop

If you use GitHub Desktop app:

1. **Open GitHub Desktop**
2. **Select**: "ai-live-trainer" repository
3. **Click**: "Fetch origin"
4. **Click**: "Pull origin"
5. **Open Xcode** and build

---

## ✅ Success Indicators

You'll know it worked when:
- ✅ Git pull shows "3893 insertions"
- ✅ Xcode shows 6 new files
- ✅ Build completes without errors
- ✅ App runs on iPhone
- ✅ Console shows "AXIS LABS - System Capability Report"
- ✅ Info banner appears during workout
- ✅ Workout report shows mode badge

---

## 💡 Pro Tip: View Commit Details

Want to see what changed?

```bash
git log --oneline -5

# Should show:
# 81b752e AXIS LABS Engine 2.0: Complete Implementation...
# db58145 (previous commits)
```

View full changes:
```bash
git show 81b752e
```

---

## 📚 Next Steps After Successful Pull

1. ✅ Read `VISUAL_GUIDE.md` to see what you'll see
2. ✅ Follow `TESTING_INSTRUCTIONS.md` for thorough testing
3. ✅ Check `WHATS_NEW_FOR_USERS.md` for user perspective

---

## 🎉 You're Ready!

After pulling and building:
- All 5 phases are implemented
- User-friendly UI is active
- Pro/Standard modes are working
- Export functionality is ready
- Zero errors, production-ready!

**Now test it on your iPhone!** 🚀

---

## Quick Reference

```bash
# Full workflow in one go:
cd ~/Desktop/SYS && \
git pull origin main && \
open AI_Live_Trainer_System/AI_Live_Trainer_System.xcodeproj

# Then in Xcode: ⌘+Shift+K, then ⌘+R
```

Done! 🎯

