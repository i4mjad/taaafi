# ScreenTime API Integration - Validation Checklist

## Purpose
Verify that iOS ScreenTime data is being captured and displayed correctly in the app.

---

## Part 1: iOS Native Data Capture ✅

### Test 1.1: DeviceActivityReport (Primary Data Source)
**What it does**: Shows Apple's official Screen Time data for today

**How to test**:
1. Open the app and navigate to Guard screen
2. Grant Screen Time permissions when prompted
3. Select some apps in the picker
4. **Use your iPhone normally for 10-15 minutes** (browse apps, use Safari, etc.)
5. Return to the app

**Expected Result**:
- You should see a widget showing "Today's Screen Time" with a time like "15m" or "1h 5m"
- This widget is located at lines 226-267 in `guard_screen.dart`
- The native iOS widget (`TotalActivityView`) should display real usage

**How to verify it's real data**:
- Open Settings → Screen Time on your iPhone
- Compare the total time shown there with what your app displays
- They should match (within a few minutes due to refresh delays)

---

### Test 1.2: Monitor Extension Data (Secondary/Custom Data)
**What it does**: Creates custom usage snapshots (currently simplified)

**Current limitation**: 
- The Monitor extension (FocusDeviceActivityMonitor) is currently just tracking "monitored apps" as a single bucket
- It's NOT getting per-app usage from Apple - that's expected and correct
- Apple doesn't provide per-app usage APIs in the Monitor extension

**How to test**:
1. Check the native logs by tapping the list icon in the app bar
2. Look for entries like:
   ```
   🔴 [EXTENSION] eventDidReachThreshold
   🔴 [EXTENSION] updateSnapshot: existing minutes=XX
   ```

**Expected Result**:
- Logs should show the Monitor extension is being triggered
- Snapshot should be incrementing over time

---

## Part 2: Flutter Data Display ✅

### Test 2.1: DeviceActivityReport Widget Display
**Location**: Lines 226-267 in `guard_screen.dart`

**How to test**:
1. Ensure you have Screen Time authorization
2. Should see a card titled "Today's Usage"
3. Inside should be the native iOS widget showing your actual Screen Time

**Check**:
```dart
// This should be visible
if (Platform.isIOS)
  Consumer(
    builder: (context, ref, child) {
      final auth = ref.watch(iosAuthStatusProvider);
      // ... DeviceActivityReport widget
    },
  )
```

**Expected**: Real Screen Time data from Apple

---

### Test 2.2: Opal-Style Focus Score Card
**Location**: Lines 269-327 in `guard_screen.dart`

**What it shows**:
- Focus Score (0-100%)
- Total screen time
- Number of apps
- Pickups count

**Data source**: `usageMetricsProvider` which reads from `iosSnapshotProvider`

**How to test**:
1. Look at the colorful gem/circle at top of screen
2. Check if it shows a percentage
3. Verify screen time is displayed below it

**Expected**:
- If no data yet: Empty state with "No app usage data"
- If has data: Shows metrics calculated from snapshot

---

### Test 2.3: Top Apps List
**Location**: Lines 330-378 in `guard_screen.dart`

**What it shows**: List of top 5 apps by usage time

**How to test**:
1. Scroll down to "Top Apps" section
2. Check if apps are listed with colored circles and time

**Expected**:
- Currently will show "Monitored Apps" as a single entry
- Shows time in format like "15m" or "2h 30m"

---

## Part 3: Data Flow Validation

### Test 3.1: Platform Channel Communication

**How to test**:
1. Open the logs modal (list icon in app bar)
2. Look for entries like:
   ```
   Dart→Native ios_getSnapshot
   Native→Dart ios_getSnapshot OK
   ```

**Expected**: Regular polling every 10 seconds when Guard screen is active

---

### Test 3.2: Real-time Updates

**How to test**:
1. Keep the Guard screen open
2. Use other apps on your phone for 2-3 minutes
3. Return to the Guard screen
4. Tap the refresh icon

**Expected**:
- OpalFocusScoreCard should update with new time
- Native DeviceActivityReport widget should also refresh

---

## Part 4: Known Limitations & Architecture

### Current Architecture:

```
┌─────────────────────────────────────────┐
│  APPLE'S OFFICIAL SCREENTIME DATA       │
│  (DeviceActivityReport Extension)       │
│  ✅ Has access to real per-app usage    │
│  ✅ Embedded in Flutter via UiKitView   │
│  ✅ Shows accurate today's total time    │
└─────────────────────────────────────────┘
              ↓
        [Displayed in]
              ↓
┌─────────────────────────────────────────┐
│  IosActivityReportView Widget           │
│  Location: guard_screen.dart:226-267    │
│  Shows: Native iOS Screen Time widget   │
└─────────────────────────────────────────┘


┌─────────────────────────────────────────┐
│  CUSTOM MONITORING DATA                 │
│  (FocusDeviceActivityMonitor Extension) │
│  ⚠️  Does NOT have per-app usage API    │
│  ⚠️  Currently just tracks "monitored"  │
│  ✅ Receives callbacks on usage events  │
└─────────────────────────────────────────┘
              ↓
        [Stored in App Group]
              ↓
        [Fetched by Flutter via]
              ↓
┌─────────────────────────────────────────┐
│  FocusBridge.getLastSnapshot()          │
│  Returns: {"apps": [...], ...}          │
└─────────────────────────────────────────┘
              ↓
        [Displayed in]
              ↓
┌─────────────────────────────────────────┐
│  OpalFocusScoreCard + OpalAppUsageList  │
│  Location: opal_style_focus_display.dart│
│  Shows: Custom UI with metrics          │
└─────────────────────────────────────────┘
```

### Apple's API Limitations:
1. **Monitor Extension CANNOT query usage stats** - This is by design
2. **DeviceActivityReport Extension CAN access usage** - via DeviceActivityResults
3. **No way to get per-app usage in real-time** - Must use DeviceActivityReport

---

## Recommendations for Your App

### Option A: Use DeviceActivityReport Only (Simplest)
- Keep the existing `IosActivityReportView` widget
- This shows **real Apple Screen Time data**
- Remove or deprecate the custom Monitor extension tracking
- **Pros**: Official, accurate, maintained by Apple
- **Cons**: Less customization, can't style the widget much

### Option B: Enhance Monitor Extension Tracking (Complex)
- Keep Monitor extension but acknowledge its limitations
- Use it for:
  - Tracking usage duration (total only, not per-app)
  - Triggering notifications based on thresholds
  - Detecting when user is using monitored apps
- **Pros**: More control over notifications and interventions
- **Cons**: Can't get per-app breakdown from Monitor

### Option C: Hybrid Approach (Recommended for your case)
- **Primary data source**: DeviceActivityReport for accurate Screen Time display
- **Secondary tracking**: Monitor extension for:
  - Real-time intervention triggers
  - Custom focus score calculations
  - Notification scheduling
  - Duration tracking (without per-app breakdown)
  
- Show **both widgets**:
  1. Native DeviceActivityReport (accurate Screen Time)
  2. Custom Opal cards (focus score, simplified metrics)

**This is what you currently have implemented!** ✅

---

## What to Check Right Now

Run through this quick validation:

1. **Authorization Status**
   ```dart
   // In Flutter, check:
   ref.watch(iosAuthStatusProvider)
   // Should return AsyncValue.data(true) if authorized
   ```

2. **Monitor is Running**
   ```
   // Check logs for:
   🔵 [FLUTTER→IOS] ios_startMonitoring: START
   === startHourlyMonitoring: START ===
   startHourlyMonitoring: ✅ monitoring started successfully
   ```

3. **DeviceActivityReport Renders**
   ```
   // Check logs for:
   📱 [REPORT WIDGET] === IosActivityReportView: build ===
   🟠 [REPORT FACTORY] === create: START ===
   🟢 [REPORT SCENE] === makeConfiguration: START ===
   ```

4. **Data is Flowing**
   ```
   // Check logs for:
   Dart→Native ios_getSnapshot
   Native→Dart ios_getSnapshot OK
   iosGetSnapshot: ✅ snapshot received - apps=1
   ```

---

## If DeviceActivityReport Shows "No activity data"

This is normal if:
1. You just installed the app (no usage history yet)
2. You haven't used selected apps today
3. Screen Time is disabled in Settings
4. It's a simulator (Screen Time doesn't work in simulator)

**Solution**: 
- Test on a real device
- Use your phone normally for 15+ minutes
- Check Settings → Screen Time to verify it's tracking

---

## Next Steps

1. ✅ Validate that DeviceActivityReport widget shows real data
2. ✅ Confirm Monitor extension is creating snapshots (even if simplified)
3. ✅ Verify both data sources display in the UI
4. ❓ **Decide if you need per-app breakdown in custom UI**

If you need per-app data in your custom Opal cards, you'll need to enhance the DeviceActivityReport extension to export that data to App Group storage, then read it in Flutter.

Would you like me to implement that enhancement?

