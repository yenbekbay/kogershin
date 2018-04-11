#import "KSPostOffice.h"

@implementation KSPostOffice

@dynamic city;
@dynamic address;
@dynamic name;
@dynamic zipCode;
@dynamic location;
@dynamic phoneNumber;

#pragma mark PFSubclassing

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"PostOffice";
}

@end
