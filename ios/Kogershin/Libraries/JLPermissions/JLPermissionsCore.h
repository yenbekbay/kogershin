//
//  Copyright (c) 2014 Joe Laws.
//

@import Foundation;
@import UIKit;

typedef NS_ENUM(NSInteger, JLAuthorizationErrorCode) {
    JLPermissionUserDenied = 42,
    JLPermissionSystemDenied
};

typedef NS_ENUM(NSInteger, JLAuthorizationStatus) {
    JLPermissionNotDetermined = 0,
    JLPermissionDenied,
    JLPermissionAuthorized
};

typedef NS_ENUM(NSInteger, JLPermissionType) {
    JLPermissionCalendar = 0,
    JLPermissionCamera,
    JLPermissionContacts,
    JLPermissionFacebook,
    JLPermissionHealth,
    JLPermissionLocation,
    JLPermissionMicrophone,
    JLPermissionNotification,
    JLPermissionPhotos,
    JLPermissionReminders,
    JLPermissionTwitter,
};

typedef void (^AuthorizationHandler)(bool granted, NSError *error);
typedef void (^NotificationAuthorizationHandler)(NSString *deviceID, NSError *error);

@interface JLPermissionsCore : NSObject<UIAlertViewDelegate>

/**
 * @return whether or not user has granted access to the calendar
 */
- (JLAuthorizationStatus)authorizationStatus;

/**
 * Displays a dialog telling the user how to re-enable the permission in
 * the Settings application
 */
- (void)displayReenableAlert;

/**
 * A view controller telling the user how to re-enable the permission in
 * the Settings application or nil if one doesnt exist.
 */
- (UIViewController *)reenableViewController;

/**
 * The type of permission.
 */
- (JLPermissionType)permissionType;

/**
 * Opens the application system settings dialog if running on iOS 8.
 */
- (void)displayAppSystemSettings;

@end
