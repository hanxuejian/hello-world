//
//  NSButton+SA.m
//  EFlightSales
//
//  Created by HanXueJian on 16-1-28.
//  Copyright (c) 2016年 SpringAirlines. All rights reserved.
//

#import "NSButton+SA.h"
#import <objc/runtime.h>

@implementation UIButton(SA)

-(void)addLongPressWithBlock:(void (^)()) block{
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressWithBlock:)];
    longPressGesture.minimumPressDuration = 0.5;
    [self addGestureRecognizer:longPressGesture];
    self.block = block;
}

-(void)longPressWithBlock:(id)sender{
    UILongPressGestureRecognizer *longPressGesture = (UILongPressGestureRecognizer*)sender;
    if(self.block == nil) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), self.block);
        NSLog(@"%ld",longPressGesture.state);
        
    });
}

const void *blockIdentifier = &blockIdentifier;
-(void)setBlock:(dispatch_block_t)block{
    objc_setAssociatedObject(self, blockIdentifier, block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(dispatch_block_t)block{
    return objc_getAssociatedObject(self, blockIdentifier);
}
@end
