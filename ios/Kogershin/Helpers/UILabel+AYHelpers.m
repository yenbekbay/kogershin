#import "UILabel+AYHelpers.h"

@implementation UILabel (AYHelpers)

- (void)setFrameToFitWithHeightLimit:(CGFloat)heightLimit {
    [self setFrame:[self frameToFitWithHeightLimit:heightLimit]];
}

- (CGRect)frameToFitWithHeightLimit:(CGFloat)heightLimit {
    CGSize expectedSize = [self sizeToFitWithHeightLimit:heightLimit];
    return CGRectMake(self.frame.origin.x, self.frame.origin.y,
                      self.frame.size.width, expectedSize.height);
}

- (CGSize)sizeToFitWithHeightLimit:(CGFloat)heightLimit {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    return ([self.text boundingRectWithSize:CGSizeMake(self.frame.size.width, heightLimit)
                                    options:NSStringDrawingUsesLineFragmentOrigin
                                 attributes:@{NSParagraphStyleAttributeName:paragraphStyle.copy,
                                              NSFontAttributeName:self.font}
                                    context:nil]).size;
}

- (CGSize)sizeToFitWithOneLine {
    return [self.text boundingRectWithSize:CGSizeZero
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{NSFontAttributeName:self.font}
                                   context:nil].size;
}

@end
