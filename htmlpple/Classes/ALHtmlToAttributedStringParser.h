

extern NSString *kALHtmlToAttributedParsedHref;

@interface ALHtmlToAttributedStringParser : NSObject

+(BOOL) doesHtmlDataContainLinks:(NSData*)data;
+(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data;
+(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data trim:(BOOL)trim;

@end
