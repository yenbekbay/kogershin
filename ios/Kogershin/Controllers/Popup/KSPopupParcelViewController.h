#import "STPopup.h"
#import <UIKit/UIKit.h>

@interface KSPopupParcelViewController : UIViewController

#pragma mark Properties

@property (nonatomic, copy) NSString *parcelTrackingId;
@property (nonatomic, copy) NSString *parcelTitle;

#pragma mark Methods

- (void)onDone;
- (void)resetTrackingId;

@end
