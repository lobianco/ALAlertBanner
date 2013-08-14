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

#import "ALAlertBannerView.h"
#import <QuartzCore/QuartzCore.h>
#import "ALAlertBannerManager.h"

# pragma mark -
# pragma mark Constants

static NSString * const kShowAlertBannerKey = @"showAlertBannerKey";
static NSString * const kHideAlertBannerKey = @"hideAlertBannerKey";
static NSString * const kMoveAlertBannerKey = @"moveAlertBannerKey";
static CGFloat const kMargin = 10.f;
static CGFloat const kNavigationBarHeight = 44.f;
static CGFloat const kStatusBarHeight = 20.f;

# pragma mark -
# pragma mark Helper Categories

//referenced from http://stackoverflow.com/questions/11598043/get-slightly-lighter-and-darker-color-from-uicolor
@implementation UIColor (LightAndDark)
- (UIColor *)darkerColor
{
    float h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.75
                               alpha:a];
    return nil;
}
@end

@interface ALAlertBannerView ()

@property (nonatomic, assign) ALAlertBannerStyle alertBannerStyle;
@property (nonatomic, assign) ALAlertBannerPosition alertBannerPosition;

@property (nonatomic) NSTimeInterval fadeDuration;

@property (nonatomic, readwrite) BOOL isAnimating;
@property (nonatomic, readwrite) BOOL isVisible;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIImageView *statusImageView;
@property (nonatomic, weak) UIView *parentView;

@end

@implementation ALAlertBannerView

- (id)init
{
    self = [super init];
    if (self) {
        
        [self commonInit];
        
    }
    return self;
}

# pragma mark -
# pragma mark Initializer Helpers

-(void)commonInit
{
    self.userInteractionEnabled = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.alpha = 0.f;
    
    _isVisible = NO;
    _allowTapToDismiss = YES;
    _fadeDuration = 0.1;
    
    _statusImageView = [[UIImageView alloc] init];
    [self addSubview:_statusImageView];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13.f];
    _titleLabel.textColor = [UIColor colorWithWhite:1.f alpha:0.9f];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.numberOfLines = 1;
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _titleLabel.layer.shadowOffset = CGSizeMake(0, -1);
    _titleLabel.layer.shadowOpacity = 0.3f;
    _titleLabel.layer.shadowRadius = 0.f;
    [self addSubview:_titleLabel];
    
    _subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _subtitleLabel.backgroundColor = [UIColor clearColor];
    _subtitleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:10.f];
    _subtitleLabel.textColor = [UIColor colorWithWhite:1.f alpha:0.9f];
    _subtitleLabel.textAlignment = NSTextAlignmentLeft;
    _subtitleLabel.numberOfLines = 0;
    _subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _subtitleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _subtitleLabel.layer.shadowOffset = CGSizeMake(0, -1);
    _subtitleLabel.layer.shadowOpacity = 0.3f;
    _subtitleLabel.layer.shadowRadius = 0.f;
    [self addSubview:_subtitleLabel];
}

# pragma mark -
# pragma mark Custom Setters & Getters

-(void)setAlertBannerStyle:(ALAlertBannerStyle)alertBannerStyle
{
    _alertBannerStyle = alertBannerStyle;
    
    switch (alertBannerStyle) {
        case ALAlertBannerStyleSuccess:
            self.statusImageView.image = [UIImage imageNamed:@"bannerSuccess.png"];
            break;
            
        case ALAlertBannerStyleFailure:
            self.statusImageView.image = [UIImage imageNamed:@"bannerFailure.png"];
            break;
            
        case ALAlertBannerStyleNotify:
            self.statusImageView.image = [UIImage imageNamed:@"bannerNotify.png"];
            break;
            
        case ALAlertBannerStyleAlert:
            self.statusImageView.image = [UIImage imageNamed:@"bannerAlert.png"];
            break;
    }    
}

-(BOOL)isAnimating
{
    return ([self.layer animationForKey:kMoveAlertBannerKey] != nil ||
            [self.layer animationForKey:kShowAlertBannerKey] != nil ||
            [self.layer animationForKey:kHideAlertBannerKey] != nil);
}

# pragma mark - 
# pragma mark Class Methods

+(ALAlertBannerView*)alertBannerForView:(UIView*)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString*)title subtitle:(NSString*)subtitle
{
    ALAlertBannerView *alertBanner = [[ALAlertBannerView alloc] init];
    BOOL isSuperviewMainWindow = ([view isKindOfClass:[UIWindow class]] && (UIWindow*)view == [UIApplication sharedApplication].delegate.window);
    
    if (!isSuperviewMainWindow && position == ALAlertBannerPositionUnderNavBar)
        [[NSException exceptionWithName:@"Bad ALAlertBannerStyle For View Type" reason:@"ALAlertBannerPositionUnderNavBar should only be used if you are presenting the alert banner on the AppDelegate window. Use ALAlertBannerPositionTop or ALAlertBannerPositionBottom for normal UIViews" userInfo:nil] raise];
    
    alertBanner.parentView = view;
    alertBanner.titleLabel.text = title;
    alertBanner.subtitleLabel.text = subtitle;
    alertBanner.alertBannerStyle = style;
    alertBanner.alertBannerPosition = position;
    
    CGSize maxLabelSize = CGSizeMake(view.bounds.size.width - (kMargin*3) - alertBanner.statusImageView.image.size.width, CGFLOAT_MAX);
    CGFloat titleLabelHeight = alertBanner.titleLabel.font.pointSize + 2.f;
    CGFloat subtitleLabelHeight = [subtitle sizeWithFont:alertBanner.subtitleLabel.font constrainedToSize:maxLabelSize lineBreakMode:alertBanner.subtitleLabel.lineBreakMode].height;
    CGFloat heightForSelf = titleLabelHeight + subtitleLabelHeight + (subtitle == nil ? kMargin*2 : kMargin*2.5);
    
    CGRect frame = CGRectMake(0, 0, view.bounds.size.width, 0);
    frame.size.height = heightForSelf;
    CGFloat initialYCoord = 0.f;
    switch (position) {
        case ALAlertBannerPositionTop:
            initialYCoord = -heightForSelf;
            if (isSuperviewMainWindow) initialYCoord += kStatusBarHeight;
            break;
        case ALAlertBannerPositionBottom:
            initialYCoord = view.bounds.size.height;
            break;
        case ALAlertBannerPositionUnderNavBar:
            initialYCoord = -heightForSelf + kNavigationBarHeight + kStatusBarHeight;
            break;
    }
    frame.origin.y = initialYCoord;
    alertBanner.frame = frame;
    
    //if position is under the nav bar, add a mask
    if (position == ALAlertBannerPositionUnderNavBar)
    {
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        CGRect maskRect = CGRectMake(0, alertBanner.frame.size.height, alertBanner.frame.size.width, view.bounds.size.height); //give the mask enough height so it doesn't clip the shadow
        CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
        maskLayer.path = path;
        CGPathRelease(path);
        
        alertBanner.layer.mask = maskLayer;
        alertBanner.layer.mask.position = CGPointZero;
    }
    
    [view addSubview:alertBanner];
            
    return alertBanner;
}

# pragma mark -
# pragma mark Instance Methods

-(void)show
{
    [self.delegate alertBannerWillShow:self];
    
    double delayInSeconds = self.fadeDuration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.alertBannerPosition == ALAlertBannerPositionUnderNavBar)
        {
            //animate mask
            CGPoint currentPoint = self.layer.mask.position;
            CGPoint newPoint = CGPointMake(0, -self.frame.size.height);
            
            self.layer.mask.position = newPoint;
            
            CABasicAnimation *moveMaskUp = [CABasicAnimation animationWithKeyPath:@"position"];
            moveMaskUp.fromValue = [NSValue valueWithCGPoint:currentPoint];
            moveMaskUp.toValue = [NSValue valueWithCGPoint:newPoint];
            moveMaskUp.duration = self.showAnimationDuration;
            moveMaskUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            
            [self.layer.mask addAnimation:moveMaskUp forKey:nil];
        }
        
        CGPoint oldPoint = self.layer.position;
        CGFloat yCoord = oldPoint.y;
        switch (self.alertBannerPosition) {
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
    
    [UIView animateWithDuration:self.fadeDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alpha = 1.f;
    } completion:nil];
}

-(void)hide
{
    [self.delegate alertBannerWillHide:self];
    
    //use the presentation layer to get the current point, just in case it's in the middle of an animation
    CALayer *presentationLayer = (CALayer*)[self.layer presentationLayer];
    
    if (self.alertBannerPosition == ALAlertBannerPositionUnderNavBar)
    {
        CGPoint currentPoint = presentationLayer.mask.position;
        CGPoint newPoint = CGPointZero;
        
        self.layer.mask.position = newPoint;
        
        CABasicAnimation *moveMaskDown = [CABasicAnimation animationWithKeyPath:@"position"];
        moveMaskDown.fromValue = [NSValue valueWithCGPoint:currentPoint];
        moveMaskDown.toValue = [NSValue valueWithCGPoint:newPoint];
        moveMaskDown.duration = self.hideAnimationDuration;
        moveMaskDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        
        [self.layer.mask addAnimation:moveMaskDown forKey:nil];
    }
    
    CGPoint oldPoint = presentationLayer.position;
    CGFloat yCoord = oldPoint.y;
    switch (self.alertBannerPosition) {
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
    moveLayer.duration = self.hideAnimationDuration;
    moveLayer.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    moveLayer.delegate = self;
    [moveLayer setValue:kHideAlertBannerKey forKey:@"anim"];
    
    [self.layer addAnimation:moveLayer forKey:kHideAlertBannerKey];
}

-(void)move:(CGFloat)distance forward:(BOOL)forward
{
    double delayInSeconds = forward ? self.fadeDuration : 0.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                
        CGFloat distanceToPush = distance;
        if (self.alertBannerPosition == ALAlertBannerPositionBottom)
            distanceToPush *= -1;
        
        CGPoint oldPoint = [(CALayer*)self.layer.presentationLayer position];
        CGPoint newPoint = CGPointMake(oldPoint.x, (self.layer.position.y - oldPoint.y)+oldPoint.y+distanceToPush);
        
        self.layer.position = newPoint;
        
        CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
        moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
        moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
        moveLayer.duration = forward ? self.showAnimationDuration : self.hideAnimationDuration;
        moveLayer.timingFunction = forward ? [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] : [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        
        [self.layer addAnimation:moveLayer forKey:kMoveAlertBannerKey];
        
    });
}

# pragma mark -
# pragma mark Touch Recognition

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.isVisible && !self.isAnimating && self.allowTapToDismiss)
        [self.delegate hideAlertBanner:self];
}

# pragma mark -
# pragma mark Private Methods

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{    
    if ([[anim valueForKey:@"anim"] isEqualToString:kShowAlertBannerKey] && flag)
    {
        [self.delegate alertBannerDidShow:self];
        self.isVisible = YES;
    }
    
    else if ([[anim valueForKey:@"anim"] isEqualToString:kHideAlertBannerKey])
    {
        //fade out slowly before removing from superview, to prevent the shadow from suddenly vanishing. this ain't no harry potter shit.
        [UIView animateWithDuration:self.fadeDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.alpha = 0.f;
        } completion:^(BOOL finished) {
            self.isVisible = NO;
            [self.delegate alertBannerDidHide:self];
            [self removeFromSuperview];
        }];
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize maxLabelSize = CGSizeMake(self.parentView.bounds.size.width - (kMargin*3) - self.statusImageView.image.size.width, CGFLOAT_MAX);
    CGFloat titleLabelHeight = self.titleLabel.font.pointSize + 2.f;
    CGFloat subtitleLabelHeight = [self.subtitleLabel.text sizeWithFont:self.subtitleLabel.font constrainedToSize:maxLabelSize lineBreakMode:self.subtitleLabel.lineBreakMode].height;
    CGFloat heightForSelf = titleLabelHeight + subtitleLabelHeight + (self.subtitleLabel.text == nil ? kMargin*2 : kMargin*2.5);
    
    CGRect frame = self.frame;
    frame.size.height = heightForSelf;
    self.frame = frame;
    
    self.statusImageView.frame = CGRectMake(kMargin, (self.frame.size.height/2) - (self.statusImageView.image.size.height/2), self.statusImageView.image.size.width, self.statusImageView.image.size.height);
    self.titleLabel.frame = CGRectMake(self.statusImageView.frame.origin.x + self.statusImageView.frame.size.width + kMargin, kMargin, maxLabelSize.width, titleLabelHeight);
    self.subtitleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + kMargin/2, maxLabelSize.width, subtitleLabelHeight);
    
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowRadius = 4.f;
    self.layer.shadowOpacity = 0.65f;
    self.layer.shadowOffset = CGSizeMake(0, self.alertBannerPosition == ALAlertBannerPositionBottom ? -1 : 1);
    CGRect shadowPath = CGRectMake(self.bounds.origin.x - kMargin, self.bounds.origin.y, self.bounds.size.width + kMargin*2, self.bounds.size.height);
    self.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowPath].CGPath;
    self.layer.shouldRasterize = YES;
    
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor *fillColor;
    switch (self.alertBannerStyle) {
        case ALAlertBannerStyleSuccess:
            fillColor = [UIColor colorWithRed:(77/255.0) green:(175/255.0) blue:(67/255.0) alpha:1.f];
            break;
        case ALAlertBannerStyleFailure:
            fillColor = [UIColor colorWithRed:(173/255.0) green:(48/255.0) blue:(48/255.0) alpha:1.f];
            break;
        case ALAlertBannerStyleNotify:
            fillColor = [UIColor colorWithRed:(48/255.0) green:(110/255.0) blue:(173/255.0) alpha:1.f];
            break;
        case ALAlertBannerStyleAlert:
            fillColor = [UIColor colorWithRed:(211/255.0) green:(209/255.0) blue:(81/255.0) alpha:1.f];
            break;
    }
    
    NSArray *colorsArray = [NSArray arrayWithObjects:(id)[fillColor CGColor], (id)[[fillColor darkerColor] CGColor], nil];
    CGColorSpaceRef colorSpace =  CGColorSpaceCreateDeviceRGB();
    const CGFloat locations[2] = {0.0, 1.0};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colorsArray, locations);
    
    CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0, self.bounds.size.height), 0);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0 green:0 blue:0 alpha:0.75].CGColor);
    CGContextFillRect(context, CGRectMake(0, self.alertBannerPosition == ALAlertBannerPositionBottom ? 0 : rect.size.height - 1.f, rect.size.width, 1.f));
}

@end