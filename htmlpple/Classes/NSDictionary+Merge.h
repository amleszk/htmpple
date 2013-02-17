

@interface NSDictionary (Merge)

- (NSDictionary *) dictionaryByMergingWith:(NSDictionary *)dict overWriteExistingKeys:(BOOL)overWriteExistingKeys;
- (NSDictionary *) dictionaryByMergingWith:(NSDictionary *)dict;

@end

