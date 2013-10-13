//
//  AppDelegate.m
//  ALAlertBannerDemo
//
//  Created by Anthony Lobianco on 8/14/13.
//  Copyright (c) 2013 Anthony Lobianco. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[ViewController alloc] init]];
    self.window.rootViewController = navigationController;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

+ (NSString *)randomLoremIpsum {
    static int arrayCount = sizeof(loremIpsum) / sizeof(loremIpsum[0]);
    return loremIpsum[arc4random_uniform(arrayCount)];
}

@end
