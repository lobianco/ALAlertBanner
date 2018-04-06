
#import <Foundation/Foundation.h>

@protocol ALBannerStyleConfigurationProtocol <NSObject>
@property (nonatomic, readonly) UIColor *fillColor;
@property (nonatomic, readonly) UIColor *titleTextColor;
@property (nonatomic, readonly) UIColor *subtitleTextColor;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) CGFloat labelsShadowOpacity;
@property (nonatomic, readonly) NSString *styleString;
@end

@interface ALBannerStyleConfiguration : NSObject <ALBannerStyleConfigurationProtocol>
+ (ALBannerStyleConfiguration *)failureStyleConfiguration;
+ (ALBannerStyleConfiguration *)successStyleConfiguration;
+ (ALBannerStyleConfiguration *)notifyStyleConfiguration;
+ (ALBannerStyleConfiguration *)warningStyleConfiguration;
@end
