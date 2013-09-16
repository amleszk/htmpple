
@interface ALDemoViewController : UIViewController

@property NSInteger nextDataset;
@property (nonatomic) UIButton *nextDataButton;
@property (nonatomic) UIView *demoView;

-(void) newDataSet;

@end
