/**
 ALAlertBanner.h
 
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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef enum {
    ALAlertBannerStyleSuccess = 0,
    ALAlertBannerStyleFailure,
    ALAlertBannerStyleNotify,
    ALAlertBannerStyleWarning,
} ALAlertBannerStyle;

typedef enum {
    ALAlertBannerPositionTop = 0,
    ALAlertBannerPositionBottom,
    ALAlertBannerPositionUnderNavBar,
} ALAlertBannerPosition;

typedef enum {
    ALAlertBannerStateShowing = 0,
    ALAlertBannerStateHiding,
    ALAlertBannerStateMovingForward,
    ALAlertBannerStateMovingBackward,
    ALAlertBannerStateVisible,
    ALAlertBannerStateHidden
} ALAlertBannerState;

@interface ALAlertBanner : UIView

@property (nonatomic, readonly) ALAlertBannerStyle style;
@property (nonatomic, readonly) ALAlertBannerPosition position;
@property (nonatomic, readonly) ALAlertBannerState state;

/**
 Length of time in seconds that a banner should show before auto-hiding.
 
 Default value is 3.5 seconds. A value == 0 will disable auto-hiding.
 */
@property (nonatomic) NSTimeInterval secondsToShow;

/**
 Tapping on a banner will immediately dismiss it.
 
 Default value is YES. If you supply a tappedHandler in one of the appropriate methods, this will be set to NO for that specific banner.
 */
@property (nonatomic) BOOL allowTapToDismiss;

/**
 The length of time it takes a banner to transition on-screen.
 
 Default value is 0.25 seconds.
 */
@property (nonatomic) NSTimeInterval showAnimationDuration;

/**
 The length of time it takes a banner to transition off-screen.
 
 Default value is 0.2 seconds.
 */
@property (nonatomic) NSTimeInterval hideAnimationDuration;

/**
 Banner opacity, between 0 and 1.
 
 Default value is 0.93f.
 */
@property (nonatomic) CGFloat bannerOpacity;

/**
 The default methods to customize and display a banner.
 */
+ (ALAlertBanner *)alertBannerForView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title;

+ (ALAlertBanner *)alertBannerForView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle;

/**
 Optional method to handle a tap on a banner.
 
 By default, supplying a tap handler will disable allowTapToDismiss on this particular banner. If you want to reinstate this behavior alongside the tap handler, you can call `[[ALAlertBannerManager sharedManager] hideAlertBanner:alertBanner];` in tappedBlock().
 */
+ (ALAlertBanner *)alertBannerForView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle tappedBlock:(void(^)(ALAlertBanner *alertBanner))tappedBlock;

/**
 Show the alert banner
 */
- (void)show;

/**
 Immediately hide this alert banner, forgoing the secondsToShow value.
 */
- (void)hide;

/**
 Returns an array of all banners within a certain view.
 */
+ (NSArray *)alertBannersInView:(UIView *)view;

/**
 Immediately hides all alert banners in all views, forgoing their secondsToShow values.
 */
+ (void)hideAllAlertBanners;

/**
 Immediately hides all alert banners in a certain view, forgoing their secondsToShow values.
 */
+ (void)hideAlertBannersInView:(UIView *)view;

/**
 Immediately force hide all alert banners, forgoing their dismissal animations. Call this in viewWillDisappear: of your view controller if necessary.
 */
+ (void)forceHideAllAlertBannersInView:(UIView *)view;

@end
