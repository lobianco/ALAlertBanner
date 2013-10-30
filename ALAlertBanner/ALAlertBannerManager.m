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
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "ALAlertBanner+Private.h"

# pragma mark -
# pragma mark Categories for Convenience

@interface UIView (ALConvenience)

@property (nonatomic, strong) NSMutableArray *alertBanners;

@end

@implementation UIView (ALConvenience)

@dynamic alertBanners;

- (void)setAlertBanners:(NSMutableArray *)alertBanners {
    objc_setAssociatedObject(self, @selector(alertBanners), alertBanners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)alertBanners {
    NSMutableArray *alertBannersArray = objc_getAssociatedObject(self, @selector(alertBanners));
    if (!alertBannersArray) {
        alertBannersArray = [NSMutableArray array];
        [self setAlertBanners:alertBannersArray];
    }
    return alertBannersArray;
}

@end

@interface ALAlertBannerManager () <ALAlertBannerViewDelegate>

@property (nonatomic) dispatch_semaphore_t topPositionSemaphore;
@property (nonatomic) dispatch_semaphore_t bottomPositionSemaphore;
@property (nonatomic) dispatch_semaphore_t navBarPositionSemaphore;
@property (nonatomic, strong) NSMutableArray *bannerViews;

- (void)didRotate:(NSNotification *)note;

@end

@implementation ALAlertBannerManager

+ (ALAlertBannerManager *)sharedManager {
    static ALAlertBannerManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ALAlertBannerManager alloc] init];
    });
    return sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        
        //let's make sure only one animation happens at a time
        _topPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_topPositionSemaphore);
        _bottomPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_bottomPositionSemaphore);
        _navBarPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_navBarPositionSemaphore);
        
        _bannerViews = [NSMutableArray new];
        
        //TODO: use UIApplicationDidChangeStatusBarOrientationNotification instead
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

# pragma mark -
# pragma mark ALAlertBannerViewDelegate Methods

- (void)showAlertBanner:(ALAlertBanner *)alertBanner hideAfter:(NSTimeInterval)delay {
    dispatch_semaphore_t semaphore;
    switch (alertBanner.position) {
        case ALAlertBannerPositionTop:
            semaphore = self.topPositionSemaphore;
            break;
        case ALAlertBannerPositionBottom:
            semaphore = self.bottomPositionSemaphore;
            break;
        case ALAlertBannerPositionUnderNavBar:
            semaphore = self.navBarPositionSemaphore;
            break;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertBanner showAlertBanner];
            
            if (delay > 0) {
                [self performSelector:@selector(hideAlertBanner:) withObject:alertBanner afterDelay:delay];
            }
        });
    });
}

- (void)hideAlertBanner:(ALAlertBanner *)alertBanner {
    [self hideAlertBanner:alertBanner forced:NO];
}

- (void)hideAlertBanner:(ALAlertBanner *)alertBanner forced:(BOOL)forced {
    if (alertBanner.isScheduledToHide) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAlertBanner:) object:alertBanner];
    
    if (forced) {
        alertBanner.shouldForceHide = YES;
        [alertBanner hideAlertBanner];
    }
    else {
        alertBanner.isScheduledToHide = YES;
        
        dispatch_semaphore_t semaphore;
        switch (alertBanner.position) {
            case ALAlertBannerPositionTop:
                semaphore = self.topPositionSemaphore;
                break;
            case ALAlertBannerPositionBottom:
                semaphore = self.bottomPositionSemaphore;
                break;
            case ALAlertBannerPositionUnderNavBar:
                semaphore = self.navBarPositionSemaphore;
                break;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertBanner hideAlertBanner];
            });
        });
    }
}

- (void)alertBannerWillShow:(ALAlertBanner *)alertBanner inView:(UIView *)view {
    //keep track of all views we've added banners to, to deal with rotation events and hideAllAlertBanners
    if (![self.bannerViews containsObject:view]) {
        [self.bannerViews addObject:view];
    }
    
    //make copy so we can set shadow before pushing banners
    NSArray *bannersToPush = [NSArray arrayWithArray:view.alertBanners];
    NSMutableArray *bannersArray = view.alertBanners;
    
    [bannersArray addObject:alertBanner];
    NSArray *bannersInSamePosition = [bannersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", alertBanner.position]];
    
    //set shadow before pushing other banners, because the banner push may be delayed by the fade in duration (which is set at the same time as the shadow) on iOS7
    alertBanner.showShadow = (bannersInSamePosition.count > 1 ? NO : YES);
    
    for (ALAlertBanner *banner in bannersToPush) {
        if (banner.position == alertBanner.position) {
            [banner pushAlertBanner:alertBanner.frame.size.height forward:YES delay:alertBanner.fadeInDuration];
        }
    }
}

- (void)alertBannerDidShow:(ALAlertBanner *)alertBanner inView:(UIView *)view {
    dispatch_semaphore_t semaphore;
    switch (alertBanner.position) {
        case ALAlertBannerPositionTop:
            semaphore = self.topPositionSemaphore;
            break;
        case ALAlertBannerPositionBottom:
            semaphore = self.bottomPositionSemaphore;
            break;
        case ALAlertBannerPositionUnderNavBar:
            semaphore = self.navBarPositionSemaphore;
            break;
    }
    dispatch_semaphore_signal(semaphore);
}

- (void)alertBannerWillHide:(ALAlertBanner *)alertBanner inView:(UIView *)view {
    NSMutableArray *bannersArray = view.alertBanners;
    NSArray *bannersInSamePosition = [bannersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", alertBanner.position]];
    NSUInteger index = [bannersInSamePosition indexOfObject:alertBanner];
    if (index != NSNotFound && index > 0) {
        NSArray *bannersToPush = [bannersInSamePosition subarrayWithRange:NSMakeRange(0, index)];

        for (ALAlertBanner *banner in bannersToPush)
            [banner pushAlertBanner:-alertBanner.frame.size.height forward:NO delay:0.f];
    }
    
    else if (index == 0) {
        if (bannersInSamePosition.count > 1) {
            ALAlertBanner *nextAlertBanner = (ALAlertBanner *)[bannersInSamePosition objectAtIndex:1];
            [nextAlertBanner setShowShadow:YES];
        }
        
        [alertBanner setShowShadow:NO];
    }
}

- (void)alertBannerDidHide:(ALAlertBanner *)alertBanner inView:(UIView *)view {
    NSMutableArray *bannersArray = view.alertBanners;
    [bannersArray removeObject:alertBanner];
    if (bannersArray.count == 0) {
        [self.bannerViews removeObject:view];
    }
    if (!alertBanner.shouldForceHide) {
        dispatch_semaphore_t semaphore;
        switch (alertBanner.position) {
            case ALAlertBannerPositionTop:
                semaphore = self.topPositionSemaphore;
                break;
            case ALAlertBannerPositionBottom:
                semaphore = self.bottomPositionSemaphore;
                break;
            case ALAlertBannerPositionUnderNavBar:
                semaphore = self.navBarPositionSemaphore;
                break;
        }
        dispatch_semaphore_signal(semaphore);
    }
}

# pragma mark -
# pragma mark Instance Methods

- (NSArray *)alertBannersInView:(UIView *)view {
    return [NSArray arrayWithArray:view.alertBanners];
}

- (void)hideAlertBannersInView:(UIView *)view {
    for (ALAlertBanner *alertBanner in [self alertBannersInView:view]) {
        [self hideAlertBanner:alertBanner forced:NO];
    }
}

- (void)hideAllAlertBanners {
    for (UIView *view in self.bannerViews) {
        [self hideAlertBannersInView:view];
    }
}

- (void)forceHideAllAlertBannersInView:(UIView *)view {
    for (ALAlertBanner *alertBanner in [self alertBannersInView:view]) {
        [self hideAlertBanner:alertBanner forced:YES];
    }
}

# pragma mark -
# pragma mark Private Methods

- (void)didRotate:(NSNotification *)note {    
    for (UIView *view in self.bannerViews) {
        NSArray *topBanners = [view.alertBanners filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", ALAlertBannerPositionTop]];
        CGFloat topYCoord = 0.f;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if (AL_IOS_7_OR_GREATER && topBanners.count > 0) {
            ALAlertBanner *firstBanner = (ALAlertBanner *)[topBanners objectAtIndex:0];
            id nextResponder = [firstBanner nextAvailableViewController:firstBanner];
            if (nextResponder) {
                UIViewController *vc = nextResponder;
                if (!(vc.automaticallyAdjustsScrollViewInsets && [vc.view isKindOfClass:[UIScrollView class]])) {
                    topYCoord += [vc topLayoutGuide].length;
                }
            }
        }
#endif
        for (ALAlertBanner *alertBanner in [topBanners reverseObjectEnumerator]) {
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            [alertBanner updatePositionAfterRotationWithY:topYCoord animated:YES];
            topYCoord += alertBanner.layer.bounds.size.height;
        }
        
        NSArray *bottomBanners = [view.alertBanners filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", ALAlertBannerPositionBottom]];
        CGFloat bottomYCoord = view.bounds.size.height;
        for (ALAlertBanner *alertBanner in [bottomBanners reverseObjectEnumerator]) {
            //update frame size before animating to new position
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            bottomYCoord -= alertBanner.layer.bounds.size.height;
            [alertBanner updatePositionAfterRotationWithY:bottomYCoord animated:YES];
        }
        
        //TODO: rotation for UIWindow
    }
}

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

@end
