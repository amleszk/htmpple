
#import "ALLinkTextView.h"
#import "ALHtmlToAttributedStringParser.h"
#import "ALLinkTextView.h"

@interface ALLinkTextView ()
@property NSMutableArray* linkRanges;
@property NSMutableArray* linkButtons;
@property CGRect linkButtonsAddedForBounds;
@end

@implementation ALLinkTextView : UITextView

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.linkRanges = [NSMutableArray array];
        self.linkButtons = [NSMutableArray array];
        self.linkColorDefault = [UIColor blueColor];
        self.linkColorActive = [self.linkColorDefault colorWithAlphaComponent:0.5];
        self.backgroundColor = [UIColor clearColor];
        self.allowInteractionOtherThanLinks = YES;
        //[self setUserInteractionEnabled:NO];
    }
    return self;
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    if (CGRectEqualToRect(bounds, self.linkButtonsAddedForBounds) ||
        CGRectEqualToRect(bounds, CGRectZero)) {
        return;
    }
    [self addButtonsForHtmlLinks];
    self.linkButtonsAddedForBounds = self.bounds;
}

#pragma mark - Hyperlink management

-(NSArray*) linkButtonsForRange:(NSRange)linkRange index:(NSUInteger)index
{
    UITextPosition *begin = [self positionFromPosition:self.beginningOfDocument offset:linkRange.location];
    UITextPosition *end = [self positionFromPosition:begin offset:linkRange.length];
    UITextRange *textRange = [self textRangeFromPosition:begin toPosition:end];
    NSArray *rects = [self selectionRectsForRange:textRange];
    
    CGFloat previouslyAddedyPosition = -1;
    NSMutableArray *linkButtons = [NSMutableArray array];
    for (UITextSelectionRect* selectionRect in rects) {
        
        //selectionRectsForRange returns multiple rects for the same line
        //for very long text strings. hack to ignore the white space rect the gets sent
        //the second time round (if Y position has not changed since previous iteration)
        CGRect rect = selectionRect.rect;
        if (rect.origin.y == previouslyAddedyPosition) {
            continue;
        }
        
        previouslyAddedyPosition = rect.origin.y;
        
        //UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        //button.alpha = 0.3;
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        button.frame = rect;
        button.tag = index;
        [button addTarget:self action:@selector(linkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(linkButtonActive:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(linkButtonInActive:) forControlEvents:UIControlEventTouchDragOutside];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(linkButtonLongPress:)];
        [button addGestureRecognizer:longPress];
        [linkButtons addObject:button];
    }
    return linkButtons;
}


-(void) setActiveLink:(BOOL)active forRange:(NSRange)range
{
    NSMutableAttributedString *newAttrText = [self.attributedText mutableCopy];
    UIColor *color = (active ? self.linkColorActive : self.linkColorDefault);
    [newAttrText addAttribute:NSForegroundColorAttributeName value:color range:range];
    self.attributedText = newAttrText;
}

-(void)linkButtonLongPress:(UILongPressGestureRecognizer*)gesture
{
    if(UIGestureRecognizerStateBegan == gesture.state) {
        NSString* href = self.linkRanges[gesture.view.tag][1];
        [self.linkDelegate textView:self didLongPressLinkWithHref:href view:gesture.view];
        [self linkButtonInActive:(UIButton*)gesture.view];
    }
    else if(UIGestureRecognizerStateEnded == gesture.state) {
        [self linkButtonInActive:(UIButton*)gesture.view];
    }
}

-(void)linkButtonTapped:(UIButton*)buttonLink
{
    [self setActiveLink:NO forRange:[self.linkRanges[buttonLink.tag][0] rangeValue]];
    [self.linkDelegate textView:self didTapLinkWithHref:self.linkRanges[buttonLink.tag][1]];
}

-(void)linkButtonActive:(UIButton*)buttonLink
{
    [self setActiveLink:YES forRange:[self.linkRanges[buttonLink.tag][0] rangeValue]];
}

-(void)linkButtonInActive:(UIButton*)buttonLink
{
    [self setActiveLink:NO forRange:[self.linkRanges[buttonLink.tag][0] rangeValue]];
}

-(BOOL) isLinkActive
{
    for (UIButton *button in self.linkButtons) {
        if (button.selected) {
            return YES;
        }
    }
    return NO;
}

-(void) addButtonsForHtmlLinks
{
    [self.linkButtons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.linkButtons removeAllObjects];
    NSUInteger idx = 0;
    for (NSArray* linkRange in self.linkRanges) {
        NSArray *linkButtons = [self linkButtonsForRange:[linkRange[0] rangeValue] index:idx];
        [self.linkButtons addObjectsFromArray:linkButtons];
        idx++;
    }
    for (UIButton* button in self.linkButtons) {
        [self addSubview:button];
    }
}

#pragma mark - Public

-(void) setLinkifiedAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self.linkRanges removeAllObjects];
    self.linkButtonsAddedForBounds = CGRectZero;
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
    
    if (hitView == self) return nil;
    else return hitView;
}

@end
