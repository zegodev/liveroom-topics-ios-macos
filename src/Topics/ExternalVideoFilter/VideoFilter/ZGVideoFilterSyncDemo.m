//
//  ZGVideoFilterSyncDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/30.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import "ZGVideoFilterSyncDemo.h"
#import "FUManager.h"

@implementation ZGVideoFilterSyncDemo {
    id<ZegoVideoFilterClient> client_;
    id<ZegoVideoFilterDelegate> delegate_;
}

#pragma mark -- ZegoVideoFilter Delgate

// 初始化外部滤镜使用的资源
- (void)zego_allocateAndStart:(id<ZegoVideoFilterClient>) client {
    client_ = client;
    if ([client_ conformsToProtocol:@protocol(ZegoVideoFilterDelegate)]) {
        delegate_ = (id<ZegoVideoFilterDelegate>)client;
    }
}

// 停止并释放外部滤镜占用的资源
- (void)zego_stopAndDeAllocate {
    [client_ destroy];
    client_ = nil;
    delegate_ = nil;
}

- (ZegoVideoBufferType)supportBufferType {
    // * 返回滤镜的类型：此滤镜为同步滤镜
    return ZegoVideoBufferTypeSyncPixelBuffer;
}

#pragma mark -- ZegoVideoFilterDelegate Delegate

- (void)onProcess:(CVPixelBufferRef)pixel_buffer withTimeStatmp:(unsigned long long)timestamp_100 {
    // * 采集到的图像数据通过这个传进来，同步处理完返回处理结果
    
    // 自定义前处理：此处使用 FaceUnity 作为外部滤镜
    CVPixelBufferRef output = [[FUManager shareManager] renderItemsToPixelBuffer:pixel_buffer];
    
    [delegate_ onProcess:output withTimeStatmp:timestamp_100];
}

@end


#endif
