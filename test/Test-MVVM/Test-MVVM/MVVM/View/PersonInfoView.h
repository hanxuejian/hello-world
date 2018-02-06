//
//  PersonInfoView.h
//  Test-MVVM
//
//  Created by HanXueJian on 2018/2/6.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PersonInfoViewDelegate <NSObject>

- (void)btnClicked:(UIButton *)sender;

@end

@interface PersonInfoView : UIView

@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *sex;
@property (weak, nonatomic) IBOutlet UITextField *age;
@property (weak, nonatomic) IBOutlet UITextField *job;

@property (weak, nonatomic) IBOutlet UITableView *personList;

@property (weak, nonatomic) id delegate;

+ (instancetype)personInfoView;

@end
