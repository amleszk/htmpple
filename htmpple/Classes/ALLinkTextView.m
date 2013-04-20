
#import "ALLinkTextView.h"
#import "ALHtmlToAttributedStringParser.h"
#import "ALLinkTextView.h"
#import <QuartzCore/QuartzCore.h>

@interface ALLinkTextView ()

@property NSInteger activeLinkIndex;
@property CGRect activeTextRect;
@property CALayer *activeLinkLayer;

@property NSMutableArray* linkRanges;
@property UIView* touchInterceptView;
@property UILongPressGestureRecognizer* longPress;
@property UITapGestureRecognizer* tap;
@end

@implementation ALLinkTextView : UITextView

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
        _linkRanges = [NSMutableArray array];
        _activeLinkIndex = NSNotFound;
        self.backgroundColor = [UIColor clearColor];
        _allowInteractionOtherThanLinks = YES;
        self.multipleTouchEnabled = NO;
        self.delaysContentTouches = NO;
        _touchInterceptView = [[UIView alloc] initWithFrame:frame];
        _touchInterceptView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_touchInterceptView];
        
        _tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        _tap.numberOfTapsRequired = 1;
        [_touchInterceptView addGestureRecognizer:_tap];
        
        _longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [_longPress setMinimumPressDuration:0.5];
        [_touchInterceptView addGestureRecognizer:_longPress];
        
    }
    return self;
}

-(void) layoutSubviews {
    [super layoutSubviews];
    _touchInterceptView.frame = self.bounds;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    
    if(gesture.state == UIGestureRecognizerStateBegan && _activeLinkIndex != NSNotFound) {
        
        NSArray *items = _linkRanges[_activeLinkIndex];
        NSRange range = [items[ALLinkTextViewLinkRangeItem] rangeValue];
        NSString* text = [self.text substringWithRange:range];
        NSString* href = items[ALLinkTextViewLinkHrefItem];
        
        [_linkDelegate textView:self
       didLongPressLinkWithText:text
                           href:href
                       textRect:_activeTextRect];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    
    CGPoint point = [gesture locationInView:self];
    NSInteger linkIndex = [self linkIndexForPoint:point textRectStorage:nil];
    if(linkIndex != NSNotFound) {
        
        NSArray *items = _linkRanges[linkIndex];
        NSRange range = [items[ALLinkTextViewLinkRangeItem] rangeValue];
        NSString* text = [self.text substringWithRange:range];
        NSString* href = items[ALLinkTextViewLinkHrefItem];
        
        [_linkDelegate textView:self didTapLinkWithText:text href:href];
    }
}

#pragma mark - UIAppearance

-(UIColor*) linkColorActive {
    return _linkColorActive ?: linkColorActiveAppearance;
}

-(UIColor*) linkColorDefault {
    return _linkColorDefault ?: linkColorDefaultAppearance;
}

#pragma mark - Hyperlink management

-(void) unHighlightActiveLink
{
    if (_activeLinkIndex == NSNotFound) {
        return;
    }
    [_activeLinkLayer removeFromSuperlayer];
    _activeLinkLayer = nil;
    _activeLinkIndex = NSNotFound;
}

-(NSInteger)linkIndexForPoint:(CGPoint)originalPoint textRectStorage:(CGRect*)textRectStorage
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
            for(NSArray *value in _linkRanges) {
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
        return NSNotFound;
    }
    
    // Check the rect of this link actually contains the touch point, characterRangeAtPoint: returns a selection range
    // when there is a link at the end of line and it doesn not actually contain the point
    UITextPosition* linkRangeStart = [self positionFromPosition:self.beginningOfDocument offset:hitRange.location];
    UITextPosition* linkRangeEnd = [self positionFromPosition:linkRangeStart offset:hitRange.length];
    UITextRange* linkTextRange = [self textRangeFromPosition:linkRangeStart toPosition:linkRangeEnd];
    NSArray *selectionRects = [self selectionRectsForRange:linkTextRange];
    BOOL oneRectContainsPoint = NO;
    CGRect selectionCGRect = CGRectZero;
    for (UITextSelectionRect *selectionRect in selectionRects) {
        selectionCGRect = selectionRect.rect;
        if (CGRectContainsPoint(selectionCGRect, pointWithOffset)) {
            oneRectContainsPoint = YES;
            break;
        }
    }
    
    if (!oneRectContainsPoint) {
        return NSNotFound;
    }
    if (textRectStorage) {
        (*textRectStorage) = selectionCGRect;
    }
    
    return hitLink;
}

#pragma mark - Public

typedef enum {
    ALLinkTextViewLinkRangeItem,
    ALLinkTextViewLinkHrefItem
} ALLinkTextViewLink;

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText
{
    [self setAttributedText:attributedText];
    [_linkRanges removeAllObjects];
    [attributedText enumerateAttribute:kALHtmlToAttributedParsedHref
                               inRange:(NSRange){0,self.text.length}
                               options:0
                            usingBlock:^(id value, NSRange range, BOOL *stop) {
                                if(value) {
                                    [_linkRanges addObject:@[[NSValue valueWithRange:range],value]];
                                }
                            }];
}


#pragma mark - Disabling user interaction

- (BOOL)canBecomeFirstResponder {
    return NO;
}

-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitView = [super hitTest:point withEvent:event];
    if (_allowInteractionOtherThanLinks) {
        return hitView;
    }
    
    NSInteger linkIndex = [self linkIndexForPoint:point textRectStorage:nil];
    if (linkIndex!= NSNotFound) {
        return hitView;
    } else {
        return nil;
    }
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    NSSet *allTouches = [event allTouches];
    for (UITouch *touch in allTouches)
    {
        CGPoint point = [touch locationInView:touch.view];
        CGRect textRect;
        NSInteger linkIndex = [self linkIndexForPoint:point textRectStorage:&textRect];
        
        if (linkIndex!= NSNotFound) {
            //NSRange range = [_linkRanges[linkIndex][ALLinkTextViewLinkRangeItem] rangeValue];
            if ([_linkDelegate respondsToSelector:@selector(textView:shouldHighlightLinkWithHref:)]) {
                NSString* href = _linkRanges[linkIndex][ALLinkTextViewLinkHrefItem];
                if(![_linkDelegate textView:self shouldHighlightLinkWithHref:href]) {
                    continue;
                }
            }
            
            _activeLinkIndex = linkIndex;
            _activeTextRect = textRect;
            _activeLinkLayer = [CALayer layer];
            _activeLinkLayer.backgroundColor = [[self linkColorActive] CGColor];
            _activeLinkLayer.cornerRadius = 4;
            _activeLinkLayer.frame = CGRectInset(_activeTextRect, -2, -2);
            [self.layer addSublayer:_activeLinkLayer];
        }
    }
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    NSSet *allTouches = [event allTouches];
    for (UITouch *touch in allTouches)
    {
        CGPoint point = [touch locationInView:touch.view];
        NSInteger linkIndex = [self linkIndexForPoint:point textRectStorage:nil];
        if (linkIndex== NSNotFound && _activeLinkIndex != NSNotFound) {
            [self unHighlightActiveLink];
        }
    }
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self unHighlightActiveLink];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self unHighlightActiveLink];
}

@end
