
#import "ALAppDelegate.h"
#import "ALHtmlToAttributedStringParser.h"
#import "ALHtmlTextView.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0
#warning "This project uses features only available in iOS SDK 6.0."
#endif

@interface htmlppleDemoViewController : UIViewController
@end

@implementation htmlppleDemoViewController

-(NSAttributedString*) hppleParsedString
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test-data-3" ofType:@"html"];
    return [ALHtmlToAttributedStringParser attributedStringWithHTMLData:[[NSData alloc] initWithContentsOfFile:path]];
}

-(void) loadView
{
    ALHtmlTextView *exampleLabel = [[ALHtmlTextView alloc] initWithFrame:CGRectInset([[UIScreen mainScreen] bounds], 20, 20)];
    exampleLabel.editable = NO;
    exampleLabel.textAlignment = NSTextAlignmentLeft;
    exampleLabel.attributedText = [self hppleParsedString];
    self.view = exampleLabel;
}
@end


@implementation ALAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor darkGrayColor];
    self.window.rootViewController = [[htmlppleDemoViewController alloc] init];
    [self.window makeKeyAndVisible];
    
    
    return YES;
}

@end
