
#import <SenTestingKit/SenTestingKit.h>
#import "ALHtmlToAttributedStringParser.h"

@interface ALHtmlToAttributedStringParserTests : SenTestCase

@end

@implementation ALHtmlToAttributedStringParserTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testTrim
{
    ALHtmlToAttributedStringParser* parser = [[ALHtmlToAttributedStringParser alloc] init];
    NSDictionary* testData = @{
        @"<div class=\"md\"><p>content</p> </div>" : @"content",
        @"<div class=\"md\">    <p>content</p></div>" : @"content",
        @"<div class=\"md\"><p>content</p> <p>content</p> <p>content</p> </div>" : @"content\ncontent\ncontent",
        @"<div class=\"md\"><p/><p/><p/><p>content</p> <p>content</p> <p>content</p> </div>" : @"content\ncontent\ncontent",
        @"<div class=\"md\">  <p>content</p> <p>content</p> <p>content</p> <p/><p/><p/></div>" : @"content\ncontent\ncontent",
        @"<div class=\"md\">  <p/><p><p></p><p></p></p> </div>" : @"",
    };
    
    for (NSString* key in testData) {
        NSAttributedString* actual = [parser attributedStringWithHTMLData:[key dataUsingEncoding:NSUTF8StringEncoding] trim:YES];
        STAssertEqualObjects(actual.string, testData[key], @"");
    }
}

- (void)testParagraphTags
{
    
}

- (void)testNestingTags
{
    
}

@end
