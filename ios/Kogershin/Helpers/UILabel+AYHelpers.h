#import <UIKit/UIKit.h>

@interface UILabel (AYHelpers)

- (void)setFrameToFitWithHeightLimit:(CGFloat)heightLimit;
- (CGRect)frameToFitWithHeightLimit:(CGFloat)heightLimit;
- (CGSize)sizeToFitWithHeightLimit:(CGFloat)heightLimit;
- (CGSize)sizeToFitWithOneLine;

@end
