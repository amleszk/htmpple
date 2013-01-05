

@interface ALHtmlTextView : UITextView

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText;
@property UIColor *linkColorActive;
@property UIColor *linkColorDefault;

@end
