//
//  Copyright (c) 2014 Joe Laws.
//

#import "JLPermissionsCore.h"

@interface JLLocationPermission : JLPermissionsCore

+ (instancetype)sharedInstance;

/**
 *  Uses the default dialog which is identical to the system permission dialog
 *
 *  @param completion the block that will be executed on the main thread
 *when access is granted or denied.  May be called immediately if access was
 *previously established
 */
- (void)authorize:(AuthorizationHandler)completion;

/**
 *  This is identical to the call other call, however it allows you to specify
 *your own custom text for the dialog window rather than using the standard
 *system dialog
 *
 *  @param messageTitle      custom alert message title
 *  @param message           custom alert message
 *  @param cancelTitle       custom cancel button message
 *  @param grantTitle        custom grant button message
 *  @param completion the block that will be executed on the main thread
 *when access is granted or denied.  May be called immediately if access was
 *previously established
 */
- (void)authorizeWithTitle:(NSString *)messageTitle
                   message:(NSString *)message
               cancelTitle:(NSString *)cancelTitle
                grantTitle:(NSString *)grantTitle
                completion:(AuthorizationHandler)completion;

@end
