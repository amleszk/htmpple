
#import "ALLinkTextView6.h"

@implementation ALLinkTextView6

static UIColor *linkColorActiveAppearance;
static UIColor *linkColorDefaultAppearance;

static NSArray *fuzzyTouchPointOffsets;

static CGFloat fuzzyTouchPointBufferY = 5.;
static CGFloat fuzzyTouchPointBufferX = 7.;

+(void) initialize
{
    linkColorActiveAppearance = [[UIColor blueColor] colorWithAlphaComponent:0.3];
    linkColorDefaultAppearance = [UIColor blueColor];
    
    fuzzyTouchPointOffsets = @[
                               [NSValue valueWithCGPoint:CGPointMake(0, 0)],
                               [NSValue valueWithCGPoint:CGPointMake(0, fuzzyTouchPointBufferY)],
                               [NSValue valueWithCGPoint:CGPointMake(0, -fuzzyTouchPointBufferY)],
                               [NSValue valueWithCGPoint:CGPointMake(fuzzyTouchPointBufferX, 0)],
                               [NSValue valueWithCGPoint:CGPointMake(-fuzzyTouchPointBufferX,0)],
                               
                               [NSValue valueWithCGPoint:CGPointMake(fuzzyTouchPointBufferX, fuzzyTouchPointBufferY)],
                               [NSValue valueWithCGPoint:CGPointMake(-fuzzyTouchPointBufferX, -fuzzyTouchPointBufferY)],
                               [NSValue valueWithCGPoint:CGPointMake(fuzzyTouchPointBufferX, -fuzzyTouchPointBufferY)],
                               [NSValue valueWithCGPoint:CGPointMake(-fuzzyTouchPointBufferX, fuzzyTouchPointBufferY)],
                               ];
    
    
}

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self commonInit];
        
    }
    return self;
}


#pragma mark - Hyperlink Management

-(ALLinkHitData*)linkIndexForPoint:(CGPoint)originalPoint
{
    CGPoint pointWithOffset;
    NSInteger hitLink = NSNotFound;
    NSRange hitRange = {NSNotFound,0};
    for (NSValue *offset in fuzzyTouchPointOffsets) {
        
        CGPoint offsetPoint = [offset CGPointValue];
        pointWithOffset = CGPointMake(originalPoint.x+offsetPoint.x, originalPoint.y+offsetPoint.y);
        UITextRange *textRange = [self characterRangeAtPoint:pointWithOffset];
        NSArray *rects = [self selectionRectsForRange:textRange];
        
        if (rects.count != 0) {
            
            NSInteger charactersIn = [self offsetFromPosition:self.beginningOfDocument toPosition:textRange.start];
            hitLink = NSNotFound;
            hitRange = (NSRange){NSNotFound,0};
            NSInteger index = 0;
            for(NSArray *value in self.linkRanges) {
                NSRange range = [value[0] rangeValue];
                if (range.location<=charactersIn &&
                    ((range.location+range.length)>=charactersIn)) {
                    hitLink = index;
                    hitRange = range;
                    break;
                }
                index++;
            }
            
            if (hitLink != NSNotFound) {
                break;
            }
        }
    }
    
    if (hitLink == NSNotFound) {
        return nil;
    }
    
    // Check the rect of this link actually contains the touch point, characterRangeAtPoint: returns a selection range
    // when there is a link at the end of line and it doesn not actually contain the point
    UITextPosition* linkRangeStart = [self positionFromPosition:self.beginningOfDocument offset:hitRange.location];
    UITextPosition* linkRangeEnd = [self positionFromPosition:linkRangeStart offset:hitRange.length];
    UITextRange* linkTextRange = [self textRangeFromPosition:linkRangeStart toPosition:linkRangeEnd];
    NSArray *selectionRects = [self selectionRectsForRange:linkTextRange];
    BOOL oneRectContainsPoint = NO;
    UIEdgeInsets insets = self.contentInset;
    NSMutableArray *textRects = [NSMutableArray arrayWithCapacity:selectionRects.count];
    for (UITextSelectionRect *selectionRect in selectionRects) {
        CGRect offsettedRect = CGRectOffset(selectionRect.rect, insets.left, insets.top);
        [textRects addObject:[NSValue valueWithCGRect:offsettedRect]];
    }
    for (NSValue *rectValue in textRects) {
        CGRect rect = [rectValue CGRectValue];
        if (CGRectContainsPoint(rect, pointWithOffset)) {
            oneRectContainsPoint = YES;
            break;
        }
    }
    
    if (!oneRectContainsPoint) {
        return nil;
    }
    ALLinkHitData *hitData = [[ALLinkHitData alloc] init];
    hitData.hitIndex = hitLink;
    hitData.hitRects = textRects;
    return hitData;
}



@end
