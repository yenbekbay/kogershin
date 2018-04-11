#import "KSAlertManager.h"

#import "UIFont+KSSizes.h"
#import <Chameleon.h>
#import <CRToast.h>
#import <Parse.h>
#import <UIFont+OpenSans.h>

@implementation KSAlertManager

#pragma mark Initialization

+ (instancetype)sharedInstance {
    static KSAlertManager *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [KSAlertManager new];
    });
    return _sharedInstance;
}

#pragma mark Public

- (void)showErrorNotificationWithError:(NSError *)error {
    [self showNotificationWithText:[self stringForError:error] color:[UIColor flatRedColor]];
}

- (void)showErrorNotificationWithText:(NSString *)text {
    [self showNotificationWithText:text color:[UIColor flatRedColor]];
}

- (void)showNotificationWithText:(NSString *)text color:(UIColor *)color {
    [self showNotificationWithText:text color:color statusBar:NO];
}

- (void)showNotificationWithText:(NSString *)text color:(UIColor *)color statusBar:(BOOL)statusBar {
    NSDictionary *options = @{ kCRToastNotificationTypeKey : statusBar ? @(CRToastTypeStatusBar) : @(CRToastTypeNavigationBar),
                               kCRToastTextKey : text,
                               kCRToastFontKey : [UIFont openSansFontOfSize:[UIFont mediumTextFontSize]],
                               kCRToastBackgroundColorKey : color,
                               kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
                               kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
                               kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                               kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionBottom) };
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

#pragma mark Private

- (NSString *)stringForError:(NSError *)error {
    NSString *errorString;
    switch (error.code) {
        case kPFScriptError:
            errorString = error.localizedDescription;
            break;
        default:
            errorString = NSLocalizedString(@"Что-то пошло не так. Попробуйте чуть позже", nil);
            break;
    }
    return errorString;
}

@end
