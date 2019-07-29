//
//  ZegoHudManager.h
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/13.
//  Copyright © 2019 zego. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZegoHudManager : NSObject

/**
 移除所有HUD
 */
+ (void)hideAllHUD;

/**
 *  显示提示消息
 *  @param message 消息内容
 */
+ (void)showMessage:(NSString *)message;

/**
 *  显示提示消息
 *  @param message     消息内容
 *  @param doneHandler 回调
 */
+ (void)showMessage:(NSString *)message done:(void(^)(void))doneHandler;

/**
 显示提示任务进行中消息
 @param message     消息内容
 @param doneHandler 完成回调
 */
+ (void)showIndeterminateMessage:(NSString *)message done:(void(^)(void))doneHandler;

/**
 显示提示自定义View和消息
 
 @param message     消息内容
 @param customView  自定义view
 @param doneHandler 完成回调
 */
+ (void)showCustomMessage:(NSString *)message customView:(UIView *)customView done:(void(^)(void))doneHandler;

/**
 显示网络加载HUD
 */
+ (void)showNetworkLoading;

/**
 移除网络加载HUD
 */
+ (void)hideNetworkLoading;

@end
