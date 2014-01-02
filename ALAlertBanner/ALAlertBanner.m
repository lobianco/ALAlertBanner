/**
 ALAlertBanner.m

 Created by Anthony Lobianco on 8/12/13.
 Copyright (c) 2013 Anthony Lobianco. All rights reserved.

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 **/

#if !__has_feature(objc_arc)
#error ALAlertBanner requires that ARC be enabled
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0
#error ALAlertBanner requires iOS 5.0 or higher
#endif

#import "ALAlertBanner.h"
#import <QuartzCore/QuartzCore.h>
#import "ALAlertBanner+Private.h"
#import "ALAlertBannerManager.h"

static NSString * const kShowAlertBannerKey = @"showAlertBannerKey";
static NSString * const kHideAlertBannerKey = @"hideAlertBannerKey";
static NSString * const kMoveAlertBannerKey = @"moveAlertBannerKey";

static CGFloat const kMargin = 10.f;
static CGFloat const kNavigationBarHeightDefault = 44.f;
static CGFloat const kNavigationBarHeightiOS7Landscape = 32.f;

static CFTimeInterval const kRotationDurationIphone = 0.3;
static CFTimeInterval const kRotationDurationIPad = 0.4;

static CGFloat const kForceHideAnimationDuration = 0.1f;

#define AL_DEVICE_ANIMATION_DURATION UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? kRotationDurationIPad : kRotationDurationIphone;

//macros referenced from MBProgressHUD. cheers to @matej
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 70000
    #define AL_SINGLELINE_TEXT_HEIGHT(text, font) [text length] > 0 ? [text sizeWithAttributes:nil].height : 0.f;
    #define AL_MULTILINE_TEXT_HEIGHT(text, font, maxSize, mode) [text length] > 0 ? [text boundingRectWithSize:maxSize \
                                                                                                       options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) \
                                                                                                    attributes:nil \
                                                                                                       context:NULL].size.height : 0.f;
#else
    #define AL_SINGLELINE_TEXT_HEIGHT(text, font) [text length] > 0 ? [text sizeWithFont:font].height : 0.f;
    #define AL_MULTILINE_TEXT_HEIGHT(text, font, maxSize, mode) [text length] > 0 ? [text sizeWithFont:font \
                                                                                     constrainedToSize:maxSize \
                                                                                         lineBreakMode:mode].height : 0.f;
#endif

# pragma mark -
# pragma mark Helper Categories


//darkerColor referenced from http://stackoverflow.com/questions/11598043/get-slightly-lighter-and-darker-color-from-uicolor
@implementation UIColor (LightAndDark)

- (UIColor *)darkerColor {
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h saturation:s brightness:b * 0.75 alpha:a];
    return nil;
}

@end

@implementation UIDevice (ALSystemVersion)

+ (float)iOSVersion {
    static float version = 0.f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    return version;
}

@end

@implementation UIApplication (ALApplicationBarHeights)

+ (CGFloat)navigationBarHeight {
    //if we're on iOS7 or later, return new landscape navBar height
    if (AL_IOS_7_OR_GREATER && UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
        return kNavigationBarHeightiOS7Landscape;
    
    return kNavigationBarHeightDefault;
}

+ (CGFloat)statusBarHeight {
	return [UIApplication sharedApplication].statusBarFrame.size.height;
}

@end

@interface ALAlertBanner () {
    @private
    ALAlertBannerManager *manager;
}

@property (nonatomic, assign) ALAlertBannerStyle style;
@property (nonatomic, assign) ALAlertBannerPosition position;
@property (nonatomic, assign) ALAlertBannerState state;
@property (nonatomic) NSTimeInterval fadeOutDuration;
@property (nonatomic, readonly) BOOL isAnimating;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIImageView *styleImageView;
@property (nonatomic) CGRect parentFrameUponCreation;

@end

@implementation ALAlertBanner

- (id)init {
    self = [super init];
    if (self) {
        
        [self commonInit];
        
    }
    return self;
}

# pragma mark -
# pragma mark Initializer Helpers

- (void)commonInit {
    self.userInteractionEnabled = YES;
    self.alpha = 0.f;
    self.layer.shadowOpacity = 0.5f;
    self.tag = arc4random_uniform(SHRT_MAX);
    
    [self setupSubviews];
    [self setupInitialValues];
}

- (void)setupInitialValues {
    _fadeOutDuration = 0.2;
    _showAnimationDuration = 0.25;
    _hideAnimationDuration = 0.2;
    _isScheduledToHide = NO;
    _bannerOpacity = 0.93f;
    _secondsToShow = 3.5;
    _allowTapToDismiss = YES;
    _shouldForceHide = NO;
    
    manager = [ALAlertBannerManager sharedManager];
    self.delegate = (ALAlertBannerManager <ALAlertBannerViewDelegate> *)manager;
}

- (void)setupSubviews {
    _styleImageView = [[UIImageView alloc] init];
    [self addSubview:_styleImageView];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.f];
    _titleLabel.textColor = [UIColor colorWithWhite:1.f alpha:0.9f];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.numberOfLines = 1;
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _titleLabel.layer.shadowOffset = CGSizeMake(0.f, -1.f);
    _titleLabel.layer.shadowOpacity = 0.3f;
    _titleLabel.layer.shadowRadius = 0.f;
    [self addSubview:_titleLabel];
    
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.backgroundColor = [UIColor clearColor];
    _subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.f];
    _subtitleLabel.textColor = [UIColor colorWithWhite:1.f alpha:0.9f];
    _subtitleLabel.textAlignment = NSTextAlignmentLeft;
    _subtitleLabel.numberOfLines = 0;
    _subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _subtitleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _subtitleLabel.layer.shadowOffset = CGSizeMake(0.f, -1.f);
    _subtitleLabel.layer.shadowOpacity = 0.3f;
    _subtitleLabel.layer.shadowRadius = 0.f;
    [self addSubview:_subtitleLabel];
}

# pragma mark -
# pragma mark Custom Setters & Getters

-(void)setStyle:(ALAlertBannerStyle)style {
    _style = style;
    
    switch (style) {
        case ALAlertBannerStyleSuccess:
            self.styleImageView.image = [UIImage imageNamed:@"bannerSuccess.png"];
            break;
            
        case ALAlertBannerStyleFailure:
            self.styleImageView.image = [UIImage imageNamed:@"bannerFailure.png"];
            break;
            
        case ALAlertBannerStyleNotify:
            self.styleImageView.image = [UIImage imageNamed:@"bannerNotify.png"];
            break;
            
        case ALAlertBannerStyleWarning:
            self.styleImageView.image = [UIImage imageNamed:@"bannerAlert.png"];
            
            //tone the shadows down a little for the yellow background
            self.titleLabel.layer.shadowOpacity = 0.2f;
            self.subtitleLabel.layer.shadowOpacity = 0.2f;
            
            break;
    }
}

- (void)setShowShadow:(BOOL)showShadow {
    _showShadow = showShadow;
    
    CGFloat oldShadowRadius = self.layer.shadowRadius;
    CGFloat newShadowRadius;
    
    if (showShadow) {
        newShadowRadius = 3.f;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0.f, self.position == ALAlertBannerPositionBottom ? -1.f : 1.f);
        CGRect shadowPath = CGRectMake(self.bounds.origin.x - kMargin, self.bounds.origin.y, self.bounds.size.width + kMargin*2.f, self.bounds.size.height);
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowPath].CGPath;
        
        self.fadeInDuration = 0.15f;
    }
    
    else {
        newShadowRadius = 0.f;
        self.layer.shadowRadius = 0.f;
        self.layer.shadowOffset = CGSizeZero;
        
        //if on iOS7, keep fade in duration at a value greater than 0 so it doesn't instantly appear behind the translucent nav bar
        self.fadeInDuration = (AL_IOS_7_OR_GREATER && self.position == ALAlertBannerPositionTop) ? 0.15f : 0.f;
    }
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shadowRadius = newShadowRadius;
    
    CABasicAnimation *fadeShadow = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
    fadeShadow.fromValue = [NSNumber numberWithFloat:oldShadowRadius];
    fadeShadow.toValue = [NSNumber numberWithFloat:newShadowRadius];
    fadeShadow.duration = self.fadeOutDuration;
    [self.layer addAnimation:fadeShadow forKey:@"shadowRadius"];
}

- (void)setAllowTapToDismiss:(BOOL)allowTapToDismiss {
    if (self.tappedBlock && allowTapToDismiss) {
        NSLog(@"allowTapToDismiss should be set to NO when a tappedBlock is used. If you want to reinstate the tap to dismiss behavior, call [alertBanner hide] in tappedBlock.");
        return;
    }
    _allowTapToDismiss = allowTapToDismiss;
}

- (BOOL)isAnimating {
    return (self.state == ALAlertBannerStateShowing ||
            self.state == ALAlertBannerStateHiding ||
            self.state == ALAlertBannerStateMovingForward ||
            self.state == ALAlertBannerStateMovingBackward);
}

# pragma mark -
# pragma mark Public Class Methods

+ (NSArray *)alertBannersInView:(UIView *)view {
    return [[ALAlertBannerManager sharedManager] alertBannersInView:view];
}

+ (void)hideAllAlertBanners {
    [[ALAlertBannerManager sharedManager] hideAllAlertBanners];
}

+ (void)hideAlertBannersInView:(UIView *)view {
    [[ALAlertBannerManager sharedManager] hideAlertBannersInView:view];
}

+ (void)forceHideAllAlertBannersInView:(UIView *)view {
    [[ALAlertBannerManager sharedManager] forceHideAllAlertBannersInView:view];
}

+ (ALAlertBanner *)alertBannerForView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title {
    return [self alertBannerForView:view style:style position:position title:title subtitle:nil tappedBlock:nil];
}

+ (ALAlertBanner *)alertBannerForView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle {
    return [self alertBannerForView:view style:style position:position title:title subtitle:subtitle tappedBlock:nil];
}

+ (ALAlertBanner *)alertBannerForView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle tappedBlock:(void (^)(ALAlertBanner *alertBanner))tappedBlock {
    ALAlertBanner *alertBanner = [ALAlertBanner createAlertBannerForView:view style:style position:position title:title subtitle:subtitle];
    alertBanner.allowTapToDismiss = tappedBlock ? NO : alertBanner.allowTapToDismiss;
    alertBanner.tappedBlock = tappedBlock;
    return alertBanner;
}

# pragma mark -
# pragma mark Internal Class Methods

+ (ALAlertBanner *)createAlertBannerForView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle {
    ALAlertBanner *alertBanner = [[ALAlertBanner alloc] init];
    
    if (![view isKindOfClass:[UIWindow class]] && position == ALAlertBannerPositionUnderNavBar)
        [[NSException exceptionWithName:@"Wrong ALAlertBannerPosition For View Type" reason:@"ALAlertBannerPositionUnderNavBar should only be used if you are presenting the alert banner on the AppDelegate window. Use ALAlertBannerPositionTop or ALAlertBannerPositionBottom for normal UIViews" userInfo:nil] raise];
    
    alertBanner.titleLabel.text = !title ? @" " : title;
    alertBanner.subtitleLabel.text = subtitle;
    alertBanner.style = style;
    alertBanner.position = position;
    alertBanner.state = ALAlertBannerStateHidden;
    
    [view addSubview:alertBanner];
    
    [alertBanner setInitialLayout];
    [alertBanner updateSizeAndSubviewsAnimated:NO];
    
    return alertBanner;
}

# pragma mark -
# pragma mark Public Instance Methods

- (void)show {
    [self.delegate showAlertBanner:self hideAfter:self.secondsToShow];
}

- (void)hide {
    [self.delegate hideAlertBanner:self forced:NO];
}

# pragma mark -
# pragma mark Internal Instance Methods

- (void)showAlertBanner {
    if (!CGRectEqualToRect(self.parentFrameUponCreation, self.superview.bounds)) {
        //if view size changed since this banner was created, reset layout
        [self setInitialLayout];
        [self updateSizeAndSubviewsAnimated:NO];
    }
    
    [self.delegate alertBannerWillShow:self inView:self.superview];
    
    self.state = ALAlertBannerStateShowing;
    
    double delayInSeconds = self.fadeInDuration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.position == ALAlertBannerPositionUnderNavBar) {
            //animate mask
            CGPoint currentPoint = self.layer.mask.position;
            CGPoint newPoint = CGPointMake(0.f, -self.frame.size.height);
            
            self.layer.mask.position = newPoint;
            
            CABasicAnimation *moveMaskUp = [CABasicAnimation animationWithKeyPath:@"position"];
            moveMaskUp.fromValue = [NSValue valueWithCGPoint:currentPoint];
            moveMaskUp.toValue = [NSValue valueWithCGPoint:newPoint];
            moveMaskUp.duration = self.showAnimationDuration;
            moveMaskUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            
            [self.layer.mask addAnimation:moveMaskUp forKey:@"position"];
        }
        
        CGPoint oldPoint = self.layer.position;
        CGFloat yCoord = oldPoint.y;
        switch (self.position) {
            case ALAlertBannerPositionTop:
            case ALAlertBannerPositionUnderNavBar:
                yCoord += self.frame.size.height;
                break;
            case ALAlertBannerPositionBottom:
                yCoord -= self.frame.size.height;
                break;
        }
        CGPoint newPoint = CGPointMake(oldPoint.x, yCoord);
        
        self.layer.position = newPoint;
        
        CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
        moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
        moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
        moveLayer.duration = self.showAnimationDuration;
        moveLayer.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        moveLayer.delegate = self;
        [moveLayer setValue:kShowAlertBannerKey forKey:@"anim"];
        
        [self.layer addAnimation:moveLayer forKey:kShowAlertBannerKey];
    });
    
    [UIView animateWithDuration:self.fadeInDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alpha = self.bannerOpacity;
    } completion:nil];
}

- (void)hideAlertBanner {
    [self.delegate alertBannerWillHide:self inView:self.superview];
    
    self.state = ALAlertBannerStateHiding;
    
    if (self.position == ALAlertBannerPositionUnderNavBar) {
        CGPoint currentPoint = self.layer.mask.position;
        CGPoint newPoint = CGPointZero;
        
        self.layer.mask.position = newPoint;
        
        CABasicAnimation *moveMaskDown = [CABasicAnimation animationWithKeyPath:@"position"];
        moveMaskDown.fromValue = [NSValue valueWithCGPoint:currentPoint];
        moveMaskDown.toValue = [NSValue valueWithCGPoint:newPoint];
        moveMaskDown.duration = self.shouldForceHide ? kForceHideAnimationDuration : self.hideAnimationDuration;
        moveMaskDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        
        [self.layer.mask addAnimation:moveMaskDown forKey:@"position"];
    }
    
    CGPoint oldPoint = self.layer.position;
    CGFloat yCoord = oldPoint.y;
    switch (self.position) {
        case ALAlertBannerPositionTop:
        case ALAlertBannerPositionUnderNavBar:
            yCoord -= self.frame.size.height;
            break;
        case ALAlertBannerPositionBottom:
            yCoord += self.frame.size.height;
            break;
    }
    CGPoint newPoint = CGPointMake(oldPoint.x, yCoord);
    
    self.layer.position = newPoint;
    
    CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
    moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
    moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
    moveLayer.duration = self.shouldForceHide ? kForceHideAnimationDuration : self.hideAnimationDuration;
    moveLayer.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    moveLayer.delegate = self;
    [moveLayer setValue:kHideAlertBannerKey forKey:@"anim"];
    
    [self.layer addAnimation:moveLayer forKey:kHideAlertBannerKey];
}

- (void)pushAlertBanner:(CGFloat)distance forward:(BOOL)forward delay:(double)delay {
    self.state = (forward ? ALAlertBannerStateMovingForward : ALAlertBannerStateMovingBackward);
    
    CGFloat distanceToPush = distance;
    if (self.position == ALAlertBannerPositionBottom)
        distanceToPush *= -1;
    
    CALayer *activeLayer = self.isAnimating ? (CALayer *)[self.layer presentationLayer] : self.layer;
    
    CGPoint oldPoint = activeLayer.position;
    CGPoint newPoint = CGPointMake(oldPoint.x, (self.layer.position.y - oldPoint.y)+oldPoint.y+distanceToPush);
    
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.layer.position = newPoint;
        
        CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
        moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
        moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
        moveLayer.duration = forward ? self.showAnimationDuration : self.hideAnimationDuration;
        moveLayer.timingFunction = forward ? [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] : [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        moveLayer.delegate = self;
        [moveLayer setValue:kMoveAlertBannerKey forKey:@"anim"];
        
        [self.layer addAnimation:moveLayer forKey:kMoveAlertBannerKey];
    });
}

# pragma mark -
# pragma mark Touch Recognition

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.state != ALAlertBannerStateVisible)
        return;
    
    if (self.tappedBlock) // && !self.isScheduledToHide ...?
        self.tappedBlock(self);
    
    if (self.allowTapToDismiss)
        [self.delegate hideAlertBanner:self forced:NO];
}

# pragma mark -
# pragma mark Private Methods

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {    
    if ([[anim valueForKey:@"anim"] isEqualToString:kShowAlertBannerKey] && flag) {
        [self.delegate alertBannerDidShow:self inView:self.superview];
        self.state = ALAlertBannerStateVisible;
    }
    
    else if ([[anim valueForKey:@"anim"] isEqualToString:kHideAlertBannerKey] && flag) {
        [UIView animateWithDuration:self.shouldForceHide ? kForceHideAnimationDuration : self.fadeOutDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.alpha = 0.f;
        } completion:^(BOOL finished) {
            self.state = ALAlertBannerStateHidden;
            [self.delegate alertBannerDidHide:self inView:self.superview];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [self removeFromSuperview];
        }];
    }
    
    else if ([[anim valueForKey:@"anim"] isEqualToString:kMoveAlertBannerKey] && flag) {
        self.state = ALAlertBannerStateVisible;
    }
}

- (void)setInitialLayout {
    self.layer.anchorPoint = CGPointMake(0.f, 0.f);
    
    UIView *superview = self.superview;
    self.parentFrameUponCreation = superview.bounds;
    BOOL isSuperviewKindOfWindow = ([superview isKindOfClass:[UIWindow class]]);
    
    CGSize maxLabelSize = CGSizeMake(superview.bounds.size.width - (kMargin*3) - self.styleImageView.image.size.width, CGFLOAT_MAX);
    CGFloat titleLabelHeight = AL_SINGLELINE_TEXT_HEIGHT(self.titleLabel.text, self.titleLabel.font);
    CGFloat subtitleLabelHeight = AL_MULTILINE_TEXT_HEIGHT(self.subtitleLabel.text, self.subtitleLabel.font, maxLabelSize, self.subtitleLabel.lineBreakMode);
    CGFloat heightForSelf = titleLabelHeight + subtitleLabelHeight + (self.subtitleLabel.text == nil || self.titleLabel.text == nil ? kMargin*2 : kMargin*2.5);
    
    CGRect frame = CGRectMake(0.f, 0.f, superview.bounds.size.width, heightForSelf);
    CGFloat initialYCoord = 0.f;
    switch (self.position) {
        case ALAlertBannerPositionTop:
            initialYCoord = -heightForSelf;
            if (isSuperviewKindOfWindow) initialYCoord += [UIApplication statusBarHeight];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
            if (AL_IOS_7_OR_GREATER) {
                id nextResponder = [self nextAvailableViewController:self];
                if (nextResponder) {
                    UIViewController *vc = nextResponder;
                    if (!(vc.automaticallyAdjustsScrollViewInsets && [vc.view isKindOfClass:[UIScrollView class]])) {
                        initialYCoord += [vc topLayoutGuide].length;
                    }
                }
            }
#endif
            break;
        case ALAlertBannerPositionBottom:
            initialYCoord = superview.bounds.size.height;
            break;
        case ALAlertBannerPositionUnderNavBar:
            initialYCoord = -heightForSelf + [UIApplication navigationBarHeight] + [UIApplication statusBarHeight];
            break;
    }
    frame.origin.y = initialYCoord;
    self.frame = frame;
    
    //if position is under the nav bar, add a mask
    if (self.position == ALAlertBannerPositionUnderNavBar) {
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        CGRect maskRect = CGRectMake(0.f, frame.size.height, frame.size.width, superview.bounds.size.height); //give the mask enough height so it doesn't clip the shadow
        CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
        maskLayer.path = path;
        CGPathRelease(path);
        
        self.layer.mask = maskLayer;
        self.layer.mask.position = CGPointZero;
    }
}

- (void)updateSizeAndSubviewsAnimated:(BOOL)animated {
    CGSize maxLabelSize = CGSizeMake(self.superview.bounds.size.width - (kMargin*3.f) - self.styleImageView.image.size.width, CGFLOAT_MAX);
    CGFloat titleLabelHeight = AL_SINGLELINE_TEXT_HEIGHT(self.titleLabel.text, self.titleLabel.font);
    CGFloat subtitleLabelHeight = AL_MULTILINE_TEXT_HEIGHT(self.subtitleLabel.text, self.subtitleLabel.font, maxLabelSize, self.subtitleLabel.lineBreakMode);
    CGFloat heightForSelf = titleLabelHeight + subtitleLabelHeight + (self.subtitleLabel.text == nil || self.titleLabel.text == nil ? kMargin*2.f : kMargin*2.5f);
    
    CFTimeInterval boundsAnimationDuration = AL_DEVICE_ANIMATION_DURATION;
        
    CGRect oldBounds = self.layer.bounds;
    CGRect newBounds = oldBounds;
    newBounds.size = CGSizeMake(self.superview.frame.size.width, heightForSelf);
    self.layer.bounds = newBounds;
    
    if (animated) {
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnimation.fromValue = [NSValue valueWithCGRect:oldBounds];
        boundsAnimation.toValue = [NSValue valueWithCGRect:newBounds];
        boundsAnimation.duration = boundsAnimationDuration;
        [self.layer addAnimation:boundsAnimation forKey:@"bounds"];
    }
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:boundsAnimationDuration];
    }
    
    self.styleImageView.frame = CGRectMake(kMargin, (self.frame.size.height/2.f) - (self.styleImageView.image.size.height/2.f), self.styleImageView.image.size.width, self.styleImageView.image.size.height);
    self.titleLabel.frame = CGRectMake(self.styleImageView.frame.origin.x + self.styleImageView.frame.size.width + kMargin, kMargin, maxLabelSize.width, titleLabelHeight);
    self.subtitleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + (self.titleLabel.text == nil ? 0.f : kMargin/2.f), maxLabelSize.width, subtitleLabelHeight);
    
    if (animated) {
        [UIView commitAnimations];
    }
    
    if (self.showShadow) {
        CGRect oldShadowPath = CGPathGetPathBoundingBox(self.layer.shadowPath);
        CGRect newShadowPath = CGRectMake(self.bounds.origin.x - kMargin, self.bounds.origin.y, self.bounds.size.width + kMargin*2.f, self.bounds.size.height);
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:newShadowPath].CGPath;
        
        if (animated) {
            CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
            shadowAnimation.fromValue = (id)[UIBezierPath bezierPathWithRect:oldShadowPath].CGPath;
            shadowAnimation.toValue = (id)[UIBezierPath bezierPathWithRect:newShadowPath].CGPath;
            shadowAnimation.duration = boundsAnimationDuration;
            [self.layer addAnimation:shadowAnimation forKey:@"shadowPath"];
        }
    }
}

- (void)updatePositionAfterRotationWithY:(CGFloat)yPos animated:(BOOL)animated {    
    CFTimeInterval positionAnimationDuration = kRotationDurationIphone; 

    BOOL isAnimating = self.isAnimating;
    CALayer *activeLayer = isAnimating ? (CALayer *)self.layer.presentationLayer : self.layer;
    NSString *currentAnimationKey = nil;
    CAMediaTimingFunction *timingFunction = nil;
    
    if (isAnimating) {
        CABasicAnimation *currentAnimation;
        if (self.state == ALAlertBannerStateShowing) {
            currentAnimation = (CABasicAnimation *)[self.layer animationForKey:kShowAlertBannerKey];
            currentAnimationKey = kShowAlertBannerKey;
        } else if (self.state == ALAlertBannerStateHiding) {
            currentAnimation = (CABasicAnimation *)[self.layer animationForKey:kHideAlertBannerKey];
            currentAnimationKey = kHideAlertBannerKey;
        } else if (self.state == ALAlertBannerStateMovingBackward || self.state == ALAlertBannerStateMovingForward) {
            currentAnimation = (CABasicAnimation *)[self.layer animationForKey:kMoveAlertBannerKey];
            currentAnimationKey = kMoveAlertBannerKey;
        } else
            return;

        CFTimeInterval remainingAnimationDuration = currentAnimation.duration - (CACurrentMediaTime() - currentAnimation.beginTime);
        timingFunction = currentAnimation.timingFunction;
        positionAnimationDuration = remainingAnimationDuration;
        
        [self.layer removeAnimationForKey:currentAnimationKey];
    }

    if (self.state == ALAlertBannerStateHiding || self.state == ALAlertBannerStateMovingBackward) {
        switch (self.position) {
            case ALAlertBannerPositionTop:
            case ALAlertBannerPositionUnderNavBar:
                yPos -= self.layer.bounds.size.height;
                break;
                
            case ALAlertBannerPositionBottom:
                yPos += self.layer.bounds.size.height;
                break;
        }
    }
    CGPoint oldPos = activeLayer.position;
    CGPoint newPos = CGPointMake(oldPos.x, yPos);
    self.layer.position = newPos;
    
    if (animated) {        
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:oldPos];
        positionAnimation.toValue = [NSValue valueWithCGPoint:newPos];
        
        //because the banner's location is relative to the height of the screen when in the bottom position, we should just immediately set it's position upon rotation events. this will prevent any ill-timed animations due to the presentation layer's position at the time of rotation
        if (self.position == ALAlertBannerPositionBottom) {
            positionAnimationDuration = AL_DEVICE_ANIMATION_DURATION;
        }
        
        positionAnimation.duration = positionAnimationDuration;
        positionAnimation.timingFunction = timingFunction == nil ? [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear] : timingFunction;
        
        if (currentAnimationKey != nil) {
            //hijack the old animation's key value
            positionAnimation.delegate = self;
            [positionAnimation setValue:currentAnimationKey forKey:@"anim"];
        }
        
        [self.layer addAnimation:positionAnimation forKey:currentAnimationKey];
    }
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *fillColor;
    switch (self.style) {
        case ALAlertBannerStyleSuccess:
            fillColor = [UIColor colorWithRed:(77/255.0) green:(175/255.0) blue:(67/255.0) alpha:1.f];
            break;
        case ALAlertBannerStyleFailure:
            fillColor = [UIColor colorWithRed:(173/255.0) green:(48/255.0) blue:(48/255.0) alpha:1.f];
            break;
        case ALAlertBannerStyleNotify:
            fillColor = [UIColor colorWithRed:(48/255.0) green:(110/255.0) blue:(173/255.0) alpha:1.f];
            break;
        case ALAlertBannerStyleWarning:
            fillColor = [UIColor colorWithRed:(211/255.0) green:(209/255.0) blue:(100/255.0) alpha:1.f];
            break;
    }
    
    NSArray *colorsArray = [NSArray arrayWithObjects:(id)[fillColor CGColor], (id)[[fillColor darkerColor] CGColor], nil];
    CGColorSpaceRef colorSpace =  CGColorSpaceCreateDeviceRGB();
    const CGFloat locations[2] = {0.f, 1.f};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colorsArray, locations);
    
    CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0.f, self.bounds.size.height), 0.f);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.f green:0.f blue:0.f alpha:0.6f].CGColor);
    CGContextFillRect(context, CGRectMake(0.f, rect.size.height - 1.f, rect.size.width, 1.f));
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:1.f green:1.f blue:1.f alpha:0.3f].CGColor);
    CGContextFillRect(context, CGRectMake(0.f, 0.f, rect.size.width, 1.f));
}

- (id)nextAvailableViewController:(id)view {
    id nextResponder = [view nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [self nextAvailableViewController:nextResponder];
    } else {
        return nil;
    }
}

- (NSString *)description {
    NSString *styleString;
    switch (self.style) {
        case ALAlertBannerStyleSuccess:
            styleString = @"ALAlertBannerStyleSuccess";
            break;
        case ALAlertBannerStyleFailure:
            styleString = @"ALAlertBannerStyleFailure";
            break;
        case ALAlertBannerStyleNotify:
            styleString = @"ALAlertBannerStyleNotify";
            break;
        case ALAlertBannerStyleWarning:
            styleString = @"ALAlertBannerStyleWarning";
            break;
    }
    NSString *positionString;
    switch (self.position) {
        case ALAlertBannerPositionTop:
            positionString = @"ALAlertBannerPositionTop";
            break;
        case ALAlertBannerPositionBottom:
            positionString = @"ALAlertBannerPositionBottom";
            break;
        case ALAlertBannerPositionUnderNavBar:
            positionString = @"ALAlertBannerPositionUnderNavBar";
            break;
    }
    NSString *descriptionString = [NSString stringWithFormat:@"<%@: %p; frame = %@; style = %@; position = %@; superview = <%@: %p>", self.class, self, NSStringFromCGRect(self.frame), styleString, positionString, self.superview.class, self.superview];
    return descriptionString;
}

@end
