//
//  ViewController.m
//  多线程下载
//
//  Created by 李泽平 on 2018/8/28.
//  Copyright © 2018年 李泽平. All rights reserved.
//

#import "ViewController.h"
#import "ZPDownLoaderManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSURL *url = [NSURL URLWithString:@"https://dldir1.qq.com/qqfile/QQforMac/QQ_V6.5.0.dmg"];
    [[ZPDownLoaderManager manager] downloadWithUrl:url progress:^(float preogress) {

    } complant:^(NSString *finish) {
        NSLog(@"finish:%@", finish);
    } error:^(NSString *failed) {
        
    }];
}

@end
