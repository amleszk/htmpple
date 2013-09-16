
#import "ALDemoViewController.h"
#import "ALHtmlToAttributedStringParser.h"

@interface ALDemoViewController ()
@end

@implementation ALDemoViewController

-(void) nextDataSetFileIndex
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"test-data-%d",self.nextDataset+1] ofType:@"html"];
    if (path) {
        self.nextDataset = self.nextDataset+1;
    } else {
        self.nextDataset = 0;
    }
}

-(void) didGetNewAttributedString:(NSAttributedString*)string {
    
}

-(void) loadView
{
    self.view = [[UIView alloc] initWithFrame:CGRectZero];

    self.nextDataset = 0;
    
    if (isiOS7)
        self.nextDataButton = [UIButton buttonWithType:UIButtonTypeSystem];
    else
        self.nextDataButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    [self.nextDataButton addTarget:self action:@selector(newDataSet) forControlEvents:UIControlEventTouchUpInside];
    [self.nextDataButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.view addSubview:self.nextDataButton];
    
}

-(void) viewDidLoad
{
    [self newDataSet];
}

-(void) newDataSet
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"test-data-%d",self.nextDataset] ofType:@"html"];
    NSData* data = [[NSData alloc] initWithContentsOfFile:path];
    NSAttributedString* newString = [[ALHtmlToAttributedStringParser parser] attributedStringWithHTMLData:data trim:YES];
    [self didGetNewAttributedString:newString];
    [self resizeDemoView];
    [self nextDataSetFileIndex];
}

-(void) viewDidLayoutSubviews
{
    CGRect bounds = self.view.bounds;
    [self resizeDemoView];
    CGFloat offsetBottom = (isiOS7) ? 120 : 50;
    self.nextDataButton.frame = (CGRect){.origin={0,bounds.size.height-offsetBottom},.size={bounds.size.width,50}};
}

-(void) resizeDemoView
{
    CGRect bounds = self.view.bounds;
    CGRect boundsWithInset = CGRectInset(bounds, 20, 20);
    CGSize sizeThatFits = [self.demoView sizeThatFits:boundsWithInset.size];
    self.demoView.frame = (CGRect){.origin=boundsWithInset.origin,.size=sizeThatFits};
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
