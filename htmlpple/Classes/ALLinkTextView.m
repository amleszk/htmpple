
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

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.linkRanges = [NSMutableArray array];
        self.activeLinkIndex = NSNotFound;
        self.linkColorDefault = [UIColor blueColor];
        self.linkColorActive = [self.linkColorDefault colorWithAlphaComponent:0.5];
        self.backgroundColor = [UIColor clearColor];
        self.allowInteractionOtherThanLinks = YES;
        self.contentInset = (UIEdgeInsets){.top=-4,.right=-4,.bottom=-5,.left=-5};
        self.multipleTouchEnabled = NO;
        self.delaysContentTouches = NO;
        self.scrollEnabled = NO;
        self.panGestureRecognizer.cancelsTouchesInView = NO;
        
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
    
    if(gesture.state == UIGestureRecognizerStateEnded && self.activeLinkIndex != NSNotFound) {
        [self.linkDelegate textView:self didTapLinkWithHref:self.linkRanges[self.activeLinkIndex][1]];
    }
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
    NSLog(@"unHighlightActiveLink");
}

//-(void)linkButtonTapped:(UIButton*)buttonLink
//{
//    [self highlightLink:NO forRange:[self.linkRanges[buttonLink.tag][0] rangeValue]];
//    [self.linkDelegate textView:self didTapLinkWithHref:self.linkRanges[buttonLink.tag][1]];
//}

-(NSInteger)linkIndexForPoint:(CGPoint)point textRect:(CGRect*)textRect
{
    UITextRange *textRange = [self characterRangeAtPoint:point];
    NSArray *rects = [self selectionRectsForRange:textRange];
    if (rects.count == 0) {
        return NSNotFound;
    }
    
    if (textRect) {
        UITextSelectionRect *textSelectionRect = rects[0];
        (*textRect) = textSelectionRect.rect;
    }
    
    NSInteger charactersIn = [self offsetFromPosition:self.beginningOfDocument toPosition:textRange.start];
    NSInteger hitLink = NSNotFound;
    NSInteger index = 0;
    for(NSArray *value in self.linkRanges) {
        NSRange range = [value[0] rangeValue];
        if (range.location<charactersIn &&
            ((range.location+range.length)>=charactersIn)) {
            hitLink = index;
            break;
        }
        index++;
    }
    return hitLink;
}

#pragma mark - Public

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
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
    
    NSInteger linkIndex = [self linkIndexForPoint:point textRect:nil];
    if (linkIndex!= NSNotFound) {
        NSLog(@"Hit link: %@",self.linkRanges[linkIndex][1]);
        return hitView;
    } else {
        return nil;
    }
    
//    if (hitView == self) return nil;
//    else return hitView;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    NSSet *allTouches = [event allTouches];
    for (UITouch *touch in allTouches)
    {
        CGPoint point = [touch locationInView:touch.view];
        NSLog(@"touchesBegan: %@",NSStringFromCGPoint(point));
        CGRect textRect;
        NSInteger linkIndex = [self linkIndexForPoint:point textRect:&textRect];
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
        NSLog(@"touchesMoved: %@",NSStringFromCGPoint(point));
        NSInteger linkIndex = [self linkIndexForPoint:point textRect:nil];
        if (linkIndex== NSNotFound && self.activeLinkIndex != NSNotFound) {
            [self unHighlightActiveLink];
        }
    }
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self unHighlightActiveLink];
    NSLog(@"touchesEnded");
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self unHighlightActiveLink];    
    NSLog(@"touchesCancelled");
}

@end
