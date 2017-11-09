//
//  YYKMagnifyingGlass.h
//  DrawLine
//
//  Created by yyk on 2017/11/8.
//  Copyright © 2017年 杨亚坤. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YYKMagnifyingGlass : UIView

@property (nonatomic, retain) UIView *viewToMagnify;
@property (nonatomic, assign) CGPoint touchPoint;
@property (nonatomic, assign) CGPoint touchPointOffset;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) BOOL scaleAtTouchPoint;

@end
