//
//  Copyright (c) 2015 Sash Zats.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WMLArrayDiffType) {
    WMLArrayDiffTypeMove,
    WMLArrayDiffTypeInsert,
    WMLArrayDiffTypeDelete
};

@interface WMLArrayDiff : NSObject

@property (nonatomic, readonly) WMLArrayDiffType type;
@property (nonatomic, readonly) NSUInteger previousIndex;
@property (nonatomic, readonly) NSUInteger currentIndex;

@end
