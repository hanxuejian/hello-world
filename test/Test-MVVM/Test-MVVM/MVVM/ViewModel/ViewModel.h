//
//  ViewModel.h
//  Test-MVVM
//
//  Created by HanXueJian on 2018/2/6.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PersonInfoView.h"

@interface ViewModel : NSObject <PersonInfoViewDelegate,UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) PersonInfoView *personView;

@property (strong, nonatomic) NSArray *personList;

@end
