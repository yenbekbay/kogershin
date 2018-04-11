#import <Parse.h>

@interface KSPostOffice : PFObject <PFSubclassing>

#pragma mark Properties

@property (nonatomic, copy, readonly) NSString *city;
@property (nonatomic, copy, readonly) NSString *address;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *zipCode;
@property (nonatomic, readonly) PFGeoPoint *location;
@property (nonatomic, copy, readonly) NSString *phoneNumber;

@end
