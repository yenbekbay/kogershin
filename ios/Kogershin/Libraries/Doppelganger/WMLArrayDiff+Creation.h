//
//  Copyright (c) 2015 Sash Zats.
//

#import "WMLArrayDiff.h"

@interface WMLArrayDiff (Creation)

+ (instancetype)arrayDiffForDeletionAtIndex:(NSUInteger)index;
+ (instancetype)arrayDiffForInsertionAtIndex:(NSUInteger)index;
+ (instancetype)arrayDiffForMoveFromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end
