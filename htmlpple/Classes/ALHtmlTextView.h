
@class ALHtmlTextView;
@protocol ALHtmlTextViewDelegate
@required
-(void) textView:(ALHtmlTextView*)textView didTapLinkWithHref:(NSString*)href;
@end


@interface ALHtmlTextView : UITextView

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText;
@property UIColor *linkColorActive;
@property UIColor *linkColorDefault;
@property (unsafe_unretained) id<ALHtmlTextViewDelegate> linkDelegate;
@end
