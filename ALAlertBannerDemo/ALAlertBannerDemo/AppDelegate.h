//
//  AppDelegate.h
//  ALAlertBannerDemo
//
//  Created by Anthony Lobianco on 8/14/13.
//  Copyright (c) 2013 Anthony Lobianco. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *loremIpsum[] = {
    @"Aliquam facilisis gravida ipsum, eu varius lacus lobortis eu. Fusce ac suscipit elit, eu varius tortor. Sed sed vestibulum ante. Integer eu orci eget felis pulvinar scelerisque. Etiam euismod risus ipsum.",
    @"Nunc id dictum enim. Nulla facilisi.",
    @"Mauris fermentum tellus in ligula laoreet accumsan. Nullam felis ipsum, ultrices id lacus a, accumsan tempor sapien hala shishkabob."
};

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (NSString *)randomLoremIpsum;

@end
