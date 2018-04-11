#import "KSEvent.h"
#import <UIKit/UIKit.h>

@interface KSParcelEventCell : UITableViewCell

#pragma mark Properties

@property (weak, nonatomic) KSEvent *event;

#pragma mark Methods

- (CGFloat)heightWithEvent:(KSEvent *)event;

@end
