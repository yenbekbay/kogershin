#import "KSParcel.h"

@implementation KSParcel

@dynamic trackingId;
@dynamic delivered;
@dynamic lastCheckedAt;
@dynamic postOffice;

#pragma mark PFSubclassing

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"Parcel";
}

@end
