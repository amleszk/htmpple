
#import "ALLinkTextView7.h"
#import "ALHtmlToAttributedStringParser.h"

@implementation ALLinkTextView7

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.textContainerInset = UIEdgeInsetsMake(5, 0, 0, 0);
        [self commonInit];
    }
    return self;
}

-(ALLinkHitData*)linkIndexForPoint:(CGPoint)originalPoint
{
    CGPoint textContainerPoint = CGPointMake(originalPoint.x-self.textContainerInset.left,
                                             originalPoint.y-self.textContainerInset.top);
    
    NSInteger charactersIn =
    [self.layoutManager glyphIndexForPoint:textContainerPoint
                           inTextContainer:self.textContainer];
    
    NSInteger index = 0;
    UIEdgeInsets insets = self.textContainerInset;
    
    for(NSArray *value in self.linkRanges) {
        NSRange range = [value[ALLinkTextViewLinkRangeItem] rangeValue];
        if (range.location<=charactersIn &&
            ((range.location+range.length)>=charactersIn)) {
            
            __block BOOL foundEnclosingRect = NO;
            void (^enumerator)() = ^(CGRect rect, BOOL *stop) {
                CGRect rectWithInsetOffset = CGRectOffset(rect, insets.left, insets.top);
                CGRect rectWithOutset = CGRectInset(rectWithInsetOffset, -3, -5);
                if(CGRectContainsPoint(rectWithOutset, textContainerPoint)) {
                    foundEnclosingRect = YES;
                    (*stop) = YES;
                }
            };
            const static NSRange NSRangeDontCare = {NSNotFound, 0};
            [self.layoutManager enumerateEnclosingRectsForGlyphRange:range
                                            withinSelectedGlyphRange:NSRangeDontCare
                                                     inTextContainer:self.textContainer
                                                          usingBlock:enumerator];
            
            if (foundEnclosingRect) {
                NSMutableArray *rectsArray = [NSMutableArray array];
                void (^collector)() = ^(CGRect rect, BOOL *stop) {
                    CGRect rectWithInsetOffset = CGRectOffset(rect, insets.left, insets.top);
                    CGRect rectWithOutset = CGRectInset(rectWithInsetOffset, -1, -2);
                    [rectsArray addObject:[NSValue valueWithCGRect:rectWithOutset]];
                };
                [self.layoutManager enumerateEnclosingRectsForGlyphRange:range
                                                withinSelectedGlyphRange:NSRangeDontCare
                                                         inTextContainer:self.textContainer
                                                              usingBlock:collector];
                
                ALLinkHitData *hitData = [[ALLinkHitData alloc] init];
                hitData.hitIndex = index;
                hitData.hitRects = rectsArray;
                return hitData;
            }
        }
        index++;
    }
    
    return nil;
}

#pragma mark - Public

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText
{
    [self setAttributedText:attributedText];
    [super updateLinkRangesWithAttributedText:attributedText];
    
}

@end
