//
//  ViewController.m
//  DrawLine
//
//  Created by yyk on 2017/11/8.
//  Copyright © 2017年 杨亚坤. All rights reserved.
//

#import "ViewController.h"
#import "YYKDrawLineViewController.h"
@interface ViewController ()<UIActionSheetDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

//选择图片
- (IBAction)selectPhoto:(id)sender{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"拍照",@"相册", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    UIImagePickerController *pickerVC = [[UIImagePickerController alloc]init];
    pickerVC.delegate = self;
    switch (buttonIndex) {
        case 0:{
            pickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
            break;
        }
        case 1:{
            pickerVC.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
            break;
        }
        default:
            break;
    }
    [self presentViewController:pickerVC animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        YYKDrawLineViewController *drawLineVC = [[YYKDrawLineViewController alloc]initWithNibName:@"YYKDrawLineViewController" bundle:nil];
        drawLineVC.showImage = image;
        [self presentViewController:drawLineVC animated:YES completion:nil];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
