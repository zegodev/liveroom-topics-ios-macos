//
//  ZGMediaPlayerVideoDataToPixelBufferConverter.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaPlayer

#import "ZGMediaPlayerVideoDataToPixelBufferConverter.h"
#import "ZGCVPixelBufferHelper.h"
#import <sys/time.h>
#import <memory>

@interface ZGMediaPlayerVideoDataToPixelBufferConverter ()
{
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

+ (CMTime)getCurrentTimestamp {
    struct timeval tv_now;
    gettimeofday(&tv_now, NULL);
    unsigned long long t = (unsigned long long)(tv_now.tv_sec) * 1000 + tv_now.tv_usec / 1000;
    CMTime timestamp = CMTimeMakeWithSeconds(t, 1000);
    return timestamp;
}

- (void)convertRGBCategoryDataToPixelBufferWithVideoData:(const char *)data size:(int)size format:(ZegoMediaPlayerVideoDataFormat)format completion:(ZGMediaPlayerVideoDataToPixelBufferConvertCompletion)completion {
    // 注意：不要在另外的线程处理 data，因为 data 可能会被释放
    CMTime timestamp = [self.class getCurrentTimestamp];
    CVPixelBufferRef pixelBuffer = NULL;
    switch (format.pixelFormat) {
        case ZegoMediaPlayerVideoPixelFormatBGRA32:
        {
            pixelBuffer = [ZGCVPixelBufferHelper createRGBCategoryPixelBufferWithWidth:format.width height:format.height format:kCVPixelFormatType_32BGRA];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:data stride:format.strides[0] width:format.width height:format.height];
            break;
        }
        case ZegoMediaPlayerVideoPixelFormatRGBA32:
        {
            pixelBuffer = [ZGCVPixelBufferHelper createRGBCategoryPixelBufferWithWidth:format.width height:format.height format:kCVPixelFormatType_32RGBA];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:data stride:format.strides[0] width:format.width height:format.height];
            break;
        }
        case ZegoMediaPlayerVideoPixelFormatARGB32:
        {
            pixelBuffer = [ZGCVPixelBufferHelper createRGBCategoryPixelBufferWithWidth:format.width height:format.height format:kCVPixelFormatType_32ARGB];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:data stride:format.strides[0] width:format.width height:format.height];
            break;
        }
        case ZegoMediaPlayerVideoPixelFormatABGR32:
        {
            pixelBuffer = [ZGCVPixelBufferHelper createRGBCategoryPixelBufferWithWidth:format.width height:format.height format:kCVPixelFormatType_32ABGR];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:data stride:format.strides[0] width:format.width height:format.height];
            break;
        }
        default:
            break;
    }
    
    if (completion) {
        if (pixelBuffer) {
            CVPixelBufferRetain(pixelBuffer);
        }
        dispatch_async(_outputQueue, ^{
            completion(self, pixelBuffer, timestamp);
            if (pixelBuffer) {
                CVPixelBufferRelease(pixelBuffer);
            }
        });
    }
    
    if (pixelBuffer) {
        CVPixelBufferRelease(pixelBuffer);
    }
}

- (void)convertYUVCategoryDataToPixelBufferWithVideoData:(const char **)data size:(int *)size format:(ZegoMediaPlayerVideoDataFormat)format completion:(ZGMediaPlayerVideoDataToPixelBufferConvertCompletion)completion {
    // 注意：不要在另外的线程处理 data，因为 data 可能会被释放
    CMTime timestamp = [self.class getCurrentTimestamp];
    CVPixelBufferRef pixelBuffer = NULL;
    switch (format.pixelFormat) {
        case ZegoMediaPlayerVideoPixelFormatI420:
        {
            // YU12，存储顺序是先存Y，再存U，最后存V。 3 plane
            pixelBuffer = [ZGCVPixelBufferHelper createI420PixelBufferWithWidth:format.width height:format.height];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withI420Data:data strides:format.strides width:format.width height:format.height];
            break;
        }
        case ZegoMediaPlayerVideoPixelFormatNV12:
        {
            // 存储顺序是先存Y，再UV交替存储。 2 plane
            pixelBuffer = [ZGCVPixelBufferHelper createNV12PixelBufferWithWidth:format.width height:format.height];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withNV12Data:data strides:format.strides width:format.width height:format.height];
        }
        default:
            break;
    }
    
    if (completion) {
        if (pixelBuffer) {
            CVPixelBufferRetain(pixelBuffer);
        }
        dispatch_async(_outputQueue, ^{
            completion(self, pixelBuffer, timestamp);
            if (pixelBuffer) {
                CVPixelBufferRelease(pixelBuffer);
            }
        });
    }
    
    if (pixelBuffer) {
        CVPixelBufferRelease(pixelBuffer);
    }
}

#pragma mark - Private

+ (OSType)toPixelBufferPixelFormatType:(ZegoMediaPlayerVideoPixelFormat)srcFormat {
    // Cb=U  Cr=V
    switch (srcFormat) {
        case ZegoMediaPlayerVideoPixelFormatBGRA32:
            return kCVPixelFormatType_32BGRA;
        case ZegoMediaPlayerVideoPixelFormatRGBA32:
            return kCVPixelFormatType_32RGBA;
        case ZegoMediaPlayerVideoPixelFormatARGB32:
            return kCVPixelFormatType_32ARGB;
        case ZegoMediaPlayerVideoPixelFormatABGR32:
            return kCVPixelFormatType_32ABGR;
        case ZegoMediaPlayerVideoPixelFormatI420:
            // YU12，存储顺序是先存Y，再存U，最后存V。 3 plane
            return kCVPixelFormatType_420YpCbCr8PlanarFullRange;
        case ZegoMediaPlayerVideoPixelFormatNV12:
            // 存储顺序是先存Y，再UV交替存储。 2 plane
            return kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        case ZegoMediaPlayerVideoPixelFormatNV21:
            // 存储顺序是先存Y，再VU交替存储。 2 plane
            // iOS 不支持该格式
            return kCVPixelFormatType_32BGRA;
        default:
            return kCVPixelFormatType_32BGRA;
            break;
    }
}

@end
#endif
