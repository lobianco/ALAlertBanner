//
//  JALabel.m
//  JALabel
//
//  Created by Josh Adams on 5/1/13.
//  Copyright (c) 2013 Josh Adams. All rights reserved.
//

#import "JALabel.h"

@implementation JALabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect
{
    CGSize labelStringSize = [self.text sizeWithFont:self.font
                                   constrainedToSize:CGSizeMake(self.frame.size.width, 9999)
                                       lineBreakMode:self.lineBreakMode];

    [super drawTextInRect:CGRectMake(0, 0, self.frame.size.width, labelStringSize.height)];
}

@end
