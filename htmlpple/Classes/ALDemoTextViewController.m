
#import "ALHtmlToAttributedStringParser.h"
#import "ALLinkTextView.h"
#import <QuartzCore/QuartzCore.h>

@interface ALDemoTextViewController : UIViewController <ALLinkTextViewDelegate>
@property (retain) ALLinkTextView *exampleLabel;
@property NSInteger nextDataset;
@property (retain) UIButton *nextDataButton;

@end

@implementation ALDemoTextViewController

-(void) newDataSet
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"test-data-%d",self.nextDataset] ofType:@"html"];
    NSData* data = [[NSData alloc] initWithContentsOfFile:path];
    NSAttributedString* newString = [ALHtmlToAttributedStringParser attributedStringWithHTMLData:data trim:YES];
    [self.exampleLabel setLinkifiedAttributedText:newString];
    CGSize size = [self.exampleLabel sizeThatFits:self.view.frame.size];
    self.exampleLabel.frame = (CGRect){.origin=CGPointZero,size=size};
    self.nextDataset = (self.nextDataset+1)%5;
}

-(void) dealloc
{
    self.exampleLabel.linkDelegate = nil;
}

-(void) viewDidLayoutSubviews
{
    CGRect bounds = self.view.bounds;
    CGRect boundsWithInset = CGRectInset(bounds, 20, 20);
    
    CGSize size = [self.exampleLabel sizeThatFits:boundsWithInset.size];
    self.exampleLabel.frame = (CGRect){.origin=boundsWithInset.origin,size=size};
    
    self.nextDataButton.frame = (CGRect){.origin={0,bounds.size.height-50},.size={bounds.size.width,50}};
}

-(NSString*) title { return @"ALLinkTextView"; };

-(void) loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.exampleLabel = [[ALLinkTextView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.exampleLabel];
    self.exampleLabel.editable = NO;
    self.exampleLabel.linkDelegate = self;
	self.exampleLabel.layer.cornerRadius = 5.0f;
	self.exampleLabel.layer.borderColor = [[UIColor darkGrayColor] CGColor];
	self.exampleLabel.layer.borderWidth = 1.0f;
    
    
    self.nextDataset = 0;
    [self newDataSet];
    
    self.nextDataButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.nextDataButton addTarget:self action:@selector(newDataSet) forControlEvents:UIControlEventTouchUpInside];
    [self.nextDataButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.view addSubview:self.nextDataButton];
}

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

