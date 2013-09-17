
@class ALLinkTextViewShared;
@protocol ALLinkTextViewDelegate <NSObject>
@optional
-(BOOL) textView:(ALLinkTextViewShared*)textView shouldHighlightLinkWithHref:(NSString*)href;
-(void) textView:(ALLinkTextViewShared*)textView didTapLinkWithText:(NSString*)text href:(NSString*)href;
-(void) textView:(ALLinkTextViewShared*)textView didLongPressLinkWithText:(NSString*)text href:(NSString*)href textRect:(CGRect)textRect;
@end

@interface ALLinkHitData : NSObject
@property NSArray *hitRects;
@property NSUInteger hitIndex;
@end

@interface ALLinkTextViewShared : UITextView <UIAppearanceContainer>

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText;
-(void) updateLinkRangesWithAttributedText:(NSAttributedString *)attributedText;
-(void) commonInit;

-(ALLinkHitData*)linkIndexForPoint:(CGPoint)originalPoint;
@property (nonatomic) NSMutableArray* linkRanges;

@property (nonatomic) UIColor *linkColorActive;
-(void) setLinkColorActive:(UIColor *)linkColorActive UI_APPEARANCE_SELECTOR;

@property (nonatomic) UIColor *linkColorDefault;
-(void) setLinkColorDefault:(UIColor *)linkColorDefault UI_APPEARANCE_SELECTOR;

@property (weak) id<ALLinkTextViewDelegate> linkDelegate;

@property BOOL allowInteractionOtherThanLinks;

@end
