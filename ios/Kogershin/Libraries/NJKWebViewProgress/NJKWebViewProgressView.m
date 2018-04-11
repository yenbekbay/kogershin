//
//  Copyright (c) 2013 Satoshi Asano.
//

#import "NJKWebViewProgressView.h"

#import "UIView+AYUtils.h"

@implementation NJKWebViewProgressView

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    self.userInteractionEnabled = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.barAnimationDuration = 0.27f;
    self.fadeAnimationDuration = 0.27f;
    self.fadeOutDelay = 0.1f;
    self.progressBarView = [[UIView alloc] initWithFrame:self.bounds];
    self.progressBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.progressBarView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.progressBarView];

    return self;
}

#pragma mark Setters

- (void)setProgress:(CGFloat)progress {
    [self setProgress:progress animated:NO];
}

#pragma mark Public

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    BOOL isGrowing = progress > 0.0;
    [UIView animateWithDuration:(isGrowing && animated) ? _barAnimationDuration : 0 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.progressBarView.width = progress * self.width;
    } completion:nil];

    if (progress >= 1) {
        [UIView animateWithDuration:animated ? _fadeAnimationDuration : 0 delay:_fadeOutDelay options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.progressBarView.alpha = 0;
        } completion:^(BOOL completed){
            self.progressBarView.width = 0;
        }];
    } else {
        [UIView animateWithDuration:animated ? _fadeAnimationDuration : 0 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.progressBarView.alpha = 1;
        } completion:nil];
    }
}

@end
