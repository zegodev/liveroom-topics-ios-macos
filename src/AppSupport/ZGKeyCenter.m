//
//  ZGKeyCenter.m
//  LiveRoomPlayGround
//
//  Created by zego on 2019/7/2.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGKeyCenter.h"

@implementation ZGKeyCenter

 + (unsigned int)appID {
     return <#填写自己的 appID#>;
 }
 
 // 从即构主页申请
 + (NSData *)appSign {
     Byte signKey[] = <#填写自己的 appSign#>;
     NSData* sign = [NSData dataWithBytes:signKey length:32];
     return sign;
 }

@end
