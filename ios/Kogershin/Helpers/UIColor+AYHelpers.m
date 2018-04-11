#import "UIColor+AYHelpers.h"

@implementation UIColor (AYHelpers)

- (instancetype)lighterColor:(CGFloat)increment {
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:(CGFloat)MIN(r + increment, 1.0)
                               green:(CGFloat)MIN(g + increment, 1.0)
                                blue:(CGFloat)MIN(b + increment, 1.0)
                               alpha:a];
    return nil;
}

- (instancetype)darkerColor:(CGFloat)decrement {
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:(CGFloat)MAX(r - decrement, 0.0)
                               green:(CGFloat)MAX(g - decrement, 0.0)
                                blue:(CGFloat)MAX(b - decrement, 0.0)
                               alpha:a];
    return nil;
}

- (BOOL)isEqualToColor:(UIColor *)compareColor {
    CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
    
    UIColor *(^convertColorToRGBSpace)(UIColor *) = ^(UIColor *color) {
        if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
            const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
            CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
            CGColorRef colorRef = CGColorCreate( colorSpaceRGB, components );
            
            UIColor *newColor = [UIColor colorWithCGColor:colorRef];
            CGColorRelease(colorRef);
            return newColor;
        } else {
            return color;
        }
    };
    
    UIColor *selfColor = convertColorToRGBSpace(self);
    compareColor = convertColorToRGBSpace(compareColor);
    CGColorSpaceRelease(colorSpaceRGB);
    
    return [selfColor isEqual:compareColor];
}

@end
