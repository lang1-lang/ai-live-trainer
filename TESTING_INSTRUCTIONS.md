# 🧪 Testing AXIS LABS Engine 2.0 on Your iPhone

## Pre-Test Checklist

✅ All code changes saved  
✅ Zero linter errors  
✅ Enhanced UI labels added  
✅ User guide created (`WHATS_NEW_FOR_USERS.md`)  

---

## Step 1: Open Xcode

```bash
cd "C:\Users\chase\OneDrive\Desktop\SYS\AI_Live_Trainer_System"
# Then double-click: AI_Live_Trainer_System.xcodeproj
```

Or from Finder:
- Navigate to Desktop > SYS > AI_Live_Trainer_System
- Double-click `AI_Live_Trainer_System.xcodeproj`

---

## Step 2: Build Settings

1. **Select Target**: "AI_Live_Trainer_System" at the top
2. **Select Your iPhone**: Choose your connected iPhone from device dropdown
3. **Signing**: Ensure your Apple ID/Team is selected
4. **Build Configuration**: Release (for best performance)

---

## Step 3: Build & Deploy

**Shortcut**: Press `⌘R` (Command + R)

Or click: **Product** → **Run**

**Expected**: App builds and launches on your iPhone automatically

---

## Step 4: Test Checklist

### 🔍 Initial Detection Test
1. App opens
2. Look at console output (should print):
   ```
   ════════════════════════════════════════════════════════
   AXIS LABS - System Capability Report
   ════════════════════════════════════════════════════════
   Mode:              AXIS LABS PRO (or Standard)
   Device:            [Your iPhone name]
   Model:             iPhone14,3
   LiDAR Available:   ✅ (or ❌)
   iOS 17+ (3D):      ✅
   Pro Mode Ready:    ✅ (or ❌)
   ════════════════════════════════════════════════════════
   ```

### 🏋️ Workout Test
1. **Start a workout**: Tap "The Morning Mobilizer"
2. **Check the info banner**: 
   - Should appear at top for 8 seconds
   - 🟢 Green "LiDAR Active" (Pro) OR 🔵 Blue "Standard Mode"
3. **Look for mode badge**: Top-right corner shows "PRO" or nothing
4. **Watch the skeleton**:
   - Pro Mode: Colors shift (green→yellow→blue) based on distance
   - Standard Mode: Green/red based on form
5. **Complete 1 set**

### 📊 Report Test
After completing the workout, check the report screen:

#### ✅ Everyone Should See:
- ✅ "Workout Complete!" header
- ✅ Mode badge below workout name (PRO MODE or STANDARD MODE)
- ✅ Form Accuracy circle
- ✅ Stats grid (Duration, Reps, Sets, Calories)

#### ✅ Pro Mode Users Should ALSO See:
- ✅ **"PRO BIOMECHANICS"** section with green icon
- ✅ Description: "🎯 Military-grade measurements..."
- ✅ **Metric cards** showing:
  - Knee Angle Deg: 87.3°
  - Hip Depth Meters: 0.45m
  - Left Knee Valgus Meters: 0.01m
  - (and more depending on exercise)
- ✅ Green **"Export Detailed Data"** button
- ✅ Helper text: "💾 Share with coaches..."

#### ✅ Standard Mode Users Should See:
- ✅ Blue "STANDARD MODE" badge
- ✅ Regular stats (no biomechanics section)
- ✅ No export button

### 💾 Export Test (Pro Mode Only)
1. **Tap**: "Export Detailed Data"
2. **Choose**: CSV or JSON
3. **Share**: Via AirDrop/Email/Files
4. **Verify**: File contains workout data

**CSV Should Look Like**:
```csv
Timestamp,IsCorrect,Confidence,Feedback
0.0,true,0.85,"Perfect squat form!"
1.5,false,0.75,"Go deeper! Lower your hips below knee level."

Metric,Value
knee_angle_deg,87.3
hip_depth_meters,0.45
```

**JSON Should Look Like**:
```json
{
  "session_id": "ABC-123-...",
  "workout_name": "The Morning Mobilizer",
  "device_mode": "pro",
  "average_metrics": {
    "knee_angle_deg": 87.3,
    "hip_depth_meters": 0.45
  }
}
```

---

## Step 5: Visual Confirmation

### During Workout (Pro Mode)
- [ ] Info banner appears (green background)
- [ ] Banner says "LiDAR Active: Military-Grade Precision"
- [ ] Top-right shows "PRO" badge with laser icon
- [ ] Skeleton colors change with distance
- [ ] Joints are larger when confident

### During Workout (Standard Mode)
- [ ] Info banner appears (blue background)
- [ ] Banner says "Standard Mode: High-Quality Analysis"
- [ ] No PRO badge shown
- [ ] Skeleton is green/red based on form

### After Workout (Pro Mode)
- [ ] Large green badge: "PRO MODE" with laser icon
- [ ] Subtitle: "LiDAR + 3D Analysis"
- [ ] PRO BIOMECHANICS section with metrics
- [ ] Export button present

### After Workout (Standard Mode)
- [ ] Large blue badge: "STANDARD MODE" with camera icon
- [ ] Subtitle: "2D Vision Analysis"
- [ ] No biomechanics section
- [ ] No export button

---

## Troubleshooting

### "I don't see PRO MODE but I have iPhone 12 Pro+"
**Check**:
1. iOS version (need iOS 17+)
2. Console output for "LiDAR Available: ❌"
3. Camera permissions granted
4. LiDAR lens not blocked

### "App crashes when starting workout"
**Check**:
1. Camera permission granted
2. Xcode console for error messages
3. Device has enough storage/battery

### "Skeleton not appearing"
**Try**:
1. Better lighting
2. Stand further back (6-8 feet)
3. Ensure full body visible
4. Try landscape orientation

### "Export button doesn't work"
**Check**:
1. Confirm you're in Pro Mode (green badge)
2. Tap and wait for dialog
3. Check if iOS sharing sheet appears

---

## Expected Performance

| Metric | Target | What to Look For |
|--------|--------|------------------|
| Frame Rate | 28-30 FPS | Smooth skeleton tracking |
| Latency | < 100ms | Instant feedback on form |
| Accuracy | < 2cm | Reliable depth measurements |
| Battery | Normal | No excessive drain |

---

## What Success Looks Like

✅ **Mode Detection**: App correctly identifies your iPhone model  
✅ **Visual Feedback**: Clear badges and banners during/after workout  
✅ **Metrics Display**: Pro users see detailed biomechanics data  
✅ **Export Works**: Pro users can download CSV/JSON files  
✅ **Smooth Performance**: No lag, crashes, or stuttering  
✅ **User-Friendly**: Everything is clearly labeled and explained  

---

## Quick Test Script

**5-Minute Test**:
1. ✅ Open app (0:30)
2. ✅ Start "Morning Mobilizer" (0:30)
3. ✅ Check info banner appears (0:10)
4. ✅ Do 5 squats (1:00)
5. ✅ Complete set (0:30)
6. ✅ Check workout report (1:00)
7. ✅ Export data if Pro Mode (1:00)
8. ✅ Done! (Total: ~5 min)

---

## Report Back

After testing, note:
- ✅ Which mode did you get? (Pro or Standard)
- ✅ Did all UI elements appear correctly?
- ✅ Were the banners clear and helpful?
- ✅ Did export work? (Pro mode only)
- ✅ Any crashes or issues?

---

## Notes

- **Physical device required**: Simulator won't work (needs camera)
- **First run**: May ask for camera permissions
- **Console output**: Check Xcode console for technical details
- **Screenshots**: Take screenshots of key screens for verification

---

**Ready to test!** 🚀

Open Xcode, connect your iPhone, press ⌘R, and let's see AXIS LABS Engine 2.0 in action!

