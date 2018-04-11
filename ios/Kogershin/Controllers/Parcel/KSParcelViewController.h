#import "KSUserParcel.h"
#import <UIKit/UIKit.h>

@protocol KSParcelViewControllerDelegate <NSObject>
@required
- (void)didDeleteUserParcel:(KSUserParcel *)userParcel;
- (void)refresh;
@end

@interface KSParcelViewController : UITableViewController

#pragma mark Properties

@property (weak, nonatomic) id<KSParcelViewControllerDelegate> delegate;

#pragma mark Methods

- (instancetype)initWithUserParcel:(KSUserParcel *)userParcel;

@end
