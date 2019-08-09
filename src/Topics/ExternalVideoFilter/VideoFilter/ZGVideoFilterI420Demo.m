//
//  ZGVideoFilterI420Demo.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/30.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import "ZGVideoFilterI420Demo.h"
#import "ZGImageUtils.h"
#import "FUManager.h"

@interface ZGVideoFilterI420Demo()

@property (atomic) int pendingCount;

@end

@implementation ZGVideoFilterI420Demo {
    id<ZegoVideoFilterClient> client_;      // SDK 创建的外部滤镜客户端，用于传递数据
    id<ZegoVideoBufferPool> buffer_pool_;
    
    dispatch_queue_t queue_;
    int width_;
    int height_;
    int stride_;
    
    CVPixelBufferPoolRef pool_;
    int buffer_count_;
}

#pragma mark -- ZegoVideoFilter Delgate

// 初始化外部滤镜使用的资源
- (void)zego_allocateAndStart:(id<ZegoVideoFilterClient>) client {
    client_ = client;
    if ([client_ conformsToProtocol:@protocol(ZegoVideoBufferPool)]) {
        buffer_pool_ = (id<ZegoVideoBufferPool>)client;
    }
    
    width_ = 0;
    height_ = 0;
    stride_ = 0;
    pool_ = nil;
    buffer_count_ = 4;
    self.pendingCount = 0;
    
    queue_ = dispatch_queue_create("video.filter", nil);
}

// 停止并释放外部滤镜占用的资源
- (void)zego_stopAndDeAllocate {
    if (queue_) {
        dispatch_sync(queue_, ^ {
        });
        queue_ = nil;
    }
    
    if (pool_) {
        [ZGImageUtils destroyPixelBufferPool:&pool_];
        pool_ = nil;
    }
    
    if (client_) {
        [client_ destroy];
        client_ = nil;
        buffer_pool_ = nil;
    }
}

- (ZegoVideoBufferType)supportBufferType {
    // * 返回滤镜的类型：此滤镜为异步 I420 滤镜
    return ZegoVideoBufferTypeAsyncI420PixelBuffer;
}

#pragma mark -- ZegoVideoBufferPool Delegate

// SDK 回调。从 App 获取 CVPixelBufferRef 对象，用于保存视频帧数据
- (CVPixelBufferRef)dequeueInputBuffer:(int)width height:(int)height stride:(int)stride {
    // * 按需创建 CVPixelBufferPool
    if (width_ != width || height_ != height || stride_ != stride) {
        if (pool_) {
            [ZGImageUtils destroyPixelBufferPool:&pool_];
        }
        
        if ([ZGImageUtils createI420PixelBufferPool:&pool_ width:width height:height]) {
            width_ = width;
            height_ = height;
            stride_ = stride;
        } else {
            return nil;
        }
    }
    
    // * 如果处理不及时，未处理帧超过了 pool 的大小，则丢弃该帧
    if (self.pendingCount >= buffer_count_) {
        return nil;
    }
    
    CVPixelBufferRef pixel_buffer = nil;
    CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool_, &pixel_buffer);
    
    if (ret != kCVReturnSuccess) {
        return nil;
    } else {
        self.pendingCount = self.pendingCount + 1;
        // * 返回一个可以用于存储采集到的图像的 CVPixelBuffer 实例
        return pixel_buffer;
    }
}

// SDK 回调。App 在此接口中获取 SDK 采集到的视频帧数据，并进行处理
- (void)queueInputBuffer:(CVPixelBufferRef)pixel_buffer timestamp:(unsigned long long)timestamp_100n {
    // * 采集到的图像数据通过这个传进来，这个点需要异步处理
    dispatch_async(queue_, ^ {
        int imageWidth = (int)CVPixelBufferGetWidth(pixel_buffer);
        int imageHeight = (int)CVPixelBufferGetHeight(pixel_buffer);
        int imageStride = (int)CVPixelBufferGetBytesPerRowOfPlane(pixel_buffer, 0);
        
        CVPixelBufferRef dst = [buffer_pool_ dequeueInputBuffer:imageWidth height:imageHeight stride:imageStride];
        
        if (!dst) {
            return;
        }
        
        // 自定义前处理：此处使用 FaceUnity 作为外部滤镜
        CVPixelBufferRef output = [[FUManager shareManager] renderItemsToPixelBuffer:pixel_buffer];
        
        if ([ZGImageUtils copyPixelBufferFrom:output to:dst]) {
            // * 把从 buffer pool 中得到的 CVPixelBuffer 实例传进来
            [buffer_pool_ queueInputBuffer:dst timestamp:timestamp_100n];
        }
        
        self.pendingCount = self.pendingCount - 1;
        
        CVPixelBufferRelease(pixel_buffer);
    });
}

@end


#endif
