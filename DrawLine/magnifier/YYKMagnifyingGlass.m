//
//  YYKMagnifyingGlass.m
//  DrawLine
//
//  Created by yyk on 2017/11/8.
//  Copyright © 2017年 杨亚坤. All rights reserved.
//

#import "YYKMagnifyingGlass.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const kACMagnifyingGlassDefaultRadius = 40;
static CGFloat const kACMagnifyingGlassDefaultOffset = -100;
static CGFloat const kACMagnifyingGlassDefaultScale = 1;

@interface YYKMagnifyingGlass ()

@end

@implementation YYKMagnifyingGlass

@synthesize viewToMagnify, touchPoint, touchPointOffset, scale, scaleAtTouchPoint;

- (id)init {
    self = [self initWithFrame:CGRectMake(0, 0, kACMagnifyingGlassDefaultRadius*2, kACMagnifyingGlassDefaultRadius*2)];
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        self.layer.borderColor = [[UIColor grayColor] CGColor];
        self.layer.borderWidth = 10;
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        self.touchPointOffset = CGPointMake(0, kACMagnifyingGlassDefaultOffset);
        self.scale = kACMagnifyingGlassDefaultScale;
        self.viewToMagnify = nil;
        self.scaleAtTouchPoint = YES;
    }
    return self;
}

- (void)setFrame:(CGRect)f {
    super.frame = f;
    self.layer.cornerRadius = f.size.width / 2;
}

- (void)setTouchPoint:(CGPoint)point {
    touchPoint = point;
    self.center = CGPointMake(point.x + touchPointOffset.x, point.y + touchPointOffset.y);
}




- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, self.frame.size.width/2, self.frame.size.height/2 );
    CGContextScaleCTM(context, scale, scale);
    CGContextTranslateCTM(context, -touchPoint.x, -touchPoint.y + (self.scaleAtTouchPoint? 0 : self.bounds.size.height/2));
    [self.viewToMagnify.layer renderInContext:context];
}


@end
