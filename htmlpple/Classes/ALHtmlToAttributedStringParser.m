
#import "ALHtmlToAttributedStringParser.h"
#import "NSDictionary+Merge.h"
#import "TFHpple.h"

NSString *kALHtmlToAttributedParsedHref = @"ALHtmlToAttributedParsedHref";
NSString *kALHtmlToAttributedId = @"kALHtmlToAttributedHrefID";

@implementation ALHtmlToAttributedStringParser

-(id) init
{
    self = [super init];
    if (self) {
        self.fontSizeModifier = 1.0;
        self.bodyFontName = @"Helvetica";
        self.boldFontName = @"Helvetica-Bold";
        self.italicsFontName = @"Helvetica-Oblique";
        self.headingFontName = @"HelveticaNeue";
        self.preFontName = @"Courier";

    }
    return self;
}

+(ALHtmlToAttributedStringParser*) parser
{
    return [[[self class] alloc] init];
}

-(NSAttributedString*) attributedStringWithHTMLData:(NSData*)data trim:(BOOL)trim
{
    NSAttributedString* attrString = [self attributedStringWithHTMLData:data];
    return (trim ? [self trimmedAttributedString:attrString] : attrString);
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

-(BOOL) htmlDataContainsLinks:(NSData*)data
{
    TFHpple *hpple = [TFHpple hppleWithXMLData:data];
    NSArray *root = [hpple searchWithXPathQuery:@"/"];
    return [self recursiveContainsLinkWithElements:root];
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

-(NSAttributedString*) trimmedAttributedString:(NSAttributedString*)attrString
{
    NSString *trimmedString = [attrString.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedString.length == attrString.string.length) {
        return attrString;
    }
    
    NSMutableAttributedString *mutableAttrStr = [attrString mutableCopy];
    NSRange subRange = [attrString.string rangeOfString:trimmedString];
    [mutableAttrStr beginEditing];
    if (subRange.location>0) {
        [mutableAttrStr deleteCharactersInRange:(NSRange){0,subRange.location}];
    }
    NSUInteger afterLocation = subRange.length-subRange.location;
    if (afterLocation<mutableAttrStr.string.length-subRange.location) {
        NSUInteger afterLength = mutableAttrStr.string.length-afterLocation;
        [mutableAttrStr deleteCharactersInRange:(NSRange){afterLocation,afterLength}];
    }
    [mutableAttrStr endEditing];
    return mutableAttrStr;
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
    blockQuoteParagraphStyle.headIndent = 20.;
    return blockQuoteParagraphStyle;
}

-(NSParagraphStyle*) pParagraphStyle
{
    NSMutableParagraphStyle* pParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    pParagraphStyle.paragraphSpacing = 5.;
    return pParagraphStyle;
}

-(NSDictionary*) staticAttributesForTagRegex
{
    static NSDictionary* options = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        options = @{
            @"p" : @{
                NSParagraphStyleAttributeName : [self pParagraphStyle],
                NSFontAttributeName : [UIFont fontWithName:[self bodyFontName] size:14*[self fontSizeModifier]],
                NSForegroundColorAttributeName : [UIColor blackColor]
            },
            @"(i|em)" : @{
                NSFontAttributeName : [UIFont fontWithName:[self italicsFontName] size:14*[self fontSizeModifier]]},
            @"thead" : @{ NSFontAttributeName : [UIFont fontWithName:[self boldFontName] size:12*[self fontSizeModifier]]},
            @"tbody" : @{ NSFontAttributeName : [UIFont fontWithName:[self bodyFontName] size:12*[self fontSizeModifier]]},
            @"(b|strong|thead)" : @{
                NSFontAttributeName : [UIFont fontWithName:[self boldFontName] size:14*[self fontSizeModifier]]},
            @"blockquote" : @{
                NSParagraphStyleAttributeName : [self blockQuoteParagraphStyle],
                NSBackgroundColorAttributeName : [UIColor colorWithRed:0 green:0 blue:1. alpha:0.1]
            },
            @"pre" : @{
                NSFontAttributeName : [UIFont fontWithName:[self preFontName] size:14*[self fontSizeModifier]]
            },
            @"(u|ins)" : @{ NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)},
            @"del" : @{ NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle) },
            @"h1" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:22*[self fontSizeModifier]]},
            @"h2" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:21*[self fontSizeModifier]]},
            @"h3" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:20*[self fontSizeModifier]]},
            @"h4" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:19*[self fontSizeModifier]]},
            @"h5" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:18*[self fontSizeModifier]]},
            @"h6" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:17*[self fontSizeModifier]]},
            @"(ul|ol)" : @{ NSParagraphStyleAttributeName : [self listParagraphStyle]},
        };
    });
    
    return options;
}

-(NSDictionary*) dynamicAttributesForTagRegex
{
    static NSDictionary* options = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        options = @{
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
    return options;
}
typedef NSDictionary* (^AttributesBlock)(NSDictionary* tagAttributes);

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

#pragma mark - String appendage after tags
// kNewLineCharactersOneNewLineOnly: Prevents adding multiple newlines when certain tags close - block style
// kNewLineCharactersAlways: always append newline on close of this tag
// kNewLineCharactersNone: never append newlines - inline styles

typedef enum {
    kNewLineCharactersNone,
    kNewLineCharactersOneNewLineOnly,
    kNewLineCharactersAlways,
} NewLineCharactersType;
static NewLineCharactersType kNewLineCharactersTypeDefault = kNewLineCharactersNone;

-(NSDictionary*) newLineActionForTagRegex
{
    static NSDictionary* options = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        options = @{
            @"(br|tr|table)" : @(kNewLineCharactersAlways),
            @"(p|h1|h2|h3|h4|h5|h6|li|blockquote)" : @(kNewLineCharactersOneNewLineOnly),
        };
    });
    return options;
}

-(NSString*) newLineActionForTag:(NSString*)tag  content:(NSString*)content
{
    NSNumber* nlTypeNumber = [self matcher:[self newLineActionForTagRegex] forTag:tag];
    NewLineCharactersType nlType = nlTypeNumber ?  [nlTypeNumber intValue] : kNewLineCharactersTypeDefault;
    switch (nlType) {
        case kNewLineCharactersNone: return nil;
        case kNewLineCharactersAlways: return @"\n";
        case kNewLineCharactersOneNewLineOnly: {
            NSRegularExpression *endsInNewLineRegex =
                [NSRegularExpression regularExpressionWithPattern:@"(\\s*)\\n(\\s*)$"
                                                          options:0
                                                            error:nil];
            NSRange range = [endsInNewLineRegex rangeOfFirstMatchInString:content options:0 range:(NSRange){0,content.length}];
            
            if(range.location == NSNotFound)
                return @"\n";
            else
                return nil;
        }
        default: {
            NSAssert(NO, @"Unsupported operation");
            break;
        }
    }
}

#pragma mark - String insertion before tags

-(NSDictionary*) beforeStringForTagRegex
{
    static NSDictionary* beforeStringForTagRegex = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        beforeStringForTagRegex = @{
            @"li" : @"• ",
            @"(td|th)" : @" | "
        };
    });
    return beforeStringForTagRegex;
}

-(NSString*) beforeStringForTag:(NSString*)tag {
    return [self matcher:[self beforeStringForTagRegex] forTag:tag];
}

#pragma mark - Trimming whitespace 
// kTrimCharactersAllWhiteSpaceAndLeaveOneSpace: adds a single space when encountering white space on either side of the tag
// kTrimCharactersAllWhiteSpace: trims everything

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
            @"(pre|code|i|em|b|strong|u|ins|del)" : @(kTrimCharactersNone),
            @"(p|h1|h2|h3|h4|h5|h6|li|br|a)" : @(kTrimCharactersAllWhiteSpaceAndLeaveOneSpace),
            @"(div|blockquote)" : @(kTrimCharactersAllWhiteSpace),
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
    //Apply collected NSAttributes from recursive descent
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
            
            //NSAttributes for this tag
            NSDictionary* attributesForTag = [self attributesForTag:tagName tagAttributes:element.attributes];
            childAttributes = [attributesForTag dictionaryByMergingWith:parentAttributes];
            
            //Actions to prepend for this tag
            NSString* preTag = [self beforeStringForTag:tagName];
            if (preTag) {
                [hppleParsedString appendAttributedString:
                 [[NSAttributedString alloc] initWithString:preTag
                                                 attributes:childAttributes]];
            }
            
        }
        
        //Recursion
        for (TFHppleElement *child in element.children) {
            [self recursiveXMLParseWithElement:child
                              hppleParsedString:hppleParsedString
                               parentAttributes:childAttributes];
        }
        
        //Actions to post-append for this tag - newlines
        if (tagName) {
            NSString* postTag = [self newLineActionForTag:tagName content:hppleParsedString.string];
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

-(BOOL) recursiveContainsLinkWithElements:(NSArray*)elements
{
    for (TFHppleElement *element in elements) {
        BOOL containsLink = [self recursiveContainsLinkWithElement:element];
        if (containsLink) {
            return YES;
        }
    }
    return NO;
}

-(BOOL) recursiveContainsLinkWithElement:(TFHppleElement *)element
{
    if(element.tagName &&
       [element.tagName isEqualToString:@"a"] &&
       [element.attributes[@"href"] length] > 0 )
    {
        return YES;
    }
    return [self recursiveContainsLinkWithElements:element.children];
    return NO;
}
@end
