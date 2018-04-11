//
//  Copyright (c) 2015 Sth4Me.
//

#import <CRGradientNavigationBar.h>
#import <UIKit/UIKit.h>

@class STPopupNavigationBar;

@protocol STPopupNavigationTouchEventDelegate <NSObject>

- (void)popupNavigationBar:(STPopupNavigationBar *)navigationBar touchDidMoveWithOffset:(CGFloat)offset;
- (void)popupNavigationBar:(STPopupNavigationBar *)navigationBar touchDidEndWithOffset:(CGFloat)offset;

@end

@interface STPopupNavigationBar : CRGradientNavigationBar

@property (nonatomic, weak) id<STPopupNavigationTouchEventDelegate> touchEventDelegate;
@property (nonatomic, assign) BOOL draggable; // Default: YES

@end
