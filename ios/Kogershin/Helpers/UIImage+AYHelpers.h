#import <UIKit/UIKit.h>

@interface UIImage (AYHelpers)

+ (instancetype)imageWithColor:(UIColor *)color;
+ (instancetype)convertViewToImage;
+ (instancetype)convertViewToImage:(UIView *)view;
- (instancetype)crop:(CGRect)rect;
- (instancetype)scaledToSize:(CGSize)newSize;
- (BOOL)isEqualToImage:(UIImage *)image;

@end
