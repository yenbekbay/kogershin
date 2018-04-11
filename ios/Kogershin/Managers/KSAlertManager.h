#import <Foundation/Foundation.h>

@interface KSAlertManager : NSObject

+ (instancetype)sharedInstance;
- (void)showErrorNotificationWithError:(NSError *)error;
- (void)showErrorNotificationWithText:(NSString *)text;
- (void)showNotificationWithText:(NSString *)text color:(UIColor *)color;
- (void)showNotificationWithText:(NSString *)text color:(UIColor *)color statusBar:(BOOL)statusBar;

@end
