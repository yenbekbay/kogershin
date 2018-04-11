#import "KSParcelCell.h"

#import "KSEvent.h"
#import "UIColor+KSTints.h"
#import "UIFont+KSSizes.h"
#import "UILabel+AYHelpers.h"
#import "UIView+AYUtils.h"
#import <Chameleon.h>
#import <UIFont+OpenSans.h>

static UIEdgeInsets const kParcelCellPadding = {10, 10, 10, 10};
static CGFloat const kParcelCellLabelMargin = 5;
static CGFloat const kParcelCellIconMargin = 15;
static CGSize const kParcelCellIconSize = {30, 30};

@interface KSParcelCell ()

@property (nonatomic) UIImageView *iconImageView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *statusLabel;

@end

@implementation KSParcelCell

#pragma mark Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setUpViews];
    
    return self;
}

#pragma mark Lifecycle

- (void)prepareForReuse {
    self.titleLabel.text = @"";
    self.statusLabel.text = @"";
    self.iconImageView.image = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (UILabel *label in @[self.titleLabel, self.statusLabel]) {
        [label setFrameToFitWithHeightLimit:0];
    }
    self.statusLabel.top = self.titleLabel.bottom + kParcelCellLabelMargin;
    self.iconImageView.centerY = (self.statusLabel.bottom + kParcelCellPadding.bottom)/2;
}

#pragma mark Public

- (CGFloat)heightWithUserParcel:(KSUserParcel *)userParcel {
    [self setUpViews];
    self.userParcel = userParcel;
    return self.statusLabel.bottom + kParcelCellPadding.bottom;
}

#pragma mark Private

- (void)setUpViews {
    self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kParcelCellPadding.left, 0, kParcelCellIconSize.width, kParcelCellIconSize.height)];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.iconImageView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.iconImageView.right + kParcelCellIconMargin, kParcelCellPadding.top, CGRectGetWidth([UIScreen mainScreen].bounds) - self.iconImageView.right - kParcelCellIconMargin - kParcelCellPadding.right, 0)];
    self.titleLabel.textColor = [UIColor flatBlackColor];
    self.titleLabel.font = [UIFont openSansSemiBoldFontOfSize:[UIFont mediumTextFontSize]];
    self.titleLabel.numberOfLines = 0;
    [self.contentView addSubview:self.titleLabel];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:self.titleLabel.frame];
    self.statusLabel.top = self.titleLabel.bottom;
    self.statusLabel.textColor = [UIColor flatGrayColorDark];
    self.statusLabel.font = [UIFont openSansFontOfSize:[UIFont mediumTextFontSize]];
    self.statusLabel.numberOfLines = 0;
    [self.contentView addSubview:self.statusLabel];
}

#pragma mark Setters and getters

- (void)setUserParcel:(KSUserParcel *)userParcel {
    _userParcel = userParcel;
    
    KSEvent *event = userParcel.events[0];
    self.titleLabel.text = userParcel.title.length > 0 ? userParcel.title : userParcel.parcel.trackingId;
    self.statusLabel.text = event.statusDescription;
    [self setIconWithStatusDescription:event.statusDescription];
    [self layoutSubviews];
}

- (void)setIconWithStatusDescription:(NSString *)statusDescription {
    if ([statusDescription isEqualToString:@"Вручено"] || [self.userParcel.parcel.delivered boolValue]) {
        self.iconImageView.image = [[UIImage imageNamed:@"CheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.iconImageView.tintColor = [UIColor flatGreenColor];
    } else if ([statusDescription isEqualToString:@"Возврат"]) {
        self.iconImageView.image = [[UIImage imageNamed:@"ExclamationIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.iconImageView.tintColor = [UIColor flatRedColor];
    } else if ([statusDescription isEqualToString:@"Не доставлено"]) {
        self.iconImageView.image = [[UIImage imageNamed:@"BoltIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.iconImageView.tintColor = [UIColor flatPurpleColor];
    } else {
        self.iconImageView.image = [[UIImage imageNamed:@"VanIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.iconImageView.tintColor = [UIColor ks_accentColor];
    }
}

@end
