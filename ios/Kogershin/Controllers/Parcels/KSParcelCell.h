#import "KSUserParcel.h"
#import <UIKit/UIKit.h>

@interface KSParcelCell : UITableViewCell

#pragma mark Properties

@property (weak, nonatomic) KSUserParcel *userParcel;

#pragma mark Methods

- (CGFloat)heightWithUserParcel:(KSUserParcel *)userParcel;

@end
