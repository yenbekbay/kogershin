#import <UIKit/UIKit.h>

@interface UIColor (AYHelpers)

- (instancetype)lighterColor:(CGFloat)increment;
- (instancetype)darkerColor:(CGFloat)decrement;
- (BOOL)isEqualToColor:(UIColor *)compareColor;

@end
