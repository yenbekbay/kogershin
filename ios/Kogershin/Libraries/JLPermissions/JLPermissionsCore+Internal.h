//
//  Copyright (c) 2014 Joe Laws.
//

#define IS_IOS_8 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 ? 1 : 0)

@interface JLPermissionsCore (Internal)

- (NSString *)appName;
- (NSString *)defaultTitle:(NSString *)authorizationType;
- (NSString *)defaultMessage;
- (NSString *)defaultCancelTitle;
- (NSString *)defaultGrantTitle;
- (NSError *)userDeniedError;
- (NSError *)previouslyDeniedError;
- (NSError *)systemDeniedError:(NSError *)error;

#pragma mark - Abstract Methods

- (void)actuallyAuthorize;
- (void)canceledAuthorization:(NSError *)error;

@end
