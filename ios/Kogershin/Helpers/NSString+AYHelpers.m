#import "NSString+AYHelpers.h"

@implementation NSString (AYHelpers)

- (CGSize)sizeWithFont:(UIFont *)font {
    return [self boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{ NSFontAttributeName:font }
                                   context:nil].size;
}

- (CGSize)sizeWithFont:(UIFont *)font width:(CGFloat)width {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    return ([self boundingRectWithSize:CGSizeMake(width, 0)
                                    options:NSStringDrawingUsesLineFragmentOrigin
                                 attributes:@{NSParagraphStyleAttributeName:paragraphStyle.copy,
                                              NSFontAttributeName:font}
                                    context:nil]).size;
}

@end
