
#import "NSDictionary+Merge.h"

@implementation NSDictionary (Merge)

- (NSDictionary *) dictionaryByMergingWith:(NSDictionary *)dict overWriteExistingKeys:(BOOL)overWriteExistingKeys
{    
    NSMutableDictionary * result = [NSMutableDictionary dictionaryWithDictionary:self];
    [dict enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
        if (self[key] && !overWriteExistingKeys)
            return;
        
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *newMergedDictionary = [self[key] dictionaryByMergingWith:(NSDictionary *)obj];
            obj = newMergedDictionary;
        }
        result[key] = obj;
    }];
    
    return (NSDictionary *) [NSDictionary dictionaryWithDictionary:result];

}

- (NSDictionary *) dictionaryByMergingWith:(NSDictionary *)dict
{
    return [self dictionaryByMergingWith:dict overWriteExistingKeys:YES];
}

@end

