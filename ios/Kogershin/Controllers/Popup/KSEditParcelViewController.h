#import "KSPopupParcelViewController.h"
#import "KSUserParcel.h"

@protocol KSEditParcelViewControllerDelegate <NSObject>
@required
- (void)didEditUserParcel:(KSUserParcel *)userParcel;
@end

@interface KSEditParcelViewController : KSPopupParcelViewController

#pragma mark Properties

@property (weak, nonatomic) id<KSEditParcelViewControllerDelegate> delegate;

#pragma mark Methods

- (instancetype)initWithUserParcel:(KSUserParcel *)userParcel;

@end
