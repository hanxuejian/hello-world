//
//  PersonInfoView.m
//  Test-MVVM
//
//  Created by HanXueJian on 2018/2/6.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import "PersonInfoView.h"

@implementation PersonInfoView

+ (instancetype)personInfoView {
    id view = [[[NSBundle mainBundle]loadNibNamed:@"View" owner:self options:nil]lastObject];
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setType:self.name];
    [self setType:self.sex];
    [self setType:self.age];
    [self setType:self.job];
}

- (void)setType:(UITextField *)field {
    field.layer.cornerRadius = 10;
    field.layer.borderColor = [UIColor grayColor].CGColor;
    field.layer.borderWidth = 1;
}

- (IBAction)btnClickedOfSave:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(btnClicked:)]) {
        [self.delegate btnClicked:sender];
    }
}

@end
