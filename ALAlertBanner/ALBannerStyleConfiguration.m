
#import "ALBannerStyleConfiguration.h"

@interface ALBannerStyleConfiguration ()
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *titleTextColor;
@property (nonatomic, strong) UIColor *subtitleTextColor;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGFloat labelsShadowOpacity;
@property (nonatomic, strong) NSString *styleString;
@end

@implementation ALBannerStyleConfiguration

+ (ALBannerStyleConfiguration *)failureStyleConfiguration {
    static ALBannerStyleConfiguration *failureConfiguration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        failureConfiguration = [[ALBannerStyleConfiguration alloc] init];
        failureConfiguration.fillColor = [UIColor colorWithRed:(173/255.0) green:(48/255.0) blue:(48/255.0) alpha:1.f];
        failureConfiguration.titleTextColor = [UIColor colorWithWhite:1.f alpha:0.9f];
        failureConfiguration.subtitleTextColor = [UIColor colorWithWhite:1.f alpha:0.9f];
        failureConfiguration.image = [UIImage imageNamed:@"bannerFailure.png"];
        failureConfiguration.labelsShadowOpacity = 0.3;
        failureConfiguration.styleString = @"ALAlertBannerStyleFailure";
    });
    return failureConfiguration;
}

+ (ALBannerStyleConfiguration *)successStyleConfiguration {
    static ALBannerStyleConfiguration *successConfiguration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        successConfiguration = [[ALBannerStyleConfiguration alloc] init];
        successConfiguration.fillColor = [UIColor colorWithRed:(77/255.0) green:(175/255.0) blue:(67/255.0) alpha:1.f];
        successConfiguration.titleTextColor = [UIColor colorWithWhite:1.f alpha:0.9f];
        successConfiguration.subtitleTextColor = [UIColor colorWithWhite:1.f alpha:0.9f];
        successConfiguration.image = [UIImage imageNamed:@"bannerSuccess.png"];
        successConfiguration.labelsShadowOpacity = 0.3;
        successConfiguration.styleString = @"ALAlertBannerStyleSuccess";
    });
    return successConfiguration;
}

+ (ALBannerStyleConfiguration *)notifyStyleConfiguration {
    static ALBannerStyleConfiguration *notifyConfiguration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        notifyConfiguration = [[ALBannerStyleConfiguration alloc] init];
        notifyConfiguration.fillColor = [UIColor colorWithRed:(48/255.0) green:(110/255.0) blue:(173/255.0) alpha:1.f];
        notifyConfiguration.titleTextColor = [UIColor colorWithWhite:1.f alpha:0.9f];
        notifyConfiguration.subtitleTextColor = [UIColor colorWithWhite:1.f alpha:0.9f];
        notifyConfiguration.image = [UIImage imageNamed:@"bannerNotify.png"];
        notifyConfiguration.labelsShadowOpacity = 0.3;
        notifyConfiguration.styleString = @"ALAlertBannerStyleNotify";
    });
    return notifyConfiguration;
}

+ (ALBannerStyleConfiguration *)warningStyleConfiguration {
    static ALBannerStyleConfiguration *warningConfiguration;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        warningConfiguration = [[ALBannerStyleConfiguration alloc] init];
        warningConfiguration.fillColor = [UIColor colorWithRed:(211/255.0) green:(209/255.0) blue:(100/255.0) alpha:1.f];
        warningConfiguration.titleTextColor = [UIColor colorWithWhite:1.f alpha:0.9f];
        warningConfiguration.subtitleTextColor = [UIColor colorWithWhite:1.f alpha:0.9f];
        warningConfiguration.image = [UIImage imageNamed:@"bannerAlert.png"];
        warningConfiguration.labelsShadowOpacity = 0.2;
        warningConfiguration.styleString = @"ALAlertBannerStyleWarning";
    });
    return warningConfiguration;
}

@end
