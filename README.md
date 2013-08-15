# ALAlertBanner

## About

ALAlertBanner is a drop-in class for iOS (both iPhone and iPad) that presents beautiful alert banners in a customizable and configurable way. 

### Preview

![Preview1](https://raw.github.com/alobi/ALAlertBanner/master/Screenshots/screenshot1.png) ![Preview2](https://raw.github.com/alobi/ALAlertBanner/master/Screenshots/screenshot3.png)

![Preview3](https://raw.github.com/alobi/ALAlertBanner/master/Screenshots/screenshot2.png)

### Behind the Scenes

ALAlertBanner uses [Core Animation](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html) and [Grand Central Dispatch](http://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html) under the hood, making it lightweight and stable. A singleton object is used to manage the presentation and dismissal of the alerts in a synchronous manner. 

## Installation

Installation is easy.

1. Download the ZIP from Github and copy the ALAlertBanner directory to your project
2. Link the ```QuartzCore.framework``` library in your project's Build Phases
3. ```#import "ALAlertBanner.h"``` in your view of choice

If you can compile without errors, congratulations! You're one step closer to... 

(•_•)

( •_•)>⌐■-■ 

(⌐■_■)

*...being cool*.

### Tested Environments

ALAlertBanner has been tested on iOS 5.0 and 5.1 (simulator) and iOS 6.1 (device) with ARC enabled. It should work in older versions/devices, but I'm not positive. 

## Example Usage

You should use the ```ALAlertBannerManager``` singleton object to manage all banners. You can easily present a banner in a regular ```UIView``` like so:

```objc
[[ALAlertBannerManager sharedManager] showAlertBannerInView:self.view 
                                      style:ALAlertBannerStyleSuccess 
                                      position:ALAlertBannerPositionTop 
                                      title:@"Success!"
                                      subtitle:@"Here's a banner. Look how easy that was."];
```

Note that ```subtitle``` may be nil. All other parameters should be used. Also note that you *can* present a banner in the AppDelegate's ```UIWindow``` but it will only work in portrait mode by default (aka no support for autorotation). 

### Other methods of consideration:

```objc
-(void)hideAllAlertBanners;
```

Immediately hide all alert banners.

```objc
-(void)hideAlertBannersInView:(UIView*)view;
```

Immediately hide all alert banners within a specific view.

### Properties

***Note:*** ALL properties should be set through ```ALAlertBannerManager``` like so:

```objc
[[ALAlertBannerManager sharedManager] setProperty:0.f];
```

***End Note***

---

```ALAlertBannerManager``` has the following editable properties:

```objc
@property (nonatomic) NSTimeInterval secondsToShow;
```

The length of time a banner should appear on-screen before auto-hiding. The default value is 3.5 seconds. A value <= 0 will disable auto-hiding. 

```objc
@property (nonatomic) NSTimeInterval showAnimationDuration;
```

The duration a banner should take when animating on-screen. Default value is 0.25 seconds.

```objc
@property (nonatomic) NSTimeInterval hideAnimationDuration;
```

The duration a banner should take when animating off-screen. Default value is 0.2 seconds.

```objc
@property (nonatomic, assign) BOOL allowTapToDismiss;
```

Should the banner dismiss prematurely if tapped? Default value is YES.


### Banner Positions

```objc
ALAlertBannerPositionTop = 0
```

The banner will be extend down from the top of the screen. If you're presenting it in a ```UIView``` within a ```UINavigationController```, that means the banner will extend down from underneath the navigation bar. If you're presenting it in the AppDelegate's main ```UIWindow```, then it should extend down from underneath the status bar (above any other UI elements, like the nav bar for instance). 

```objc
ALAlertBannerPositionBottom
```

The banner will be extend up from the bottom of the screen. 

```objc
ALAlertBannerPositionUnderNavBar
```

This position should **ONLY** be used if presenting on the AppDelegate's main ```UIWindow```. It will cause an effect similar to ```ALAlertBannerPositionTop``` in a ```UIView``` (i.e. extending down from underneath the navigation bar), but it will in fact be above all other displaying ```UIView```s. It accomplishes this by using a ```CALayer``` mask to create the illusion of animating from behind the navigation bar. 

### Banner Types

```objc
ALAlertBannerStyleSuccess = 0
```

The banner will have a cute little checkmark and a nice green gradient.

```objc
ALAlertBannerStyleFailure
```

The banner will have a cute little X and a nice red gradient.

```objc
ALAlertBannerStyleNotify
```

The banner will have a cute little info symbol and a nice blue gradient.

```objc
ALAlertBannerStyleAlert
```

The banner will have a cute little caution triangle and a nice yellow gradient.

Did I mention they have cute little shapes and nice colorful gradients?

## Known Issues

* ALAlertBanner supports all interface orientations. However, if you rotate the device while one or more banners is displaying (or animating), the layout will get fudgesicled. This is just something I haven't figured out how to fix yet. 
* If you find any other bugs, please open a new issue. 

## Contact Me

Github: [alobi](https://github.com/alobi)
Twitter: [@lobi4nco](https://twitter.com/lobi4nco)
Email: [anthony@lobian.co](mailto:anthony@lobian.co)

## Credits & License

Feel free to give me a shoutout on Twitter to let me know how you like it. I'd love to hear your thoughts. 

ALAlertBanner is developed and maintained by Anthony Lobianco ([@lobi4nco](https://twitter.com/lobi4nco)). Licensed under the MIT License. Basically, I would appreciate attribution if you use it.

Enjoy!

(⌐■_■)