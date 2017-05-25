//
//  NSButton+SA.h
//  EFlightSales
//
//  Created by HanXueJian on 16-1-28.
//  Copyright (c) 2016年 SpringAirlines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIButton (SA)

///长按事件触发时，所执行的代码块
@property(nonatomic,strong)dispatch_block_t block;

/**
 * 给按钮添加长按事件，当事件触发时，执行参数块中的代码
 * @param block 长按事件触发时，所执行的代码块
 */
-(void)addLongPressWithBlock:(void (^)()) block;

@end

