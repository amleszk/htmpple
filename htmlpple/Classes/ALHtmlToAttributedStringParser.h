

extern NSString *kALHtmlToAttributedParsedHref;

@interface ALHtmlToAttributedStringParser : NSObject

+(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data;
+(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data trim:(BOOL)trim;

@end
