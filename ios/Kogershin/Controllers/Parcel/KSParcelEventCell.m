#import "KSParcelEventCell.h"

#import "NSDate+KSHelpers.h"
#import "UIColor+KSTints.h"
#import "UIFont+KSSizes.h"
#import "UILabel+AYHelpers.h"
#import "UIView+AYUtils.h"
#import <Chameleon.h>
#import <UIFont+OpenSans.h>

static UIEdgeInsets const kParcelEventCellPadding = {10, 10, 10, 10};
static CGFloat const kParcelEventCellLabelMargin = 5;

@interface KSParcelEventCell ()

@property (nonatomic) UILabel *dateLabel;
@property (nonatomic) UILabel *statusLabel;
@property (nonatomic) UILabel *addressLabel;

@end

@implementation KSParcelEventCell

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
    self.dateLabel.text = @"";
    self.statusLabel.text = @"";
    self.statusLabel.textColor = [UIColor flatBlackColor];
    self.addressLabel.text = @"";
}

- (void)layoutSubviews {
    [super layoutSubviews];
    for (UILabel *label in @[self.dateLabel, self.statusLabel, self.addressLabel]) {
        [label setFrameToFitWithHeightLimit:0];
    }
    self.statusLabel.top = self.dateLabel.bottom + kParcelEventCellLabelMargin;
    self.addressLabel.top = self.statusLabel.bottom + kParcelEventCellLabelMargin;
}

#pragma mark Public

- (CGFloat)heightWithEvent:(KSEvent *)event {
    [self setUpViews];
    self.event = event;
    return self.addressLabel.bottom + kParcelEventCellPadding.bottom;
}

#pragma mark Private

- (void)setUpViews {
    self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(kParcelEventCellPadding.left, kParcelEventCellPadding.top, CGRectGetWidth([UIScreen mainScreen].bounds) - kParcelEventCellPadding.left - kParcelEventCellPadding.right, 0)];
    [self.contentView addSubview:self.dateLabel];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:self.dateLabel.frame];
    self.statusLabel.textColor = [UIColor flatBlackColor];
    self.statusLabel.font = [UIFont openSansSemiBoldFontOfSize:[UIFont mediumTextFontSize]];
    self.statusLabel.numberOfLines = 0;
    [self.contentView addSubview:self.statusLabel];
    
    self.addressLabel = [[UILabel alloc] initWithFrame:self.dateLabel.frame];
    [self.contentView addSubview:self.addressLabel];
    
    for (UILabel *label in @[self.dateLabel, self.addressLabel]) {
        label.textColor = [UIColor flatGrayColorDark];
        label.font = [UIFont openSansFontOfSize:[UIFont smallTextFontSize]];
        label.numberOfLines = 0;
    }
}

#pragma mark Setters

- (void)setEvent:(KSEvent *)event {
    _event = event;
    
    self.dateLabel.text = [event.date dateString];
    self.statusLabel.text = event.statusDescription;
    if ([event.statusDescription isEqualToString:@"Вручено"]) {
        self.statusLabel.textColor = [UIColor flatGreenColorDark];
    } else if ([event.statusDescription isEqualToString:@"Не доставлено"] || [event.statusDescription isEqualToString:@"Возврат"]) {
        self.statusLabel.textColor = [UIColor flatRedColorDark];
    }
    self.addressLabel.text = [NSString stringWithFormat:@"%@, %@, %@", event.name, event.city, event.zipCode];
    [self layoutSubviews];
}

@end
