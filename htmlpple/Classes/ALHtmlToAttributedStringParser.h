

extern NSString *kALHtmlToAttributedParsedHref;

@interface ALHtmlToAttributedStringParser : NSObject

+(ALHtmlToAttributedStringParser*) parser;

@property CGFloat fontSizeModifier;
@property NSString* bodyFontName;
@property NSString* boldFontName;
@property NSString* italicsFontName;
@property NSString* headingFontName;
@property NSString* preFontName;

@property UIColor* textColorDefault;
@property UIColor* textColorLink;

-(BOOL) htmlDataContainsLinks:(NSData*)data;
-(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data;
-(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data trim:(BOOL)trim;
-(void) reloadTagData;

@end
