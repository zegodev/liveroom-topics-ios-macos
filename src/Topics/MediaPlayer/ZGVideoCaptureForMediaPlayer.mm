//
//  ZGVideoCaptureForMediaPlayer.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGVideoCaptureForMediaPlayer.h"
#import <sys/time.h>
#import <memory>
#import <thread>

@interface ZGVideoCaptureForMediaPlayer () <ZegoVideoCaptureDevice> {
    id<ZegoVideoCaptureClientDelegate> client_;
    BOOL capture_started_;
    std::mutex capture_lock_;
    
    CVPixelBufferPoolRef pool_;
    int video_width_;
    int video_height_;
}
@end

@implementation ZGVideoCaptureForMediaPlayer

#pragma mark - ZegoVideoCaptureFactory

- (id<ZegoVideoCaptureDevice>)zego_create:(NSString *)deviceId {
    NSLog(@"%s", __func__);
    return self;
}

- (void)zego_destroy:(id<ZegoVideoCaptureDevice>)device {
    NSLog(@"%s", __func__);
}

#pragma mark - ZegoVideoCaptureDevice

- (void)zego_allocateAndStart:(id<ZegoVideoCaptureClientDelegate>)client {
    NSLog(@"%s", __func__);
    client_ = client;
}

- (void)zego_stopAndDeAllocate {
    NSLog(@"%s", __func__);
    [client_ destroy];
    client_ = nil;
}

- (int)zego_startCapture {
    NSLog(@"%s", __func__);
    std::lock_guard<std::mutex> lg(capture_lock_);
    capture_started_ = YES;
    return 0;
}

- (int)zego_stopCapture {
    NSLog(@"%s", __func__);
    std::lock_guard<std::mutex> lg(capture_lock_);
    capture_started_ = NO;
    return 0;
}

- (ZegoVideoCaptureDeviceOutputBufferType)zego_supportBufferType {
    NSLog(@"%s", __func__);
    return ZegoVideoCaptureDeviceOutputBufferTypeCVPixelBuffer;
}

#pragma mark - ZegoMediaPlayerVideoPlayDelegate

typedef void (*CFTypeDeleter)(CFTypeRef cf);
#define MakeCFTypeHolder(ptr) std::unique_ptr<void, CFTypeDeleter>(ptr, CFRelease)

- (void)onPlayVideoData:(const char *)data size:(int)size format:(ZegoMediaPlayerVideoDataFormat)format {
    struct timeval tv_now;
    gettimeofday(&tv_now, NULL);
    unsigned long long t = (unsigned long long)(tv_now.tv_sec) * 1000 + tv_now.tv_usec / 1000;
    
    CVPixelBufferRef pixelBuffer = [self createInputBufferWithWidth:format.width height:format.height stride:format.strides[0]];
    if (pixelBuffer == NULL) return;
    
    auto holder = MakeCFTypeHolder(pixelBuffer);
    
    CVReturn cvRet = CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    if (cvRet != kCVReturnSuccess) return;
    
    size_t destStride = CVPixelBufferGetBytesPerRow(pixelBuffer);
    unsigned char *dest = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    unsigned char *src = (unsigned char *)data;
    for (int i = 0; i < format.height; i++) {
        memcpy(dest, src, format.strides[0]);
        src += format.strides[0];
        dest += destStride;
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    [self handleFrame:pixelBuffer time:t];
}

#pragma mark - Private

- (void)createPixelBufferPool {
    NSDictionary *pixelBufferAttributes = @{
                                            (id)kCVPixelBufferOpenGLCompatibilityKey: @(YES),
                                            (id)kCVPixelBufferWidthKey: @(video_width_),
                                            (id)kCVPixelBufferHeightKey: @(video_height_),
                                            (id)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary],
                                            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
                                            };
    
    CFDictionaryRef ref = (__bridge CFDictionaryRef)pixelBufferAttributes;
    CVReturn ret = CVPixelBufferPoolCreate(nil, nil, ref, &pool_);
    if (ret != kCVReturnSuccess) {
        return ;
    }
}

- (CVPixelBufferRef)createInputBufferWithWidth:(int)width height:(int)height stride:(int)stride {
    if (video_width_ != width || video_height_ != height) {
        if (video_height_ && video_width_) {
            CVPixelBufferPoolFlushFlags flag = 0;
            CVPixelBufferPoolFlush(pool_, flag);
            CFRelease(pool_);
            pool_ = nil;
        }
        
        video_width_ = width;
        video_height_ = height;
        [self createPixelBufferPool];
        
        ZegoAVConfig* config = [ZegoAVConfig presetConfigOf:ZegoAVConfigPreset_High];
        config.videoEncodeResolution = CGSizeMake(width, height);
        [[ZGManager api] setAVConfig:config];
    }
    
    CVPixelBufferRef pixelBuffer;
    CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(nil, pool_, &pixelBuffer);
    if (ret != kCVReturnSuccess)
        return nil;
    
    return pixelBuffer;
}

- (void)handleFrame:(CVPixelBufferRef)frame time:(unsigned long long)t {
    CMTime pts = CMTimeMakeWithSeconds(t, 1000);
    std::lock_guard<std::mutex> lg(capture_lock_);
    if (capture_started_) {
        [client_ onIncomingCapturedData:frame withPresentationTimeStamp:pts];
    }
}

@end
