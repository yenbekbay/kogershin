#import "KSParcel.h"
#import <Parse.h>

@interface KSEvent : PFObject <PFSubclassing>

#pragma mark Properties

@property (weak, nonatomic, readonly) KSParcel *parcel;
@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, copy, readonly) NSString *city;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *zipCode;
@property (nonatomic, copy, readonly) NSString *statusCode;
@property (nonatomic, copy, readonly) NSString *statusDescription;

@end
