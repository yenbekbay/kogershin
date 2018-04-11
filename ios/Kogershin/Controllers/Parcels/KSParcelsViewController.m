#import "KSParcelsViewController.h"

#import "Doppelganger.h"
#import "JLNotificationPermission.h"
#import "JTProgressHUD.h"
#import "KSAddParcelViewController.h"
#import "KSArrowIcon.h"
#import "KSDataManager.h"
#import "KSEditParcelViewController.h"
#import "KSParcelCell.h"
#import "KSParcelViewController.h"
#import "KSSettingsViewController.h"
#import "KSUserParcel.h"
#import "STPopup.h"
#import "UIColor+KSTints.h"
#import "UIFont+KSSizes.h"
#import "UIImage+AYHelpers.h"
#import "UILabel+AYHelpers.h"
#import "UIView+AYUtils.h"
#import <Chameleon.h>
#import <DGActivityIndicatorView.h>
#import <LGFilterView.h>
#import <Parse.h>
#import <Reachability.h>
#import <SSSnackbar.h>
#import <UIFont+OpenSans.h>
#import <UIScrollView+EmptyDataSet.h>

CGSize const kTitleViewArrowIconSize = {14, 1};
UIEdgeInsets const kTitleViewPadding = {5, 10, 5, 10};
CGFloat const kTitleViewArrowIconLeftMargin = 10;

typedef enum {
    KSParcelsFilterNone,
    KSParcelsFilterNotDelivered,
    KSParcelsFilterDelivered
} KSParcelsFilter;

@interface KSParcelsViewController () <KSAddParcelViewControllerDelegate, KSEditParcelViewControllerDelegate, KSParcelViewControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic) KSArrowIcon *arrowIcon;
@property (nonatomic) KSParcelsFilter filter;
@property (nonatomic) LGFilterView *filterView;
@property (nonatomic) NSArray *userParcels;
@property (nonatomic) UIButton *errorReloadButton;
@property (nonatomic) UIImageView *errorImageView;
@property (nonatomic) UILabel *errorLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *errorView;
@property (nonatomic) UIView *titleView;
@property (nonatomic, getter=isConnected) BOOL connected;
@property (nonatomic, getter=isLoaded) BOOL loaded;
@property (nonatomic) Reachability *reachability;

@end

@implementation KSParcelsViewController

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.filter = KSParcelsFilterNone;
    self.connected = NO;
    [self setUpTableView];
    [self setUpFilterView];
    [self setUpNavigationBar];
    [self connect];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshWithHUD) name:@"refresh" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Setters 

- (void)setConnected:(BOOL)connected {
    _connected = connected;
    self.tableView.scrollEnabled = connected;
    self.navigationItem.rightBarButtonItem.enabled = connected;
}

#pragma mark Private

- (void)connect {
    [self showHUD];
    
    if (!self.reachability) {
        __weak typeof(self) weakSelf = self;
        self.reachability = [Reachability reachabilityWithHostname:@"parse.com"];
        self.reachability.reachableBlock = ^(Reachability *reachability) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [reachability stopNotifier];
                [weakSelf.errorView removeFromSuperview];
#ifdef SNAPSHOT
                [PFUser logInWithUsernameInBackground:@"test" password:@"test" block:^(PFUser *user, NSError *userError) {
                    weakSelf.connected = YES;
                    [weakSelf refresh];
                }];
#else
                 if ([PFUser currentUser]) {
                     weakSelf.connected = YES;
                     [weakSelf refresh];
                 } else {
                     [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *userError) {
                         if (!userError) {
                             if ([[UIApplication sharedApplication] currentUserNotificationSettings].types == UIUserNotificationTypeNone) {
                                 [[JLNotificationPermission sharedInstance] authorizeWithTitle:@"Разрешите нам посылать вам push-уведомления" message:nil cancelTitle:@"Отказать" grantTitle:@"Разрешить" completion:nil];
                             } else {
                                 PFInstallation *installation = [PFInstallation currentInstallation];
                                 installation[@"user"] = [PFUser currentUser];
                                 [installation saveEventually];
                             }
                             weakSelf.connected = YES;
                             [weakSelf refresh];
                         } else {
                             [weakSelf setUpLoginErrorView];
                         }
                     }];
                 }
#endif
            });
        };
        self.reachability.unreachableBlock = ^(Reachability *reach) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.connected = NO;
                [weakSelf setUpNoConnectionView];
            });
        };
    } else {
        [self.reachability stopNotifier];
    }
    [self.reachability startNotifier];
}

- (void)reload {
    [[KSDataManager sharedInstance] loadUserParcels:^(NSArray *userParcels, NSError *error) {
        if (self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
        if (error) return;
        if (self.view.window) {
            self.loaded = NO;
            
            NSArray *oldUserParcels = self.userParcels;
            self.userParcels = @[];
            NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.userParcels previousArray:oldUserParcels];
            [self.tableView wml_applyBatchChangesForRows:diffs inSection:0 withRowAnimation:UITableViewRowAnimationAutomatic completion:^{
                [self.tableView reloadData];
                [self refresh];
            }];
        } else {
            [self refresh];
        }
    }];
}

- (void)refreshWithHUD {
    if (self.isConnected) {
        [self showHUD];
        [self refresh];
    } else {
        [self connect];
    }
}

- (void)refresh {
    if (!self.isConnected) return;
    
    NSArray *oldUserParcels = self.userParcels;
    [[KSDataManager sharedInstance] getUserParcels:^(NSArray *userParcels, NSError *error) {
        [JTProgressHUD hide];
        self.loaded = YES;
        if (error) {
            [self.tableView reloadData];
            return;
        }
        self.userParcels = [[[userParcels copy] sortedArrayUsingComparator:^(KSUserParcel *i1, KSUserParcel *i2) {
            NSTimeInterval time1 = [i1.createdAt timeIntervalSince1970];
            NSTimeInterval time2 = [i2.createdAt timeIntervalSince1970];
            if (time1 > time2) {
                return NSOrderedAscending;
            } else if (time1 < time2) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(KSUserParcel *userParcel, NSDictionary *bindings) {
            switch (self.filter) {
                case KSParcelsFilterNone:
                    return true;
                case KSParcelsFilterNotDelivered:
                    return ![userParcel.parcel.delivered boolValue];
                case KSParcelsFilterDelivered:
                    return [userParcel.parcel.delivered boolValue];
                default:
                    return true;
            }
        }]];
        if (self.view.window) {
            NSArray *diffs = [WMLArrayDiffUtility diffForCurrentArray:self.userParcels previousArray:oldUserParcels];
            [self.tableView wml_applyBatchChangesForRows:diffs inSection:0 withRowAnimation:UITableViewRowAnimationAutomatic completion:^{
                [self.tableView reloadData];
            }];
        } else {
            [self.tableView reloadData];
        }
    }];
}

- (void)setUpTableView {
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:[KSParcelCell class] forCellReuseIdentifier:NSStringFromClass([KSParcelCell class])];
    self.refreshControl = [UIRefreshControl new];
    self.refreshControl.tintColor = [UIColor ks_primaryColor];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)setUpFilterView {
    self.filterView = [[LGFilterView alloc] initWithTitles:@[NSLocalizedString(@"Все посылки", nil), NSLocalizedString(@"Недоставленные посылки", nil), NSLocalizedString(@"Доставленные посылки", nil)] actionHandler:^(LGFilterView *filterView, NSString *title, NSUInteger index) {
        self.filter = (KSParcelsFilter)index;
        [self updateTitleView];
        [self refresh];
    } cancelHandler:nil];
    __weak typeof(self) weakSelf = self;
    self.filterView.willShowHandler = ^(LGFilterView *filterView) {
        [weakSelf.arrowIcon pointUpAnimated:YES];
        weakSelf.tableView.scrollEnabled = NO;
    };
    self.filterView.willDismissHandler = ^(LGFilterView *filterView) {
        [weakSelf.arrowIcon pointDownAnimated:YES];
    };
    self.filterView.didDismissHandler = ^(LGFilterView *filterView) {
        weakSelf.tableView.scrollEnabled = YES;
    };
    self.filterView.selectedIndex = self.filter;
    self.filterView.transitionStyle = LGFilterViewTransitionStyleTop;
    self.filterView.numberOfLines = 0;
    self.filterView.font = [UIFont openSansFontOfSize:[UIFont buttonFontSize]];
    self.filterView.titleColor = self.filterView.titleColorHighlighted = [UIColor flatBlackColor];
    self.filterView.titleColorSelected = [UIColor whiteColor];
    self.filterView.backgroundColorHighlighted = [[UIColor ks_primaryColor] colorWithAlphaComponent:0.1f];
    self.filterView.backgroundColorSelected = [UIColor ks_accentColor];
}

- (void)setUpNavigationBar {
    UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    [settingsButton setBackgroundImage:[[UIImage imageNamed:@"SettingsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(openSettings)
             forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithCustomView:settingsButton];
    self.navigationItem.leftBarButtonItem = settingsButtonItem;
    
    UIBarButtonItem *addParcelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addParcel)];
    [self.navigationItem setRightBarButtonItem:addParcelButtonItem];
    
    self.titleView = [UIView new];
    self.titleView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openFilterView)];
    [self.titleView addGestureRecognizer:tapGestureRecognizer];
    
    self.titleLabel = [UILabel new];
    [self.titleView addSubview:self.titleLabel];
    
    self.arrowIcon = [[KSArrowIcon alloc] initWithFrame:CGRectMake(0, 0, kTitleViewArrowIconSize.width, kTitleViewArrowIconSize.height)];
    [self.arrowIcon pointDownAnimated:YES];
    [self.titleView addSubview:self.arrowIcon];
    [self updateTitleView];
    
    self.navigationItem.titleView = self.titleView;
}

- (void)setUpNoConnectionView {
    [self setUpErrorViewWithText:NSLocalizedString(@"Приложению требуется подключение к интернету.", nil) image:[UIImage imageNamed:@"Globe"]];
}

- (void)setUpLoginErrorView {
    [self setUpErrorViewWithText:NSLocalizedString(@"Что-то пошло не так. Пожалуйста, попробуйте еще раз.", nil) image:[UIImage imageNamed:@"SadFace"]];
}

- (void)setUpErrorViewWithText:(NSString *)text image:(UIImage *)image {
    if (!self.errorView) {
        self.errorImageView = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.errorImageView.tintColor = [UIColor flatGrayColorDark];
        
        self.errorLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.errorImageView.bottom + 20, self.view.width - 100, 0)];
        self.errorLabel.text = text;
        self.errorLabel.textColor = [UIColor flatGrayColorDark];
        self.errorLabel.font = [UIFont openSansFontOfSize:[UIFont mediumTextFontSize]];
        self.errorLabel.textAlignment = NSTextAlignmentCenter;
        self.errorLabel.numberOfLines = 0;
        
        self.errorReloadButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        self.errorReloadButton.tintColor = [UIColor flatGrayColorDark];
        [self.errorReloadButton setImage:[[UIImage imageNamed:@"ReloadIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.errorReloadButton addTarget:self action:@selector(connect) forControlEvents:UIControlEventTouchUpInside];
        
        self.errorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0)];
        self.errorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.errorView addSubview:self.errorImageView];
        [self.errorView addSubview:self.errorLabel];
        [self.errorView addSubview:self.errorReloadButton];
    } else {
        self.errorLabel.text = text;
    }
    if (!self.errorView.superview) {
        [self.view addSubview:self.errorView];
    }
    [self.errorLabel setFrameToFitWithHeightLimit:0];
    self.errorReloadButton.top = self.errorLabel.bottom + 20;
    for (UIView *view in @[self.errorImageView, self.errorLabel, self.errorReloadButton]) {
        view.centerX = self.errorView.centerX;
    }
    self.errorView.height = self.errorReloadButton.bottom;
    self.errorView.centerY = self.view.height/2;
    
    [JTProgressHUD hide];
}

- (void)showHUD {
    DGActivityIndicatorView *activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeDoubleBounce];
    [activityIndicatorView startAnimating];
    [JTProgressHUD showWithView:activityIndicatorView];
}

- (void)openFilterView {
    if (!self.filterView.isShowing) {
        [self.filterView showInView:self.view animated:YES completionHandler:nil];
    } else {
        [self.filterView dismissAnimated:YES completionHandler:nil];
    }
}

- (void)openSettings {
    KSSettingsViewController *settingsViewController = [KSSettingsViewController new];
    UINavigationController *settingsViewNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    [self presentViewController:settingsViewNavigationController animated:YES completion:nil];
}

- (void)addParcel {
    KSAddParcelViewController *addParcelViewController = [KSAddParcelViewController new];
    addParcelViewController.delegate = self;
    STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:addParcelViewController];
    popupController.cornerRadius = 4;
    popupController.transitionStyle = STPopupTransitionStyleSlideVertical;
    [popupController presentInViewController:self];
}

- (void)updateTitleView {
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:[self titleForFilter:self.filter] attributes:self.navigationController.navigationBar.titleTextAttributes];
    [self.titleLabel sizeToFit];
    self.titleLabel.left = kTitleViewPadding.left;
    self.titleLabel.height += kTitleViewPadding.top + kTitleViewPadding.bottom;
    self.arrowIcon.left = self.titleLabel.right + kTitleViewArrowIconLeftMargin;
    self.arrowIcon.centerY = self.titleLabel.centerY;
    self.titleView.width = self.arrowIcon.right + kTitleViewPadding.right;
    self.titleView.height = self.titleLabel.height;
}

- (NSString *)titleForFilter:(KSParcelsFilter)filter {
    switch (filter) {
        case KSParcelsFilterNone:
            return NSLocalizedString(@"Все", nil);
        case KSParcelsFilterNotDelivered:
            return NSLocalizedString(@"Недоставленные", nil);
        case KSParcelsFilterDelivered:
            return NSLocalizedString(@"Доставленные", nil);
        default:
            return nil;
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.userParcels.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    KSParcelCell *cell = [KSParcelCell new];
    return [cell heightWithUserParcel:self.userParcels[(NSUInteger)indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KSParcelCell *cell = (KSParcelCell *)[self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([KSParcelCell class]) forIndexPath:indexPath];
    cell.separatorInset = UIEdgeInsetsZero;
    cell.preservesSuperviewLayoutMargins = NO;
    cell.layoutMargins = UIEdgeInsetsZero;
    cell.userParcel = (KSUserParcel *)self.userParcels[(NSUInteger)indexPath.row];;
    return cell;
}

#pragma mark UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    KSParcelCell *cell = (KSParcelCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [[UIColor ks_primaryColor] colorWithAlphaComponent:0.1f];
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    KSParcelCell *cell = (KSParcelCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    KSUserParcel *userParcel = (KSUserParcel *)self.userParcels[(NSUInteger)indexPath.row];
    KSParcelViewController *parcelViewController = [[KSParcelViewController alloc] initWithUserParcel:userParcel];
    parcelViewController.delegate = self;
    [self.navigationController pushViewController:parcelViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"Редакт.", nil) handler:^(UITableViewRowAction *action, NSIndexPath *editIndexPath) {
        KSUserParcel *userParcel = (KSUserParcel *)self.userParcels[(NSUInteger)editIndexPath.row];
        KSEditParcelViewController *editParcelViewController = [[KSEditParcelViewController alloc] initWithUserParcel:userParcel];
        editParcelViewController.delegate = self;
        STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:editParcelViewController];
        popupController.cornerRadius = 4;
        popupController.transitionStyle = STPopupTransitionStyleSlideVertical;
        [popupController presentInViewController:self];
    }];
    editAction.backgroundColor = [UIColor ks_accentColor];;
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Удалить", nil)  handler:^(UITableViewRowAction *action, NSIndexPath *deleteIndexPath) {
        [self didDeleteUserParcel:self.userParcels[(NSUInteger)deleteIndexPath.row]];
    }];
    deleteAction.backgroundColor = [UIColor flatRedColor];
    
    return @[deleteAction, editAction];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath { }

#pragma mark KSParcelViewControllerDelegate

- (void)didDeleteUserParcel:(KSUserParcel *)userParcel {
    [[KSDataManager sharedInstance] removeUserParcel:userParcel];
    [self refresh];
    SSSnackbar *snackbar = [[SSSnackbar alloc] initWithMessage:[NSString stringWithFormat:NSLocalizedString(@"Вы удалили %@.", nil), userParcel.title.length > 0 ? userParcel.title : userParcel.parcel.trackingId] actionText:@"Вернуть" duration:3 actionBlock:^(SSSnackbar *sender) {
        [[KSDataManager sharedInstance] addUserParcel:userParcel];
        [self refresh];
    } dismissalBlock:^(SSSnackbar *sender) {
        if (![[KSDataManager sharedInstance] hasUserParcel:userParcel]) {
            [userParcel deleteEventually];
        }
    }];
    [snackbar show];
}

#pragma mark KSEditParcelViewControllerDelegate

- (void)didEditUserParcel:(KSUserParcel *)userParcel {
    [self refresh];
}

#pragma mark DZNEmptyDataSetSource

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *logoImage = [UIImage imageNamed:@"GrayscaleLogo"];
    CGFloat heightRatio = logoImage.size.height / logoImage.size.width;
    return [logoImage scaledToSize:CGSizeMake(200, 200 * heightRatio)];
}

#pragma mark DZNEmptyDataSet

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return self.isLoaded;
}

@end
