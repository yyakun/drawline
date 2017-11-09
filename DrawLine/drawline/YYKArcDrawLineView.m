//
//  YYKArcDrawLineView.m
//  DrawLine
//
//  Created by yyk on 2017/11/9.
//  Copyright © 2017年 杨亚坤. All rights reserved.
//

#import "YYKArcDrawLineView.h"
#import "YYKMagnifyingGlass.h"
#import "YYKLoupe.h"
#define DebugMode 0
#define TitleViewTag 100
@interface YYKArcDrawLineView () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint endPoint;

@property (nonatomic, assign) CGFloat editRadius;
@property (nonatomic, assign) CGFloat titleBottomSpace;

//编辑状态时展现
@property (nonatomic, strong) UIImageView *leftImageView;
@property (nonatomic, strong) UIImageView *rightImageView;
@property (nonatomic, strong) CAShapeLayer *drawDashLineLayer;


@property (nonatomic, assign) CGPoint originalTranslation;
@property (nonatomic, assign) CGAffineTransform originalTransform;

// only used on unarchive
@property (nonatomic, assign) CGPoint originalAnchorPoint;

// 放大镜
@property (nonatomic, retain) NSTimer *touchTimer;
@property (nonatomic, strong) YYKMagnifyingGlass *magnifyingGlass;
@property (nonatomic, assign) CGFloat magnifyingGlassShowDelay;

@end


@implementation YYKArcDrawLineView

@synthesize title = _title;
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _lineAlpha = 1.0f;
        _lineWidth = 1.0f;
        _lineColor = [UIColor yellowColor];
        _arrowAngle = M_PI/8;
        _arrowLength = 8;
        
        _startPoint = CGPointZero;
        _endPoint = CGPointZero;
        _editRadius = 35;
        
        self.userInteractionEnabled = YES;
        
#if DebugMode
        self.backgroundColor = [UIColor colorWithRed:(arc4random()%100)/100.0 green:(arc4random()%100)/100.0 blue:(arc4random()%100)/100.0 alpha:0.9f];
#else
        self.backgroundColor = [UIColor clearColor];
#endif
        
        _titleBottomSpace = 0.5f;
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.tag = TitleViewTag;
        _titleLabel.numberOfLines = 1;
        _titleLabel.textColor = _lineColor;
        _titleLabel.font = [UIFont systemFontOfSize:13];
        _titleLabel.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        [self addSubview:_titleLabel];
        [_titleLabel sizeToFit];
        
        // Gesture
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];
        _tapGesture = tap;
        
        UIPanGestureRecognizer *move = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovePan:)];
        [self addGestureRecognizer:move];
        move.delegate = self;
        _moveGesture = move;
        
        UIPanGestureRecognizer *scale = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleScalePan:)];
        [self addGestureRecognizer:scale];
        scale.delegate = self;
        _scaleGesture = scale;
        
        // 放大镜
        self.magnifyingGlassShowDelay = 0.0f;
        YYKLoupe *loupe = [[YYKLoupe alloc] init];
        self.magnifyingGlass = loupe;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        _lineColor = [aDecoder decodeObjectForKey:@"_lineColor"];
        _lineAlpha = [aDecoder decodeDoubleForKey:@"_lineAlpha"];
        _lineWidth = [aDecoder decodeDoubleForKey:@"_lineWidth"];
        _arrowAngle = [aDecoder decodeDoubleForKey:@"_arrowAngle"];
        _arrowLength = [aDecoder decodeDoubleForKey:@"_arrowLength"];
        _translation = [aDecoder decodeCGPointForKey:@"_translation"];
        _startPoint = [aDecoder decodeCGPointForKey:@"_startPoint"];
        _endPoint = [aDecoder decodeCGPointForKey:@"_endPoint"];
        _editRadius = [aDecoder decodeDoubleForKey:@"_editRadius"];
        _titleBottomSpace = [aDecoder decodeDoubleForKey:@"_titleBottomSpace"];
        _originalTranslation = [aDecoder decodeCGPointForKey:@"_originalTranslation"];
        _originalTransform = [aDecoder decodeCGAffineTransformForKey:@"_originalTransform"];
        _originalAnchorPoint = [aDecoder decodeCGPointForKey:@"_originalAnchorPoint"];
        
        
        self.layer.anchorPoint = _originalAnchorPoint;
        _titleLabel = (UILabel *)[self viewWithTag:TitleViewTag];
        _titleLabel.layer.anchorPoint = [aDecoder decodeCGPointForKey:@"_titleLabelAnchorPoint"];
        [_titleLabel sizeToFit];
        
        // Gesture
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];
        _tapGesture = tap;
        
        UIPanGestureRecognizer *move = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMovePan:)];
        [self addGestureRecognizer:move];
        move.delegate = self;
        _moveGesture = move;
        
        UIPanGestureRecognizer *scale = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleScalePan:)];
        [self addGestureRecognizer:scale];
        scale.delegate = self;
        _scaleGesture = scale;
        
        // 放大镜
        self.magnifyingGlassShowDelay = 0.0f;
        YYKLoupe *loupe = [[YYKLoupe alloc] init];
        self.magnifyingGlass = loupe;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.lineColor forKey:@"_lineColor"];
    [aCoder encodeDouble:self.lineAlpha forKey:@"_lineAlpha"];
    [aCoder encodeDouble:self.lineWidth forKey:@"_lineWidth"];
    [aCoder encodeDouble:self.arrowAngle forKey:@"_arrowAngle"];
    [aCoder encodeDouble:self.arrowLength forKey:@"_arrowLength"];
    
    [aCoder encodeCGPoint:self.startPoint forKey:@"_startPoint"];
    [aCoder encodeCGPoint:self.endPoint forKey:@"_endPoint"];
    [aCoder encodeDouble:self.editRadius forKey:@"_editRadius"];
    [aCoder encodeDouble:self.titleBottomSpace forKey:@"_titleBottomSpace"];
    
    [aCoder encodeCGPoint:self.translation forKey:@"_translation"];
    [aCoder encodeCGPoint:self.originalTranslation forKey:@"_originalTranslation"];
    [aCoder encodeCGAffineTransform:self.originalTransform forKey:@"_originalTransform"];
    [aCoder encodeCGPoint:self.layer.anchorPoint forKey:@"_originalAnchorPoint"];
    [aCoder encodeCGPoint:self.titleLabel.layer.anchorPoint forKey:@"_titleLabelAnchorPoint"];
    
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if([self isInDragArea:point]) {
        return self;
    }
    
    if([self isInEditArea:point]) {
        return self;
    }
    
    return nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _titleLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2-CGRectGetHeight(_titleLabel.bounds)/2-_titleBottomSpace);
    
    
    CGFloat currentRoateAngle = ABS(atan2(self.transform.b, self.transform.a));
    self.currentRoate_Angle = currentRoateAngle;
}

- (NSString *)title {
    return self.titleLabel.text;
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
}

-(void)setchangeLineColor:(UIColor *)color
{
    if (color)
    {
        _lineColor = color;
        _titleLabel.textColor = color;
    }
    else
    {
        _lineColor = [UIColor yellowColor];
        _titleLabel.textColor = _lineColor;
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGPoint startPoint = CGPointMake(0, CGRectGetMaxY(rect)/2);
    CGPoint endPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)/2);
    
    _startPoint = startPoint;
    _endPoint = endPoint;
    
    // arrow
    //
    //
    // LEFT:    .up                  RIGHT:  up.
    //         /.1                             2.\
    //       a/__________________________________\b
    //        \ .3                             4./
    //         \                                /
    //          .down                      down.
    //
    //
    CGFloat arrowAngle = _arrowAngle;
    CGFloat arrowLength = _arrowLength;
    
    CGFloat leftArrow_down_x = arrowLength*cos(arrowAngle);
    CGFloat leftArrow_down_y = CGRectGetMaxY(rect)/2+arrowLength*sin(arrowAngle);
    
    CGFloat leftArrow_up_x = leftArrow_down_x;
    CGFloat leftArrow_up_y = CGRectGetMaxY(rect)/2-arrowLength*sin(arrowAngle);
    
    CGFloat rightArrow_up_x = CGRectGetMaxX(rect)-leftArrow_up_x;
    CGFloat rightArrow_up_y = leftArrow_up_y;
    
    CGFloat rightArrow_down_x = rightArrow_up_x;
    CGFloat rightArrow_down_y = leftArrow_down_y;
    
    //1
    CGFloat leftFirstLine_x = leftArrow_up_x;
    CGFloat leftFirstLine_y = CGRectGetMaxY(rect)/2-(arrowLength/3.5)*sin(arrowAngle);
    
    //3
    CGFloat leftSecondLine_x = leftArrow_up_x;
    CGFloat leftSecondLine_y = CGRectGetMaxY(rect)/2+(arrowLength/3.5)*sin(arrowAngle);
    
    //2
    CGFloat rightFirstLine_x = rightArrow_up_x;
    CGFloat rightFirstLine_y = leftFirstLine_y;
    
    //4
    CGFloat rightSecondLine_x = rightArrow_up_x;
    CGFloat rightSecondLine_y = leftSecondLine_y;
    
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.editLineStatusType  == YYKEditLineStatusTypeNOEdit)
    {
        UIColor *clearColor1 = [UIColor clearColor];
        CGContextSetStrokeColorWithColor(context, clearColor1.CGColor);
        
    }
    else
    {
        NSMutableString *str = [[NSMutableString alloc]initWithString:@"#ffa500"];
        UIColor *editLineColor = [self getColor:str];
        CGContextSetStrokeColorWithColor(context, editLineColor.CGColor);
    }
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, self.lineWidth);
    CGContextSetAlpha(context, self.lineAlpha);
    
    
    //a-up
    CGPathMoveToPoint(path, NULL,startPoint.x, startPoint.y);
    CGPathAddLineToPoint(path, NULL, leftArrow_up_x, leftArrow_up_y);
    //up-1
    CGPathAddLineToPoint(path, NULL,  leftFirstLine_x, leftFirstLine_y);
    //1-2
    CGPathAddLineToPoint(path, NULL,  rightFirstLine_x, rightFirstLine_y);
    //2-right-up
    CGPathAddLineToPoint(path, NULL,  rightArrow_up_x, rightArrow_up_y);
    //up- b
    CGPathAddLineToPoint(path, NULL,  endPoint.x, endPoint.y);
    //b-down
    CGPathAddLineToPoint(path, NULL,  rightArrow_down_x, rightArrow_down_y);
    //down-4
    CGPathAddLineToPoint(path, NULL,  rightSecondLine_x, rightSecondLine_y);
    //4-3
    CGPathAddLineToPoint(path, NULL,  leftSecondLine_x , leftSecondLine_y);
    //3-left-down
    CGPathAddLineToPoint(path, NULL,  leftArrow_down_x, leftArrow_down_y);
    //down-a
    CGPathAddLineToPoint(path, NULL,  startPoint.x, startPoint.y);
    
    
#if DebugMode
    
    CGPathRef startEditRect = CGPathCreateWithRect([self leftEditArea], &CGAffineTransformIdentity);
    CGContextAddPath(context, startEditRect);
    CGPathRelease(startEditRect);
    
    CGPathRef endEditRect = CGPathCreateWithRect([self rightEditArea], &CGAffineTransformIdentity);
    CGContextAddPath(context, endEditRect);
    CGPathRelease(endEditRect);
#endif
    
    CGContextAddPath(context, path);
    CGContextSetFillColorWithColor(context, _lineColor.CGColor);
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)scaleWithTranslation:(CGPoint)translation andTouchPoint:(CGPoint)touchPoint {
    [self setAnchorPoint:CGPointMake(0, 0.5)];
    
    CGFloat rotateAngle = atan2(translation.y, translation.x);
    self.transform = CGAffineTransformRotate(CGAffineTransformIdentity, rotateAngle);
    
    CGFloat lenth = sqrt(ABS(translation.x)*ABS(translation.x)+ABS(translation.y)*ABS(translation.y));
    self.bounds = CGRectMake(0, 0, lenth, _editRadius);
    self.translation = translation;
    [self setNeedsDisplay];
}

#pragma mark - Gesture

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint touchPoint = [gestureRecognizer locationInView:self];
    
    if(gestureRecognizer == _tapGesture) {
        return YES;
    }
    
    if(gestureRecognizer == _moveGesture) {
        return [self isInDragArea:touchPoint];
    }
    
    if(gestureRecognizer == _scaleGesture) {
        return [self isInEditArea:touchPoint];
    }
    
    return NO;
}

- (void)handleTap:(UIGestureRecognizer *)gesture
{
    [self.superview bringSubviewToFront:gesture.view];
    
    for (YYKArcDrawLineView *itemView in self.superview.subviews)
    {
        if (itemView != self)
        {
            itemView.editLineStatusType = YYKEditLineStatusTypeNOEdit;
            [itemView setNeedsDisplay];
        }
        else
        {
            itemView.editLineStatusType = YYKEditLineStatusTypeEditing;
            [itemView setNeedsDisplay];
        }
    }
    
    
}

- (void)handleMovePan:(UIPanGestureRecognizer *)gesture
{
    if (self.editLineStatusType == YYKEditLineStatusTypeNOEdit)
    {
        return;
    }
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan: {
            [self.superview bringSubviewToFront:gesture.view];
            _originalTransform = self.transform;
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [gesture translationInView:self.superview];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(_originalTransform.tx+translation.x, _originalTransform.ty+translation.y);
            transform = CGAffineTransformRotate(transform, atan2(_originalTransform.b, _originalTransform.a));
            self.transform = transform;
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            _originalTransform = CGAffineTransformIdentity;
            break;
        }
            
        default:
            break;
    }
}

- (void)handleScalePan:(UIPanGestureRecognizer *)gesture
{
    if (self.editLineStatusType == YYKEditLineStatusTypeNOEdit)
    {
        return;
    }
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            _originalTranslation = self.translation;
            _originalTransform = self.transform;
            
            CGPoint touchPoint = [gesture locationInView:self];
            BOOL isFlipped = [self flipAnchorPointIfNesscesaryWithTouchPoint:touchPoint];
            if(isFlipped) {
                _originalTranslation = CGPointApplyAffineTransform(_originalTranslation, CGAffineTransformMakeRotation(M_PI));
            }
            
            self.touchTimer = [NSTimer scheduledTimerWithTimeInterval:_magnifyingGlassShowDelay
                                                               target:self
                                                             selector:@selector(addMagnifyingGlassTimer:)
                                                             userInfo:[NSValue valueWithCGPoint:touchPoint]
                                                              repeats:NO];
        }
            break;
            
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [gesture translationInView:self.superview];
            CGPoint theNewTranslation = CGPointMake(_originalTranslation.x+translation.x, _originalTranslation.y+translation.y);
            self.translation = theNewTranslation;
            
            
            // rotate
            CGFloat angle = atan2(theNewTranslation.y, theNewTranslation.x)-atan2(_originalTranslation.y, _originalTranslation.x);
            CGAffineTransform transfrom = CGAffineTransformRotate(_originalTransform, angle);
            self.transform = transfrom;
            
            // scale
            CGFloat lenth = sqrt(ABS(theNewTranslation.x)*ABS(theNewTranslation.x)+ABS(theNewTranslation.y)*ABS(theNewTranslation.y));
            self.bounds = CGRectMake(0, 0, lenth, CGRectGetHeight(self.bounds));
            [self setNeedsDisplay];
            
            // magnify
            [self updateMagnifyingGlassAtPoint:[gesture locationInView:self]];
            
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            _originalTranslation = CGPointZero;
            _originalTransform = CGAffineTransformIdentity;
            [self removeMagnifyingGlass];
            break;
        }
            
        default:
            break;
    }
}

- (CGPoint)anchorPointInUIKitCoordinate {
    CGPoint anchorPoint = self.layer.anchorPoint;
    anchorPoint = CGPointMake(anchorPoint.x*CGRectGetWidth(self.bounds), anchorPoint.y*CGRectGetHeight(self.bounds));
    
    CGAffineTransform transfrom = CGAffineTransformMakeTranslation(0, CGRectGetHeight(self.bounds));
    transfrom = CGAffineTransformScale(transfrom, 1.0f, -1.0f);
    
    return CGPointApplyAffineTransform(anchorPoint, transfrom);
}

-(void)setAnchorPoint:(CGPoint)anchorPoint
{
    CGPoint oldOrigin = self.frame.origin;
    self.layer.anchorPoint = anchorPoint;
    CGPoint newOrigin = self.frame.origin;
    CGPoint transition;
    transition.x = (newOrigin.x - oldOrigin.x);
    transition.y = (newOrigin.y - oldOrigin.y);
    CGPoint myNewCenter = CGPointMake (self.center.x - transition.x, self.center.y - transition.y);
    self.center =  myNewCenter;
}

- (BOOL)flipAnchorPointIfNesscesaryWithTouchPoint:(CGPoint)touchPoint {
    CGPoint anchorPoint = [self anchorPointInUIKitCoordinate];
    CGFloat distance = [self distanceFromPoint:touchPoint toPoint:anchorPoint];
    CGFloat judgeDistance = M_SQRT2*_editRadius;
    if(distance < judgeDistance) {
        // 假设当前anchor在左边
        CGPoint leftAnchor = CGPointMake(0.0f, CGRectGetHeight(self.bounds)/2);
        
        // 假设正确, 翻转anchor到右边
        if([self distanceFromPoint:leftAnchor toPoint:touchPoint] < judgeDistance) {
            [self setAnchorPoint:CGPointMake(1, 0.5)];
        }
        // 假设错误, 说明当前anchor在右边, 现在翻转到左边
        else {
            [self setAnchorPoint:CGPointMake(0, 0.5)];
        }
        
        return YES;
    }
    
    return NO;
}

- (CGFloat)distanceFromPoint:(CGPoint)a toPoint:(CGPoint)b {
    return sqrt(pow(a.x-b.x, 2)+pow(a.y-b.y, 2));
}

- (BOOL)isInDragArea:(CGPoint)touchPoint {
    if([self isInEditArea:touchPoint]) {
        return NO;
    }
    
    if(!CGRectContainsPoint(self.bounds, touchPoint)) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isInEditArea:(CGPoint)touchPoint {
    CGRect leftRect = [self leftEditArea];
    CGRect rightRect = [self rightEditArea];
    return CGRectContainsPoint(leftRect, touchPoint) || CGRectContainsPoint(rightRect, touchPoint);
}

- (CGRect)leftEditArea
{
    return CGRectMake(-_editRadius/2, 0, _editRadius/2*3, _editRadius);
}

- (CGRect)rightEditArea {
    CGRect rect = self.bounds;
    return CGRectMake(CGRectGetWidth(rect)-_editRadius, 0, _editRadius/2*3, _editRadius);
}

#pragma mark - magnifier functions

- (void)addMagnifyingGlassTimer:(NSTimer*)timer {
    NSValue *v = timer.userInfo;
    CGPoint point = [v CGPointValue];
    [self addMagnifyingGlassAtPoint:point];
}

- (void)addMagnifyingGlassAtPoint:(CGPoint)point {
    
    if (!_magnifyingGlass)
    {
        _magnifyingGlass = [[YYKMagnifyingGlass alloc] init];
    }
    
    if (!_magnifyingGlass.viewToMagnify) {
        _magnifyingGlass.viewToMagnify = self.superview.superview.superview;
        
    }
    
    _magnifyingGlass.touchPoint = [self convertPoint:point toView:nil];
    [self.window addSubview:_magnifyingGlass];
    [_magnifyingGlass setNeedsDisplay];
}

- (void)removeMagnifyingGlass {
    [_magnifyingGlass removeFromSuperview];
}

- (void)updateMagnifyingGlassAtPoint:(CGPoint)point {
    _magnifyingGlass.touchPoint = [self convertPoint:point toView:nil];
    if (_magnifyingGlass.touchPoint.y < 120)
    {
        
        _magnifyingGlass.touchPointOffset = CGPointMake(0, 220);
    }
    else
    {
        
        _magnifyingGlass.touchPointOffset = CGPointMake(0, -100);
    }
    [_magnifyingGlass setNeedsDisplay];
}
-(void)certainDrawText{
    self.editLineStatusType = YYKEditLineStatusTypeNOEdit;
    [self setNeedsDisplay];
}
-(void)cancelCustomKeyBoard{
    self.editLineStatusType = YYKEditLineStatusTypeNOEdit;
    [self setNeedsDisplay];
}


-(UIColor *) getColor:(NSMutableString *)color
{
    // 转换成标准16进制数
    [color replaceCharactersInRange:[color rangeOfString:@"#" ] withString:@"0x"];
    // 十六进制字符串转成整形。
    long colorLong = strtoul([color cStringUsingEncoding:NSUTF8StringEncoding], 0, 16);
    // 通过位与方法获取三色值
    int R = (colorLong & 0xFF0000 )>>16;
    int G = (colorLong & 0x00FF00 )>>8;
    int B =  colorLong & 0x0000FF;
    
    //string转color
    UIColor *wordColor = [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1.0];
    return wordColor;
    
}



@end
