//
//  Copyright (c) 2013 Satoshi Asano.
//

#import "NJKWebViewProgress.h"

NSString *completeRPCURL = @"webviewprogressproxy:///complete";

const CGFloat NJKInitialProgressValue = 0.1f;
const CGFloat NJKInteractiveProgressValue = 0.5f;
const CGFloat NJKFinalProgressValue = 0.9f;

@interface NJKWebViewProgress ()

@property (nonatomic) NSUInteger loadingCount;
@property (nonatomic) NSUInteger maxLoadCount;
@property (nonatomic) NSURL *currentURL;
@property (nonatomic) BOOL interactive;

@end

@implementation NJKWebViewProgress

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    self.maxLoadCount = self.loadingCount = 0;
    self.interactive = NO;
    
    return self;
}

#pragma mark Private

- (void)startProgress {
    if (self.progress < NJKInitialProgressValue) {
        self.progress = NJKInitialProgressValue;
    }
}

- (void)incrementProgress {
    CGFloat progress = self.progress;
    CGFloat maxProgress = self.interactive ? NJKFinalProgressValue : NJKInteractiveProgressValue;
    CGFloat remainPercent = (CGFloat)self.loadingCount / (CGFloat)self.maxLoadCount;
    CGFloat increment = (maxProgress - progress) * remainPercent;
    progress += increment;
    progress = (CGFloat)fmin(progress, maxProgress);
    self.progress = progress;
}

- (void)completeProgress {
    self.progress = 1;
}

#pragma mark Setters

- (void)setProgress:(CGFloat)progress {
    // Progress should be incremental only
    if (progress > self.progress || progress == 0) {
        _progress = progress;
        if ([self.progressDelegate respondsToSelector:@selector(webViewProgress:updateProgress:)]) {
            [self.progressDelegate webViewProgress:self updateProgress:progress];
        }
        if (self.progressBlock) {
            self.progressBlock(progress);
        }
    }
}

#pragma mark Public

- (void)reset {
    self.maxLoadCount = self.loadingCount = 0;
    self.interactive = NO;
    self.progress = 0;
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.absoluteString isEqualToString:completeRPCURL]) {
        [self completeProgress];
        return NO;
    }
    
    BOOL ret = YES;
    if ([self.webViewProxyDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        ret = [self.webViewProxyDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    BOOL isFragmentJump = NO;
    if (request.URL.fragment) {
        NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:webView.request.URL.absoluteString];
    }

    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];

    BOOL isHTTP = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"];
    if (ret && !isFragmentJump && isHTTP && isTopLevelNavigation) {
        self.currentURL = request.URL;
        [self reset];
    }
    return ret;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if ([self.webViewProxyDelegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.webViewProxyDelegate webViewDidStartLoad:webView];
    }

    self.loadingCount++;
    self.maxLoadCount = (NSUInteger)fmax(self.maxLoadCount, self.loadingCount);

    [self startProgress];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([self.webViewProxyDelegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.webViewProxyDelegate webViewDidFinishLoad:webView];
    }
    
    self.loadingCount--;
    [self incrementProgress];
    
    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];

    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        self.interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", completeRPCURL];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    
    BOOL isNotRedirect = self.currentURL && [self.currentURL isEqual:webView.request.mainDocumentURL];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {
        [self completeProgress];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if ([self.webViewProxyDelegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.webViewProxyDelegate webView:webView didFailLoadWithError:error];
    }
    
    self.loadingCount--;
    [self incrementProgress];

    NSString *readyState = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];

    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        self.interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", completeRPCURL];
        [webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    
    BOOL isNotRedirect = self.currentURL && [self.currentURL isEqual:webView.request.mainDocumentURL];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {
        [self completeProgress];
    }
}

#pragma mark Method Forwarding

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    if ([self.webViewProxyDelegate respondsToSelector:aSelector]) {
        return YES;
    }
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if (!signature) {
        if ([self.webViewProxyDelegate respondsToSelector:selector]) {
            return [(NSObject *)self.webViewProxyDelegate methodSignatureForSelector:selector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation*)invocation {
    if ([self.webViewProxyDelegate respondsToSelector:[invocation selector]]) {
        [invocation invokeWithTarget:self.webViewProxyDelegate];
    }
}

@end
