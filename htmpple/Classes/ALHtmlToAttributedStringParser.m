
#import "ALHtmlToAttributedStringParser.h"
#import "NSDictionary+Merge.h"
#import "TFHpple.h"

NSString *kALHtmlToAttributedParsedHref = @"ALHtmlToAttributedParsedHref";
NSString *kALHtmlToAttributedId = @"kALHtmlToAttributedHrefID";

typedef NSDictionary* (^AttributesBlock)(NSDictionary* tagAttributes);

// kTrimCharactersAllWhiteSpaceAndLeaveOneSpace: adds a single space when encountering white space on either side of the tag
// kTrimCharactersAllWhiteSpace: trims everything
typedef enum {
    kTrimCharactersNone,
    kTrimCharactersAllWhiteSpaceAndLeaveOneSpace,
    kTrimCharactersAllWhiteSpace,
} TrimCharactersType;
static TrimCharactersType kTrimCharactersTypeDefault = kTrimCharactersAllWhiteSpace;

// kNewLineCharactersOneNewLineOnly: Prevents adding multiple newlines when certain tags close - block style
// kNewLineCharactersAlways: always append newline on close of this tag
// kNewLineCharactersNone: never append newlines - inline styles
typedef enum {
    kNewLineCharactersNone,
    kNewLineCharactersOneNewLineOnly,
    kNewLineCharactersAlways,
} NewLineCharactersType;
static NewLineCharactersType kNewLineCharactersTypeDefault = kNewLineCharactersNone;

typedef enum {
    ALHtmlToAttributedStringParserFontSizeBodySmall,
    ALHtmlToAttributedStringParserFontSizeBodyMid,
} ALHtmlToAttributedStringParserFontSizeBody;

typedef enum {
    ALHtmlToAttributedStringParserFontSizeHeading6,
    ALHtmlToAttributedStringParserFontSizeHeading5,
    ALHtmlToAttributedStringParserFontSizeHeading4,
    ALHtmlToAttributedStringParserFontSizeHeading3,
    ALHtmlToAttributedStringParserFontSizeHeading2,
    ALHtmlToAttributedStringParserFontSizeHeading1
} ALHtmlToAttributedStringParserFontSizeHeading;


@interface ALHtmlToAttributedStringParser ()
@property NSArray* staticAttributesForTag;
@property NSArray* dynamicAttributesForTag;
@property NSArray* prependStringForTag;
@property NSArray* trimActionForTag;
@property NSArray* newlineActionForTag;
@property NSRegularExpression* endsInNewlineRegex;
@property NSDictionary* rootAttributes;
@property CGFloat currentIndentLevel;
@property NSMutableArray* indentLevelStack;
@end

@implementation ALHtmlToAttributedStringParser

-(id) init
{
    self = [super init];
    if (self) {
        self.bodyFontName = @"Helvetica";
        self.boldFontName = @"Helvetica-Bold";
        self.italicsFontName = @"Helvetica-Oblique";
        self.headingFontName = @"HelveticaNeue";
        self.preFontName = @"Courier";
        self.fontSizesHeading = @[@12,@13,@14,@15,@16,@17];
        self.fontSizesBody = @[@12,@14];
        self.backgroundColorQuote = [UIColor colorWithRed:0 green:0 blue:1. alpha:0.1];
        self.textColorDefault = [UIColor blackColor];
        self.backgroundColorDefault = [UIColor clearColor];
        self.textColorLink = [UIColor blueColor];
        self.indentLevelStack = [NSMutableArray array];
        
        self.endsInNewlineRegex = [NSRegularExpression regularExpressionWithPattern:@"(\\s*)\\n(\\s*)$"
                                                                            options:0
                                                                              error:nil];
        
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
    UIFont *bodyFont1 = [UIFont fontWithName:self.bodyFontName size:[self.fontSizesBody[ALHtmlToAttributedStringParserFontSizeBodyMid] floatValue]];
    UIFont *bodyFont2 = [UIFont fontWithName:self.bodyFontName size:[self.fontSizesBody[ALHtmlToAttributedStringParserFontSizeBodySmall] floatValue]];
    UIFont *italicsFont1 = [UIFont fontWithName:self.italicsFontName size:[self.fontSizesBody[ALHtmlToAttributedStringParserFontSizeBodyMid] floatValue]];
    UIFont *boldFont1 = [UIFont fontWithName:self.boldFontName size:[self.fontSizesBody[ALHtmlToAttributedStringParserFontSizeBodyMid] floatValue]];
    UIFont *preFont1 = [UIFont fontWithName:self.preFontName size:[self.fontSizesBody[ALHtmlToAttributedStringParserFontSizeBodyMid] floatValue]];
    
    UIFont *hFont1 = [UIFont fontWithName:self.headingFontName size:[self.fontSizesHeading[ALHtmlToAttributedStringParserFontSizeHeading1] floatValue]];
    UIFont *hFont2 = [UIFont fontWithName:self.headingFontName size:[self.fontSizesHeading[ALHtmlToAttributedStringParserFontSizeHeading2] floatValue]];
    UIFont *hFont3 = [UIFont fontWithName:self.headingFontName size:[self.fontSizesHeading[ALHtmlToAttributedStringParserFontSizeHeading3] floatValue]];
    UIFont *hFont4 = [UIFont fontWithName:self.headingFontName size:[self.fontSizesHeading[ALHtmlToAttributedStringParserFontSizeHeading4] floatValue]];
    UIFont *hFont5 = [UIFont fontWithName:self.headingFontName size:[self.fontSizesHeading[ALHtmlToAttributedStringParserFontSizeHeading5] floatValue]];
    UIFont *hFont6 = [UIFont fontWithName:self.headingFontName size:[self.fontSizesHeading[ALHtmlToAttributedStringParserFontSizeHeading6] floatValue]];
    
    self.staticAttributesForTag = @[
        @[ @[@"p"] , @{ NSFontAttributeName : bodyFont1} ],
        @[ @[@"i",@"em"] , @{ NSFontAttributeName : italicsFont1} ],
        @[ @[@"thead"] , @{ NSFontAttributeName : boldFont1} ],
        @[ @[@"tbody"] , @{ NSFontAttributeName : bodyFont2} ],
        @[ @[@"b",@"strong",@"thead"] , @{ NSFontAttributeName : boldFont1} ],
        @[ @[@"blockquote"] , @{ NSBackgroundColorAttributeName : self.backgroundColorQuote } ],
        @[ @[@"pre"] , @{ NSFontAttributeName : preFont1}],
        @[ @[@"u",@"ins"] , @{ NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle)}],
        @[ @[@"del"] , @{ NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle) }],
        @[ @[@"h1"] , @{ NSFontAttributeName : hFont1}],
        @[ @[@"h2"] , @{ NSFontAttributeName : hFont2}],
        @[ @[@"h3"] , @{ NSFontAttributeName : hFont3}],
        @[ @[@"h4"] , @{ NSFontAttributeName : hFont4}],
        @[ @[@"h5"] , @{ NSFontAttributeName : hFont5}],
        @[ @[@"h6"] , @{ NSFontAttributeName : hFont6}],
    ];
    
    __weak typeof(self)weakSelf = self;
    
    AttributesBlock aDynamicAction = ^NSDictionary*(NSDictionary* tagAttributes) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        return @{
            NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle),
            NSForegroundColorAttributeName : strongSelf.textColorLink,
            kALHtmlToAttributedParsedHref : tagAttributes[@"href"],
            //Required to uniquely identify the text, otherwise if 2 links are side by side they get combined
            kALHtmlToAttributedId : [NSDate date]
        };
    };

    //Need dynamic access to indentation
    AttributesBlock pDynamicAction = ^NSDictionary*(NSDictionary* tagAttributes) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        return @{
                 NSParagraphStyleAttributeName : [strongSelf pParagraphStyle]
         };
    };

    //Need dynamic access to indentation
    AttributesBlock blockquoteDynamicAction = ^NSDictionary*(NSDictionary* tagAttributes) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        return @{
            NSParagraphStyleAttributeName : [strongSelf blockQuoteParagraphStyle],
        };
    };

    AttributesBlock listDynamicAction = ^NSDictionary*(NSDictionary* tagAttributes) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        return @{
             NSParagraphStyleAttributeName : [strongSelf listParagraphStyle],
             NSFontAttributeName : bodyFont1
        };
    };
    
    self.dynamicAttributesForTag = @[
        @[@[@"a"],[aDynamicAction copy]],
        @[@[@"p"],[pDynamicAction copy]],
        @[@[@"blockquote"],[blockquoteDynamicAction copy]],
        @[@[@"ul",@"ol"],[listDynamicAction copy]],
    ];

    self.prependStringForTag = @[
        @[@[@"li"],@"• "],
        @[@[@"td",@"th"],@" | "],
    ];
    
    self.trimActionForTag = @[
        @[@[@"pre",@"code",@"i",@"em",@"b",@"strong",@"u",@"ins",@"del"] , @(kTrimCharactersNone)],
        @[@[@"p",@"h1",@"h2",@"h3",@"h4",@"h5",@"h6",@"li",@"br",@"a"] , @(kTrimCharactersAllWhiteSpaceAndLeaveOneSpace)],
        @[@[@"div",@"blockquote"] , @(kTrimCharactersAllWhiteSpace)],
    ];    

    self.newlineActionForTag = @[
        @[@[@"br",@"tr",@"table",@"ul",@"ol"] , @(kNewLineCharactersAlways)],
        @[@[@"p",@"h1",@"h2",@"h3",@"h4",@"h5",@"h6",@"li",@"blockquote"] , @(kNewLineCharactersOneNewLineOnly)],        
    ];
        
    self.rootAttributes = @{
        NSBackgroundColorAttributeName : self.backgroundColorDefault,
        NSForegroundColorAttributeName : self.textColorDefault,
        NSParagraphStyleAttributeName : [self pParagraphStyle]
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

-(id) matcher:(NSArray*)tagsAndAttributesArray forTag:(NSString*)tag
{
    NSInteger i = 0;
    NSDictionary* matchedAttributes;
    for (NSArray *tagsAndAttributes in tagsAndAttributesArray) {
        NSArray * tagsToMatch = tagsAndAttributes[0];
        for (NSString *tagToMatch in tagsToMatch) {
            if([tagToMatch isEqualToString:tag]) {
                matchedAttributes = tagsAndAttributesArray[i][1];
                break;
            }
        }
        if (matchedAttributes)
            break;
        i++;
    }
    
    return matchedAttributes;
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

-(NSString*) newLineActionForTag:(NSString*)tag  content:(NSString*)content
{
    NSNumber* nlTypeNumber = [self matcher:self.newlineActionForTag forTag:tag];
    NewLineCharactersType nlType = nlTypeNumber ?  [nlTypeNumber intValue] : kNewLineCharactersTypeDefault;
    switch (nlType) {
        case kNewLineCharactersNone: return nil;
        case kNewLineCharactersAlways: return @"\n";
        case kNewLineCharactersOneNewLineOnly: {
            NSRange range = [self.endsInNewlineRegex rangeOfFirstMatchInString:content options:0 range:(NSRange){0,content.length}];
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

-(NSNumber*) trimForTag:(NSString*)tag {
    return [self matcher:self.trimActionForTag forTag:tag];
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
        NSAssert(element.children.count == 0, @"Expected no children for textnode, most likely an error");
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
            NSString* preTag = [self matcher:self.prependStringForTag forTag:tagName];
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
