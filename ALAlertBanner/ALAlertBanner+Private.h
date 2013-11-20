/**
 ALAlertBanner+Private.h
 
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

#import "ALAlertBanner.h"

#define AL_IOS_7_OR_GREATER [UIDevice iOSVersion] >= 7.0

@interface UIDevice (ALSystemVersion)

+ (float)iOSVersion;

@end

@interface UIApplication (ALApplicationBarHeights)

+ (CGFloat)navigationBarHeight;
+ (CGFloat)statusBarHeight;

@end

@class ALAlertBanner;
@protocol ALAlertBannerViewDelegate <NSObject>
@required
- (void)showAlertBanner:(ALAlertBanner *)alertBanner hideAfter:(NSTimeInterval)delay;
- (void)hideAlertBanner:(ALAlertBanner *)alertBanner forced:(BOOL)forced;
- (void)alertBannerWillShow:(ALAlertBanner *)alertBanner inView:(UIView *)view;
- (void)alertBannerDidShow:(ALAlertBanner *)alertBanner inView:(UIView *)view;
- (void)alertBannerWillHide:(ALAlertBanner *)alertBanner inView:(UIView *)view;
- (void)alertBannerDidHide:(ALAlertBanner *)alertBanner inView:(UIView *)view;
@end

@interface ALAlertBanner ()

@property (nonatomic, weak) id <ALAlertBannerViewDelegate> delegate;
@property (nonatomic) BOOL isScheduledToHide;
@property (nonatomic, copy) void(^tappedBlock)(ALAlertBanner *alertBanner);
@property (nonatomic) NSTimeInterval fadeInDuration;
@property (nonatomic) BOOL showShadow;
@property (nonatomic) BOOL shouldForceHide;

- (void)showAlertBanner;
- (void)hideAlertBanner;
- (void)pushAlertBanner:(CGFloat)distance forward:(BOOL)forward delay:(double)delay;
- (void)updateSizeAndSubviewsAnimated:(BOOL)animated;
- (void)updatePositionAfterRotationWithY:(CGFloat)yPos animated:(BOOL)animated;
- (id)nextAvailableViewController:(id)view;

@end