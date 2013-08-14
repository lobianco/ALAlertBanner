/**
 ALAlertBannerManager.m
 
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

#import "ALAlertBannerManager.h"

@interface ALAlertBannerManager () <ALAlertBannerViewDelegate>

@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) NSMutableArray *banners;

@end

@implementation ALAlertBannerManager

+(ALAlertBannerManager *)sharedManager
{
    static ALAlertBannerManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ALAlertBannerManager alloc] init];
    });
    return sharedManager;
}

-(id)init
{
    self = [super init];
    if (self) {
        
        //let's make sure only one animation happens at a time
        _semaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_semaphore);
        _banners = [[NSMutableArray alloc] init];
        _secondsToShow = 3.5;
        _showAnimationDuration = 0.25f;
        _hideAnimationDuration = 0.2f;
        _allowTapToDismiss = YES;
        
    }
    return self;
}

-(void)showAlertBannerInView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle
{
    ALAlertBannerView *alertBanner = [ALAlertBannerView alertBannerForView:view style:style position:position title:title subtitle:subtitle];
    alertBanner.delegate = self;
    alertBanner.tag = arc4random_uniform(SHRT_MAX);
    alertBanner.showAnimationDuration = self.showAnimationDuration;
    alertBanner.hideAnimationDuration = self.hideAnimationDuration;
    alertBanner.allowTapToDismiss = self.allowTapToDismiss;
    
    [self showAlertBanner:alertBanner];
}

-(void)showAlertBanner:(ALAlertBannerView*)alertBanner
{
    dispatch_semaphore_t semaphore = self.semaphore;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertBanner show];
            
            if (self.secondsToShow > 0)
                [self performSelector:@selector(hideAlertBanner:) withObject:alertBanner afterDelay:self.secondsToShow];
        });
    });
}

# pragma mark -
# pragma mark Delegate Methods

-(void)hideAlertBanner:(ALAlertBannerView *)alertBanner
{
    [NSOperation cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAlertBanner:) object:alertBanner];
    dispatch_semaphore_t semaphore = self.semaphore;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertBanner hide];
        });
    });
}

-(void)alertBannerWillShow:(ALAlertBannerView *)alertBanner
{
    for (ALAlertBannerView *banner in self.banners)
        if (banner.alertBannerPosition == alertBanner.alertBannerPosition)
            [banner move:alertBanner.frame.size.height forward:YES];
    
    [self.banners addObject:alertBanner];
}

-(void)alertBannerDidShow:(ALAlertBannerView *)alertBanner
{
    dispatch_semaphore_t semaphore = self.semaphore;
    dispatch_semaphore_signal(semaphore);
}

-(void)alertBannerWillHide:(ALAlertBannerView *)alertBanner
{
    NSUInteger index = [self.banners indexOfObject:alertBanner];
    if (index != NSNotFound && index > 0)
    {
        NSArray *bannersToPush = [self.banners subarrayWithRange:NSMakeRange(0, index)];
        for (ALAlertBannerView *banner in bannersToPush)
            if (banner.alertBannerPosition == alertBanner.alertBannerPosition)
                [banner move:-alertBanner.frame.size.height forward:NO];
    }
}

-(void)alertBannerDidHide:(ALAlertBannerView *)alertBanner
{
    [self.banners removeObject:alertBanner];

    dispatch_semaphore_t semaphore = self.semaphore;
    dispatch_semaphore_signal(semaphore);
}

# pragma mark -
# pragma mark Instance Methods

-(void)hideAlertBannersInView:(UIView *)view
{
    for (UIView *subview in view.subviews)
    {
        if ([subview isKindOfClass:[ALAlertBannerView class]])
            [self hideAlertBanner:(ALAlertBannerView *)subview];
    }
}

-(void)hideAllAlertBanners
{
    for (int i = 0; i < self.banners.count; i++)
        [self hideAlertBanner:(ALAlertBannerView*)[self.banners objectAtIndex:i]];
}

@end
