
#import "ALHtmlTextView.h"
#import "ALHtmlToAttributedStringParser.h"
#import "ALHtmlTextView.h"

@interface ALHtmlTextView ()
@property NSMutableArray* linkRanges;
@property CGRect linkButtonsAddedForBounds;
@end

@implementation ALHtmlTextView : UITextView

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.linkRanges = [NSMutableArray array];
        self.linkColorDefault = [UIColor blueColor];
        self.linkColorActive = [self.linkColorDefault colorWithAlphaComponent:0.5];
    }
    return self;
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    if (CGRectEqualToRect(self.frame, self.linkButtonsAddedForBounds)) {
        return;
    }
    [self addButtonsForHtmlLinks];
    self.linkButtonsAddedForBounds = self.frame;
}


-(void) addLinkButtonForRange:(NSRange)linkRange index:(NSUInteger)index
{
    UITextPosition *begin = [self positionFromPosition:self.beginningOfDocument offset:linkRange.location];
    UITextPosition *end = [self positionFromPosition:begin offset:linkRange.length];
    UITextRange *textRange = [self textRangeFromPosition:begin toPosition:end];
    NSArray *rects = [self selectionRectsForRange:textRange];
    
    //selectionRectsForRange returns multiple rects for the same line
    //for very long text strings. hack to ignore the white space rect the gets sent
    //the second time round (if Y position has not changed since previous iteration)
    CGFloat previouslyAddedyPosition = -1;
    
    for (UITextSelectionRect* selectionRect in rects) {
        CGRect rect = selectionRect.rect;
        if (rect.origin.y == previouslyAddedyPosition) {
            continue;
        }
        previouslyAddedyPosition = rect.origin.y;
        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = rect;
        button.tag = index;
        [button addTarget:self action:@selector(linkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(linkButtonActive:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(linkButtonInActive:) forControlEvents:UIControlEventTouchDragOutside];
        [self addSubview:button];
    }
}


-(void) setActiveLink:(BOOL)active forRange:(NSRange)range
{
    NSMutableAttributedString *newAttrText = [self.attributedText mutableCopy];
    UIColor *color = (active ? self.linkColorActive : self.linkColorDefault);
    [newAttrText addAttribute:NSForegroundColorAttributeName value:color range:range];
    self.attributedText = newAttrText;
}

-(void)linkButtonTapped:(UIButton*)buttonLink
{
    [self setActiveLink:NO forRange:[self.linkRanges[buttonLink.tag][0] rangeValue]];
    NSURL* url = [NSURL URLWithString:self.linkRanges[buttonLink.tag][1]];
    [[UIApplication sharedApplication] openURL:url];
}

-(void)linkButtonActive:(UIButton*)buttonLink
{
    [self setActiveLink:YES forRange:[self.linkRanges[buttonLink.tag][0] rangeValue]];
}

-(void)linkButtonInActive:(UIButton*)buttonLink
{
    [self setActiveLink:NO forRange:[self.linkRanges[buttonLink.tag][0] rangeValue]];
}

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

-(void) addButtonsForHtmlLinks
{
    [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[UIButton class]]) {
            [obj removeFromSuperview];
        }
    }];
    NSUInteger idx = 0;
    for (NSArray* linkRange in self.linkRanges) {
        [self addLinkButtonForRange:[linkRange[0] rangeValue] index:idx];
        idx++;
    }
}

@end
