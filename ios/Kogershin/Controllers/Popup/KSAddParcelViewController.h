#import "KSPopupParcelViewController.h"

@protocol KSAddParcelViewControllerDelegate <NSObject>
- (void)refresh;
@end

@interface KSAddParcelViewController : KSPopupParcelViewController

@property (weak, nonatomic) id<KSAddParcelViewControllerDelegate> delegate;

@end
