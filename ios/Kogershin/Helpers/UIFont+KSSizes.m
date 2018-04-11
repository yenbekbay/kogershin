#import "UIFont+KSSizes.h"
#import "AYMacros.h"

@implementation UIFont (KSSizes)

+ (CGFloat)extraSmallTextFontSize {
    if (IS_IPHONE_6P) {
        return 12;
    } else if (IS_IPHONE_6) {
        return 11;
    } else {
        return 10;
    }
}

+ (CGFloat)smallTextFontSize {
    if (IS_IPHONE_6P) {
        return 16;
    } else if (IS_IPHONE_6) {
        return 15;
    } else {
        return 14;
    }
}

+ (CGFloat)mediumTextFontSize {
    if (IS_IPHONE_6P) {
        return 17;
    } else if (IS_IPHONE_6) {
        return 16;
    } else {
        return 15;
    }
}

+ (CGFloat)largeTextFontSize {
    if (IS_IPHONE_6P) {
        return 26;
    } else if (IS_IPHONE_6) {
        return 24;
    } else {
        return 22;
    }
}

+ (CGFloat)extraLargeTextFontSize {
    if (IS_IPHONE_6P) {
        return 64;
    } else if (IS_IPHONE_6) {
        return 60;
    } else {
        return 56;
    }
}

+ (CGFloat)buttonFontSize {
    if (IS_IPHONE_6P) {
        return 19;
    } else if (IS_IPHONE_6) {
        return 18;
    } else {
        return 17;
    }
}

@end
