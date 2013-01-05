
#import "ALAppDelegate.h"
#import "ALHtmlToAttributedStringParser.h"
#import "ALHtmlTextView.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_6_0
#warning "This project uses features only available in iOS SDK 6.0."
#endif

@interface htmlppleDemoViewController : UIViewController <ALHtmlTextViewDelegate>
@end

@implementation htmlppleDemoViewController

-(NSAttributedString*) hppleParsedString
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test-data" ofType:@"html"];
    return [ALHtmlToAttributedStringParser attributedStringWithHTMLData:[[NSData alloc] initWithContentsOfFile:path]];
}

-(void) dealloc
{
    ((ALHtmlTextView *)self.view).linkDelegate = nil;
}

-(void) loadView
{
    ALHtmlTextView *exampleLabel = [[ALHtmlTextView alloc] initWithFrame:CGRectInset([[UIScreen mainScreen] bounds], 20, 20)];
    exampleLabel.editable = NO;
    exampleLabel.textAlignment = NSTextAlignmentLeft;
    exampleLabel.linkDelegate = self;
    [exampleLabel setLinkifiedAttributedText:[self hppleParsedString]];
    self.view = exampleLabel;
}

-(void) textView:(ALHtmlTextView *)textView didTapLinkWithHref:(NSString *)href
{
    [[[UIAlertView alloc] initWithTitle:@"Tapped:"
                                message:href
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
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
