# Biometric Authentication Troubleshooting Guide

## Recent Changes

### Enhanced Error Handling
1. **Settings Screen** - Added detailed error messages and feedback
2. **BiometricAuthService** - Added comprehensive logging for debugging

## Testing the Biometric Feature

### Step 1: Check Device Support
1. Open the app
2. Go to **Settings** (gear icon)
3. Look at the **Biometric Lock** option:
   - If it says "Biometric authentication not available" → Your device doesn't support it
   - If the switch is enabled → Your device supports biometrics

### Step 2: Enable Biometric Lock
1. Toggle the **Biometric Lock** switch to ON
2. You should see a biometric authentication prompt (fingerprint/face)
3. **Authenticate** using your fingerprint or face
4. You should see a green success message: "Biometric lock enabled"

### Step 3: Test the Lock
1. **Close the app** completely (swipe it away from recent apps)
2. **Reopen the app**
3. You should see the biometric lock screen with:
   - Animated pulsing lock icon
   - "Unlock" button
4. Tap "Unlock" and authenticate

### Step 4: Test App Lifecycle
1. With the app open, **lock your phone** (press power button)
2. **Unlock your phone**
3. Return to the app
4. You should be prompted for biometric authentication again

## What to Look For

### Success Indicators
✅ Biometric prompt appears when toggling ON
✅ Success message shows after authentication
✅ Lock screen appears when reopening app
✅ Authentication works when returning from background

### Error Messages You Might See

#### "Biometric authentication was cancelled or failed"
- **Cause**: You cancelled the biometric prompt or authentication failed
- **Solution**: Try again and complete the authentication

#### "Error: PlatformException..."
- **Cause**: Device doesn't support biometrics or no biometrics enrolled
- **Solution**: 
  1. Go to your phone's Settings
  2. Set up fingerprint or face unlock
  3. Try again in the app

#### "Biometric authentication not available"
- **Cause**: Device hardware doesn't support biometrics
- **Solution**: This feature won't work on your device

## Debugging

### Check the Logs
When you toggle the biometric switch, you should see logs like:
```
BiometricAuth: Starting authentication...
BiometricAuth: canCheckBiometrics = true
BiometricAuth: isDeviceSupported = true
BiometricAuth: canAuthenticate = true
BiometricAuth: Available biometrics: [BiometricType.fingerprint]
BiometricAuth: Calling authenticate with reason: Authenticate to enable biometric lock
BiometricAuth: Authentication result = true
```

### Common Issues

#### 1. Switch doesn't respond
**Check**: Is the switch grayed out?
- If YES → Biometrics not available on device
- If NO → Check logs for errors

#### 2. Authentication prompt doesn't appear
**Possible causes**:
- No biometrics enrolled on device
- Biometric service is disabled
- App doesn't have permission

**Solution**:
1. Check phone settings for biometric enrollment
2. Ensure biometric authentication is enabled system-wide
3. Check app permissions

#### 3. Authentication always fails
**Possible causes**:
- Biometric sensor is dirty
- Too many failed attempts (locked out)
- Biometric data needs re-enrollment

**Solution**:
1. Clean the fingerprint sensor
2. Wait a few minutes if locked out
3. Re-enroll your biometric data in phone settings

#### 4. Lock screen doesn't appear after enabling
**Check**:
1. Did you see the success message?
2. Close and reopen the app
3. Check logs for errors

## Manual Testing Checklist

- [ ] Device has biometrics enrolled
- [ ] Biometric Lock switch is enabled (not grayed out)
- [ ] Toggle switch to ON
- [ ] Biometric prompt appears
- [ ] Authenticate successfully
- [ ] See success message
- [ ] Close app completely
- [ ] Reopen app
- [ ] Lock screen appears
- [ ] Tap "Unlock" button
- [ ] Authenticate successfully
- [ ] App unlocks and shows chat list

## Permissions

### Android Manifest
Ensure this permission is in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

### iOS (if applicable)
Ensure this is in `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>We need to use Face ID to secure your encrypted messages</string>
```

## Advanced Debugging

### Enable Verbose Logging
The app now logs all biometric operations. To view logs:

**Android Studio / VS Code**:
- Open the Debug Console
- Look for lines starting with "BiometricAuth:"

**Command Line**:
```bash
flutter logs | grep BiometricAuth
```

### Test Biometric Availability
Add this temporary code to check device support:
```dart
final biometricAuth = BiometricAuthService();
final canCheck = await biometricAuth.canCheckBiometrics();
final available = await biometricAuth.getAvailableBiometrics();
print('Can check: $canCheck');
print('Available: $available');
```

## Known Limitations

1. **Emulators**: Biometric authentication may not work on emulators
2. **Old Devices**: Devices without biometric hardware won't support this feature
3. **Android < 6.0**: Biometric authentication requires Android 6.0+
4. **iOS < 11.0**: Face ID/Touch ID requires iOS 11.0+

## Success Criteria

The biometric feature is working correctly if:
1. ✅ You can toggle it ON in settings
2. ✅ Authentication prompt appears
3. ✅ Lock screen shows when reopening app
4. ✅ You can unlock with biometrics
5. ✅ App re-locks when backgrounded (if enabled)

## Still Not Working?

If after following this guide the biometric button still doesn't work:

1. **Share the logs**: Copy the console output showing "BiometricAuth:" lines
2. **Describe the behavior**: What happens when you tap the switch?
3. **Device info**: What phone model and Android/iOS version?
4. **Biometric setup**: Do you have fingerprint/face unlock set up on your phone?

This information will help diagnose the specific issue.
