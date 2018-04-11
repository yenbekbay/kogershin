#import "KSParcelViewController.h"

#import "JTProgressHUD.h"
#import "KSDataManager.h"
#import "KSEditParcelViewController.h"
#import "KSEvent.h"
#import "KSParcelEventCell.h"
#import "KSWebViewController.h"
#import "UIColor+KSTints.h"
#import "UIFont+KSSizes.h"
#import "UIView+AYUtils.h"
#import <Chameleon.h>
#import <DGActivityIndicatorView.h>
#import <GoogleMaps/GoogleMaps.h>
#import <UIFont+OpenSans.h>

static UIEdgeInsets const kParcelEventsTableHeaderPadding = {10, 10, 10, 10};
static CGFloat const kParcelEventsTableHeaderMapViewHeight = 200;
static CGFloat const kParcelEventsTableHeaderDeliveredLabelHeight = 44;
static NSString * const kKazPostTrackingUrlFormat = @"http://track.kazpost.kz/%@";

@interface KSParcelViewController () <KSEditParcelViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic) KSUserParcel *userParcel;
@property (nonatomic) NSArray *events;
@property (nonatomic) UILabel *trackingIdLabel;
@property (nonatomic) UITextView *trackingIdTextView;
@property (nonatomic) GMSMapView *mapView;
@property (nonatomic) UILabel *deliveredLabel;

@end

@implementation KSParcelViewController

#pragma mark Initialization

- (instancetype)initWithUserParcel:(KSUserParcel *)userParcel {
    self = [super init];
    if (!self) return nil;
    
    self.userParcel = userParcel;
    
    return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setUpTableView];
    [self setUpNavigationBar];
}

#pragma mark Setters

- (void)setUserParcel:(KSUserParcel *)userParcel {
    _userParcel = userParcel;
    self.title = userParcel.title.length > 0 ? userParcel.title : userParcel.parcel.trackingId;
    self.events = userParcel.events;
}

#pragma mark Private

- (void)setUpTableView {
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:[KSParcelEventCell class] forCellReuseIdentifier:NSStringFromClass([KSParcelEventCell class])];
    [self setUpTableHeaderView];
    if (![self.userParcel.parcel.delivered boolValue]) {
        self.refreshControl = [UIRefreshControl new];
        self.refreshControl.tintColor = [UIColor ks_primaryColor];
        [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
        [self.tableView addSubview:self.refreshControl];
    }
}

- (void)setUpTableHeaderView {
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0)];
    tableHeaderView.backgroundColor = [[UIColor ks_primaryColor] colorWithAlphaComponent:0.1f];
    
    self.trackingIdLabel = [[UILabel alloc] initWithFrame:CGRectMake(kParcelEventsTableHeaderPadding.left, kParcelEventsTableHeaderPadding.top, self.view.width - kParcelEventsTableHeaderPadding.left - kParcelEventsTableHeaderPadding.right, 0)];
    self.trackingIdLabel.textColor = [UIColor flatGrayColorDark];
    self.trackingIdLabel.font = [UIFont openSansFontOfSize:[UIFont mediumTextFontSize]];
    self.trackingIdLabel.text = NSLocalizedString(@"Трек-номер:", nil);
    [self.trackingIdLabel sizeToFit];
    [tableHeaderView addSubview:self.trackingIdLabel];
    
    self.trackingIdTextView = [[UITextView alloc] initWithFrame:CGRectMake(kParcelEventsTableHeaderPadding.left, self.trackingIdLabel.bottom, self.view.width - kParcelEventsTableHeaderPadding.left - kParcelEventsTableHeaderPadding.right, 0)];
    self.trackingIdTextView.textColor = [UIColor flatBlackColor];
    self.trackingIdTextView.font = [UIFont openSansSemiBoldFontOfSize:[UIFont mediumTextFontSize]];
    self.trackingIdTextView.editable = NO;
    self.trackingIdTextView.backgroundColor = [UIColor clearColor];
    self.trackingIdTextView.text = self.userParcel.parcel.trackingId;
    self.trackingIdTextView.textContainerInset = UIEdgeInsetsZero;
    self.trackingIdTextView.textContainer.lineFragmentPadding = 0;
    [self.trackingIdTextView sizeToFit];
    [tableHeaderView addSubview:self.trackingIdTextView];
    
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, self.trackingIdTextView.bottom + kParcelEventsTableHeaderPadding.bottom, self.view.width, 1/[UIScreen mainScreen].scale)];
    bottomBorder.backgroundColor = self.tableView.separatorColor;
    [tableHeaderView addSubview:bottomBorder];
    tableHeaderView.height = bottomBorder.bottom;
    
    if ([self.userParcel.parcel.delivered boolValue] && self.userParcel.parcel.postOffice) {
        if (!self.userParcel.parcel.postOffice.isDataAvailable) {
            DGActivityIndicatorView *activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeDoubleBounce];
            [activityIndicatorView startAnimating];
            [JTProgressHUD showWithView:activityIndicatorView];
        }
        [self.userParcel.parcel.postOffice fetchIfNeededInBackgroundWithBlock:^(PFObject *postOfficeObject, NSError *error) {
            [JTProgressHUD hide];
            if (error) {
                self.tableView.tableHeaderView = tableHeaderView;
                return;
            }
            KSPostOffice *postOffice = (KSPostOffice *)postOfficeObject;
            
            GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:postOffice.location.latitude longitude:postOffice.location.longitude zoom:16];
            self.mapView = [GMSMapView mapWithFrame:CGRectMake(0, bottomBorder.bottom, self.view.width, kParcelEventsTableHeaderMapViewHeight) camera:camera];
            GMSMarker *marker = [GMSMarker new];
            marker.position = CLLocationCoordinate2DMake(postOffice.location.latitude, postOffice.location.longitude);
            marker.title = postOffice.name;
            marker.snippet = postOffice.address;
            marker.icon = [UIImage imageNamed:@"PinInBoxIcon"];
            marker.map = self.mapView;
            [tableHeaderView addSubview:self.mapView];
            
            self.deliveredLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.mapView.bottom, self.view.width, kParcelEventsTableHeaderDeliveredLabelHeight)];
            self.deliveredLabel.font = [UIFont openSansFontOfSize:[UIFont mediumTextFontSize]];
            self.deliveredLabel.text = NSLocalizedString(@"Доставлено", nil);
            self.deliveredLabel.backgroundColor = [UIColor flatGreenColorDark];
            self.deliveredLabel.textColor = [UIColor whiteColor];
            self.deliveredLabel.textAlignment = NSTextAlignmentCenter;
            [tableHeaderView addSubview:self.deliveredLabel];
            
            tableHeaderView.height = self.deliveredLabel.bottom;
            self.tableView.tableHeaderView = tableHeaderView;
        }];
    } else {
        self.tableView.tableHeaderView = tableHeaderView;
    }
}

- (void)setUpNavigationBar {
    UIButton *actionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    [actionButton setImage:[[UIImage imageNamed:@"MeatballsMenuIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(openActionMenu)
           forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *actionButtonItem = [[UIBarButtonItem alloc] initWithCustomView:actionButton];
    self.navigationItem.rightBarButtonItem = actionButtonItem;
}

- (void)openActionMenu {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Отмена", nil) destructiveButtonTitle:NSLocalizedString(@"Удалить посылку", nil) otherButtonTitles:NSLocalizedString(@"Редактировать посылку", nil), NSLocalizedString(@"Посмотреть на сайте Казпочты", nil), nil];
    [actionSheet showInView:self.view];
}

- (void)reload {
    [[KSDataManager sharedInstance] getUpdatedUserParcel:self.userParcel.parcel completionBlock:^(KSUserParcel *userParcel, NSError *error) {
        if (self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
        if (!error) {
            [self didEditUserParcel:userParcel];
        }
    }];
}

- (void)deleteUserParcel {
    [self.navigationController popViewControllerAnimated:YES];
    [self.delegate didDeleteUserParcel:self.userParcel];
}

- (void)editUserParcel {
    KSEditParcelViewController *editParcelViewController = [[KSEditParcelViewController alloc] initWithUserParcel:self.userParcel];
    editParcelViewController.delegate = self;
    STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:editParcelViewController];
    popupController.cornerRadius = 4;
    popupController.transitionStyle = STPopupTransitionStyleSlideVertical;
    [popupController presentInViewController:self];
}

- (void)openWebView {
    KSWebViewController *webViewController = [[KSWebViewController alloc] initWithUrl:[NSURL URLWithString:[NSString stringWithFormat:kKazPostTrackingUrlFormat, self.userParcel.parcel.trackingId]]];
    [self.navigationController pushViewController:webViewController animated:YES];
}

#pragma mark KSPopupParcelViewControllerDelegate

- (void)didEditUserParcel:(KSUserParcel *)userParcel {
    self.userParcel = userParcel;
    [self.tableView reloadData];
    [self setUpTableHeaderView];
    [self.delegate refresh];
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.events.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    KSParcelEventCell *cell = [KSParcelEventCell new];
    return [cell heightWithEvent:self.events[(NSUInteger)indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KSParcelEventCell *cell = (KSParcelEventCell *)[self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([KSParcelEventCell class]) forIndexPath:indexPath];
    cell.event = self.events[(NSUInteger)indexPath.row];
    
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        cell.separatorInset = UIEdgeInsetsZero;
    }
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        cell.preservesSuperviewLayoutMargins = NO;
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        cell.layoutMargins = UIEdgeInsetsZero;
    }
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self deleteUserParcel];
            break;
        case 1:
            [self editUserParcel];
            break;
        case 2:
            [self openWebView];
            break;
        default:
            break;
    }
}

@end
