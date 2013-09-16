

extern NSString *kALHtmlToAttributedParsedHref;

@interface ALHtmlToAttributedStringParser : NSObject

+(ALHtmlToAttributedStringParser*) parser;

@property NSString* bodyFontName;
@property NSString* boldFontName;
@property NSString* italicsFontName;
@property NSString* headingFontName;
@property NSString* preFontName;

@property NSArray* fontSizesHeading;
@property NSArray* fontSizesBody;

@property UIColor* backgroundColorQuote;
@property UIColor* textColorDefault;
@property UIColor* backgroundColorDefault;
@property UIColor* textColorLink;

-(BOOL) htmlDataContainsLinks:(NSData*)data;
-(NSArray*) htmlData:(NSData*)data linksMatchingPredicate:(BOOL (^)(NSString *href))predicate;

-(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data;
-(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data trim:(BOOL)trim;

-(void) reloadTagData;

@end
