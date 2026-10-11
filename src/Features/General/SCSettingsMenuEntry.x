#import "../../InstagramHeaders.h"
#import "../../Settings/SCISettingsViewController.h"

// Add a dedicated, visible entry on profile pages. This avoids relying on
// Instagram's gesture handling for its own profile menu button.
%hook IGProfileViewController
- (void)viewDidLayoutSubviews {
    %orig;

    static NSInteger const SCInstaSettingsButtonTag = 0x534349;
    if ([self.view viewWithTag:SCInstaSettingsButtonTag]) return;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.tag = SCInstaSettingsButtonTag;
    button.accessibilityIdentifier = @"scinsta-settings-button";
    button.accessibilityLabel = @"SCInsta Settings";

    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = @"SCInsta";
    configuration.image = [UIImage systemImageNamed:@"slider.horizontal.3"];
    configuration.imagePlacement = NSDirectionalRectEdgeLeading;
    configuration.imagePadding = 6;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    button.configuration = configuration;

    [button addTarget:self action:@selector(sc_openSettings) forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:button];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [button.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-12],
        [button.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-12]
    ]];
}

%new - (void)sc_openSettings {
    [SCIUtils showSettingsVC:self.view.window];
}
%end

// Optional quick access from the home tab remains available for users who
// enable it in SCInsta settings.
%hook IGTabBarButton
- (void)didMoveToSuperview {
    %orig;

    if (![self.accessibilityIdentifier isEqualToString:@"mainfeed-tab"]) return;
    if (![SCIUtils getBoolPref:@"settings_shortcut"]) return;

    for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
        if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]]) return;
    }

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 0.3;

    for (UIGestureRecognizer *existing in self.gestureRecognizers) {
        [existing requireGestureRecognizerToFail:longPress];
    }

    [self addGestureRecognizer:longPress];
}

%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    [SCIUtils showSettingsVC:[self window]];
}
%end
