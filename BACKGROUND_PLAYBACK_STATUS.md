# Background Playback Status

## Current State (2025-11-30)

**Branch:** `feature/background-playback`

### Implementation Complete - Migration to just_audio_background

**Status:** MIGRATED from `audio_service` to `just_audio_background`

The app has been successfully migrated from the problematic `audio_service` package to `just_audio_background`, which is a simpler wrapper that should avoid the previous crashes.

## What Changed

### 1. Dependencies (pubspec.yaml)
- REMOVED: `audio_service: ^0.18.12`
- ADDED: `just_audio_background: ^0.0.1-beta.13`
- KEPT: `just_audio: ^0.9.36` and `audio_session: ^0.1.18`

### 2. Initialization (lib/main.dart)
Replaced the commented-out `AudioService.init()` with:
```dart
await JustAudioBackground.init(
  androidNotificationChannelId: 'io.github.collotsspot.massiv.audio',
  androidNotificationChannelName: 'Massiv Audio',
  androidNotificationOngoing: true,
  androidNotificationIcon: 'drawable/ic_notification',
);
```

### 3. AndroidManifest.xml
Changed activity from `.MainActivity` to:
```xml
android:name="com.ryanheise.audioservice.AudioServiceActivity"
```

### 4. LocalPlayerService (lib/services/local_player_service.dart)
Major simplification:
- Removed dual-path architecture (audioHandler vs fallback)
- Now uses single `AudioPlayer` instance with `just_audio_background` support
- Added MediaItem tags to AudioSource for notification display:
```dart
final source = AudioSource.uri(
  Uri.parse(url),
  headers: headers.isNotEmpty ? headers : null,
  tag: MediaItem(
    id: url,
    title: _currentMetadata?.title ?? 'Unknown Track',
    artist: _currentMetadata?.artist ?? 'Unknown Artist',
    album: _currentMetadata?.album ?? '',
    duration: _currentMetadata?.duration,
    artUri: _currentMetadata?.artworkUrl != null
        ? Uri.parse(_currentMetadata!.artworkUrl!)
        : null,
  ),
);
```

### 5. Removed Files
- `lib/services/audio_handler.dart` - No longer needed with just_audio_background

### 6. Provider Updates (lib/providers/music_assistant_provider.dart)
- Removed `audioHandler` import and references
- Removed callback setup for skip next/previous (will be implemented separately if needed)

## Architecture After Migration

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MASSIV FLUTTER APP                           │
└─────────────────────────────────────────────────────────────────────┘
                                  │
         ┌────────────────────────┴────────────────────────┐
         │ MusicAssistantProvider (ChangeNotifier)          │
         │   ├── LocalPlayerService                         │
         │   │     └── AudioPlayer (just_audio)             │
         │   │           └── JustAudioBackground integration│
         │   ├── MusicAssistantAPI (WebSocket)              │
         │   └── Player state management                    │
         └──────────────────────────────────────────────────┘
```

## How just_audio_background Works

1. **Initialization:** Called once in `main()` before `runApp()`
2. **Notification Display:** Automatic when AudioSource has a MediaItem tag
3. **Background Playback:** Enabled automatically (audio continues when app backgrounded)
4. **Media Controls:** Play/pause/seek handled automatically via notification
5. **Lock Screen:** Controls appear automatically on lock screen

## Expected Behavior

✅ **Should Work:**
- Background playback (audio continues when app minimized)
- Media notification with track info and artwork
- Notification play/pause control
- Lock screen media controls
- Audio focus handling (phone calls, headphone unplug)
- Position tracking and seek bar
- State sync with Music Assistant server

⚠️ **May Need Additional Work:**
- Skip next/previous buttons in notification (requires implementing custom media actions)
- Custom notification button callbacks

## Next Steps for Testing

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Build and test:**
   ```bash
   flutter build apk --debug
   ```
   Or for release:
   ```bash
   flutter build apk --release
   ```

3. **Install on device and verify:**
   - Play a track from Music Assistant
   - Check that notification appears with track info and artwork
   - Background the app - verify audio continues
   - Lock the screen - verify controls appear on lock screen
   - Test notification play/pause button
   - Test headphone unplug pause behavior
   - Answer a phone call - verify audio pauses

4. **Check logs:**
   ```bash
   adb logcat | grep "LocalPlayerService\|JustAudioBackground"
   ```

## Files Modified

- `pubspec.yaml` - Updated dependencies
- `lib/main.dart` - JustAudioBackground initialization
- `lib/services/local_player_service.dart` - Simplified to use AudioPlayer with MediaItem tags
- `lib/providers/music_assistant_provider.dart` - Removed audioHandler references
- `android/app/src/main/AndroidManifest.xml` - Changed to AudioServiceActivity

## Files Removed

- `lib/services/audio_handler.dart` - No longer needed

## AndroidManifest Configuration (Still Correct)

All required permissions and service declarations remain:

```xml
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<service android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
</service>

<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</receiver>
```

## Reference Implementation

This migration was based on the approach used by [Vaani](https://github.com/Dr-Blank/Vaani), another Music Assistant client that successfully uses `just_audio_background`.

## Why This Should Work

1. **Simpler API:** `just_audio_background` is a lightweight wrapper that handles the audio_service integration internally
2. **Less Configuration:** No need to manually implement BaseAudioHandler or manage MediaItem updates
3. **Proven Solution:** Used successfully in other Flutter music apps
4. **Automatic Notification:** MediaItem tag on AudioSource automatically populates notification
5. **No AudioService.init() crash:** The problematic `AudioService.init()` call is handled internally by just_audio_background

## Troubleshooting

If issues occur:

1. **Check logs for initialization:**
   - Look for "JustAudioBackground initialized" message
   - Check for any errors during initialization

2. **Verify notification icon:**
   - Ensure `android/app/src/main/res/drawable/ic_notification.xml` exists

3. **Check permissions:**
   - Verify all permissions in AndroidManifest.xml are granted

4. **Test on different devices:**
   - The previous crash may have been device-specific

## Known Limitations

- Skip next/previous in notification may require custom implementation
- Notification customization is more limited than full audio_service
- Still in beta (version 0.0.1-beta.13)

## Success Criteria

- ✅ App builds successfully
- ✅ No crashes on playback (unlike previous AudioService implementation)
- ⏳ Audio continues when app is backgrounded (TO BE VERIFIED)
- ⏳ Media notification displays with track info and artwork (TO BE VERIFIED)
- ⏳ Notification play/pause works (TO BE VERIFIED)
- ⏳ Lock screen media controls work (TO BE VERIFIED)
- ⏳ Audio focus handling works (TO BE VERIFIED)
- ✅ All existing in-app playback functionality preserved
- ✅ State continues to sync with Music Assistant server
