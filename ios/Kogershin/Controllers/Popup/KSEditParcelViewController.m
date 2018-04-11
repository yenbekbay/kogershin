#import "KSEditParcelViewController.h"

#import "JTProgressHUD.h"
#import "KSAlertManager.h"
#import "KSDataManager.h"
#import <DGActivityIndicatorView.h>

@interface KSEditParcelViewController ()

@property (weak, nonatomic) KSUserParcel *userParcel;

@end

@implementation KSEditParcelViewController

#pragma mark Initialization

- (instancetype)initWithUserParcel:(KSUserParcel *)userParcel {
    self = [super init];
    if (!self) return nil;
    
    self.userParcel = userParcel;    
    self.title = NSLocalizedString(@"Редактировать посылку", nil);
    
    return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.parcelTrackingId = self.userParcel.parcel.trackingId;
    self.parcelTitle = self.userParcel.title;
}

#pragma mark Public

- (void)onDone {
    if ([self.parcelTrackingId isEqualToString:self.userParcel.parcel.trackingId]) {
        [self.view endEditing:YES];
        if (![self.parcelTitle isEqualToString:self.userParcel.title]) {
            self.userParcel.title = self.parcelTitle;
            [self.userParcel saveEventually];
        }
        [self.popupController dismiss];
        [self.delegate didEditUserParcel:self.userParcel];
    } else {
        [[KSDataManager sharedInstance] getUserParcels:^(NSArray *userParcels, NSError *userParcelsError) {
            if (userParcelsError) {
                [[KSAlertManager sharedInstance] showErrorNotificationWithError:userParcelsError];
                return;
            }
            BOOL alreadyAdded = NO;
            for (KSUserParcel *userParcel in userParcels) {
                if ([userParcel.parcel.trackingId isEqualToString:self.parcelTrackingId]) {
                    alreadyAdded = YES;
                    break;
                }
            }
            if (alreadyAdded) {
                [[KSAlertManager sharedInstance] showErrorNotificationWithText:[NSString stringWithFormat:@"Посылка %@ уже была добавлена", self.parcelTrackingId]];
                [self resetTrackingId];
                return;
            } else {
                [self.view endEditing:YES];
            }
            DGActivityIndicatorView *activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeDoubleBounce];
            [activityIndicatorView startAnimating];
            [JTProgressHUD showWithView:activityIndicatorView];
            [[KSDataManager sharedInstance] getParcelForTrackingId:self.parcelTrackingId completionBlock:^(KSParcel *parcel, NSError *parcelError) {
                if (parcelError) {
                    [JTProgressHUD hide];
                    [[KSAlertManager sharedInstance] showErrorNotificationWithError:parcelError];
                    return;
                }
                [[KSDataManager sharedInstance] addParcel:parcel title:self.parcelTitle completionBlock:^(KSUserParcel *userParcel, NSError *userParcelError) {
                    [JTProgressHUD hide];
                    if (userParcelError) {
                        [[KSAlertManager sharedInstance] showErrorNotificationWithError:userParcelError];
                        return;
                    }
                    [[KSDataManager sharedInstance] removeUserParcel:self.userParcel];
                    [self.popupController dismiss];
                    [self.delegate didEditUserParcel:userParcel];
                }];
            }];
        }];

    }
}

@end
