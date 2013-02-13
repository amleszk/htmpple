
@class ALLinkTextView;
@protocol ALLinkTextViewDelegate
@required
-(void) textView:(ALLinkTextView*)textView didTapLinkWithHref:(NSString*)href;
-(void) textView:(ALLinkTextView*)textView didLongPressLinkWithHref:(NSString*)href textRect:(CGRect)textRect;
@end


@interface ALLinkTextView : UITextView <UIAppearanceContainer>

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText;
@property UIColor *linkColorActive;
-(void) setLinkColorActive:(UIColor *)linkColorActive UI_APPEARANCE_SELECTOR;
@property UIColor *linkColorDefault;
-(void) setLinkColorDefault:(UIColor *)linkColorDefault UI_APPEARANCE_SELECTOR;
@property (unsafe_unretained) id<ALLinkTextViewDelegate> linkDelegate;
@property BOOL allowInteractionOtherThanLinks;
@end
