
#import "ALHtmlToAttributedStringParser.h"
#import "ALLinkTextView.h"
#import <QuartzCore/QuartzCore.h>

@interface ALDemoLabelViewController : UIViewController
@property (retain) UILabel *exampleLabel;
@property NSInteger nextDataset;
@property (retain) UIButton *nextDataButton;

@end

@implementation ALDemoLabelViewController

-(void) newDataSet
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"test-data-%d",self.nextDataset] ofType:@"html"];
    NSData* data = [[NSData alloc] initWithContentsOfFile:path];
    NSAttributedString* newString = [[ALHtmlToAttributedStringParser parser] attributedStringWithHTMLData:data trim:YES];
    self.exampleLabel.attributedText =  newString;
    CGSize size = [self.exampleLabel sizeThatFits:self.view.frame.size];
    self.exampleLabel.frame = (CGRect){.origin=CGPointZero,size=size};
    self.nextDataset = (self.nextDataset+1)%5;
}

-(void) viewDidLayoutSubviews
{
    CGRect bounds = self.view.bounds;
    CGRect boundsWithInset = CGRectInset(bounds, 20, 20);
    
    CGSize size = [self.exampleLabel sizeThatFits:boundsWithInset.size];
    self.exampleLabel.frame = (CGRect){.origin=boundsWithInset.origin,size=size};
    
    self.nextDataButton.frame = (CGRect){.origin={0,bounds.size.height-50},.size={bounds.size.width,50}};
}

-(NSString*) title { return @"UILabel"; };

-(void) loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.exampleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.exampleLabel.numberOfLines = 0;
    [self.view addSubview:self.exampleLabel];
	self.exampleLabel.layer.cornerRadius = 5.0f;
	self.exampleLabel.layer.borderColor = [[UIColor darkGrayColor] CGColor];
	self.exampleLabel.layer.borderWidth = 1.0f;
    
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

@end

