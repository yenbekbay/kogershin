#import "UIColor+KSTints.h"

@implementation UIColor (KSTints)

#define AGEColorImplement(COLOR_NAME,RED,GREEN,BLUE)    \
+ (UIColor *)COLOR_NAME{    \
static UIColor* COLOR_NAME##_color;    \
static dispatch_once_t COLOR_NAME##_onceToken;   \
dispatch_once(&COLOR_NAME##_onceToken, ^{    \
COLOR_NAME##_color = [UIColor colorWithRed:RED green:GREEN blue:BLUE alpha:1.0];  \
}); \
return COLOR_NAME##_color;  \
}

AGEColorImplement(ks_primaryColor, 0.21f, 0.36f, 0.46f)
AGEColorImplement(ks_accentColor, 0.96f, 0.67f, 0.32f)

@end
