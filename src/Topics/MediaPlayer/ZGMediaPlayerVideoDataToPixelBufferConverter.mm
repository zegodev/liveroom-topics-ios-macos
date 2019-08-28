//
//  ZGMediaPlayerVideoDataToPixelBufferConverter.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaPlayer

#import "ZGMediaPlayerVideoDataToPixelBufferConverter.h"
#import <sys/time.h>
#import <memory>

@interface ZGMediaPlayerVideoDataToPixelBufferConverter ()
{
    CVPixelBufferPoolRef pool_;
    int video_width_;
    int video_height_;
    OSType pixel_format_type_;
    dispatch_queue_t _outputQueue;
}

@end

@implementation ZGMediaPlayerVideoDataToPixelBufferConverter

- (instancetype)init {
    if (self = [super init]) {
        _outputQueue = dispatch_queue_create("com.doudong.ZGMediaPlayerVideoDataToPixelBufferConverter.outputQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    [self releasePixelBufferPool];
}

typedef void (*CFTypeDeleter)(CFTypeRef cf);
#define MakeCFTypeHolder(ptr) std::unique_ptr<void, CFTypeDeleter>(ptr, CFRelease)

- (void)convertToPixelBufferWithVideoData:(const char *)data size:(int)size format:(ZegoMediaPlayerVideoDataFormat)format completion:(ZGMediaPlayerVideoDataToPixelBufferConvertCompletion)completion {
    Weakify(self);
    dispatch_async(_outputQueue, ^{
        Strongify(self);
        
        struct timeval tv_now;
        gettimeofday(&tv_now, NULL);
        unsigned long long t = (unsigned long long)(tv_now.tv_sec) * 1000 + tv_now.tv_usec / 1000;
        CMTime timestamp = CMTimeMakeWithSeconds(t, 1000);
        
        OSType pixelFormat = [[self class] toPixelBufferPixelFormatType:format.pixelFormat];
        CVPixelBufferRef pixelBuffer = [self createInputBufferWithWidth:format.width height:format.height stride:format.strides[0] pixelFormatType:pixelFormat];
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
        
        if (completion) {
            completion(self, pixelBuffer, timestamp);
        }
    });
}

#pragma mark - Private

+ (OSType)toPixelBufferPixelFormatType:(ZegoMediaPlayerVideoPixelFormat)srcFormat {
    switch (srcFormat) {
        case ZegoMediaPlayerVideoPixelFormatBGRA32:
            return kCVPixelFormatType_32BGRA;
        case ZegoMediaPlayerVideoPixelFormatRGBA32:
            return kCVPixelFormatType_32RGBA;
        case ZegoMediaPlayerVideoPixelFormatARGB32:
            return kCVPixelFormatType_32ARGB;
        case ZegoMediaPlayerVideoPixelFormatABGR32:
            return kCVPixelFormatType_32ABGR;
        default:
            return kCVPixelFormatType_32BGRA;
            break;
    }
}

- (void)createPixelBufferPool {
    NSDictionary *pixelBufferAttributes = @{
                                            (id)kCVPixelBufferOpenGLCompatibilityKey: @(YES),
                                            (id)kCVPixelBufferWidthKey: @(video_width_),
                                            (id)kCVPixelBufferHeightKey: @(video_height_),
                                            (id)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary],
                                            (id)kCVPixelBufferPixelFormatTypeKey: @(pixel_format_type_)
                                            };
    
    CFDictionaryRef ref = (__bridge CFDictionaryRef)pixelBufferAttributes;
    CVReturn ret = CVPixelBufferPoolCreate(nil, nil, ref, &pool_);
    if (ret != kCVReturnSuccess) {
        return ;
    }
}

- (CVPixelBufferRef)createInputBufferWithWidth:(int)width height:(int)height stride:(int)stride pixelFormatType:(OSType)pixelFormatType{
    if (video_width_ != width || video_height_ != height || pixel_format_type_ != pixelFormatType) {
        [self releasePixelBufferPool];
        
        video_width_ = width;
        video_height_ = height;
        pixel_format_type_ = pixelFormatType;
        
        [self createPixelBufferPool];
    }
    
    CVPixelBufferRef pixelBuffer;
    CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(nil, pool_, &pixelBuffer);
    if (ret != kCVReturnSuccess)
        return nil;
    
    return pixelBuffer;
}

- (void)releasePixelBufferPool {
    if (pool_) {
        CVPixelBufferPoolFlushFlags flag = 0;
        CVPixelBufferPoolFlush(pool_, flag);
        CVPixelBufferPoolRelease(pool_);
        pool_ = nil;
    }
}

@end
#endif
