//
//  FaceUVideoFilterFactoryDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import "ZGVideoFilterFactoryDemo.h"

#import "ZGVideoFilterAsyncDemo.h"
#import "ZGVideoFilterSyncDemo.h"
#import "ZGVideoFilterI420Demo.h"
#import "ZGVideoFilterNV12Demo.h"


@implementation ZGVideoFilterFactoryDemo {
    id<ZegoVideoFilter> g_filter_;
}

#pragma mark - ZegoVideoFilterFactory Delegate

// 创建外部滤镜实例
- (id<ZegoVideoFilter>)zego_create {
    if (g_filter_ == nil) {
        // 此处的 bufferType 对应四种滤镜类型，以创建不同的外部滤镜实例
        switch (self.bufferType) {
            case ZegoVideoBufferTypeAsyncPixelBuffer:
                g_filter_ = [[ZGVideoFilterAsyncDemo alloc] init];
                break;
            
            case ZegoVideoBufferTypeSyncPixelBuffer:
                g_filter_ = [[ZGVideoFilterSyncDemo alloc] init];
                break;
                
            case ZegoVideoBufferTypeAsyncI420PixelBuffer:
                g_filter_ = [[ZGVideoFilterI420Demo alloc] init];
                break;
                
            case ZegoVideoBufferTypeAsyncNV12PixelBuffer:
                g_filter_ = [[ZGVideoFilterNV12Demo alloc] init];
                break;
            
            default:
                break;
        }
    }
    return g_filter_;
}

// 销毁外部滤镜实例
- (void)zego_destroy:(id<ZegoVideoFilter>)filter {
    if (g_filter_ == filter) {
        g_filter_ = nil;
    }
}

@end

#endif
