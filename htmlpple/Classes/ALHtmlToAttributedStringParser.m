
#import "ALHtmlToAttributedStringParser.h"
#import "NSDictionary+Merge.h"
#import "TFHpple.h"

NSString *kALHtmlToAttributedParsedHref = @"ALHtmlToAttributedParsedHref";
NSString *kALHtmlToAttributedId = @"kALHtmlToAttributedHrefID";

@implementation ALHtmlToAttributedStringParser

+(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data
{
    return [[[[self class] alloc] init] attributedStringWithHTMLData:data];
}

-(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data
{
    TFHpple *hpple = [TFHpple hppleWithXMLData:data];
    NSMutableAttributedString *hppleParsedString = [[NSMutableAttributedString alloc] init];
    NSArray *root = [hpple searchWithXPathQuery:@"/"];
    [self recursiveXMLParseWithElements:root
                      hppleParsedString:hppleParsedString
                       parentAttributes:@{}];
    return hppleParsedString;
}

#pragma mark - Helpers

-(id) matcher:(NSDictionary*)matchers forTag:(NSString*)tag
{
    NSString* match = nil;
    NSError *error;
    
    for (NSString *regexPattern in matchers) {
        NSRegularExpression *tagRegex = [NSRegularExpression regularExpressionWithPattern:regexPattern
                                                                                  options:0
                                                                                    error:&error];
        NSRange range = [tagRegex rangeOfFirstMatchInString:tag options:0 range:(NSRange){0,tag.length}];
        if(range.location == 0 && range.length == tag.length) {
            match = regexPattern;
            break;
        }
    }
    
    return match ? matchers[match] : nil;
}

#pragma mark - Tag to Attributes mapping

-(NSParagraphStyle*) blockQuoteParagraphStyle
{
    NSMutableParagraphStyle* blockQuoteParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    blockQuoteParagraphStyle.firstLineHeadIndent = 20.;
    blockQuoteParagraphStyle.headIndent = 20.;
    return blockQuoteParagraphStyle;
}

-(NSParagraphStyle*) listParagraphStyle
{
    NSMutableParagraphStyle* blockQuoteParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    blockQuoteParagraphStyle.firstLineHeadIndent = 30.;
    blockQuoteParagraphStyle.headIndent = 30.;
    return blockQuoteParagraphStyle;
}

-(NSParagraphStyle*) pParagraphStyle
{
    NSMutableParagraphStyle* pParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    pParagraphStyle.paragraphSpacing = 5.;
    return pParagraphStyle;
}

-(NSDictionary*) dynamicAttributesForTagRegex
{
    static NSDictionary* dynamicAttributesForTagRegex = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        dynamicAttributesForTagRegex = @{
        @"a" : [^NSDictionary*(NSDictionary* tagAttributes) {
            return @{
                NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
                NSForegroundColorAttributeName : [UIColor blueColor],
                kALHtmlToAttributedParsedHref : tagAttributes[@"href"],
                //Required to uniquely identify the text, otherwise if 2 links are side by side they get combined
                kALHtmlToAttributedId : [NSDate date]
            };
        } copy],
        };
    });
    
    return dynamicAttributesForTagRegex;    
}
typedef NSDictionary* (^AttributesBlock)(NSDictionary* tagAttributes);

-(NSDictionary*) staticAttributesForTagRegex
{
    static NSDictionary* attributesForTagRegex = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        attributesForTagRegex = @{
        @"p" : @{
            NSParagraphStyleAttributeName : [self pParagraphStyle],
            NSFontAttributeName : [UIFont systemFontOfSize:12]
        },
        @"(i|em)" : @{ NSFontAttributeName : [UIFont italicSystemFontOfSize:14] },
        @"(b|strong)" : @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14]},
        @"blockquote" : @{
            NSParagraphStyleAttributeName : [self blockQuoteParagraphStyle],
            NSFontAttributeName : [UIFont italicSystemFontOfSize:14]
        },
        @"(u|ins)" : @{ NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)},
        @"del" : @{ NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle) },
        @"h1" : @{ NSFontAttributeName : [UIFont systemFontOfSize:20]},
        @"h2" : @{ NSFontAttributeName : [UIFont systemFontOfSize:19]},
        @"h3" : @{ NSFontAttributeName : [UIFont systemFontOfSize:18]},
        @"h4" : @{ NSFontAttributeName : [UIFont systemFontOfSize:17]},
        @"h5" : @{ NSFontAttributeName : [UIFont systemFontOfSize:16]},
        @"h6" : @{ NSFontAttributeName : [UIFont systemFontOfSize:15]},
        @"ul" : @{ NSParagraphStyleAttributeName : [self listParagraphStyle]},
        };
    });
    
    return attributesForTagRegex;
}

-(NSDictionary *) attributesForTag:(NSString*)tag tagAttributes:(NSDictionary*)tagAttributes {
    NSDictionary *staticAttributes = [self matcher:[self staticAttributesForTagRegex] forTag:tag];
    if (staticAttributes) {
        return staticAttributes;
    }
    AttributesBlock dynamicAttributes = [self matcher:[self dynamicAttributesForTagRegex] forTag:tag];
    if (dynamicAttributes) {
        return dynamicAttributes(tagAttributes);
    }    
    return @{};
}

#pragma mark - Tag to Post processor mapping

-(NSDictionary*) afterStringForTagRegex
{
    static NSDictionary* afterStringForTagRegex = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        afterStringForTagRegex = @{
            @"(p|h1|h2|h3|h4|h5|h6|li|blockquote|br)" : @"\n"
        };
    });
    return afterStringForTagRegex;
}

-(NSString*) afterStringForTag:(NSString*)tag {
    return [self matcher:[self afterStringForTagRegex] forTag:tag];
}

-(NSDictionary*) beforeStringForTagRegex
{
    static NSDictionary* beforeStringForTagRegex = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        beforeStringForTagRegex = @{
            @"li" : @"• "
        };
    });
    return beforeStringForTagRegex;
}

-(NSString*) beforeStringForTag:(NSString*)tag {
    return [self matcher:[self beforeStringForTagRegex] forTag:tag];
}

typedef enum {
    kTrimCharactersNone,
    kTrimCharactersAllWhiteSpaceAndLeaveOneSpace,
    kTrimCharactersAllWhiteSpace,
} TrimCharactersType;
static TrimCharactersType kTrimCharactersTypeDefault = kTrimCharactersAllWhiteSpace;

-(NSDictionary*) trimTagRegex
{
    static NSDictionary* trimTagRegex = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        trimTagRegex = @{
            @"pre" : @(kTrimCharactersNone),
            @"(p|h1|h2|h3|h4|h5|h6|li|blockquote|br|a)" : @(kTrimCharactersAllWhiteSpaceAndLeaveOneSpace),
            @"div" : @(kTrimCharactersAllWhiteSpace),
        };
    });
    return trimTagRegex;
}

-(NSNumber*) trimForTag:(NSString*)tag {
    return [self matcher:[self trimTagRegex] forTag:tag];
}

-(NSString*) trimmedElementWithTag:(NSString*)tag content:(NSString*)content
{
    NSNumber* trimTypeNumber = [self trimForTag:tag];
    TrimCharactersType trimType = trimTypeNumber ?  [trimTypeNumber intValue] : kTrimCharactersTypeDefault;
    switch (trimType) {
        case kTrimCharactersNone: return content;
        case kTrimCharactersAllWhiteSpace: {
            return [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
        case kTrimCharactersAllWhiteSpaceAndLeaveOneSpace: {
            NSString* newContent = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            //No white space trimmed
            if (newContent.length == content.length) {
                return newContent;
            }
            //The string contained only white space
            else if(newContent.length == 0) {
                return @" ";
            }
            //Trimming happened, add space padding
            else {
                NSRange beforeWhiteSpaceRange =
                    [content rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                             options:0
                                               range:(NSRange){0,1}];
                if (beforeWhiteSpaceRange.location != NSNotFound) {
                    newContent = [NSString stringWithFormat:@" %@",newContent];
                }
                NSRange afterWhiteSpaceRange =
                    [content rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                             options:0
                                               range:(NSRange){content.length-1,1}];
                if (afterWhiteSpaceRange.location != NSNotFound) {
                    newContent = [NSString stringWithFormat:@"%@ ",newContent];
                }
            }
            return newContent;
        }
        default: {
            NSAssert(NO, @"Unsupported operation");
            break;
        }
    }
}

#pragma mark - Parsing

-(void) recursiveXMLParseWithElement:(TFHppleElement *)element
                   hppleParsedString:(NSMutableAttributedString*)hppleParsedString
                    parentAttributes:(NSDictionary*)parentAttributes
{
    if ([element isTextNode]) {
        NSString* text = [self trimmedElementWithTag:element.parent.tagName content:element.content];
        if (text.length) {
            [hppleParsedString appendAttributedString:
             [[NSAttributedString alloc] initWithString:text
                                             attributes:parentAttributes]];
        }
        NSAssert(element.children.count == 0, @"");
    }
    else {
        NSDictionary* childAttributes = parentAttributes;
        NSString* tagName = element.tagName;
        if (tagName) {
            NSDictionary* attributesForTag = [self attributesForTag:tagName tagAttributes:element.attributes];
            childAttributes = [attributesForTag dictionaryByMergingWith:parentAttributes];

            NSString* preTag = [self beforeStringForTag:tagName];
            if (preTag) {
                [hppleParsedString appendAttributedString:
                 [[NSAttributedString alloc] initWithString:preTag
                                                 attributes:childAttributes]];
            }
        }
        for (TFHppleElement *child in element.children) {
            [self recursiveXMLParseWithElement:child
                              hppleParsedString:hppleParsedString
                               parentAttributes:childAttributes];
        }
        if (tagName) {
            NSString* postTag = [self afterStringForTag:tagName];
            if (postTag) {
                [hppleParsedString appendAttributedString:
                 [[NSAttributedString alloc] initWithString:postTag
                                                 attributes:childAttributes]];
            }
        }
    }
}

-(void) recursiveXMLParseWithElements:(NSArray*)elements
                    hppleParsedString:(NSMutableAttributedString*)hppleParsedString
                     parentAttributes:(NSDictionary*)parentAttributes
{
    for (TFHppleElement *element in elements) {
            [self recursiveXMLParseWithElement:element
                             hppleParsedString:hppleParsedString
                              parentAttributes:parentAttributes];
    }
}


@end
