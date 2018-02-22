//
//  InputURLProtocol.m
//  Test-NSURLProtocol
//
//  Created by HanXueJian on 2018/2/22.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import "InputURLProtocol.h"

@implementation InputURLProtocol

+ (void)load
{
    [NSURLProtocol registerClass:self];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([request.URL.scheme isEqualToString:@"customprotocol"]) {
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSURL *url = self.request.URL;
        
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:[url relativeString] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    
    // 响应请求，不然会话持续到超时才会释放
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading
{
    
}

@end
