-- =============================================================================
-- NSNotificationCenter Library — Example LiveCode Script
-- Place this in your main stack script.
--
-- LCB public constants are not accessible from LiveCode Script scope.
-- Define notification name strings as LiveCode Script constants here,
-- or use the raw strings directly in your handlers.
-- =============================================================================

constant kMacNotifyAppearanceChanged   = "AppleInterfaceThemeChangedNotification"
constant kMacNotifyMusicTrackChanged   = "com.apple.Music.playerInfo"
constant kMacNotifySpotifyTrackChanged = "com.spotify.client.PlaybackStateChanged"
constant kMacNotifyNetworkChanged      = "com.apple.system.config.network_change"
constant kMacNotifyScreenSaverStarted  = "com.apple.screensaver.didstart"
constant kMacNotifyScreenSaverStopped  = "com.apple.screensaver.didstop"
constant kMacNotifyDisplaySleep        = "com.apple.screenIsLocked"
constant kMacNotifyDisplayWake         = "com.apple.screenIsUnlocked"

constant kMacNotifySystemWillSleep     = "NSWorkspaceWillSleepNotification"
constant kMacNotifySystemDidWake       = "NSWorkspaceDidWakeNotification"
constant kMacNotifyScreensDidSleep     = "NSWorkspaceScreensDidSleepNotification"
constant kMacNotifyScreensDidWake      = "NSWorkspaceScreensDidWakeNotification"
constant kMacNotifyActiveAppChanged    = "NSWorkspaceDidActivateApplicationNotification"
constant kMacNotifyVolumeMounted       = "NSWorkspaceDidMountNotification"
constant kMacNotifyVolumeUnmounted     = "NSWorkspaceDidUnmountNotification"

-- =============================================================================

on openStack
   -- Register distributed notifications immediately on open.
   -- These are safe to register right away.
   macNotificationsAddObserver kMacNotifyAppearanceChanged
   macNotificationsAddObserver kMacNotifyMusicTrackChanged
   macNotificationsAddObserver kMacNotifySpotifyTrackChanged
   macNotificationsAddObserver kMacNotifyNetworkChanged
   macNotificationsAddObserver kMacNotifyScreenSaverStarted
   macNotificationsAddObserver kMacNotifyScreenSaverStopped
   macNotificationsAddObserver kMacNotifyDisplaySleep
   macNotificationsAddObserver kMacNotifyDisplayWake
   
   -- Workspace notifications must be registered after the stack is fully open.
   -- Use "send ... in 0 milliseconds" to defer until the engine is ready.
   send "registerWorkspaceObservers" to me in 0 milliseconds
end openStack

on registerWorkspaceObservers
   macWorkspaceAddObserver kMacNotifySystemWillSleep
   macWorkspaceAddObserver kMacNotifySystemDidWake
   macWorkspaceAddObserver kMacNotifyScreensDidSleep
   macWorkspaceAddObserver kMacNotifyScreensDidWake
   macWorkspaceAddObserver kMacNotifyVolumeMounted
   macWorkspaceAddObserver kMacNotifyVolumeUnmounted
   macWorkspaceAddObserver kMacNotifyActiveAppChanged
end registerWorkspaceObservers

on closeStack
   -- Always clean up observers when the stack closes.
   macNotificationsRemoveAllObservers
   macWorkspaceRemoveAllObservers
end closeStack

-- =============================================================================
-- macNotification pName, pUserInfo
-- All registered notifications — both distributed and workspace — deliver here.
-- pName    : the notification name string
-- pUserInfo: a string representation of the notification's userInfo dictionary,
--            or "{}" if none was provided
-- =============================================================================

on macNotification pName, pUserInfo
   switch pName
      
      -- Appearance
      case kMacNotifyAppearanceChanged
         put "Appearance changed" into field "log"
         break
      
      -- Music / Spotify
      case kMacNotifyMusicTrackChanged
         put "Music: " & pUserInfo into field "log"
         break

      case kMacNotifySpotifyTrackChanged
         put "Spotify: " & pUserInfo into field "log"
         break

      -- Network
      case kMacNotifyNetworkChanged
         put "Network configuration changed" into field "log"
         break

      -- Screen saver
      case kMacNotifyScreenSaverStarted
         put "Screen saver started" into field "log"
         break
         
      case kMacNotifyScreenSaverStopped
         put "Screen saver stopped" into field "log"
         break
      
      -- Screen lock
      case kMacNotifyDisplaySleep
         put "Screen locked" into field "log"
         break
         
      case kMacNotifyDisplayWake
         put "Screen unlocked" into field "log"
         break
      
      -- Sleep / wake
      case kMacNotifySystemWillSleep
         put "System going to sleep" into field "log"
         break
         
      case kMacNotifySystemDidWake
         put "System woke from sleep" into field "log"
         break

      case kMacNotifyScreensDidSleep
         put "Screens slept" into field "log"
         break

      case kMacNotifyScreensDidWake
         put "Screens woke" into field "log"
         break
      
      -- Volume mount / unmount
      case kMacNotifyVolumeMounted
         put "Volume mounted: " & pUserInfo into field "log"
         break
         
      case kMacNotifyVolumeUnmounted
         put "Volume unmounted: " & pUserInfo into field "log"
         break
      
      -- App activation
      case kMacNotifyActiveAppChanged
         put "Active app changed: " & pUserInfo into field "log"
         break
      
      default
         put "Unknown notification: " & pName & " — " & pUserInfo into field "log"
         break
         
   end switch
end macNotification
