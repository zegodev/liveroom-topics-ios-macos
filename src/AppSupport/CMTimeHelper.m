//
//  CMTimeHelper.m
//  LiveRoomPlayground
//
//  Created by jeffreypeng on 2020/3/18.
//  Copyright © 2020 Zego. All rights reserved.
//

#import "CMTimeHelper.h"
#import <sys/time.h>

@implementation CMTimeHelper

+ (CMTime)getCurrentTimestamp {
    struct timeval tv_now;
    gettimeofday(&tv_now, NULL);
    // 获得当前时间毫秒值
    unsigned long long t = (unsigned long long)(tv_now.tv_sec) * 1000 + tv_now.tv_usec / 1000;
    // 毫秒的 timescale = 1000
    CMTime timestamp = CMTimeMake(t, 1000);
    return timestamp;
}

@end
