//
//  ViewController.h
//  Test-JavaScriptCore
//
//  Created by HanXueJian on 2018/2/28.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol CustomJSExport <JSExport>

@property (strong, nonatomic) NSString *name;

- (void)saveValue;

@end

@interface CustomSave : NSObject  <CustomJSExport>

@property (strong, nonatomic) NSString *name;

@end

@interface ViewController : UIViewController


@end

