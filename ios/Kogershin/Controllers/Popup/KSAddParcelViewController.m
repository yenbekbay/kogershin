#import "KSAddParcelViewController.h"

#import "JTProgressHUD.h"
#import "KSAlertManager.h"
#import "KSDataManager.h"
#import "KSUserParcel.h"
#import <DGActivityIndicatorView.h>

@implementation KSAddParcelViewController

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    self.title = NSLocalizedString(@"Добавить посылку", nil);
    
    return self;
}

#pragma mark Public

- (void)onDone {
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
                [self.popupController dismiss];
                [self.delegate refresh];
            }];
        }];
    }];
}

@end
