//
//  ZGVideoRenderDataToPixelBufferConverter.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoRender


#import "ZGVideoRenderDataToPixelBufferConverter.h"
#import "ZGCVPixelBufferHelper.h"

@interface ZGVideoRenderDataToPixelBufferConverter ()
{
    dispatch_queue_t _outputQueue;
}
@end

@implementation ZGVideoRenderDataToPixelBufferConverter

- (instancetype)init {
    if (self = [super init]) {
        _outputQueue = dispatch_queue_create("com.doudong.ZGVideoRenderDataToPixelBufferConverter.outputQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)convertToPixelBufferWithData:(const unsigned char **)data dataLen:(int*)dataLen width:(int)width height:(int)height strides:(int[])strides pixelFormat:(VideoPixelFormat)pixelFormat  completion:(ZGVideoRenderDataToPixelBufferConvertCompletion)completion {
    
    const char **originData = (const char **)data;
    CVPixelBufferRef pixelBuffer = NULL;
    switch (pixelFormat) {
        case PixelFormatI420:
        {
            // YU12，存储顺序是先存Y，再存U，最后存V。 3 plane
            pixelBuffer = [ZGCVPixelBufferHelper createI420PixelBufferWithWidth:width height:height];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withI420Data:originData strides:strides width:width height:height];
            break;
        }
        case PixelFormatNV12:
        {
            // 存储顺序是先存Y，再UV交替存储。 2 plane
            pixelBuffer = [ZGCVPixelBufferHelper createNV12PixelBufferWithWidth:width height:height];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withNV12Data:originData strides:strides width:width height:height];
            break;
        }
        case PixelFormatBGRA32:
        {
            pixelBuffer = [ZGCVPixelBufferHelper createRGBCategoryPixelBufferWithWidth:width height:height format:kCVPixelFormatType_32BGRA];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:(const char *)data[0] stride:strides[0] width:width height:height];
            break;
        }
        case PixelFormatRGBA32:
        {
            pixelBuffer = [ZGCVPixelBufferHelper createRGBCategoryPixelBufferWithWidth:width height:height format:kCVPixelFormatType_32RGBA];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:(const char *)data[0] stride:strides[0] width:width height:height];
            break;
        }
        case PixelFormatARGB32:
        {
            pixelBuffer = [ZGCVPixelBufferHelper createRGBCategoryPixelBufferWithWidth:width height:height format:kCVPixelFormatType_32ARGB];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:(const char *)data[0] stride:strides[0] width:width height:height];
            break;
        }
        case PixelFormatABGR32:
        {
            pixelBuffer = [ZGCVPixelBufferHelper createRGBCategoryPixelBufferWithWidth:width height:height format:kCVPixelFormatType_32ABGR];
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:(const char *)data[0] stride:strides[0] width:width height:height];
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
            completion(self, pixelBuffer);
            if (pixelBuffer) {
                CVPixelBufferRelease(pixelBuffer);
            }
        });
    }
    
    if (pixelBuffer) {
        CVPixelBufferRelease(pixelBuffer);
    }
}

+ (BOOL)copyToPixelBuffer:(CVPixelBufferRef)pixelBuffer withData:(const unsigned char **)data dataLen:(int*)dataLen width:(int)width height:(int)height strides:(int[])strides pixelFormat:(VideoPixelFormat)pixelFormat {
    BOOL ret = NO;
    const char **originData = (const char **)data;
    switch (pixelFormat) {
        case PixelFormatI420:
        {
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withI420Data:originData strides:strides width:width height:height];
            ret = YES;
            break;
        }
        case PixelFormatNV12:
        {
            // 存储顺序是先存Y，再UV交替存储。 2 plane
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withNV12Data:originData strides:strides width:width height:height];
            ret = YES;
            break;
        }
        case PixelFormatBGRA32:
        {
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:(const char *)data[0] stride:strides[0] width:width height:height];
            ret = YES;
            break;
        }
        case PixelFormatRGBA32:
        {
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:(const char *)data[0] stride:strides[0] width:width height:height];
            ret = YES;
            break;
        }
        case PixelFormatARGB32:
        {
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:(const char *)data[0] stride:strides[0] width:width height:height];
            ret = YES;
            break;
        }
        case PixelFormatABGR32:
        {
            [ZGCVPixelBufferHelper copyDataIntoPixelBuffer:pixelBuffer withRGBCategoryData:(const char *)data[0] stride:strides[0] width:width height:height];
            ret = YES;
            break;
        }
        default:
            break;
    }
    return ret;
}

+ (OSType)getApplePixelFormatFromZego:(VideoPixelFormat)zegoPixelFormat {
    OSType destFormat = 0;
    switch (zegoPixelFormat) {
        case PixelFormatI420:
        {
            destFormat = kCVPixelFormatType_420YpCbCr8PlanarFullRange;
            break;
        }
        case PixelFormatNV12:
        {
            // 存储顺序是先存Y，再UV交替存储。 2 plane
            destFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
            break;
        }
        case PixelFormatBGRA32:
        {
            destFormat = kCVPixelFormatType_32BGRA;
            break;
        }
        case PixelFormatRGBA32:
        {
            destFormat = kCVPixelFormatType_32RGBA;
            break;
        }
        case PixelFormatARGB32:
        {
            destFormat = kCVPixelFormatType_32ARGB;
            break;
            break;
        }
        case PixelFormatABGR32:
        {
            destFormat = kCVPixelFormatType_32ABGR;
            break;
        }
        default:
            break;
    }
    
    return destFormat;
}

@end


#endif
