
#import "ALDemoLabelViewController.h"

@interface ALDemoLabelViewController ()
@property (retain) UILabel *exampleLabel;
@end

@implementation ALDemoLabelViewController


-(NSString*) title { return @"UILabel"; };

-(void) loadView
{
    [super loadView];
    
    self.exampleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.exampleLabel.numberOfLines = 0;
    [self.view addSubview:self.exampleLabel];
	self.exampleLabel.layer.cornerRadius = 5.0f;
	self.exampleLabel.layer.borderColor = [[UIColor darkGrayColor] CGColor];
	self.exampleLabel.layer.borderWidth = 1.0f;
    
    self.demoView = self.exampleLabel;
}

-(void) didGetNewAttributedString:(NSAttributedString*)string {
    self.exampleLabel.attributedText = string;
}


//-(void) runPerformanceTest
//{
//    NSDate* startTime = [NSDate date];
//    for (int i=0; i<200; i++) {
//        [self newDataSet];
//    }
//    NSLog(@"Time %.2f",[[NSDate date] timeIntervalSinceDate:startTime]);    
//}

@end

