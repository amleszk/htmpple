
#import "ALLinkTextViewShared.h"
#import "ALHtmlToAttributedStringParser.h"

@interface ALLinkTextViewShared ()

@property NSInteger activeLinkIndex;
@property CGRect activeTextRect;
@property CALayer *activeLinkLayer;

@property UIView* touchInterceptView;
@property UILongPressGestureRecognizer* longPress;
@property UITapGestureRecognizer* tap;

@end

@implementation ALLinkTextViewShared : UITextView

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

-(void) commonInit
{
    _allowInteractionOtherThanLinks = NO;
    self.multipleTouchEnabled = NO;
    self.delaysContentTouches = NO;
    self.scrollEnabled = NO;
    _touchInterceptView = [[UIView alloc] initWithFrame:self.frame];
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
    
    _linkRanges = [NSMutableArray array];
    _activeLinkIndex = NSNotFound;
    self.backgroundColor = [UIColor clearColor];
}

//-(id) initWithFrame:(CGRect)frame
//{
//    NSTextContainer *textContainer = [[NSTextContainer alloc] init];
//    textContainer.widthTracksTextView = YES;
//    self = [super initWithFrame:frame textContainer:textContainer];
//    if (self) {
//        
//        self.textContainerInset = UIEdgeInsetsZero;
//        
//        self.al_layoutManager = [[NSLayoutManager alloc] init];
//        [self.al_layoutManager addTextContainer:textContainer];
//        
//        self.al_textStorage = [[NSTextStorage alloc] init];
//        [self.al_textStorage addLayoutManager:self.al_layoutManager];
//        
//    }
//    return self;
//}

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
    NSAssert(NO, @"Override");
    return 0;
}

#pragma mark - Public

typedef enum {
    ALLinkTextViewLinkRangeItem,
    ALLinkTextViewLinkHrefItem
} ALLinkTextViewLink;

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText
{
    [self setAttributedText:attributedText];
    [self updateLinkRangesWithAttributedText:attributedText];
}

-(void) updateLinkRangesWithAttributedText:(NSAttributedString *)attributedText
{
    [_linkRanges removeAllObjects];
    [attributedText enumerateAttribute:kALHtmlToAttributedParsedHref
                               inRange:(NSRange){0,attributedText.string.length}
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
