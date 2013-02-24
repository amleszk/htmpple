
#import "NSDictionary+Merge.h"

@implementation NSDictionary (Merge)

- (NSDictionary *) dictionaryByMergingWith:(NSDictionary *)dict overWriteExistingKeys:(BOOL)overWriteExistingKeys
{    
    NSMutableDictionary * result = [NSMutableDictionary dictionaryWithDictionary:self];
    [result mergeWith:dict overWriteExistingKeys:overWriteExistingKeys];
    return (NSDictionary *) [NSDictionary dictionaryWithDictionary:result];

}

- (NSDictionary *) dictionaryByMergingWith:(NSDictionary *)dict
{
    return [self dictionaryByMergingWith:dict overWriteExistingKeys:YES];
}

@end

@implementation NSMutableDictionary (Merge)

- (void) mergeWith:(NSDictionary *)dict overWriteExistingKeys:(BOOL)overWriteExistingKeys
{
    [dict enumerateKeysAndObjectsUsingBlock: ^(id otherKey, id otherObject, BOOL *stop) {
        id myObject = self[otherKey];
        if (myObject) {
            if (!overWriteExistingKeys) {
                return;
            }
            if ([otherObject isKindOfClass:[NSDictionary class]] && [myObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *newMergedDictionary = [myObject dictionaryByMergingWith:(NSDictionary *)otherObject];
                otherObject = newMergedDictionary;
            }
        }
        self[otherKey] = otherObject;
    }];
}

@end
