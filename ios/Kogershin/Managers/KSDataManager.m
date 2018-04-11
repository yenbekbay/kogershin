#import "KSDataManager.h"

#import "KSEvent.h"
#import <Parse.h>

@interface KSDataManager ()

@property (nonatomic) NSMutableArray *userParcels;

@end

@implementation KSDataManager

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    return self;
}

+ (KSDataManager *)sharedInstance {
    static KSDataManager *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [KSDataManager new];
    });
    return sharedInstance;
}

#pragma mark Public

- (void)getUserParcels:(void (^)(NSArray *userParcels, NSError *error))completionBlock {
    if (!completionBlock) return;
    if (self.userParcels) {
        completionBlock(self.userParcels, nil);
        return;
    }
    [self loadUserParcels:completionBlock];
}

- (void)loadUserParcels:(void (^)(NSArray *userParcels, NSError *error))completionBlock {
    PFQuery *userParcelQuery = [KSUserParcel query];
    [userParcelQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [userParcelQuery includeKey:@"parcel"];
    [userParcelQuery includeKey:@"events"];
    [userParcelQuery findObjectsInBackgroundWithBlock:^(NSArray *userParcels, NSError *error) {
        if (!error) {
            self.userParcels = [userParcels mutableCopy];
        }
        completionBlock(userParcels, error);
    }];
}

- (void)getUpdatedUserParcel:(KSParcel *)parcel completionBlock:(void (^)(KSUserParcel *userParcel, NSError *error))completionBlock {
    if (!completionBlock) return;
    PFQuery *userParcelQuery = [KSUserParcel query];
    [userParcelQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [userParcelQuery whereKey:@"parcel" equalTo:parcel];
    [userParcelQuery includeKey:@"parcel"];
    [userParcelQuery includeKey:@"events"];
    [userParcelQuery getFirstObjectInBackgroundWithBlock:^(PFObject *userParcelObject, NSError *error) {
        completionBlock((KSUserParcel *)userParcelObject, error);
    }];
}

- (void)getParcelForTrackingId:(NSString *)trackingId completionBlock:(void (^)(KSParcel *parcel, NSError *error))completionBlock {
    if (!completionBlock) return;
    [PFCloud callFunctionInBackground:@"getParcel" withParameters:@{ @"trackingId": trackingId } block:completionBlock];
}

- (void)getParcelEventsForTrackingId:(NSString *)trackingId completionBlock:(void (^)(NSArray *events, NSError *error))completionBlock {
    if (!completionBlock) return;
    [PFCloud callFunctionInBackground:@"getEventsForParcel" withParameters:@{ @"trackingId": trackingId, @"onlyNew": @0 } block:completionBlock];
}

- (void)addParcel:(KSParcel *)parcel title:(NSString *)title completionBlock:(void (^)(KSUserParcel *userParcel, NSError *error))completionBlock {
    if (!completionBlock) return;
    [self getUserParcels:^(NSArray *userParcels, NSError *userParcelsError) {
        if (userParcelsError) {
            completionBlock(nil, userParcelsError);
            return;
        }
        [self getParcelEventsForTrackingId:parcel.trackingId completionBlock:^(NSArray *events, NSError *eventsError) {
            if (eventsError) {
                completionBlock(nil, eventsError);
                return;
            }
            [parcel fetchIfNeededInBackgroundWithBlock:^(PFObject *updatedParcelObject, NSError *parcelError) {
                if (parcelError) {
                    completionBlock(nil, parcelError);
                    return;
                }
                KSUserParcel *userParcel = [KSUserParcel object];
                userParcel.user = [PFUser currentUser];
                userParcel.parcel = (KSParcel *)updatedParcelObject;
                userParcel.events = [[events reverseObjectEnumerator] allObjects];
                userParcel.title = title;
                [userParcel saveEventually];
                [self.userParcels addObject:userParcel];
                completionBlock(userParcel, nil);
            }];
        }];
    }];
}

- (void)removeUserParcel:(KSUserParcel *)userParcel {
    for (KSUserParcel *i in self.userParcels) {
        if ([i.parcel.trackingId isEqualToString:userParcel.parcel.trackingId]) {
            [self.userParcels removeObject:i];
            break;
        }
    }
}

- (void)addUserParcel:(KSUserParcel *)userParcel {
    if (![self hasUserParcel:userParcel]) {
        [self.userParcels addObject:userParcel];
    }
}

- (BOOL)hasUserParcel:(KSUserParcel *)userParcel {
    for (KSUserParcel *i in self.userParcels) {
        if ([i.parcel.trackingId isEqualToString:userParcel.parcel.trackingId]) {
            return YES;
        }
    }
    return NO;
}

@end
