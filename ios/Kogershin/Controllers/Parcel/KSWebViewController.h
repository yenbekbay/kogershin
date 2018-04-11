#import "NJKWebViewProgress.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface KSWebViewController : UIViewController <UIWebViewDelegate, NJKWebViewProgressDelegate>

#pragma mark Properties

@property (nonatomic) UIWebView *webView;

#pragma mark Methods

- (instancetype)initWithUrl:(NSURL *)url;

@end
