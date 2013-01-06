
@class ALLinkTextView;
@protocol ALLinkTextViewDelegate
@required
-(void) textView:(ALLinkTextView*)textView didTapLinkWithHref:(NSString*)href;
-(void) textView:(ALLinkTextView*)textView didLongPressLinkWithHref:(NSString*)href view:(UIView*)view;
@end


@interface ALLinkTextView : UITextView

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText;
@property UIColor *linkColorActive;
@property UIColor *linkColorDefault;
@property (unsafe_unretained) id<ALLinkTextViewDelegate> linkDelegate;
@property (readonly) BOOL isLinkActive;
@property BOOL allowInteractionOtherThanLinks;
@end
