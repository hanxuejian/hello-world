//
//  ViewController.m
//  Test-UIButtonLongPressGesture
//
//  Created by han on 2017/5/25.
//  Copyright © 2017年 han. All rights reserved.
//

#import "ViewController.h"
#import "UIButton(SA)/NSButton+SA.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = [UIColor yellowColor];
    button.frame = CGRectMake(50, 50, 100, 50);
    [button setTitle:@"long press" forState:UIControlStateNormal];
    [button addLongPressWithBlock:^{
        
        NSLog(@"%s",__FUNCTION__);
    }];
    [self.view addSubview:button];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
