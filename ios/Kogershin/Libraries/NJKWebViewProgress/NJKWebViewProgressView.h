//
//  Copyright (c) 2013 Satoshi Asano.
//

#import <UIKit/UIKit.h>

@interface NJKWebViewProgressView : UIView

#pragma mark Properties

@property (nonatomic) CGFloat progress;
@property (nonatomic) UIView *progressBarView;
@property (nonatomic) NSTimeInterval barAnimationDuration; // default 0.1
@property (nonatomic) NSTimeInterval fadeAnimationDuration; // default 0.27
@property (nonatomic) NSTimeInterval fadeOutDelay; // default 0.1

#pragma mark Methods

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;

@end
