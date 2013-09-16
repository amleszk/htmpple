
#import "ALDemoTextViewController.h"
#import "ALDemoLabelViewController.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0
#warning "This project uses features only available in iOS SDK 6.0."
#endif

@interface ALAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end


@implementation ALAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor darkGrayColor];

    UITabBarController* tabbar = [[UITabBarController alloc] init];
    tabbar.viewControllers = @[
        [[ALDemoTextViewController alloc] init],
        [[ALDemoLabelViewController alloc] init]
    ];
    self.window.rootViewController = tabbar;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

@end
