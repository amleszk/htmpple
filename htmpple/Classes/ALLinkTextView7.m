
#import "ALLinkTextView7.h"
#import "ALHtmlToAttributedStringParser.h"

@implementation ALLinkTextView7
{
    NSTextStorage *_al_textStorage;
    NSLayoutManager *_al_layoutManager;
}

//-(id) initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
//{
//    NSAssert(NO, @"Disabled");
//    return nil;
//}

-(id) initWithFrame:(CGRect)frame
{
//    NSTextContainer *textContainer = [[NSTextContainer alloc] init];
//    textContainer.widthTracksTextView = YES;
//    textContainer.heightTracksTextView = YES;
//    self = [super initWithFrame:frame textContainer:textContainer];
    self = [super initWithFrame:frame];
    if (self) {
        self.textContainerInset = UIEdgeInsetsZero;
        
//        _al_layoutManager = [[NSLayoutManager alloc] init];
//        [_al_layoutManager addTextContainer:textContainer];
//        
//        _al_textStorage = [[NSTextStorage alloc] init];
//        [_al_textStorage addLayoutManager:_al_layoutManager];
        
        [self commonInit];
    }
    return self;
}

-(NSInteger)linkIndexForPoint:(CGPoint)originalPoint textRectStorage:(CGRect*)textRectStorage
{
    NSInteger charactersIn =
    [self.layoutManager glyphIndexForPoint:originalPoint
                           inTextContainer:self.textContainer];
    
    NSInteger hitLink = NSNotFound;
    NSRange hitRange = {NSNotFound,0};
    NSInteger index = 0;
    for(NSArray *value in self.linkRanges) {
        NSRange range = [value[0] rangeValue];
        if (range.location<=charactersIn &&
            ((range.location+range.length)>=charactersIn)) {
            
            __block CGRect glyphRectForPoint = CGRectZero;
            void (^enumerator)() = ^(CGRect rect, BOOL *stop) {
                if(CGRectContainsPoint(rect, originalPoint)) {
                    glyphRectForPoint = rect;
                    (*stop) = YES;
                }
            };
            const static NSRange NSRangeDontCare = {NSNotFound, 0};
            [self.layoutManager enumerateEnclosingRectsForGlyphRange:range
                                            withinSelectedGlyphRange:NSRangeDontCare
                                                     inTextContainer:self.textContainer
                                                          usingBlock:enumerator];
            
            if (CGRectEqualToRect(glyphRectForPoint,CGRectZero)) {
                continue;
            }
            
            hitLink = index;
            hitRange = range;
            if (textRectStorage) {
                (*textRectStorage) = glyphRectForPoint;
            }
            break;
        }
        index++;
    }
    
    return hitLink;
}

#pragma mark - Public

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText
{
    [self setAttributedText:attributedText];
//    [_al_textStorage beginEditing];
//    [_al_textStorage setAttributedString:attributedText];
//    [_al_textStorage endEditing];
    [super updateLinkRangesWithAttributedText:attributedText];
    
}

@end
