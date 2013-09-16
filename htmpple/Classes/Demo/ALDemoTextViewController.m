
#import "ALHtmlToAttributedStringParser.h"
#import "ALDemoTextViewController.h"
#import "ALLinkTextView6.h"
#import "ALLinkTextView7.h"

@interface ALDemoTextViewController () <ALLinkTextViewDelegate>
@property (retain) ALLinkTextViewShared *exampleTextView;
@property NSInteger nextDataset;
@property (retain) UIButton *nextDataButton;

@end

@implementation ALDemoTextViewController

-(NSString*) title { return @"ALLinkTextView"; };

-(void) loadView
{
    [super loadView];
    
    if (isiOS7)
        self.exampleTextView = [[ALLinkTextView7 alloc] initWithFrame:CGRectZero];
    else
        self.exampleTextView = [[ALLinkTextView6 alloc] initWithFrame:CGRectZero];
    
    [self.view addSubview:self.exampleTextView];
    self.exampleTextView.editable = NO;
    self.exampleTextView.linkDelegate = self;
	self.exampleTextView.layer.cornerRadius = 5.0f;
	self.exampleTextView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
	self.exampleTextView.layer.borderWidth = 1.0f;
    self.demoView = self.exampleTextView;
}

-(void) didGetNewAttributedString:(NSAttributedString*)string {
    [self.exampleTextView setLinkifiedAttributedText:string];
}


#pragma mark - Delegate

-(void)     textView:(ALLinkTextViewShared*)textView
  didTapLinkWithText:(NSString*)text href:(NSString*)href
{
    [[[UIAlertView alloc] initWithTitle:@"Tapped:"
                                message:href
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

-(void)             textView:(ALLinkTextViewShared*)textView
    didLongPressLinkWithText:(NSString*)text href:(NSString*)href textRect:(CGRect)textRect
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Long press"
                                                             delegate:nil
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:href,nil];
    
    CGRect viewRect = [textView convertRect:textRect toView:nil];
    [actionSheet showFromRect:viewRect
                       inView:[[UIApplication sharedApplication] keyWindow]
                     animated:YES];

}

@end

