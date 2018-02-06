//
//  ViewModel.m
//  Test-MVVM
//
//  Created by HanXueJian on 2018/2/6.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import <objc/runtime.h>

#import "ViewModel.h"
#import "Person+CoreDataProperties.h"
#import "SACoreDataManager.h"

@implementation ViewModel

+ (instancetype)viewModel {
    id model = [[ViewModel alloc]init];
    return model;
}

- (PersonInfoView *)personView {
    if (_personView == nil) {
        _personView = [PersonInfoView personInfoView];
        _personView.delegate = self;
        _personView.personList.delegate = self;
        _personView.personList.dataSource = self;
        [self reloadData];
        
    }
    return _personView;
}

- (void)reloadData {
    self.personList = [[SACoreDataManager sharedCoreDataManager]searchDataByEntityName:NSStringFromClass([Person class]) andPredicateFormat:nil];
    [_personView.personList reloadData];
}

#pragma mark - PersonInfoViewDelegate
- (void)btnClicked:(UIButton *)sender {
    if (self.personView.name.text.length == 0) return;
    Person *person = [[SACoreDataManager sharedCoreDataManager]insertObjectForEntityName:NSStringFromClass([Person class])];
    
    person.name = self.personView.name.text;
    person.sex = self.personView.sex.text;
    person.age = self.personView.age.text;
    person.job = self.personView.job.text;
    
    [[SACoreDataManager sharedCoreDataManager]saveChanges];
    [self reloadData];
}


#pragma mark - UITableViewDelegate,UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.personList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    Person *person = self.personList[indexPath.row];
    NSString *string = [NSString stringWithFormat:@"%@  %@  %@  %@  ",person.name,person.sex,person.age,person.job];
    cell.textLabel.text = string;
    
    return cell;
        
}

@end
