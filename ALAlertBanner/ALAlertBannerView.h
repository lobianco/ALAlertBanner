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

@interface ALAlertBannerStyle : NSObject

@property (nonatomic, strong, readonly) UIColor *backgroundColor;
@property (nonatomic, strong, readonly) UIImage *image;

@end

extern ALAlertBannerStyle *ALAlertBannerStyleMake(UIColor *backgroundColor, UIImage *image);

#define kALAlertBannerBackgroundColorGreen  [UIColor colorWithRed:(77/255.f) green:(175/255.f) blue:(67/255.f) alpha:1.f]
#define kALAlertBannerBackgroundColorRed    [UIColor colorWithRed:(173/255.f) green:(48/255.f) blue:(48/255.f) alpha:1.f]
#define kALAlertBannerBackgroundColorBlue   [UIColor colorWithRed:(48/255.f) green:(110/255.f) blue:(173/255.f) alpha:1.f]
#define kALAlertBannerBackgroundColorYellow [UIColor colorWithRed:(211/255.f) green:(209/255.f) blue:(100/255.f) alpha:1.f]

#define kALAlertBannerIconSuccess   [UIImage imageNamed:@"bannerSuccess.png"]
#define kALAlertBannerIconFailure   [UIImage imageNamed:@"bannerFailure.png"]
#define kALAlertBannerIconInfo      [UIImage imageNamed:@"bannerNotify.png"]
#define kALAlertBannerIconWarning   [UIImage imageNamed:@"bannerAlert.png"]

#define kALAlertBannerStyleSuccess  ALAlertBannerStyleMake(kALAlertBannerBackgroundColorGreen, kALAlertBannerIconSuccess)
#define kALAlertBannerStyleFailure  ALAlertBannerStyleMake(kALAlertBannerBackgroundColorRed, kALAlertBannerIconFailure)
#define kALAlertBannerStyleNotify   ALAlertBannerStyleMake(kALAlertBannerBackgroundColorBlue, kALAlertBannerIconInfo)
#define kALAlertBannerStyleAlert    ALAlertBannerStyleMake(kALAlertBannerBackgroundColorYellow, kALAlertBannerIconWarning)

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


@class ALAlertBannerView;
@protocol ALAlertBannerViewDelegate <NSObject>
@required

- (void)alertBannerWillShow:(ALAlertBannerView *)alertBanner inView:(UIView *)view;
- (void)alertBannerDidShow:(ALAlertBannerView *)alertBanner inView:(UIView *)view;
- (void)alertBannerWillHide:(ALAlertBannerView *)alertBanner inView:(UIView *)view;
- (void)alertBannerDidHide:(ALAlertBannerView *)alertBanner inView:(UIView *)view;
- (void)hideAlertBanner:(ALAlertBannerView *)alertBanner;
@end

@interface ALAlertBannerView : UIView

- (ALAlertBannerStyle *)style;
- (ALAlertBannerPosition)position;
- (ALAlertBannerState)state;

@end
