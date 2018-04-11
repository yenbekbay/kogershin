#import "KSParcel.h"
#import "KSUserParcel.h"
#import <Foundation/Foundation.h>

@interface KSDataManager : NSObject

#pragma mark Methods

+ (KSDataManager *)sharedInstance;
- (void)getUserParcels:(void (^)(NSArray *userParcels, NSError *error))completionBlock;
- (void)loadUserParcels:(void (^)(NSArray *userParcels, NSError *error))completionBlock;
- (void)getUpdatedUserParcel:(KSParcel *)parcel completionBlock:(void (^)(KSUserParcel *userParcel, NSError *error))completionBlock;
- (void)getParcelForTrackingId:(NSString *)trackingId completionBlock:(void (^)(KSParcel *parcel, NSError *error))completionBlock;
- (void)getParcelEventsForTrackingId:(NSString *)trackingId completionBlock:(void (^)(NSArray *events, NSError *error))completionBlock;
- (void)addParcel:(KSParcel *)parcel title:(NSString *)title completionBlock:(void (^)(KSUserParcel *userParcel, NSError *error))completionBlock;
- (void)removeUserParcel:(KSUserParcel *)userParcel;
- (void)addUserParcel:(KSUserParcel *)userParcel;
- (BOOL)hasUserParcel:(KSUserParcel *)userParcel;

@end
