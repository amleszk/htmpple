
@class ALLinkTextView;
@protocol ALLinkTextViewDelegate
@required
-(void) textView:(ALLinkTextView*)textView didTapLinkWithHref:(NSString*)href;
-(void) textView:(ALLinkTextView*)textView didLongPressLinkWithHref:(NSString*)href textRect:(CGRect)textRect;
@end


@interface ALLinkTextView : UITextView

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText;
@property UIColor *linkColorActive;
@property UIColor *linkColorDefault;
@property (unsafe_unretained) id<ALLinkTextViewDelegate> linkDelegate;
@property BOOL allowInteractionOtherThanLinks;
@end
