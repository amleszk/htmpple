
#import "ALLinkTextView.h"
#import "ALHtmlToAttributedStringParser.h"
#import "ALLinkTextView.h"

@interface ALLinkTextView ()
@property NSInteger activeLinkIndex;
@property CGRect activeTextRect;
@property NSMutableArray* linkRanges;
@property UIView* touchInterceptView;
@property UILongPressGestureRecognizer* longPress;
@property UITapGestureRecognizer* tap;
@end

@implementation ALLinkTextView : UITextView

static UIColor *linkColorActiveAppearance;
static UIColor *linkColorDefaultAppearance;
+(void) initialize
{
    linkColorActiveAppearance = [[UIColor blueColor] colorWithAlphaComponent:0.5];
    linkColorDefaultAppearance = [UIColor blueColor];
}

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.linkRanges = [NSMutableArray array];
        self.activeLinkIndex = NSNotFound;
        self.backgroundColor = [UIColor clearColor];
        self.allowInteractionOtherThanLinks = YES;
        self.multipleTouchEnabled = NO;
        self.delaysContentTouches = NO;
        self.touchInterceptView = [[UIView alloc] initWithFrame:frame];
        self.touchInterceptView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.touchInterceptView];

        self.tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        self.tap.numberOfTapsRequired = 1;
        [self.touchInterceptView addGestureRecognizer:self.tap];

        self.longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self.longPress setMinimumPressDuration:0.5];
        [self.touchInterceptView addGestureRecognizer:self.longPress];

    }
    return self;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    
    if(gesture.state == UIGestureRecognizerStateBegan && self.activeLinkIndex != NSNotFound) {
        [self.linkDelegate textView:self
           didLongPressLinkWithHref:self.linkRanges[self.activeLinkIndex][1]
                           textRect:self.activeTextRect];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    
    CGPoint point = [gesture locationInView:self];
    NSInteger linkIndex = [self linkIndexForPoint:point textRectStorage:nil];
    if(linkIndex != NSNotFound) {
        [self.linkDelegate textView:self didTapLinkWithHref:self.linkRanges[linkIndex][1]];
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

-(void) highlightLink:(BOOL)active atIndex:(NSInteger)index
{
    NSMutableAttributedString *newAttrText = [self.attributedText mutableCopy];
    UIColor *color = (active ? self.linkColorActive : self.linkColorDefault);
    NSRange range = [self.linkRanges[index][0] rangeValue];
    [newAttrText addAttribute:NSForegroundColorAttributeName value:color range:range];
    self.attributedText = newAttrText;
}

-(void) unHighlightActiveLink
{
    if (self.activeLinkIndex == NSNotFound) {
        return;
    }
    [self highlightLink:NO atIndex:self.activeLinkIndex];
    self.activeLinkIndex = NSNotFound;
}

-(NSInteger)linkIndexForPoint:(CGPoint)point textRectStorage:(CGRect*)textRectStorage
{
    UITextRange *textRange = [self characterRangeAtPoint:point];
    NSArray *rects = [self selectionRectsForRange:textRange];
    if (rects.count == 0) {
        return NSNotFound;
    }
    
    NSInteger charactersIn = [self offsetFromPosition:self.beginningOfDocument toPosition:textRange.start];
    NSInteger hitLink = NSNotFound;
    NSRange hitRange = {NSNotFound,0};
    NSInteger index = 0;
    for(NSArray *value in self.linkRanges) {
        NSRange range = [value[0] rangeValue];
        if (range.location<charactersIn &&
            ((range.location+range.length)>=charactersIn)) {
            hitLink = index;
            hitRange = range;
            break;
        }
        index++;
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
    CGRect selectionCGRect;
    for (UITextSelectionRect *selectionRect in selectionRects) {
        selectionCGRect = selectionRect.rect;
        if (CGRectContainsPoint(selectionCGRect, point)) {
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

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText
{
    [self setAttributedText:attributedText];
    [self.linkRanges removeAllObjects];
    [attributedText enumerateAttribute:kALHtmlToAttributedParsedHref
                               inRange:(NSRange){0,self.text.length}
                               options:0
                            usingBlock:^(id value, NSRange range, BOOL *stop) {
                                if(value) {
                                    [self.linkRanges addObject:@[[NSValue valueWithRange:range],value]];
                                }
                            }];
}


#pragma mark - Disabling user interaction

- (BOOL)canBecomeFirstResponder {
    return NO;
}

-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    id hitView = [super hitTest:point withEvent:event];
    if (self.allowInteractionOtherThanLinks) {
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
            self.activeLinkIndex = linkIndex;
            self.activeTextRect = textRect;
            [self highlightLink:YES atIndex:linkIndex];
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
        if (linkIndex== NSNotFound && self.activeLinkIndex != NSNotFound) {
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
