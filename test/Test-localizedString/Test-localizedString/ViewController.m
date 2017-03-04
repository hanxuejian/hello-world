//
//  ViewController.m
//  Test-localizedString
//
//  Created by han on 2017/2/25.
//  Copyright © 2017年 han. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UILabel *label;

@property (nonatomic, weak) IBOutlet UIButton *button;

@end

@implementation ViewController

#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self test];
}

#pragma mark - button clicked methods
- (IBAction)btnChangeLanguage:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSLog(@"support languages : %@", languages);
    NSString *currentLanguage = [defaults objectForKey:@"userLanguage"];
    NSLog(@"current language:%@",currentLanguage);
    if ([currentLanguage isEqualToString:@"en"]) {
        currentLanguage = @"zh-Hans";
    }else{
        currentLanguage = @"en";
    }
    [defaults setValue:currentLanguage forKey:@"userLanguage"];
    [defaults synchronize];
    
    NSString *path = [[NSBundle mainBundle]pathForResource:currentLanguage ofType:@"lproj"];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    NSString  *result = NSLocalizedStringFromTableInBundle(@"buttonTitle", @"localized", bundle,nil);
    [self.button setTitle:result forState:UIControlStateNormal];
    result = NSLocalizedStringFromTableInBundle(@"labelTitle", @"localized", bundle, nil);
    self.label.text = result;
    NSLog(@"language have changed : %@",currentLanguage);
}

#pragma mark - inside methods
- (void)test {
    NSLog(@"home directory : %@",NSHomeDirectory());
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSLog(@"support languages : %@", languages);
    NSString *currentLanguage = [defaults objectForKey:@"userLanguage"];
    NSLog(@"current language : %@",currentLanguage);
    
    if (currentLanguage.length == 0) {
        [defaults setValue:languages[0] forKey:@"userLanguage"];
        [defaults synchronize];
    }
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *key,*result;
    
    key = @"name";
    result = NSLocalizedString(key, @"this reusult should be the value of key 'name' in the table named 'Localizable.strings'");
    NSLog(@"%@ : %@",key,result);
    self.label .text = [mainBundle localizedStringForKey:key value:@"null" table:@"localized"];

    result = NSLocalizedStringFromTable(key,@"localized", @"this key should return 'name' ");
    NSLog(@"%@ : %@",key,result);
    
    result = NSLocalizedStringWithDefaultValue(key, @"key not exist", mainBundle, @"默认值", @"this key should return 'name' ");
    NSLog(@"%@ : %@",key,result);
    
    NSString *path = [[NSBundle mainBundle]pathForResource:@"en" ofType:@"lproj"];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    result = NSLocalizedStringFromTableInBundle(key, @"localized", bundle, @"this result is always the value of table named localized.strings in the resource named 'en.proj'");
    NSLog(@"%@ : %@",key,result);
    
    result = NSLocalizedString(@"", @"this result depending on the system language ");
    NSLog(@"%@ : %@",key,result);
    
    result = NSLocalizedStringFromTable(@"",@"localized", @"this result depending on the system language");
    NSLog(@"%@ : %@",key,result);
}

@end
