#import "KSArrowIcon.h"

#import "UIView+AYUtils.h"

#define DEGREES_TO_RADIANS(x) ((x) * M_PI / 180)

static CGFloat const kArrowIconCurvature = (CGFloat)DEGREES_TO_RADIANS(30);
static CGFloat const kArrowIconAnimationDuration = 0.2f;

@interface KSArrowIcon ()

@property (nonatomic) UIView *leftArrowPart;
@property (nonatomic) UIView *rightArrowPart;

@end

@implementation KSArrowIcon

#pragma mark Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    CGFloat overlap = self.height;
    self.leftArrowPart = [self arrowPart];
    self.leftArrowPart.frame = CGRectMake(0, 0, self.width/2 + overlap, self.height);
    [self addSubview:self.leftArrowPart];
    self.rightArrowPart = [self arrowPart];
    self.rightArrowPart.frame = CGRectMake(self.width/2 - overlap, 0, self.width/2 + overlap, self.height);
    [self addSubview:self.rightArrowPart];
    
    self.clipsToBounds = NO;
    self.color = [UIColor whiteColor];
    
    return self;
}

#pragma mark Private

- (UIView *)arrowPart {
    UIView *arrowPart = [UIView new];
    arrowPart.layer.cornerRadius = self.height/2;
    arrowPart.layer.allowsEdgeAntialiasing = YES;
    return arrowPart;
}

- (void)pointDown {
    self.leftArrowPart.transform = CGAffineTransformMakeRotation(kArrowIconCurvature);
    self.rightArrowPart.transform = CGAffineTransformMakeRotation(-kArrowIconCurvature);
}

- (void)pointUp {
    self.leftArrowPart.transform = CGAffineTransformMakeRotation(-kArrowIconCurvature);
    self.rightArrowPart.transform = CGAffineTransformMakeRotation(kArrowIconCurvature);
}

#pragma mark Public

- (void)pointDownAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:kArrowIconAnimationDuration animations:^{
            [self pointDown];
        }];
    } else {
        [self pointDown];
    }
}

- (void)pointUpAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:kArrowIconAnimationDuration animations:^ {
            [self pointUp];
        }];
    } else {
        [self pointUp];
    }
}

#pragma mark Setters

- (void)setColor:(UIColor *)color {
    _color = color;
    self.rightArrowPart.backgroundColor = color;
    self.leftArrowPart.backgroundColor = color;
}

@end
