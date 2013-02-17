
#import <SenTestingKit/SenTestingKit.h>
#import "NSDictionary+Merge.h"

@interface NSDictionary_MergeTests : SenTestCase

@end

@implementation NSDictionary_MergeTests

- (void)testExclusiveKeys
{
    NSDictionary *merge1 = @{@"key1" : @"value1"};
    NSDictionary *merge2 = @{@"key2" : @"value2"};

    NSDictionary *expected = @{@"key1": @"value1",
                               @"key2": @"value2"};
    NSDictionary *result = [merge1 dictionaryByMergingWith:merge2];
    STAssertEqualObjects(expected, result, @"");
}

- (void)testIntersectingKeysWithOverWrite
{
    NSDictionary *merge1 = @{@"key1" : @"value1",@"key2" : @"value1"};
    NSDictionary *merge2 = @{@"key2" : @"value2"};
    
    NSDictionary *expected = @{@"key1": @"value1",
                               @"key2": @"value2"};
    
    NSDictionary *result = [merge1 dictionaryByMergingWith:merge2 overWriteExistingKeys:YES];
    STAssertEqualObjects(expected, result, @"");
}

- (void)testIntersectingKeysWithNoOverWrite
{
    NSDictionary *merge1 = @{@"key1" : @"value1",@"key2" : @"value1"};
    NSDictionary *merge2 = @{@"key2" : @"value2"};
    
    NSDictionary *expected = @{@"key1": @"value1",
                               @"key2": @"value1"};
    
    NSDictionary *result = [merge1 dictionaryByMergingWith:merge2 overWriteExistingKeys:NO];
    STAssertEqualObjects(expected, result, @"");
    
}


- (void)testIntersectingRecursiveKeysWithNoOverWrite
{
    NSDictionary *subdict1 = @{@"key1.1" : @"value1.1", @"key1.2" : @"value1.2"};
    NSDictionary *subdict2 = @{@"key1.1" : @"value1.1-a", @"key1.2" : @"value1.2-a"};
    NSDictionary *merge1 = @{@"key1" : subdict1, @"key2" : @"value1"};
    NSDictionary *merge2 = @{@"key1" : subdict2};
    
    NSDictionary *expected = @{@"key1": [subdict1 copy],
                               @"key2": @"value1"};
    
    NSDictionary *result = [merge1 dictionaryByMergingWith:merge2 overWriteExistingKeys:NO];
    STAssertEqualObjects(expected, result, @"");
    
}

- (void)testIntersectingRecursiveKeysWithOverWrite
{
    NSDictionary *subdict1 = @{@"key1.1" : @"value1.1", @"key1.2" : @"value1.2"};
    NSDictionary *subdict2 = @{@"key1.1" : @"value1.1-a", @"key1.2" : @"value1.2-a"};
    NSDictionary *merge1 = @{@"key1" : subdict1, @"key2" : @"value1"};
    NSDictionary *merge2 = @{@"key1" : subdict2};
    
    NSDictionary *expected = @{@"key1": [subdict2 copy],
                               @"key2": @"value1"};
    
    NSDictionary *result = [merge1 dictionaryByMergingWith:merge2 overWriteExistingKeys:YES];
    STAssertEqualObjects(expected, result, @"");
    
}



@end
