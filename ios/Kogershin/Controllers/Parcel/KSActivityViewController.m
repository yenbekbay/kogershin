#import "KSActivityViewController.h"

@implementation KSActivityViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    [(UINavigationController *)viewControllerToPresent navigationBar].barStyle = UIBarStyleBlack;
    [(UINavigationController *)viewControllerToPresent navigationBar].tintColor = [UIColor whiteColor];
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

@end
