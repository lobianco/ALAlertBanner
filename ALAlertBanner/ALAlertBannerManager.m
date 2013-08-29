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

# pragma mark -
# pragma mark Categories for Convenience

@interface UIView (Convenience)
@property (nonatomic, strong) NSMutableArray *alertBanners;
@end

@implementation UIView (Convenience)
@dynamic alertBanners;
-(void)setAlertBanners:(NSMutableArray *)alertBanners
{
    objc_setAssociatedObject(self, @selector(alertBanners), alertBanners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSMutableArray *)alertBanners
{
    NSMutableArray *alertBannersArray = objc_getAssociatedObject(self, @selector(alertBanners));
    if (alertBannersArray == nil)
    {
        alertBannersArray = [NSMutableArray new];
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

-(void)didRotate:(NSNotification *)note;

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
        _topPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_topPositionSemaphore);
        _bottomPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_bottomPositionSemaphore);
        _navBarPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_navBarPositionSemaphore);
        
        _bannerViews = [NSMutableArray new];
        
        _secondsToShow = 3.5f;
        _showAnimationDuration = 0.25f;
        _hideAnimationDuration = 0.2f;
        _allowTapToDismiss = YES;
        _bannerOpacity = 0.93f;
        
        //TODO
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

-(void)showAlertBannerInView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title
{
    [self showAlertBannerInView:view style:style position:position title:title subtitle:nil hideAfter:self.secondsToShow tappedHandler:nil];
}

-(void)showAlertBannerInView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle
{
    [self showAlertBannerInView:view style:style position:position title:title subtitle:subtitle hideAfter:self.secondsToShow tappedHandler:nil];
}

-(void)showAlertBannerInView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle hideAfter:(NSTimeInterval)secondsToShow
{
    [self showAlertBannerInView:view style:style position:position title:title subtitle:subtitle hideAfter:secondsToShow tappedHandler:nil];
}

-(void)showAlertBannerInView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle tappedHandler:(void (^)(ALAlertBannerView *))tappedBlock
{
    [self showAlertBannerInView:view style:style position:position title:title subtitle:subtitle hideAfter:self.secondsToShow tappedHandler:tappedBlock];
}

-(void)showAlertBannerInView:(UIView *)view style:(ALAlertBannerStyle)style position:(ALAlertBannerPosition)position title:(NSString *)title subtitle:(NSString *)subtitle hideAfter:(NSTimeInterval)secondsToShow tappedHandler:(void (^)(ALAlertBannerView *))tappedBlock
{    
    ALAlertBannerView *alertBanner = [ALAlertBannerView alertBannerForView:view style:style position:position title:title subtitle:subtitle];
    alertBanner.delegate = self;
    alertBanner.tag = arc4random_uniform(SHRT_MAX);
    alertBanner.showAnimationDuration = self.showAnimationDuration;
    alertBanner.hideAnimationDuration = self.hideAnimationDuration;
    alertBanner.allowTapToDismiss = tappedBlock ? NO : self.allowTapToDismiss;
    alertBanner.isScheduledToHide = NO;
    alertBanner.bannerOpacity = self.bannerOpacity;
    alertBanner.tappedBlock = tappedBlock;
    
    //keep track of all views we've added banners to, to deal with rotation events and hideAllAlertBanners
    if (![self.bannerViews containsObject:view])
        [self.bannerViews addObject:view];
    
    [self showAlertBanner:alertBanner hideAfter:secondsToShow];
}

-(void)showAlertBanner:(ALAlertBannerView*)alertBanner hideAfter:(NSTimeInterval)delay
{
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
            [alertBanner show];
            
            if (delay > 0)
                [self performSelector:@selector(hideAlertBanner:) withObject:alertBanner afterDelay:delay];
        });
    });
}

# pragma mark -
# pragma mark Delegate Methods

-(void)hideAlertBanner:(ALAlertBannerView *)alertBanner
{
    if (alertBanner.isScheduledToHide)
        return;
    
    [NSOperation cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAlertBanner:) object:alertBanner];
    
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
            [alertBanner hide];
        });
    });
}

-(void)alertBannerWillShow:(ALAlertBannerView *)alertBanner inView:(UIView*)view
{
    //make copy so we can set shadow before pushing banners
    NSArray *bannersToPush = [NSArray arrayWithArray:view.alertBanners];
    NSMutableArray *bannersArray = view.alertBanners;
    
    [bannersArray addObject:alertBanner];
    NSArray *bannersInSamePosition = [bannersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", alertBanner.position]];
    
    //set shadow before pushing other banners, because the banner push may be delayed by the fade in duration (which is set at the same time as the shadow) on iOS7
    
    if (AL_IOS_7_OR_GREATER) {
        alertBanner.showShadow = NO;
    } else {
        alertBanner.showShadow = (bannersInSamePosition.count > 1 ? NO : YES);
    }
    
    for (ALAlertBannerView *banner in bannersToPush)
        if (banner.position == alertBanner.position)
            [banner push:alertBanner.frame.size.height forward:YES delay:alertBanner.fadeInDuration];
}

-(void)alertBannerDidShow:(ALAlertBannerView *)alertBanner inView:(UIView *)view
{
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

-(void)alertBannerWillHide:(ALAlertBannerView *)alertBanner inView:(UIView *)view
{
    NSMutableArray *bannersArray = view.alertBanners;
    NSArray *bannersInSamePosition = [bannersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", alertBanner.position]];
    NSUInteger index = [bannersInSamePosition indexOfObject:alertBanner];
    if (index != NSNotFound && index > 0)
    {
        NSArray *bannersToPush = [bannersInSamePosition subarrayWithRange:NSMakeRange(0, index)];

        for (ALAlertBannerView *banner in bannersToPush)
            [banner push:-alertBanner.frame.size.height forward:NO delay:0.f];
    }
    
    else if (index == 0)
    {
        if (bannersInSamePosition.count > 1)
        {
            ALAlertBannerView *nextAlertBanner = (ALAlertBannerView*)[bannersInSamePosition objectAtIndex:1];
            if (!AL_IOS_7_OR_GREATER) {
                [nextAlertBanner setShowShadow:YES];
            } else {
                [nextAlertBanner setShowShadow:NO];
            }
        }
        
        [alertBanner setShowShadow:NO];
    }
}

-(void)alertBannerDidHide:(ALAlertBannerView *)alertBanner inView:(UIView *)view
{
    NSMutableArray *bannersArray = view.alertBanners;
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
    [bannersArray removeObject:alertBanner];
    dispatch_semaphore_signal(semaphore);
}

# pragma mark -
# pragma mark Instance Methods

-(NSArray *)alertBannersInView:(UIView *)view
{
    /*
    NSMutableArray *arrayOfBanners = [[NSMutableArray alloc] init];
    for (UIView *subview in view.subviews)
        if ([subview isKindOfClass:[ALAlertBannerView class]])
            [arrayOfBanners addObject:(ALAlertBannerView*)subview];
     */
    
    return [NSArray arrayWithArray:view.alertBanners];
}

-(void)hideAlertBannersInView:(UIView *)view
{
    for (ALAlertBannerView *alertBanner in [self alertBannersInView:view])
        [self hideAlertBanner:alertBanner];
}

-(void)hideAllAlertBanners
{
    for (UIView *view in self.bannerViews)
        [self hideAlertBannersInView:view];
}

# pragma mark -
# pragma mark Private Methods

-(void)didRotate:(NSNotification *)note
{    
    for (UIView *view in self.bannerViews)
    {
        NSArray *topBanners = [view.alertBanners filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", ALAlertBannerPositionTop]];
        CGFloat topYCoord = 0.f;
        if (AL_IOS_7_OR_GREATER)
            topYCoord += [UIApplication navigationBarHeight] + kStatusBarHeight;
        for (ALAlertBannerView *alertBanner in [topBanners reverseObjectEnumerator])
        {
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            [alertBanner updatePositionAfterRotationWithY:topYCoord animated:YES];
            topYCoord += alertBanner.layer.bounds.size.height;
        }
        
        NSArray *bottomBanners = [view.alertBanners filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", ALAlertBannerPositionBottom]];
        CGFloat bottomYCoord = view.bounds.size.height;
        for (ALAlertBannerView *alertBanner in [bottomBanners reverseObjectEnumerator])
        {
            //update frame size before animating to new position
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            bottomYCoord -= alertBanner.layer.bounds.size.height;
            [alertBanner updatePositionAfterRotationWithY:bottomYCoord animated:YES];
        }
        
        //TODO rotation for UIWindow
    }
}

-(void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

@end
