//
//  ZGExternalVideoFilterDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//


#ifdef _Module_ExternalVideoFilter

#import "ZGExternalVideoFilterDemo.h"
#import "ZGVideoFilterFactoryDemo.h"


@interface ZGExternalVideoFilterDemo ()

@property (nonatomic, strong) ZGVideoFilterFactoryDemo *g_filterFactory;

@end

@implementation ZGExternalVideoFilterDemo

+ (instancetype)shared {
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });

    return instance;
}


/**
 初始化外部滤镜工厂对象
 
 @param type 视频缓冲区类型（Async, Sync, I420）
 @discussion 创建外部滤镜工厂对象后，先释放 ZegoLiveRoomSDK 确保 setVideoFilterFactory:channelIndex: 的调用在 initSDK 前
 */
- (void)initFilterFactoryType:(ZegoVideoBufferType)type {
    if (self.g_filterFactory == nil) {
        self.g_filterFactory = [[ZGVideoFilterFactoryDemo alloc] init];
        self.g_filterFactory.bufferType = type;
    }
    
    [ZGApiManager releaseApi];
    [ZegoExternalVideoFilter setVideoFilterFactory:self.g_filterFactory channelIndex:ZEGOAPI_CHN_MAIN];
}


/**
 释放外部滤镜工厂对象
 */
- (void)releaseFilterFactory {
    self.g_filterFactory = nil;
    [ZegoExternalVideoFilter setVideoFilterFactory:nil channelIndex:ZEGOAPI_CHN_MAIN];
}

@end

#endif
