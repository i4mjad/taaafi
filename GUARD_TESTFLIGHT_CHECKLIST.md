# Guard Feature TestFlight Quick Checklist

## Pre-Flight Checks (Do Before Building)

### 1. Apple Developer Portal
- [ ] App Group `group.com.taaafi.app` exists in Identifiers
- [ ] Family Controls capability enabled for main app identifier
- [ ] Family Controls capability enabled for extension identifier
- [ ] Provisioning profiles regenerated with Family Controls

### 2. Xcode Project Settings
- [ ] Main app has `Runner/Runner.entitlements` with:
  - `com.apple.developer.family-controls` = `true`
  - `com.apple.security.application-groups` includes `group.com.taaafi.app`
  
- [ ] Extension has `FocusDeviceActivityMonitor/FocusDeviceActivityMonitor.entitlements` with:
  - `com.apple.developer.family-controls` = `true`
  - `com.apple.security.application-groups` includes `group.com.taaafi.app`

- [ ] Extension is embedded in main app:
  - Xcode → Runner → General → Frameworks, Libraries, and Embedded Content
  - Should see `FocusDeviceActivityMonitor.appex` with "Embed & Sign"

### 3. Build Configuration
- [ ] iOS Deployment Target = 16.0+ (currently ✅)
- [ ] Main app bundle ID: `com.amjadkhalfan.RebootApp`
- [ ] Extension bundle ID: `com.amjadkhalfan.RebootApp.FocusDeviceActivityMonitor`
- [ ] Both targets use same signing team

## Build & Upload
```bash
# Clean build
flutter clean
flutter pub get
cd ios
pod install
cd ..

# Build for release
flutter build ios --release

# Open Xcode to upload
open ios/Runner.xcworkspace
```

In Xcode:
1. Select "Any iOS Device (arm64)"
2. Product → Archive
3. Distribute App → App Store Connect → Upload
4. Wait for processing (~5-10 minutes)

## TestFlight Testing Steps

### Test 1: Fresh Authorization Flow
1. [ ] Delete app completely from device
2. [ ] Install from TestFlight
3. [ ] Navigate to Guard screen
4. [ ] Tap settings icon (⚙️)
5. [ ] See "Request Authorization" button (should be enabled, not locked)
6. [ ] Tap "Request Authorization"
7. [ ] iOS permission dialog appears
8. [ ] Grant permission
9. [ ] Success message appears
10. [ ] "Request Authorization" button disappears
11. [ ] "Select Apps and Sites" and "Start Monitoring" are enabled

### Test 2: Picker Functionality
12. [ ] Tap "Select Apps and Sites"
13. [ ] Picker sheet appears
14. [ ] Can see app categories (Social, Games, etc.)
15. [ ] **CRITICAL**: Can see individual apps under categories
16. [ ] Can tap apps to select them (they get checkmarks)
17. [ ] Can deselect apps
18. [ ] Tap "Done"
19. [ ] Picker closes

### Test 3: Selection Persistence
20. [ ] Re-open picker (tap "Select Apps and Sites" again)
21. [ ] Previously selected apps are still selected
22. [ ] Can modify selection
23. [ ] Changes persist

### Test 4: Monitoring
24. [ ] Close picker
25. [ ] Tap "Start Monitoring"
26. [ ] Success message appears
27. [ ] Use some apps on the device
28. [ ] Wait ~5 minutes
29. [ ] Check Guard screen for usage data

## Debugging (If Issues)

### View Native Logs
1. In Guard screen, tap list icon (📋) to view logs
2. Look for:
   ```
   ✅ GOOD: ios_requestAuthorization:done true
   ✅ GOOD: ios_getAuthorizationStatus:done true
   ✅ GOOD: ios_presentPicker:done
   ❌ BAD: any line with "ERROR"
   ```

### Common Failures & Solutions

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| "Request Authorization" locked | Authorization check failing | Check app has Family Controls entitlement |
| Permission dialog never appears | Already granted/denied or missing entitlement | Delete app, check entitlements, reinstall |
| Picker shows categories but NO apps | Authorization not `.approved` | Check logs for authorization status, try re-granting |
| Picker crashes when opening | Extension not properly embedded | Check Xcode build settings |
| Selected apps don't persist | App Group not working | Verify app group in both entitlements |
| "Select Apps" does nothing | Native bridge issue | Check logs for errors |

### Critical Log Messages to Check

**Authorization Success:**
```
D [Runner] ios_requestAuthorization:start
D [Runner] requestAuthorization current status: approved
D [Runner] authorization already approved
D [Runner] ios_requestAuthorization:done true
```

**Picker Presentation:**
```
D [Runner] ios_presentPicker:start
D [Runner] presenting FamilyActivityPicker
D [Runner] FamilyActivityPicker presented
D [Runner] ios_presentPicker:done
```

**Monitoring Start:**
```
D [Runner] ios_startMonitoring:start
D [Runner] startRealtimeMonitoring
D [Runner] realtime monitoring started (5min intervals + 1min thresholds)
D [Runner] ios_startMonitoring:done true
```

## App Store Connect Settings

Before submitting for review:

- [ ] Add "Privacy - Screen Time Usage" to Info.plist (if required)
- [ ] Prepare explanation of why Family Controls is needed
- [ ] Document that no user data is collected (only usage tokens)
- [ ] Have privacy policy ready that explains Screen Time usage

## Emergency Rollback

If completely broken in TestFlight:

1. Revert changes:
   ```bash
   git checkout HEAD~1 lib/features/guard/
   ```

2. Or disable feature:
   - Add feature flag in code
   - Hide Guard screen tab temporarily
   - Show "Coming Soon" message

## Success Criteria

✅ Feature is working if:
1. Authorization dialog appears and can be granted
2. Picker shows both categories AND individual apps
3. Can select/deselect apps with checkmarks
4. Selections persist across app restarts
5. Monitoring captures usage data
6. No crashes in TestFlight crash reports

## Contact/Notes

- iOS Version Required: 16.0+
- Test Device Recommended: iPhone with iOS 16.0+
- Extension Name: FocusDeviceActivityMonitor
- App Group: group.com.taaafi.app
- Main Bundle: com.amjadkhalfan.RebootApp

---

**Last Updated**: After code fixes for authorization status checking
**Modified Files**: 
- `ios_focus_providers.dart`
- `guard_usage_repository.dart`  
- `ios_picker_controls_modal.dart`

