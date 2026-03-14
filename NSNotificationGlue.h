/*
 * NSNotificationGlue.h
 *
 * C API for NSNotificationGlue.dylib
 * Provides macOS notification centre registration for NSNotificationCenter.lcb
 *
 * Author: Emily-Elizabeth Howard
 */

#ifndef NSNotificationGlue_h
#define NSNotificationGlue_h

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Callback type invoked when any registered notification fires.
 * pName    : UTF-8 notification name string
 * pUserInfo: UTF-8 description of the notification's userInfo dictionary,
 *            or "{}" if none was provided
 */
typedef void (*NotificationCallbackType)(const char *pName, const char *pUserInfo);

void lcb_notifications_set_callback(void *callback);

/**
 * Register a distributed notification observer by name.
 * Use for: appearance, screen saver, screen lock, Spotify, network etc.
 * Safe to call multiple times — duplicate registrations are ignored.
 */
void lcb_notifications_add_distributed(const char *name);

/**
 * Register a workspace notification observer by name.
 * Use for: sleep, wake, volume mount/unmount, app activation etc.
 * Call after the app is fully launched — not during startup.
 */
void lcb_notifications_add_workspace(const char *name);

/**
 * Register a local (per-process) notification observer by name.
 * Use for: NSApplication hide/unhide, window events, and any notification
 * posted to [NSNotificationCenter defaultCenter].
 */
void lcb_notifications_add_local(const char *name);

/**
 * Remove a single distributed notification observer by name.
 */
void lcb_notifications_remove_distributed(const char *name);

/**
 * Remove a single workspace notification observer by name.
 */
void lcb_notifications_remove_workspace(const char *name);

/**
 * Remove a single local notification observer by name.
 */
void lcb_notifications_remove_local(const char *name);

/**
 * Remove all registered distributed notification observers.
 */
void lcb_notifications_remove_all_distributed(void);

/**
 * Remove all registered workspace notification observers.
 */
void lcb_notifications_remove_all_workspace(void);

/**
 * Remove all registered local notification observers.
 */
void lcb_notifications_remove_all_local(void);

/**
 * Post a test notification to the distributed center.
 * Useful for verifying the callback is wired up correctly.
 */
void lcb_notifications_post_distributed(const char *name);

#ifdef __cplusplus
}
#endif

#endif /* NSNotificationGlue_h */
