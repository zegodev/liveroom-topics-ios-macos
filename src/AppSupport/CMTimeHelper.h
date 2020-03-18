//
//  CMTimeHelper.h
//  LiveRoomPlayground
//
//  Created by jeffreypeng on 2020/3/18.
//  Copyright © 2020 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMTime.h>

@interface CMTimeHelper : NSObject


/// 获取当前时间的 CMTime 表示形式
+ (CMTime)getCurrentTimestamp;

@end
