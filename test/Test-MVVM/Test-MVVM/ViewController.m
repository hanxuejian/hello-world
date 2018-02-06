//
//  ViewController.m
//  Test-MVVM
//
//  Created by HanXueJian on 2018/2/6.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import "ViewController.h"
#import "ViewModel.h"

@interface ViewController ()

@property (strong, nonatomic) ViewModel *viewModel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.viewModel = [[ViewModel alloc]init];
    [self.view addSubview:self.viewModel.personView];
}

@end
