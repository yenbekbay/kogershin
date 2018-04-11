//
//  Copyright (c) 2013 Satoshi Asano.
//

#import <UIKit/UIKit.h>

#undef njk_weak
#if __has_feature(objc_arc_weak)
#define njk_weak weak
#else
#define njk_weak unsafe_unretained
#endif

@class NJKWebViewProgress;

extern const CGFloat NJKInitialProgressValue;
extern const CGFloat NJKInteractiveProgressValue;
extern const CGFloat NJKFinalProgressValue;

typedef void (^NJKWebViewProgressBlock)(CGFloat progress);

@protocol NJKWebViewProgressDelegate <NSObject>
- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(CGFloat)progress;
@end

@interface NJKWebViewProgress : NSObject<UIWebViewDelegate>

#pragma mark Properties

@property (nonatomic, njk_weak) id<NJKWebViewProgressDelegate>progressDelegate;
@property (nonatomic, njk_weak) id<UIWebViewDelegate>webViewProxyDelegate;
@property (nonatomic, copy) NJKWebViewProgressBlock progressBlock;
@property (nonatomic, readonly) CGFloat progress; // 0.0..1.0

#pragma mark Methods

- (void)reset;

@end

