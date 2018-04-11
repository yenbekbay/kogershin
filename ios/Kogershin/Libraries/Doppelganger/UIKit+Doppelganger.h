//
//  Copyright (c) 2015 Sash Zats.
//

#import <UIKit/UIKit.h>

@interface UICollectionView (Doppelganger)

- (void)wml_applyBatchChangesForRows:(NSArray *)changes inSection:(NSUInteger)section completion:(void (^)(BOOL finished))completion;

@end

@interface UITableView (Doppelganger)

- (void)wml_applyBatchChangesForRows:(NSArray *)changes inSection:(NSUInteger)section withRowAnimation:(UITableViewRowAnimation)animation completion:(void (^)(void))completion;
- (void)wml_applyBatchChangesForSections:(NSArray *)changes withRowAnimation:(UITableViewRowAnimation)animation completion:(void (^)(void))completion;

@end
