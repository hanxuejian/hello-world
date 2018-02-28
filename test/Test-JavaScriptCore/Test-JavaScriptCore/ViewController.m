//
//  ViewController.m
//  Test-JavaScriptCore
//
//  Created by HanXueJian on 2018/2/28.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *path = [[NSBundle mainBundle]pathForResource:@"web" ofType:@"html"];
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:html baseURL:nil];
    
}

- (void)test:(UIWebView *)webView {
    id aa = [webView valueForKey:@"documentView"];
    NSLog(@"documentView %@",aa);
    
    id bb = [webView valueForKeyPath:@"documentView.webView"];
    NSLog(@"documentView.webView %@",bb);
    
    id cc = [webView valueForKeyPath:@"documentView.webView.mainFrame"];
    NSLog(@"documentView.webView.mainFrame %@",cc);
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [self test:webView];
  
    JSContext *context = [webView valueForKeyPath: @"documentView.webView.mainFrame.javaScriptContext"];
    
    
    context[@"saveValue"] = ^(){
        
        NSLog(@"currentArguments %@",[JSContext currentArguments]);

        JSContext *currentContext = [JSContext currentContext];

       [currentContext[@"show"] callWithArguments:nil];

    };
    
    
    CustomSave *save = [[CustomSave alloc]init];
    save.name = @"Martin";
    
    context[@"CustomSave"] = save;
    
    context[@"age"] = @"20";
    
}

@end


@implementation CustomSave

- (void)saveValue {
    
    NSLog(@"currentArguments %@",[JSContext currentArguments]);
    
    JSValue *currentThis = [JSContext currentThis];
    NSLog(@"currentThis %@",currentThis);
    
    JSValue *currentCallee = [JSContext currentCallee];
    NSLog(@"currentCallee %@",currentCallee);
    
    [[JSContext currentContext][@"clear"] callWithArguments:nil];
}

@end
