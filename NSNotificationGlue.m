/*
 * NSNotificationGlue.m
 *
 * Objective-C glue library for NSNotificationCenter.lcb
 *
 * Handles all NSDistributedNotificationCenter and NSWorkspace notification
 * registration. When a notification fires, converts the name and userInfo
 * to plain C strings and calls back into LCB via a function pointer.
 *
 * Build as a dynamic library and place alongside the .lcb extension:
 *
 *   clang -fobjc-arc \
 *         -framework Foundation \
 *         -framework AppKit \
 *         -dynamiclib \
 *         -o NSNotificationGlue.dylib \
 *         NSNotificationGlue.m
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "NSNotificationGlue.h"

// ---------------------------------------------------------------------------
// Callback — stored as void*, cast on use. Matches toolbar pattern exactly.
// LCB passes its handler as a plain Pointer — no foreign handler type needed.
// ---------------------------------------------------------------------------
typedef void (*NotificationCallbackType)(const char *pName, const char *pUserInfo);
static NotificationCallbackType sNotificationCallback = NULL;

// ---------------------------------------------------------------------------
// Internal observer object — one shared instance handles all notifications
// from all three centers and funnels them through the single LCB callback.
// ---------------------------------------------------------------------------
@interface LCBNotificationObserver : NSObject
- (void)handleNotification:(NSNotification *)note;
@end

@implementation LCBNotificationObserver

- (void)handleNotification:(NSNotification *)note {
    if (!sNotificationCallback) return;

    const char *name = note.name ? [note.name UTF8String] : "";
    NSString *infoStr = note.userInfo ? ([note.userInfo description] ?: @"{}") : @"{}";
    const char *info = [infoStr UTF8String];

    // Copy strings to heap — safe to use after this stack frame
    char *nameCopy = strdup(name);
    char *infoCopy = strdup(info);

    NotificationCallbackType cb = sNotificationCallback;
    dispatch_async(dispatch_get_main_queue(), ^{
        cb(nameCopy, infoCopy);
        free(nameCopy);
        free(infoCopy);
    });
}

@end

// ---------------------------------------------------------------------------
// Module state
// ---------------------------------------------------------------------------
static LCBNotificationObserver *sObserver         = nil;
static NSMutableDictionary     *sDistTokens       = nil; // name -> token
static NSMutableDictionary     *sWorkspaceTokens  = nil; // name -> token

// ---------------------------------------------------------------------------
// C API called from LCB
// ---------------------------------------------------------------------------

// Set the LCB callback. Takes void* — LCB passes handler as function pointer.
void lcb_notifications_set_callback(void *callback) {
    sNotificationCallback = (NotificationCallbackType)callback;
    if (!sObserver) {
        sObserver        = [[LCBNotificationObserver alloc] init];
        sDistTokens      = [NSMutableDictionary dictionary];
        sWorkspaceTokens = [NSMutableDictionary dictionary];
    }
}

// Register a distributed notification by name.
void lcb_notifications_add_distributed(const char *name) {
    if (!sObserver || !name) return;
    NSString *nsName = [NSString stringWithUTF8String:name];
    if (sDistTokens[nsName]) return; // already registered

    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    id token = [center addObserverForName:nsName
                                   object:nil
                                    queue:nil
                               usingBlock:^(NSNotification *note) {
        [sObserver handleNotification:note];
    }];
    if (token) {
        sDistTokens[nsName] = token;
    }
}

// Register a workspace notification by name.
void lcb_notifications_add_workspace(const char *name) {
    if (!sObserver || !name) return;
    NSString *nsName = [NSString stringWithUTF8String:name];
    if (sWorkspaceTokens[nsName]) return; // already registered

    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
    id token = [center addObserverForName:nsName
                                   object:nil
                                    queue:nil
                               usingBlock:^(NSNotification *note) {
        [sObserver handleNotification:note];
    }];
    if (token) {
        sWorkspaceTokens[nsName] = token;
    }
}

// Remove a distributed observer by name.
void lcb_notifications_remove_distributed(const char *name) {
    if (!sDistTokens || !name) return;
    NSString *nsName = [NSString stringWithUTF8String:name];
    id token = sDistTokens[nsName];
    if (token) {
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:token];
        [sDistTokens removeObjectForKey:nsName];
    }
}

// Remove a workspace observer by name.
void lcb_notifications_remove_workspace(const char *name) {
    if (!sWorkspaceTokens || !name) return;
    NSString *nsName = [NSString stringWithUTF8String:name];
    id token = sWorkspaceTokens[nsName];
    if (token) {
        [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:token];
        [sWorkspaceTokens removeObjectForKey:nsName];
    }
}

// Remove all distributed observers.
void lcb_notifications_remove_all_distributed(void) {
    if (!sDistTokens) return;
    NSDistributedNotificationCenter *center = [NSDistributedNotificationCenter defaultCenter];
    for (id token in sDistTokens.allValues) {
        [center removeObserver:token];
    }
    [sDistTokens removeAllObjects];
}

// Remove all workspace observers.
void lcb_notifications_remove_all_workspace(void) {
    if (!sWorkspaceTokens) return;
    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
    for (id token in sWorkspaceTokens.allValues) {
        [center removeObserver:token];
    }
    [sWorkspaceTokens removeAllObjects];
}

// Post a distributed notification — used for testing.
void lcb_notifications_post_distributed(const char *name) {
    if (!name) return;
    [[NSDistributedNotificationCenter defaultCenter]
        postNotificationName:[NSString stringWithUTF8String:name]
                      object:nil
                    userInfo:nil
          deliverImmediately:YES];
}
