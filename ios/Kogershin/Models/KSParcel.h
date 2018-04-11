#import "KSPostOffice.h"
#import <Parse.h>

@interface KSParcel : PFObject <PFSubclassing>

#pragma mark Properties

@property (nonatomic, copy, readonly) NSString *trackingId;
@property (nonatomic, readonly) NSNumber *delivered;
@property (nonatomic, readonly) NSDate *lastCheckedAt;
@property (weak, nonatomic) KSPostOffice *postOffice;

@end
