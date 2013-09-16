
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

- (void)testLinkAttributes
{
    NSString * html = @"<!-- SC_OFF --><div class=\"md\"><p>NAY D DelBene, Suzan WA 1st</p> <p>YEA D Larsen, Rick WA 2nd</p> <p>NAY R Herrera Beutler, Jaime WA 3rd</p> <p>YEA R Hastings, Doc WA 4th</p> <p>YEA R McMorris Rodgers, Cathy WA 5th</p> <p>YEA D Kilmer, Derek WA 6th</p> <p>NAY D McDermott, Jim WA 7th</p> <p>YEA R Reichert, David WA 8th</p> <p>YEA D Smith, Adam WA 9th</p> <p>YEA D Heck, Denny WA 10th</p> <p><a href=\"http://www.govtrack.us/congress/votes/113-2013/h117\">http://www.govtrack.us/congress/votes/113-2013/h117</a></p> </div><!-- SC_ON -->";
    
    ALHtmlToAttributedStringParser* parser = [[ALHtmlToAttributedStringParser alloc] init];
    NSAttributedString* attrString = [parser attributedStringWithHTMLData:[html dataUsingEncoding:NSUTF8StringEncoding] trim:YES];
    
    [attrString enumerateAttribute:kALHtmlToAttributedParsedHref
                       inRange:(NSRange){0,attrString.string.length}
                               options:0
                            usingBlock:^(id value, NSRange range, BOOL *stop) {
                                if(value) {
                                    STAssertEqualObjects(@"http://www.govtrack.us/congress/votes/113-2013/h117", value, @"");
                                }
                            }];

}

- (void)testNestingTags
{
    
}

@end
