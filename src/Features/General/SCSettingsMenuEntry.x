#import "../../InstagramHeaders.h"
#import "../../Settings/SCISettingsViewController.h"
#import <objc/runtime.h>

static char SCSettingsLongPressRecognizerKey;

static void SCInstallSettingsLongPress(UIView *view) {
    if (![view.accessibilityIdentifier isEqualToString:@"profile-more-button"]) return;

    // Instagram adds its own gestures to this button. Track ours separately so
    // those gestures do not prevent SCInsta from installing its shortcut.
    if (objc_getAssociatedObject(view, &SCSettingsLongPressRecognizerKey)) return;

    NSLog(@"[SCInsta] Adding tweak settings long press gesture recognizer");

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:view action:@selector(handleLongPress:)];
    [view addGestureRecognizer:longPress];
    objc_setAssociatedObject(view, &SCSettingsLongPressRecognizerKey, longPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Show SCInsta tweak settings by holding on the settings/more icon under profile for ~1 second
%hook IGBadgedNavigationButton
- (void)didMoveToWindow {
    %orig;
    SCInstallSettingsLongPress(self);
}

- (void)didMoveToSuperview {
    %orig;
    SCInstallSettingsLongPress(self);
}

- (void)setAccessibilityIdentifier:(NSString *)identifier {
    %orig;
    SCInstallSettingsLongPress(self);
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    
    NSLog(@"[SCInsta] Tweak settings gesture activated");

    [SCIUtils showSettingsVC:[self window]];
}
%end

// Quick access to tweak settings by holding on home tab button
%hook IGTabBarButton
- (void)didMoveToSuperview {
    %orig;

    // Only work on home/feed tab
    if (![self.accessibilityIdentifier isEqualToString:@"mainfeed-tab"]) return;
    
    if ([SCIUtils getBoolPref:@"settings_shortcut"]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.3;
        
        // Take precidence over existing gesture recognizers
        for (UIGestureRecognizer *existing in self.gestureRecognizers) {
            [existing requireGestureRecognizerToFail:longPress];
        }
        
        [self addGestureRecognizer:longPress];
    }
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    [SCIUtils showSettingsVC:[self window]];
}
%end
