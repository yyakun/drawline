//
//  YYKDrawLineViewController.m
//  DrawLine
//
//  Created by yyk on 2017/11/9.
//  Copyright © 2017年 杨亚坤. All rights reserved.
//

#import "YYKDrawLineViewController.h"
#import "YYKArcDrawLineView.h"
@interface YYKDrawLineViewController (){
    CGPoint startPoint;
    CGPoint endPoint;
}
@property (nonatomic, strong)YYKArcDrawLineView *currentLineView;
@property (nonatomic, strong) NSMutableArray *redoList;
@property (nonatomic, strong) NSMutableArray *undoList;
@end

@implementation YYKDrawLineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.showLineImageView.image = self.showImage;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePaintPan:)];
    [self.showLineImageView addGestureRecognizer:pan];
}

- (NSMutableArray *)redoList{
    if (!_redoList) {
        _redoList = [NSMutableArray array];
    }
    return _redoList;
}

- (NSMutableArray *)undoList{
    if (!_undoList) {
        _undoList = [NSMutableArray array];
    }
    return _undoList;
}

//撤销
-(IBAction)redo:(id)sender{
    YYKArcDrawLineView *viewnext = self.redoList.lastObject;
    if(!viewnext)return;
    [self.undoList addObject:viewnext];
    [self.redoList removeLastObject];
    [viewnext removeFromSuperview];
}
//恢复
-(IBAction)undo:(id)sender{
    YYKArcDrawLineView *viewnext = self.undoList.lastObject;
    if(!viewnext)return;
    [self.undoList removeLastObject];
    [self.redoList addObject:viewnext];
    [self.showLineImageView addSubview:viewnext];
}


//画线
- (void)handlePaintPan:(UIPanGestureRecognizer *)gesture{
    switch (gesture.state){
        case UIGestureRecognizerStateBegan:{
            if(!_currentLineView){
                CGPoint touchPoint = [gesture locationInView:gesture.view];
                startPoint = touchPoint;
                _currentLineView = [[YYKArcDrawLineView alloc] initWithFrame:CGRectMake(touchPoint.x, touchPoint.y, 0, 0)];
                [_currentLineView setTitle:@"title"];
                [_currentLineView setchangeLineColor:[UIColor redColor]];
                [gesture.view addSubview:_currentLineView];
                [_currentLineView addMagnifyingGlassAtPoint:[gesture locationInView:_currentLineView]];
            }
        }
            break;
    
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [gesture translationInView:gesture.view];
            CGPoint changPoint =  [gesture locationInView:gesture.view];
            
            if (!CGRectContainsPoint(CGRectMake(0, 0, CGRectGetWidth(gesture.view.bounds), CGRectGetHeight(gesture.view.bounds)), changPoint)){
                return;
            }
            
            [_currentLineView scaleWithTranslation:translation andTouchPoint:changPoint];
            [_currentLineView updateMagnifyingGlassAtPoint:[gesture locationInView:_currentLineView]];
            break;
        }
        case UIGestureRecognizerStateEnded:{
            endPoint = [gesture locationInView:gesture.view];
            [self.undoManager registerUndoWithTarget:_currentLineView selector:@selector(removeFromSuperview) object:nil];
            [_currentLineView removeMagnifyingGlass];
            [self.redoList addObject:_currentLineView];
            _currentLineView = nil;
            break;
        }
        case UIGestureRecognizerStateCancelled: {
            [_currentLineView removeMagnifyingGlass];
            _currentLineView = nil;
            break;
        }
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
