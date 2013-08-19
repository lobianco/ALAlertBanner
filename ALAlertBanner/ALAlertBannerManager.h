/**
 ALAlertBannerManager.h
 
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

#import <Foundation/Foundation.h>
#import "ALAlertBannerView.h"

@interface ALAlertBannerManager : NSObject

@property (nonatomic) NSTimeInterval secondsToShow; //default is 3.5
@property (nonatomic) NSTimeInterval showAnimationDuration; //default is 0.25
@property (nonatomic) NSTimeInterval hideAnimationDuration; //default is 0.2
@property (nonatomic, assign) BOOL allowTapToDismiss; //default is YES

+(ALAlertBannerManager*)sharedManager;

-(void)showAlertBannerInView:(UIView*)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString*)title subtitle:(NSString*)subtitle;
-(NSArray *)alertBannersInView:(UIView*)view;
-(void)hideAllAlertBanners;
-(void)hideAlertBannersInView:(UIView*)view;

@end
