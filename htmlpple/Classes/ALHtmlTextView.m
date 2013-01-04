
#import "ALHtmlTextView.h"
#import "ALHtmlToAttributedStringParser.h"
#import "ALHtmlTextView.h"

@interface ALHtmlTextView ()
@property NSMutableArray* linkRanges;
@end

@implementation ALHtmlTextView : UITextView

-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.linkRanges = [NSMutableArray array];
    }
    return self;
}

-(void) addLinkButtonForRange:(NSRange)linkRange index:(NSUInteger)index
{
    UITextPosition *begin = [self positionFromPosition:self.beginningOfDocument offset:linkRange.location];
    UITextPosition *end = [self positionFromPosition:begin offset:linkRange.length];
    UITextRange *textRange = [self textRangeFromPosition:begin toPosition:end];
    NSArray *rects = [self selectionRectsForRange:textRange];
    for (UITextSelectionRect* selectionRect in rects) {
        CGRect rect = selectionRect.rect;
        UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.frame = rect;
        button.alpha = 0.2;
        button.tag = index;
        [button addTarget:self action:@selector(linkButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
    }
}

-(void)linkButtonTapped:(UIButton*)buttonLink
{
    NSURL* url = [NSURL URLWithString:self.linkRanges[buttonLink.tag][2]];
    [[UIApplication sharedApplication] openURL:url];
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    [self addButtonsForHtmlLinks];
}

-(void) setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self.linkRanges removeAllObjects];
    [attributedText enumerateAttribute:kALHtmlToAttributedParsedHref
                                    inRange:(NSRange){0,self.text.length}
                                    options:0
                                 usingBlock:^(id value, NSRange range, BOOL *stop) {
                                     if(value) {
                                         [self.linkRanges addObject:@[@(range.location),@(range.length),value]];
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
        [self addLinkButtonForRange:(NSRange){[linkRange[0] intValue],[linkRange[1] intValue]} index:idx];
        idx++;
    }
}

@end
