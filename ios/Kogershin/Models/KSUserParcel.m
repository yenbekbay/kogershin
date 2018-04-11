#import "KSUserParcel.h"

@implementation KSUserParcel

@dynamic user;
@dynamic parcel;
@dynamic events;
@dynamic title;

#pragma mark PFSubclassing

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"UserParcel";
}

@end
