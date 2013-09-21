
#import "ALLinkTextViewShared.h"
#import "ALHtmlToAttributedStringParser.h"

@implementation ALLinkHitData
@end

@interface ALLinkTextViewShared ()
@end

@implementation ALLinkTextViewShared
{
    NSInteger _activeLinkIndex;
    CGRect _activeTextRect;
    CALayer *_activeLinkLayer;
    
    UIView* _touchInterceptView;
    UILongPressGestureRecognizer* _longPress;
    UITapGestureRecognizer* _tap;
    CALayer *_activeLinkHighlightLayer;
}
static UIColor *linkColorActiveAppearance;
static UIColor *linkColorDefaultAppearance;

+(void) initialize
{
    linkColorActiveAppearance = [UIColor blueColor];
    linkColorDefaultAppearance = [UIColor blueColor];
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
    ALLinkHitData *hit = [self linkIndexForPoint:point];
    if(hit) {
        NSArray *items = _linkRanges[hit.hitIndex];
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
    [_activeLinkHighlightLayer removeFromSuperlayer];
    _activeLinkIndex = NSNotFound;

}

-(ALLinkHitData*)linkIndexForPoint:(CGPoint)originalPoint
{
    NSAssert(NO, @"Override");
    return 0;
}

#pragma mark - Public

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
    
    ALLinkHitData *hit = [self linkIndexForPoint:point];
    if (hit) {
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
        ALLinkHitData *hit = [self linkIndexForPoint:point];
        
        if (hit) {
            //NSRange range = [_linkRanges[linkIndex][ALLinkTextViewLinkRangeItem] rangeValue];
            if ([_linkDelegate respondsToSelector:@selector(textView:shouldHighlightLinkWithHref:)]) {
                NSString* href = _linkRanges[hit.hitIndex][ALLinkTextViewLinkHrefItem];
                if(![_linkDelegate textView:self shouldHighlightLinkWithHref:href]) {
                    continue;
                }
            }
            
            _activeLinkIndex = hit.hitIndex;
            CALayer *alphaLayer = [[CALayer alloc] init];
            alphaLayer.frame = self.bounds;
            alphaLayer.opacity = 0.3;

            for (NSValue *valeRect in hit.hitRects) {
                CALayer *activeLinkLayer = [CALayer layer];
                activeLinkLayer.backgroundColor = [[self linkColorActive] CGColor];
                activeLinkLayer.cornerRadius = 0;
                activeLinkLayer.frame = CGRectInset([valeRect CGRectValue], 0, 0);
                [alphaLayer addSublayer:activeLinkLayer];
            }
            [self.layer addSublayer:alphaLayer];
            _activeLinkHighlightLayer = alphaLayer;
            
            _activeTextRect = [hit.hitRects[0] CGRectValue];
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
        ALLinkHitData *hit = [self linkIndexForPoint:point];
        if (hit && _activeLinkIndex != NSNotFound) {
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
