#import <UIKit/UIKit.h>

@interface KSArrowIcon : UIView

#pragma mark Properties

@property (nonatomic) UIColor *color;

#pragma mark Methods

- (void)pointDownAnimated:(BOOL)animated;
- (void)pointUpAnimated:(BOOL)animated;

@end
