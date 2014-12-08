//
//  ALAlertWindow.m
//  ALAlertBannerDemo
//
//  Created by Matthew Ryan on 8/12/2014.
//  Copyright (c) 2014 Anthony Lobianco. All rights reserved.
//

#import "ALAlertWindow.h"

@implementation ALAlertWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    __block BOOL inside = NO;

    [self.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        CGPoint mediatedPoint = CGPointMake(point.x, point.y - subview.frame.origin.y);
        inside = [subview pointInside:mediatedPoint withEvent:event];
        if (inside) {
            *stop = YES;
        }
    }];

    return inside;
}

@end
