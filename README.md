# org.openxtalk.nsnotificationcenter

**Version:** 1.0.0  
**Author:** Emily-Elizabeth Howard  
**Platform:** macOS only  

A LiveCode Builder extension that lets LiveCode Script listen to macOS system notifications — appearance changes, screen saver events, sleep/wake, volume mount/unmount, media player events, and more.

All Objective-C work is handled by a companion glue dylib (`NSNotificationGlue.dylib`), keeping the LCB layer thin and stable. Callbacks are dispatched on the main thread and delivered as a `macNotification` message to the script object that registered the observer.

---

## Requirements

- macOS 10.14 or later (macOS 11+ recommended for SF Symbols icon support in related extensions)
- LiveCode / OpenXTalk with LCB extension support
- `NSNotificationGlue.dylib` built and placed in the extension's `code/` folder (see [Building the Glue](#building-the-glue))

---

## Installation

1. Build `NSNotificationGlue.dylib` (see below).
2. Place the compiled dylib into the extension package:
   - `code/x86_64-mac/NSNotificationGlue.dylib`
   - `code/arm64-mac/NSNotificationGlue.dylib`
3. Load the extension in your stack script or via the Extension Manager.

---

## Building the Glue

The `build_glue.sh` script compiles `NSNotificationGlue.m` as a universal binary and installs it into the extension package.

```bash
./build_glue.sh /path/to/org.openxtalk.nsnotificationcenter
```

Requirements: Xcode Command Line Tools installed (`xcode-select --install`).

To build manually:

```bash
clang -x objective-c -fobjc-arc \
      -framework Foundation -framework AppKit \
      -dynamiclib -arch arm64 \
      -o nstoolbar_glue_arm64.dylib NSNotificationGlue.m

clang -x objective-c -fobjc-arc \
      -framework Foundation -framework AppKit \
      -dynamiclib -arch x86_64 \
      -o NSNotificationGlue_x86_64.dylib NSNotificationGlue.m

lipo -create NSNotificationGlue_arm64.dylib NSNotificationGlue_x86_64.dylib \
     -output NSNotificationGlue.dylib
```

---

## Usage

### Receiving notifications

Add a `macNotification` handler to the object that calls the observer registration. The handler receives two parameters: the notification name and a string representation of the userInfo dictionary.

```livecode
on macNotification pName, pUserInfo
  switch pName
    case kMacNotifyAppearanceChanged
      -- update UI for dark/light mode
      break
    case kMacNotifySystemWillSleep
      -- save state before sleep
      break
    case kMacNotifyVolumeMounted
      -- a drive was connected
      put pUserInfo into field "log"
      break
  end switch
end macNotification
```

### Distributed notifications

Use `macNotificationsAddObserver` for system-wide notifications broadcast via `NSDistributedNotificationCenter`. These include appearance changes, screen saver events, media player state, network changes, and screen lock/unlock.

```livecode
on openStack
  macNotificationsAddObserver kMacNotifyAppearanceChanged
  macNotificationsAddObserver kMacNotifyScreenSaverStarted
  macNotificationsAddObserver kMacNotifyNetworkChanged
end openStack

on closeStack
  macNotificationsRemoveAllObservers
end closeStack
```

### Workspace notifications

Use `macWorkspaceAddObserver` for `NSWorkspace` notifications such as sleep/wake and volume events. **Do not register these in `openStack` or `preOpenStack`** — use a deferred `send` to avoid a potential hang on startup.

```livecode
on openStack
  send "registerWorkspaceObservers" to me in 0 milliseconds
end openStack

on registerWorkspaceObservers
  macWorkspaceAddObserver kMacNotifySystemWillSleep
  macWorkspaceAddObserver kMacNotifySystemDidWake
  macWorkspaceAddObserver kMacNotifyVolumeMounted
  macWorkspaceAddObserver kMacNotifyVolumeUnmounted
end registerWorkspaceObservers

on closeStack
  macWorkspaceRemoveAllObservers
end closeStack
```

### Local notifications

Use `macLocalAddObserver` for notifications posted to `[NSNotificationCenter defaultCenter]` within your process. This covers NSApplication lifecycle events — hide, unhide, resign/become active — and window events. Safe to call directly from `openStack`, no deferred send needed.

```livecode
on openStack
   macLocalAddObserver "NSApplicationWillHideNotification"
   macLocalAddObserver "NSApplicationDidUnhideNotification"
   macLocalAddObserver "NSApplicationWillResignActiveNotification"
   macLocalAddObserver "NSApplicationDidBecomeActiveNotification"
end openStack

on closeStack
   macLocalRemoveAllObservers
end closeStack
```

### Broadcasting a notification

Use `macNotificationsPost` to broadcast a distributed notification to any application listening for it — including other stacks or other instances of your own app. Use a reverse-DNS style name to avoid collisions with system notifications.

```livecode
macNotificationsPost "com.mycompany.myapp.dataUpdated"
```

Any stack that has registered an observer for that name will receive it:

```livecode
macNotificationsAddObserver "com.mycompany.myapp.dataUpdated"

on macNotification pName, pUserInfo
  if pName is "com.mycompany.myapp.dataUpdated" then
    -- refresh data
  end if
end macNotification
```

### Testing the callback pipeline

```livecode
macNotificationsAddObserver "test.notification"
macNotificationsPostTest
-- fires macNotification with pName = "test.notification"
```

---

## Notification Name Strings

LCB `public constant` values are not accessible from LiveCode Script scope. Use the raw notification name strings directly, or define your own constants in your stack script:

```livecode
constant kMacNotifyAppearanceChanged  = "AppleInterfaceThemeChangedNotification"
constant kMacNotifyMusicTrackChanged  = "com.apple.Music.playerInfo"
constant kMacNotifySpotifyTrackChanged = "com.spotify.client.PlaybackStateChanged"
constant kMacNotifyNetworkChanged     = "com.apple.system.config.network_change"
constant kMacNotifyScreenSaverStarted = "com.apple.screensaver.didstart"
constant kMacNotifyScreenSaverStopped = "com.apple.screensaver.didstop"
constant kMacNotifyDisplaySleep       = "com.apple.screenIsLocked"
constant kMacNotifyDisplayWake        = "com.apple.screenIsUnlocked"

constant kMacNotifySystemWillSleep    = "NSWorkspaceWillSleepNotification"
constant kMacNotifySystemDidWake      = "NSWorkspaceDidWakeNotification"
constant kMacNotifyScreensDidSleep    = "NSWorkspaceScreensDidSleepNotification"
constant kMacNotifyScreensDidWake     = "NSWorkspaceScreensDidWakeNotification"
constant kMacNotifyActiveAppChanged   = "NSWorkspaceDidActivateApplicationNotification"
constant kMacNotifyVolumeMounted      = "NSWorkspaceDidMountNotification"
constant kMacNotifyVolumeUnmounted    = "NSWorkspaceDidUnmountNotification"
```

### Distributed (use with `macNotificationsAddObserver`)

| Notification Name String | Notes |
|---|---|
| `AppleInterfaceThemeChangedNotification` | ✅ Verified macOS 14+ |
| `com.apple.Music.playerInfo` | ✅ Verified |
| `com.spotify.client.PlaybackStateChanged` | ✅ Verified (Spotify must be running) |
| `com.apple.system.config.network_change` | ✅ Verified |
| `com.apple.screensaver.didstart` | ✅ Verified |
| `com.apple.screensaver.didstop` | ✅ Verified |
| `com.apple.screenIsLocked` | ✅ Verified |
| `com.apple.screenIsUnlocked` | ✅ Verified |
| `com.apple.iTunes.playerInfo` | ⚠️ Legacy, iTunes only |

### Local (use with `macLocalAddObserver`)

| Notification Name String | Notes |
|---|---|
| `NSApplicationWillHideNotification` | ✅ Verified |
| `NSApplicationDidHideNotification` | ✅ Verified |
| `NSApplicationDidUnhideNotification` | ✅ Verified |
| `NSApplicationWillResignActiveNotification` | ✅ Verified |
| `NSApplicationDidBecomeActiveNotification` | ✅ Verified |

| Notification Name String | Notes |
|---|---|
| `NSWorkspaceWillSleepNotification` | ✅ Verified |
| `NSWorkspaceDidWakeNotification` | ✅ Verified |
| `NSWorkspaceScreensDidSleepNotification` | ✅ Verified |
| `NSWorkspaceScreensDidWakeNotification` | ✅ Verified |
| `NSWorkspaceDidActivateApplicationNotification` | ✅ Verified |
| `NSWorkspaceDidMountNotification` | ✅ Verified |
| `NSWorkspaceDidUnmountNotification` | ✅ Verified |

---

## Architecture

```
LiveCode Script
      │  macNotificationsAddObserver / macWorkspaceAddObserver
      ▼
NSNotificationCenter.lcb  (LCB extension)
      │  lcb_notifications_add_distributed / lcb_notifications_add_workspace
      ▼
NSNotificationGlue.dylib  (Objective-C)
      │  NSDistributedNotificationCenter / NSWorkspace notificationCenter
      ▼
macOS Notification System
      │  notification fires → block → handleNotification:
      │  dispatch_async(main_queue)
      ▼
NSNotificationGlue.dylib  (callback via function pointer)
      │  sNotificationCallback(name, userInfo)
      ▼
NSNotificationCenter.lcb  (OnNotification handler)
      │  post "macNotification" to mTarget
      ▼
LiveCode Script  (on macNotification pName, pUserInfo)
```

The glue library approach keeps all Objective-C and Cocoa API complexity out of LCB, avoids the LCB type system issues that arise from using `ObjcId` or `ObjcObject` in foreign handler declarations, and ensures all callbacks reach LiveCode on the main thread.

---

## Known Limitations

- macOS only. The extension handlers are no-ops on other platforms if you guard calls with `if the platform is "macos"`.
- Workspace notification registration should be deferred past `openStack` to avoid a potential hang in signed standalones.
- Some distributed notification names (Music track changes, screen saver) are no longer reliably posted on macOS Sonoma and later due to Apple's increased restrictions on inter-process communication.
- `pUserInfo` is a plain string representation of the NSDictionary (via `-description`), not structured data. Parse with care if you need specific values.

---

## License

MIT
