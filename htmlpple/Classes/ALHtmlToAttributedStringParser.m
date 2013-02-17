
#import "ALHtmlToAttributedStringParser.h"
#import "NSDictionary+Merge.h"
#import "TFHpple.h"

NSString *kALHtmlToAttributedParsedHref = @"ALHtmlToAttributedParsedHref";
NSString *kALHtmlToAttributedId = @"kALHtmlToAttributedHrefID";

@interface ALHtmlToAttributedStringParser ()
@property NSDictionary* staticAttributesForTag;
@property NSDictionary* dynamicAttributesForTag;
@property NSDictionary* rootAttributes;
@property CGFloat currentIndentLevel;
@property NSMutableArray* indentLevelStack;
@end

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
        self.backgroundColorQuote = [UIColor colorWithRed:0 green:0 blue:1. alpha:0.1];
        self.textColorDefault = [UIColor blackColor];
        self.textColorLink = [UIColor blueColor];
        self.indentLevelStack = [NSMutableArray array];
        self.rootAttributes = @{ NSForegroundColorAttributeName : self.textColorDefault };
        [self reloadTagData];

    }
    return self;
}

-(void) dealloc
{
    NSLog(@"dealloc ALHtmlToAttributedStringParser");
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
                       parentAttributes:self.rootAttributes];
    return hppleParsedString;
}

-(void) reloadTagData
{    
    self.staticAttributesForTag = @{
        @"p" : @{
                NSFontAttributeName : [UIFont fontWithName:[self bodyFontName] size:14*[self fontSizeModifier]],
        },
        @"i|em" : @{
                NSFontAttributeName : [UIFont fontWithName:[self italicsFontName] size:14*[self fontSizeModifier]],
        },
        @"thead" : @{
                NSFontAttributeName : [UIFont fontWithName:[self boldFontName] size:12*[self fontSizeModifier]],
        },
        @"tbody" : @{
                NSFontAttributeName : [UIFont fontWithName:[self bodyFontName] size:12*[self fontSizeModifier]],
        },
        @"b|strong|thead" : @{
             NSFontAttributeName : [UIFont fontWithName:[self boldFontName] size:14*[self fontSizeModifier]]},
        @"blockquote" : @{
             NSBackgroundColorAttributeName : self.backgroundColorQuote
        },
        @"pre" : @{
             NSFontAttributeName : [UIFont fontWithName:[self preFontName] size:12*[self fontSizeModifier]]
        },
        @"u|ins" : @{ NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)},
        @"del" : @{ NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle) },
        @"h1" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:19*[self fontSizeModifier]]},
        @"h2" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:16*[self fontSizeModifier]]},
        @"h3" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:14*[self fontSizeModifier]]},
        @"h4" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:13*[self fontSizeModifier]]},
        @"h5" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:12*[self fontSizeModifier]]},
        @"h6" : @{ NSFontAttributeName : [UIFont fontWithName:[self headingFontName] size:11*[self fontSizeModifier]]},
    };
    
    __unsafe_unretained ALHtmlToAttributedStringParser *blockSelf = self;
    self.dynamicAttributesForTag = @{
        @"a" : [^NSDictionary*(NSDictionary* tagAttributes) {
            return @{
                     NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
                     NSForegroundColorAttributeName : blockSelf.textColorLink,
                     kALHtmlToAttributedParsedHref : tagAttributes[@"href"],
                     //Required to uniquely identify the text, otherwise if 2 links are side by side they get combined
                     kALHtmlToAttributedId : [NSDate date]
                     };
        } copy],
        @"p" : [^NSDictionary*(NSDictionary* tagAttributes) {
            return @{NSParagraphStyleAttributeName : [blockSelf pParagraphStyle]};
        } copy],
        @"blockquote" : [^NSDictionary*(NSDictionary* tagAttributes) {
            return @{NSParagraphStyleAttributeName : [blockSelf blockQuoteParagraphStyle]};
        } copy],
        @"ul|ol" : [^NSDictionary*(NSDictionary* tagAttributes) {
            return @{
                NSParagraphStyleAttributeName : [blockSelf listParagraphStyle],
            };
        } copy]
    };
}

-(BOOL) htmlDataContainsLinks:(NSData*)data
{
    TFHpple *hpple = [TFHpple hppleWithXMLData:data];
    NSArray *root = [hpple searchWithXPathQuery:@"/"];
    __block BOOL containsLinks = NO;
    [self collectElements:root withBlock:^id(TFHppleElement *element, BOOL *stop) {
        if(element.tagName &&
           [element.tagName isEqualToString:@"a"] &&
           ((NSString*)element.attributes[@"href"]).length)
        {
            containsLinks = YES;
            (*stop) = YES;
        }
        return nil;
    }];
    return containsLinks;
}

-(NSArray*) htmlData:(NSData*)data linksMatchingPredicate:(BOOL (^)(NSString *href))predicate
{
    TFHpple *hpple = [TFHpple hppleWithXMLData:data];
    NSArray *root = [hpple searchWithXPathQuery:@"/"];
    return
    [self collectElements:root withBlock:^id(TFHppleElement *element, BOOL *stop) {
        if(element.tagName && [element.tagName isEqualToString:@"a"]) {
            NSString *href = element.attributes[@"href"];
            if (predicate(href)) {
                return href;
            }
        }
        return nil;
    }];
}

#pragma mark - Helpers

-(id) matcher:(NSDictionary*)matchers forTag:(NSString*)tag
{
    NSString* tagMatch = nil;
    for (NSString *tagsToMatchString in matchers) {
        NSArray * tagsToMatch = [tagsToMatchString componentsSeparatedByString:@"|"];
        for (NSString *tagToMatch in tagsToMatch) {
            if([tagToMatch isEqualToString:tag]) {
                tagMatch = tagsToMatchString;
                break;
            }
        }
        if (tagMatch) break;
    }
    
    return tagMatch ? matchers[tagMatch] : nil;
}

-(NSAttributedString*) trimmedAttributedString:(NSAttributedString*)attrString
{
    NSString *trimmedString = [attrString.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedString.length == attrString.string.length) {
        return attrString;
    }
    
    NSMutableAttributedString *mutableAttrStr = [attrString mutableCopy];
    NSRange subRange = [attrString.string rangeOfString:trimmedString];
    //Empty string after trimming
    if (subRange.location== NSNotFound) {
        return [[NSAttributedString alloc] init];
    }
    
    [mutableAttrStr beginEditing];
    if (subRange.location!= NSNotFound && subRange.location>0) {
        [mutableAttrStr deleteCharactersInRange:(NSRange){0,subRange.location}];
    }
    if (subRange.length<mutableAttrStr.string.length) {
        NSUInteger afterTrim = mutableAttrStr.string.length-subRange.length;
        [mutableAttrStr deleteCharactersInRange:(NSRange){subRange.length,afterTrim}];
    }
    [mutableAttrStr endEditing];
    return mutableAttrStr;
}

#pragma mark - Tag to Attributes mapping

-(NSMutableParagraphStyle*) paragraphStyleByAddingIndent:(CGFloat)additionalIndent
{
    CGFloat newIndentLevel = self.currentIndentLevel+additionalIndent;
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.firstLineHeadIndent = newIndentLevel;
    paragraphStyle.headIndent = newIndentLevel;
    self.currentIndentLevel = newIndentLevel;
    return paragraphStyle;
}

-(NSParagraphStyle*) blockQuoteParagraphStyle
{
    return [self paragraphStyleByAddingIndent:20];
}

-(NSParagraphStyle*) listParagraphStyle
{
    return [self paragraphStyleByAddingIndent:20];
}

-(NSParagraphStyle*) pParagraphStyle
{
    NSMutableParagraphStyle* paragraphStyle = [self paragraphStyleByAddingIndent:0];
    paragraphStyle.paragraphSpacing = 5.;
    return paragraphStyle;
}


typedef NSDictionary* (^AttributesBlock)(NSDictionary* tagAttributes);

-(NSDictionary *) attributesForTag:(NSString*)tag tagAttributes:(NSDictionary*)tagAttributes {
    NSDictionary *attributes = [self matcher:self.staticAttributesForTag forTag:tag];
    if (!attributes) {
        attributes = @{};
    }
    AttributesBlock dynamicAttributesBlock = [self matcher:self.dynamicAttributesForTag forTag:tag];
    if (dynamicAttributesBlock) {
        NSDictionary *dynamicAttributes = dynamicAttributesBlock(tagAttributes);
        attributes = [attributes dictionaryByMergingWith:dynamicAttributes];
    }
    
    return attributes;
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

-(NSDictionary*) newLineActionForTag
{
    static NSDictionary* options = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        options = @{
            @"br|tr|table|ul|ol" : @(kNewLineCharactersAlways),
            @"p|h1|h2|h3|h4|h5|h6|li|blockquote" : @(kNewLineCharactersOneNewLineOnly),
        };
    });
    return options;
}

-(NSString*) newLineActionForTag:(NSString*)tag  content:(NSString*)content
{
    NSNumber* nlTypeNumber = [self matcher:[self newLineActionForTag] forTag:tag];
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

-(NSDictionary*) beforeStringForTag
{
    static NSDictionary* beforeStringForTag = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        beforeStringForTag = @{
            @"li" : @"• ",
            @"td|th" : @" | "
        };
    });
    return beforeStringForTag;
}

-(NSString*) beforeStringForTag:(NSString*)tag {
    return [self matcher:[self beforeStringForTag] forTag:tag];
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
            @"pre|code|i|em|b|strong|u|ins|del" : @(kTrimCharactersNone),
            @"p|h1|h2|h3|h4|h5|h6|li|br|a" : @(kTrimCharactersAllWhiteSpaceAndLeaveOneSpace),
            @"div|blockquote" : @(kTrimCharactersAllWhiteSpace),
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

-(void) pushAttributes
{
    [self.indentLevelStack addObject:@(self.currentIndentLevel)];
}

-(void) popAttributes
{
    self.currentIndentLevel = [[self.indentLevelStack lastObject] floatValue];
    [self.indentLevelStack removeLastObject];
}

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
        [self pushAttributes];
        
        NSDictionary* childAttributes = parentAttributes;
        NSString* tagName = element.tagName;
        if (tagName) {
            
            //attributes for this tag
            NSDictionary* attributesForTag = [self attributesForTag:tagName tagAttributes:element.attributes];
            childAttributes = [attributesForTag dictionaryByMergingWith:parentAttributes overWriteExistingKeys:NO];
            
            //Actions to prepend for this tag, dot points etc.
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
                 [[NSAttributedString alloc] initWithString:postTag attributes:childAttributes]];
            }
        }
        
        [self popAttributes];
    }
    
    
}

-(void) recursiveXMLParseWithElements:(NSArray*)elements
                    hppleParsedString:(NSMutableAttributedString*)hppleParsedString
                     parentAttributes:(NSDictionary*)parentAttributes
{
    NSAssert(self.currentIndentLevel == 0, @"");
    NSAssert(self.indentLevelStack.count == 0, @"");
    for (TFHppleElement *element in elements) {
            [self recursiveXMLParseWithElement:element
                             hppleParsedString:hppleParsedString
                              parentAttributes:parentAttributes];
    }
}


-(NSArray*) collectElements:(NSArray*)elements stop:(BOOL*)stop withBlock:(id (^)(TFHppleElement *element, BOOL *stop))collectBlock
{
    NSMutableArray *collected = [NSMutableArray array];
    for (TFHppleElement *element in elements) {
        if ((*stop)) {
            break;
        }
        id collectedElement = collectBlock(element,stop);
        if (collectedElement) {
            [collected addObject:collectedElement];
        }
        if ((*stop)) {
            break;
        }
        [collected addObjectsFromArray:[self collectElements:element.children stop:stop withBlock:collectBlock]];
    }
    return collected;    
}

-(NSArray*) collectElements:(NSArray*)elements withBlock:(id (^)(TFHppleElement *element, BOOL *stop))collectBlock
{
    BOOL stop = NO;
    return [self collectElements:elements stop:&stop withBlock:collectBlock];
}

@end
