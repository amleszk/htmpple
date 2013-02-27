

@interface NSDictionary (Merge)

- (NSDictionary *) dictionaryByMergingWith:(NSDictionary *)dict overWriteExistingKeys:(BOOL)overWriteExistingKeys;
- (NSDictionary *) dictionaryByMergingWith:(NSDictionary *)dict;

@end

@interface NSMutableDictionary (Merge)
- (void) mergeWith:(NSDictionary *)dict overWriteExistingKeys:(BOOL)overWriteExistingKeys;
@end

