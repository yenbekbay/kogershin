#import "KSEvent.h"

@implementation KSEvent

@dynamic parcel;
@dynamic date;
@dynamic city;
@dynamic name;
@dynamic zipCode;
@dynamic statusCode;
@dynamic statusDescription;

#pragma mark PFSubclassing

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"Event";
}

@end
