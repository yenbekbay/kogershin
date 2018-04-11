//
//  Copyright (c) 2015 Sash Zats.
//

#import "UIKit+Doppelganger.h"

#import "WMLArrayDiff.h"

static NSString *const WMLArrayDiffSourceIndexPathKey = @"WMLArrayDiffSourceIndexPathKey";
static NSString *const WMLArrayDiffDestinationIndexPathKey = @"WMLArrayDiffDestinationIndexPathKey";

@implementation UICollectionView (Doppelganger)

- (void)wml_applyBatchChangesForRows:(NSArray *)changes inSection:(NSUInteger)section completion:(void (^)(BOOL))completion {
    NSMutableArray *insertion = [NSMutableArray array];
    NSMutableArray *deletion = [NSMutableArray array];
    NSMutableArray *moving = [NSMutableArray array];
    
    for (WMLArrayDiff *diff in changes) {
        switch (diff.type) {
            case WMLArrayDiffTypeDelete:
                [deletion addObject:[NSIndexPath indexPathForItem:(NSInteger)diff.previousIndex inSection:(NSInteger)section]];
                break;
            case WMLArrayDiffTypeInsert:
                [insertion addObject:[NSIndexPath indexPathForItem:(NSInteger)diff.currentIndex inSection:(NSInteger)section]];
                break;
            case WMLArrayDiffTypeMove:
                [moving addObject:diff];
                break;
        }
    }
    
    [self performBatchUpdates:^{
        [self insertItemsAtIndexPaths:insertion];
        [self deleteItemsAtIndexPaths:deletion];
        for (WMLArrayDiff *diff in moving) {
            [self moveItemAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)diff.previousIndex inSection:(NSInteger)section]
                          toIndexPath:[NSIndexPath indexPathForItem:(NSInteger)diff.currentIndex inSection:(NSInteger)section]];
        }
    } completion:completion];
}

@end

@implementation UITableView (Doppelganger)

- (void)wml_applyBatchChangesForRows:(NSArray *)changes inSection:(NSUInteger)section withRowAnimation:(UITableViewRowAnimation)animation completion:(void (^)(void))completion {
    NSMutableArray *insertion = [NSMutableArray array];
    NSMutableArray *deletion = [NSMutableArray array];
    NSMutableArray *moving = [NSMutableArray array];
    
    for (WMLArrayDiff *diff in changes) {
        switch (diff.type) {
            case WMLArrayDiffTypeDelete:
                [deletion addObject:[NSIndexPath indexPathForItem:(NSInteger)diff.previousIndex inSection:(NSInteger)section]];
                break;
            case WMLArrayDiffTypeInsert:
                [insertion addObject:[NSIndexPath indexPathForItem:(NSInteger)diff.currentIndex inSection:(NSInteger)section]];
                break;
            case WMLArrayDiffTypeMove:
                [moving addObject:diff];
                break;
        }
    }
    
    [self beginUpdates];
    [self deleteRowsAtIndexPaths:deletion withRowAnimation:animation];
    [self insertRowsAtIndexPaths:insertion withRowAnimation:animation];
    for (WMLArrayDiff *diff in moving) {
        [self moveRowAtIndexPath:[NSIndexPath indexPathForItem:(NSInteger)diff.previousIndex inSection:(NSInteger)section]
                     toIndexPath:[NSIndexPath indexPathForItem:(NSInteger)diff.currentIndex inSection:(NSInteger)section]];
    }
    [CATransaction setCompletionBlock:completion];
    [self endUpdates];
}

- (void)wml_applyBatchChangesForSections:(NSArray *)changes withRowAnimation:(UITableViewRowAnimation)animation completion:(void (^)(void))completion {
    NSMutableIndexSet *insertion = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *deletion = [NSMutableIndexSet indexSet];
    NSMutableArray *moving = [NSMutableArray array];
    
    for (WMLArrayDiff *diff in changes) {
        switch (diff.type) {
            case WMLArrayDiffTypeDelete:
                [deletion addIndex:diff.previousIndex];
                break;
            case WMLArrayDiffTypeInsert:
                [insertion addIndex:diff.currentIndex];
                break;
            case WMLArrayDiffTypeMove:
                [moving addObject:diff];
                break;
        }
    }
    
    [self beginUpdates];
    [self deleteSections:deletion withRowAnimation:animation];
    [self insertSections:insertion withRowAnimation:animation];
    for (WMLArrayDiff *diff in moving) {
        [self moveSection:(NSInteger)diff.previousIndex toSection:(NSInteger)diff.currentIndex];
    }
    [CATransaction setCompletionBlock:completion];
    [self endUpdates];
}

@end
