#import "KSPopupParcelViewController.h"

#import "KSAlertManager.h"
#import "UIFont+KSSizes.h"
#import "UIView+AYUtils.h"
#import <Chameleon.h>
#import <UIFont+OpenSans.h>

static UIEdgeInsets const kParcelFormItemPadding = {5, 10, 5, 10};
static CGFloat const kParcelFormItemHeight = 40;

@interface KSPopupParcelViewController () <UITextFieldDelegate>

@property (nonatomic) UILabel *trackingIdLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UITextField *trackingIdTextField;
@property (nonatomic) UITextField *titleTextField;
@property (nonatomic, getter=isTrackingIdEntered) BOOL trackingIdEntered;

@end

@implementation KSPopupParcelViewController

#pragma mark Initialization

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    
    self.contentSizeInPopup = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) - 20, (kParcelFormItemPadding.top + kParcelFormItemHeight + kParcelFormItemPadding.bottom) * 2+ 1/[UIScreen mainScreen].scale);
    
    return self;
}

#pragma mark Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont openSansFontOfSize:17],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.5f] } forState:UIControlStateNormal];
    [self setUpViews];
    [self.trackingIdTextField becomeFirstResponder];
}

#pragma mark Setters & getters

- (void)setParcelTrackingId:(NSString *)parcelTrackingId {
    self.trackingIdTextField.text = parcelTrackingId;
    [self checkTrackingId];
}

- (NSString *)parcelTrackingId {
    return self.trackingIdTextField.text;
}

- (void)setParcelTitle:(NSString *)parcelTitle {
    self.titleTextField.text = parcelTitle;
}

- (NSString *)parcelTitle {
    return self.titleTextField.text;
}

#pragma mark Public

- (void)onDone { }

- (void)resetTrackingId {
    self.trackingIdTextField.text = @"";
    [self checkTrackingId];
    [self.trackingIdTextField becomeFirstResponder];
}

#pragma mark Private

- (void)setUpViews {
    self.trackingIdLabel = [self label];
    self.trackingIdLabel.text = NSLocalizedString(@"Трек-номер", nil);
    self.trackingIdLabel.width = [self.trackingIdLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.trackingIdLabel.font }].width;
    [self.view addSubview:self.trackingIdLabel];
    
    UIView *border = [[UIView alloc] initWithFrame:CGRectMake(0, self.trackingIdLabel.bottom + kParcelFormItemPadding.bottom, self.view.width, 1/[UIScreen mainScreen].scale)];
    border.backgroundColor = [UIColor flatGrayColor];
    [self.view addSubview:border];
    
    self.titleLabel = [self label];
    self.titleLabel.text = NSLocalizedString(@"Название", nil);
    self.titleLabel.width = [self.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName: self.titleLabel.font }].width;
    self.titleLabel.top = border.bottom + kParcelFormItemPadding.top;
    [self.view addSubview:self.titleLabel];
    
    for (UILabel *label in @[self.trackingIdLabel, self.titleLabel]) {
        label.width = MAX(self.trackingIdLabel.width, self.titleLabel.width);
    }
    
    self.trackingIdTextField = [self textField];
    self.trackingIdTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Обязательно", nil) attributes:@{ NSForegroundColorAttributeName: [UIColor flatGrayColorDark] }];
    self.trackingIdTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.trackingIdTextField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.trackingIdTextField.returnKeyType = UIReturnKeyNext;
    self.trackingIdTextField.left += self.trackingIdLabel.right + kParcelFormItemPadding.right;
    self.trackingIdTextField.width = self.view.width - kParcelFormItemPadding.right - self.trackingIdTextField.left;
    [self.view addSubview:self.trackingIdTextField];
    
    self.titleTextField = [self textField];
    self.titleTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Необязательно", nil) attributes:@{ NSForegroundColorAttributeName: [UIColor flatGrayColorDark] }];
    self.titleTextField.returnKeyType = UIReturnKeyNext;
    self.titleTextField.left += self.titleLabel.right + kParcelFormItemPadding.right;
    self.titleTextField.width = self.view.width - kParcelFormItemPadding.right - self.titleTextField.left;
    self.titleTextField.top = self.titleLabel.top;
    [self.view addSubview:self.titleTextField];
}

- (UILabel *)label {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kParcelFormItemPadding.left, kParcelFormItemPadding.top, 0, kParcelFormItemHeight)];
    label.textColor = [UIColor flatBlackColor];
    label.font = [UIFont openSansFontOfSize:[UIFont mediumTextFontSize]];
    return label;
}

- (UITextField *)textField {
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(kParcelFormItemPadding.left, kParcelFormItemPadding.top, 0, kParcelFormItemHeight)];
    textField.textColor = [UIColor flatBlackColor];
    textField.font = [UIFont openSansFontOfSize:[UIFont mediumTextFontSize]];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.delegate = self;
    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    return textField;
}

- (void)checkTrackingId {
    NSPredicate *patternMatching = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[a-zA-Z]{2}[0-9]{9}[a-zA-Z]{2}"];
    self.trackingIdEntered = [patternMatching evaluateWithObject:self.trackingIdTextField.text];
    self.titleTextField.returnKeyType = self.trackingIdEntered ? UIReturnKeyDone : UIReturnKeyNext;
    self.navigationItem.rightBarButtonItem.enabled = self.isTrackingIdEntered;
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{ NSFontAttributeName: [UIFont openSansFontOfSize:17],
        NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:self.isTrackingIdEntered ? 1 : 0.5f] } forState:UIControlStateNormal];
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidChange:(UITextField *)textField {
    if (textField == self.trackingIdTextField) {
        [self checkTrackingId];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.trackingIdTextField) {
        if (self.trackingIdEntered) {
            [self.titleTextField becomeFirstResponder];
        } else {
            [[KSAlertManager sharedInstance] showErrorNotificationWithText:@"Пожалуйста, введите правильный трек номер в формате AB012345678CD"];
        }
    } else if (self.trackingIdEntered) {
        [self onDone];
    } else {
        [self.trackingIdTextField becomeFirstResponder];
    }
    return YES;
}

@end
