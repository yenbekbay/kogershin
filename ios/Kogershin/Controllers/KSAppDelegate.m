#import "KSAppDelegate.h"

#import "JLNotificationPermission.h"
#import "KSAlertManager.h"
#import "KSParcelsViewController.h"
#import "Secrets.h"
#import "UIColor+AYHelpers.h"
#import "UIColor+KSTints.h"
#import <Crashlytics/Crashlytics.h>
#import <CRGradientNavigationBar.h>
#import <Fabric/Fabric.h>
#import <GoogleMaps/GoogleMaps.h>
#import <Parse.h>
#import <UIFont+OpenSans.h>

@interface KSAppDelegate ()

@property (nonatomic) BOOL didEnterBackground;

@end

@implementation KSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Fabric with:@[[Crashlytics class]]];
    [Parse setApplicationId:kParseApplicationId
                  clientKey:kParseClientKey];
    [GMSServices provideAPIKey:kGoogleMapsApiKey];
    if ([application currentUserNotificationSettings].types != UIUserNotificationTypeNone) {
        [[JLNotificationPermission sharedInstance] authorize:nil];
    }
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.navigationController = [[KSNavigationController alloc] initWithNavigationBarClass:[CRGradientNavigationBar class] toolbarClass:nil];
    self.navigationController.viewControllers = @[[KSParcelsViewController new]];
    self.window.rootViewController = self.navigationController;
    
    [self setUpNavigationBar];
    [application setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    PFInstallation *installation = [PFInstallation currentInstallation];
    [installation setDeviceTokenFromData:deviceToken];
    if ([PFUser currentUser]) {
        installation[@"user"] = [PFUser currentUser];
    }
    installation.channels = @[@"global"];
    [installation saveInBackground];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"%@", err);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (self.didEnterBackground) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:nil];
        self.didEnterBackground = NO;
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    self.didEnterBackground = YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    self.didEnterBackground = NO;
    [[KSAlertManager sharedInstance] showNotificationWithText:userInfo[@"aps"][@"alert"] color:[UIColor ks_accentColor]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:nil];
}

#pragma mark Private

- (void)setUpNavigationBar {
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont openSansFontOfSize:17],
                                  NSForegroundColorAttributeName: [UIColor whiteColor] };
    [[CRGradientNavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[CRGradientNavigationBar appearance] setBarTintGradientColors:@[[[UIColor ks_primaryColor] lighterColor:0.3f], [UIColor ks_primaryColor]]];
    [[CRGradientNavigationBar appearance] setTranslucent:NO];
    [[CRGradientNavigationBar appearance] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [[CRGradientNavigationBar appearance] setShadowImage:[UIImage new]];
    [[CRGradientNavigationBar appearance] setTitleTextAttributes:attributes];
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
}

@end
