#import "KSSettingsViewController.h"

#import "AYAppStore.h"
#import "AYFeedback.h"
#import "KSAlertManager.h"
#import "KSIconButton.h"
#import "STPopupLeftBarItem.h"
#import "UIColor+KSTints.h"
#import "UIFont+KSSizes.h"
#import "UILabel+AYHelpers.h"
#import "UIView+AYUtils.h"
#import <Chameleon.h>
#import <MessageUI/MessageUI.h>
#import <UIFont+OpenSans.h>

static UIEdgeInsets const kSettingsPadding = {30, 30, 30, 30};
static CGFloat const kSettingsButtonsSpacing = 30;
static NSString * const kAppId = @"1043220890";

@interface KSSettingsViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic) KSIconButton *shareButton;
@property (nonatomic) KSIconButton *rateButton;
@property (nonatomic) KSIconButton *mailButton;
@property (nonatomic) MFMailComposeViewController *mailComposeViewController;
@property (nonatomic) UILabel *creditLabel;

@end

@implementation KSSettingsViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setUpNavigationBar];
    [self setUpCreditLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    [self setUpButtons];
}

#pragma mark Private

- (void)setUpButtons {
    self.shareButton = [[KSIconButton alloc] initWithFrame:CGRectMake(kSettingsPadding.left, self.navigationController.navigationBar.bottom + kSettingsPadding.top, self.view.width - kSettingsPadding.left - kSettingsPadding.right, 0) image:[UIImage imageNamed:@"ShareIcon"] buttonTitle:NSLocalizedString(@"Поделиться с друзьями", nil)];
    [self.shareButton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.shareButton];
    
    self.rateButton = [[KSIconButton alloc] initWithFrame:CGRectMake(kSettingsPadding.left, self.shareButton.bottom + kSettingsButtonsSpacing, self.view.width - kSettingsPadding.left - kSettingsPadding.right, 0) image:[UIImage imageNamed:@"StarIcon"] buttonTitle:NSLocalizedString(@"Оставить рецензию в App Store", nil)];
    [self.rateButton addTarget:self action:@selector(rate) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.rateButton];
    
    self.mailButton = [[KSIconButton alloc] initWithFrame:CGRectMake(kSettingsPadding.left, self.rateButton.bottom + kSettingsButtonsSpacing, self.view.width - kSettingsPadding.left - kSettingsPadding.right, 0) image:[UIImage imageNamed:@"MailIcon"] buttonTitle:NSLocalizedString(@"Написать нам", nil)];
    [self.mailButton addTarget:self action:@selector(sendFeedback) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.mailButton];
}

- (void)setUpCreditLabel {
    self.creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(kSettingsPadding.left, 0, self.view.width - kSettingsPadding.left - kSettingsPadding.right, 0)];
    self.creditLabel.textColor = [UIColor flatGrayColorDark];
    self.creditLabel.font = [UIFont openSansLightFontOfSize:[UIFont smallTextFontSize]];
    self.creditLabel.numberOfLines = 0;
    self.creditLabel.textAlignment = NSTextAlignmentCenter;
    self.creditLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Kogershin %@\r© Аян Енбекбай", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    [self.creditLabel setFrameToFitWithHeightLimit:0];
    self.creditLabel.bottom = self.view.bottom - kSettingsPadding.bottom;
    [self.view addSubview:self.creditLabel];
}

- (void)setUpNavigationBar {
    STPopupLeftBarItem *dismissBarButtonItem = [[STPopupLeftBarItem alloc] initWithTarget:self action:@selector(dismiss)];
    dismissBarButtonItem.tintColor = [UIColor ks_primaryColor];
    dismissBarButtonItem.type = STPopupLeftBarItemCross;
    self.navigationItem.leftBarButtonItem = dismissBarButtonItem;
}

- (void)dismiss {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)share {
    NSString *itunesLink = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", kAppId];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"Взгляни на Kogershin, лучшее приложение для трекинга посылок Казпочты: %@", itunesLink]] applicationActivities:nil];
    activityViewController.view.tintColor = [UIColor ks_primaryColor];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)rate {
    [AYAppStore openAppStoreReviewForApp:kAppId];
}

- (void)sendFeedback {
    if ([MFMailComposeViewController canSendMail]) {
        AYFeedback *feedback = [AYFeedback new];
        self.mailComposeViewController = [MFMailComposeViewController new];
        self.mailComposeViewController.mailComposeDelegate = self;
        self.mailComposeViewController.toRecipients = @[@"ayan.yenb@gmail.com"];
        self.mailComposeViewController.subject = feedback.subject;
        [self.mailComposeViewController setMessageBody:feedback.messageWithMetaData isHTML:NO];
        [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Настройте ваш почтовый сервис", nil) message:NSLocalizedString(@"Чтобы отправить нам письмо, вам необходим настроенный почтовый аккаунт.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"ОК", nil) otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:^{
        if (result == MFMailComposeResultSent) {
            [[KSAlertManager sharedInstance] showNotificationWithText:NSLocalizedString(@"Спасибо! Ваш отзыв был получен, и мы скоро с вами свяжемся.", nil) color:[UIColor flatGreenColor]];
        }
    }];
}

@end
