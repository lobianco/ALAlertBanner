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
@property (nonatomic, strong) NSMutableArray *topBanners;
@property (nonatomic, strong) NSMutableArray *bottomBanners;
@property (nonatomic, strong) NSMutableArray *navBarBanners;
@end

@implementation UIView (Convenience)
@dynamic topBanners, bottomBanners, navBarBanners;
-(void)setTopBanners:(NSMutableArray *)topBanners
{
    objc_setAssociatedObject(self, @selector(topBanners), topBanners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSMutableArray *)topBanners
{
    NSMutableArray *topBannersArray = objc_getAssociatedObject(self, @selector(topBanners));
    if (topBannersArray == nil)
    {
        topBannersArray = [NSMutableArray new];
        [self setTopBanners:topBannersArray];
    }
    return topBannersArray;
}
-(void)setBottomBanners:(NSMutableArray *)bottomBanners
{
    objc_setAssociatedObject(self, @selector(bottomBanners), bottomBanners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSMutableArray *)bottomBanners
{
    NSMutableArray *bottomBannersArray = objc_getAssociatedObject(self, @selector(bottomBanners));
    if (bottomBannersArray == nil)
    {
        bottomBannersArray = [NSMutableArray new];
        [self setBottomBanners:bottomBannersArray];
    }
    return bottomBannersArray;
}
-(void)setNavBarBanners:(NSMutableArray *)navBarBanners
{
    objc_setAssociatedObject(self, @selector(navBarBanners), navBarBanners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSMutableArray *)navBarBanners
{
    NSMutableArray *navBarBannersArray = objc_getAssociatedObject(self, @selector(navBarBanners));
    if (navBarBannersArray == nil)
    {
        navBarBannersArray = [NSMutableArray new];
        [self setNavBarBanners:navBarBannersArray];
    }
    return navBarBannersArray;
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
        
        //TODO
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
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
    alertBanner.isScheduledToHide = NO;
    
    //keep track of all views we've added banners to, to deal with rotation events and hideAllAlertBanners
    if (![self.bannerViews containsObject:view])
        [self.bannerViews addObject:view];
    
    [self showAlertBanner:alertBanner];
}

-(void)showAlertBanner:(ALAlertBannerView*)alertBanner
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
            
            if (self.secondsToShow > 0)
                [self performSelector:@selector(hideAlertBanner:) withObject:alertBanner afterDelay:self.secondsToShow];
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
    NSMutableArray *activeArray;
    switch (alertBanner.position) {
        case ALAlertBannerPositionTop:
            activeArray = view.topBanners;
            break;
        case ALAlertBannerPositionBottom:
            activeArray = view.bottomBanners;
            break;
        case ALAlertBannerPositionUnderNavBar:
            activeArray = view.navBarBanners;
            break;
    }
    for (ALAlertBannerView *banner in activeArray)
        if (banner.position == alertBanner.position)
            [banner push:alertBanner.frame.size.height forward:YES];
    
    [activeArray addObject:alertBanner];
    alertBanner.shadowOpacity = (activeArray.count > 1 ? 0.f : 0.65f);
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
    NSMutableArray *activeArray;
    switch (alertBanner.position) {
        case ALAlertBannerPositionTop:
            activeArray = view.topBanners;
            break;
        case ALAlertBannerPositionBottom:
            activeArray = view.bottomBanners;
            break;
        case ALAlertBannerPositionUnderNavBar:
            activeArray = view.navBarBanners;
            break;
    }
    NSUInteger index = [activeArray indexOfObject:alertBanner];
    if (index != NSNotFound && index > 0)
    {
        NSArray *bannersToPush = [activeArray subarrayWithRange:NSMakeRange(0, index)];
        for (ALAlertBannerView *banner in bannersToPush)
            if (banner.position == alertBanner.position)
                [banner push:-alertBanner.frame.size.height forward:NO];
    }
    
    else if (index == 0)
    {
        if (activeArray.count > 1)
        {
            ALAlertBannerView *nextAlertBanner = (ALAlertBannerView*)[activeArray objectAtIndex:1];
            [nextAlertBanner setShadowOpacity:0.65f];
        }
        
        [alertBanner setShadowOpacity:0.f];
    }
}

-(void)alertBannerDidHide:(ALAlertBannerView *)alertBanner inView:(UIView *)view
{
    NSMutableArray *activeArray;
    dispatch_semaphore_t semaphore;
    switch (alertBanner.position) {
        case ALAlertBannerPositionTop:
            activeArray = view.topBanners;
            semaphore = self.topPositionSemaphore;
            break;
        case ALAlertBannerPositionBottom:
            activeArray = view.bottomBanners;
            semaphore = self.bottomPositionSemaphore;
            break;
        case ALAlertBannerPositionUnderNavBar:
            activeArray = view.navBarBanners;
            semaphore = self.navBarPositionSemaphore;
            break;
    }
    [activeArray removeObject:alertBanner];
    
    dispatch_semaphore_signal(semaphore);
}

# pragma mark -
# pragma mark Instance Methods

-(NSArray *)alertBannersInView:(UIView *)view
{
    NSMutableArray *arrayOfBanners = [[NSMutableArray alloc] init];
    for (UIView *subview in view.subviews)
        if ([subview isKindOfClass:[ALAlertBannerView class]])
            [arrayOfBanners addObject:(ALAlertBannerView*)subview];
    
    return [NSArray arrayWithArray:arrayOfBanners];
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
        CGFloat topYCoord = 0.f;
        for (ALAlertBannerView *alertBanner in [view.topBanners reverseObjectEnumerator])
        {
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            [alertBanner updatePositionAfterRotationWithY:topYCoord animated:YES];
            topYCoord += alertBanner.layer.bounds.size.height;
        }
        
        CGFloat bottomYCoord = view.bounds.size.height;
        for (ALAlertBannerView *alertBanner in [view.bottomBanners reverseObjectEnumerator])
        {
            //update frame size before animating to new position
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            bottomYCoord -= alertBanner.layer.bounds.size.height;
            [alertBanner updatePositionAfterRotationWithY:bottomYCoord animated:YES];
        }
    }
}

-(void)dealloc
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

@end
