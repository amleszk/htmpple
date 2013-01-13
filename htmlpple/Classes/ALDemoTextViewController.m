
#import "ALHtmlToAttributedStringParser.h"
#import "ALLinkTextView.h"
#import <QuartzCore/QuartzCore.h>

@interface ALDemoTextViewController : UIViewController <ALLinkTextViewDelegate>
@property (retain) ALLinkTextView *exampleTextView;
@property NSInteger nextDataset;
@property (retain) UIButton *nextDataButton;

@end

@implementation ALDemoTextViewController

-(void) newDataSet
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"test-data-%d",self.nextDataset] ofType:@"html"];
    NSData* data = [[NSData alloc] initWithContentsOfFile:path];
    NSAttributedString* newString = [[ALHtmlToAttributedStringParser parser] attributedStringWithHTMLData:data trim:YES];    
    [self.exampleTextView setLinkifiedAttributedText:newString];

    CGSize size = [self.exampleTextView sizeThatFits:self.view.frame.size];
    self.exampleTextView.frame = (CGRect){.origin=CGPointZero,size=size};
    self.nextDataset = (self.nextDataset+1)%5;
}

-(void) dealloc
{
    self.exampleTextView.linkDelegate = nil;
}

-(void) viewDidLayoutSubviews
{
    CGRect bounds = self.view.bounds;
    CGRect boundsWithInset = CGRectInset(bounds, 20, 20);
    
    CGSize size = [self.exampleTextView sizeThatFits:boundsWithInset.size];
    self.exampleTextView.frame = (CGRect){.origin=boundsWithInset.origin,size=size};
    
    self.nextDataButton.frame = (CGRect){.origin={0,bounds.size.height-50},.size={bounds.size.width,50}};
}

-(NSString*) title { return @"ALLinkTextView"; };

-(void) loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.exampleTextView = [[ALLinkTextView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.exampleTextView];
    self.exampleTextView.editable = NO;
    self.exampleTextView.linkDelegate = self;
	self.exampleTextView.layer.cornerRadius = 5.0f;
	self.exampleTextView.layer.borderColor = [[UIColor darkGrayColor] CGColor];
	self.exampleTextView.layer.borderWidth = 1.0f;
    
    
    self.nextDataset = 0;
    [self newDataSet];
    
    
    //[self runPerformanceTest];
    
    self.nextDataButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.nextDataButton addTarget:self action:@selector(newDataSet) forControlEvents:UIControlEventTouchUpInside];
    [self.nextDataButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.view addSubview:self.nextDataButton];
}

-(void) runPerformanceTest
{
    NSDate* startTime = [NSDate date];
    for (int i=0; i<200; i++) {
        [self newDataSet];
    }
    NSLog(@"Time %.2f",[[NSDate date] timeIntervalSinceDate:startTime]);
}


#pragma mark - Delegate

-(void) textView:(ALLinkTextView *)textView didTapLinkWithHref:(NSString *)href
{
    [[[UIAlertView alloc] initWithTitle:@"Tapped:"
                                message:href
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

-(void) textView:(ALLinkTextView*)textView didLongPressLinkWithHref:(NSString*)href view:(UIView*)view;
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Long press"
                                                             delegate:nil
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:href,nil];
    
    CGRect viewRect = [view convertRect:view.bounds toView:nil];
    [actionSheet showFromRect:viewRect
                       inView:[[UIApplication sharedApplication] keyWindow]
                     animated:YES];

}

@end

