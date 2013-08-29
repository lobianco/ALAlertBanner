//
//  ALAlertBannerView+Private.h
//  ALAlertBannerDemo
//
//  Created by Jonas Gessner on 25.08.13.
//  Copyright (c) 2013 Jonas Gessner. All rights reserved.
//

#import "ALAlertBannerView.h"


#define AL_IOS_7_OR_GREATER [UIDevice iOSVersion] >= 7.0

static CGFloat const kStatusBarHeight = 20.f;

@interface UIDevice (ALSystemVersion)
+ (float)iOSVersion;
@end

@interface UIApplication (ALNavigationBarHeight)
+ (CGFloat)navigationBarHeight;
@end


@interface ALAlertBannerStyle ()

- (instancetype)initWithColor:(UIColor *)color icon:(UIImage *)icon;
+ (instancetype)alertBannerStyleWithColor:(UIColor *)color icon:(UIImage *)icon;

@end

@interface ALAlertBannerView ()

@property (nonatomic, weak) id <ALAlertBannerViewDelegate> delegate;

@property (nonatomic) BOOL isScheduledToHide;
@property (nonatomic) BOOL allowTapToDismiss;
@property (nonatomic, copy) void(^tappedBlock)(ALAlertBannerView *);

@property (nonatomic) NSTimeInterval fadeInDuration;
@property (nonatomic) BOOL showShadow;
@property (nonatomic) NSTimeInterval showAnimationDuration;
@property (nonatomic) NSTimeInterval hideAnimationDuration;
@property (nonatomic) CGFloat bannerOpacity;

+ (ALAlertBannerView *)alertBannerForView:(UIView *)view style:(ALAlertBannerStyle *)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle;
- (void)show;
- (void)hide;
- (void)push:(CGFloat)distance forward:(BOOL)forward delay:(double)delay;
- (void)updateSizeAndSubviewsAnimated:(BOOL)animated;
- (void)updatePositionAfterRotationWithY:(CGFloat)yPos animated:(BOOL)animated;

@end