
#import "ALAppDelegate.h"
#import "ALDemoTextViewController.h"
#import "ALDemoLabelViewController.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0
#warning "This project uses features only available in iOS SDK 6.0."
#endif

@implementation ALAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor darkGrayColor];

    //self.window.rootViewController = [[ALDemoTextViewController alloc] init];
    self.window.rootViewController = [[ALDemoLabelViewController alloc] init];
    

    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

@end
