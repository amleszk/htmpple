

extern NSString *kALHtmlToAttributedParsedHref;

@interface ALHtmlToAttributedStringParser : NSObject

+(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data;

@end
