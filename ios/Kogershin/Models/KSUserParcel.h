#import "KSParcel.h"
#import <Parse.h>

@interface KSUserParcel : PFObject <PFSubclassing>

#pragma mark Properties

@property (weak, nonatomic) PFUser *user;
@property (weak, nonatomic) KSParcel *parcel;
@property (nonatomic) NSArray *events;
@property (nonatomic, copy) NSString *title;

@end
