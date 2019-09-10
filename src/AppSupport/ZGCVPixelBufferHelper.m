//
//  ZGCVPixelBufferHelper.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGCVPixelBufferHelper.h"

@implementation ZGCVPixelBufferHelper

/**
 创建 RGB 类别的 CVPixelBufferRef

 @param width 图片 width
 @param height 图片 height
 @param format 数据格式
 @return 创建的 CVPixelBufferRef
 */
+ (CVPixelBufferRef)createRGBCategoryPixelBufferWithWidth:(size_t)width
                    height:(size_t)height format:(OSType)format {
    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey:[NSDictionary dictionary]};
    
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(NULL, width, height, format, (__bridge CFDictionaryRef)(pixelBufferAttributes), &pixelBuffer);
    return pixelBuffer;
}

/**
 创建 NV12 类别的 CVPixelBufferRef
 
 @param width 图片 width
 @param height 图片 height
 @param format 数据格式
 @return 创建的 CVPixelBufferRef
 */
+ (CVPixelBufferRef)createNV12PixelBufferWithWidth:(size_t)width
                                            height:(size_t)height {
    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey:[NSDictionary dictionary]};
    
    OSType format = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(NULL, width, height, format, (__bridge CFDictionaryRef)(pixelBufferAttributes), &pixelBuffer);
    return pixelBuffer;
}

/**
 创建 I420 类别的 CVPixelBufferRef
 
 @param width 图片 width
 @param height 图片 height
 @param format 数据格式
 @return 创建的 CVPixelBufferRef
 */
+ (CVPixelBufferRef)createI420PixelBufferWithWidth:(size_t)width
                                            height:(size_t)height {
    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey:[NSDictionary dictionary]};
    
    OSType format = kCVPixelFormatType_420YpCbCr8PlanarFullRange;
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferCreate(NULL, width, height, format, (__bridge CFDictionaryRef)(pixelBufferAttributes), &pixelBuffer);
    return pixelBuffer;
}

/**
 将 RGB 类别的数据拷贝到 PixelBuffer 中
 
 @param pixelBuffer
 @param data RGB 类别的数据
 @param stride 步长
 @param width 像素宽
 @param height 像素高
 @param pixelFormatType pixelFormatType
 */
+ (void)copyDataIntoPixelBuffer:(CVPixelBufferRef)pixelBuffer
            withRGBCategoryData:(const char *)data
                         stride:(int)stride
                          width:(size_t)width
                         height:(size_t)height {
    
    if (!pixelBuffer) return;
    if (!data) return;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t destStride = CVPixelBufferGetBytesPerRow(pixelBuffer);
    unsigned char *dest = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    const char *src = data;
    for (int i = 0; i < height; i++, dest += destStride, src += stride) {
        memcpy(dest, src, stride);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

/**
 将 NV12 数据拷贝到 PixelBuffer 中
 
 @param pixelBuffer
 @param data NV12 数据，data[0] 为 Y 平面数据，data[1] 为 UV 平面数据。
 @param strides strides[0] 为 Y 平面的步长，strides[1] 为 UV 平面的步长。
 @param width 像素宽
 @param height 像素高
 */
+ (void)copyDataIntoPixelBuffer:(CVPixelBufferRef)pixelBuffer
                   withNV12Data:(const char **)data
                        strides:(const int *)strides
                          width:(size_t)width
                         height:(size_t)height {
    if (!data) return;
    
    const char* yData = data[0];
    const char* uvData = data[1];
    
    if (!yData || !uvData) return;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t destStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    const int yStride = strides[0];
    unsigned char* dst = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    for (unsigned int rIdx = 0; rIdx < height; ++rIdx, dst += destStride, yData += yStride) {
        memcpy(dst, yData, yStride);
    }
    
    size_t destStrideUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    const int uvStride = strides[1];
    dst = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    size_t uvHeight = height >> 1;
    for (unsigned int rIdx = 0; rIdx < uvHeight; ++rIdx, dst += destStrideUV, uvData += uvStride) {
        memcpy(dst, uvData, uvStride);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}


/**
 将 i420 数据拷贝到 PixelBuffer 中
 
 @param pixelBuffer
 @param data i420 数据，data[0] 为 Y 平面数据，data[1] 为 U 平面数据，data[2] 为 V 平面数据。
 @param strides strides[0] 为 Y 平面的步长，strides[1] 为 U 平面的步长，strides[2] 为 V 平面的步长。
 @param width 像素宽
 @param height 像素高
 */
+ (void)copyDataIntoPixelBuffer:(CVPixelBufferRef)pixelBuffer
                   withI420Data:(const char **)data
                        strides:(const int *)strides
                          width:(size_t)width
                         height:(size_t)height {
    
    if (!data) return;
    
    const char* yData = data[0];
    const char* uData = data[1];
    const char* vData = data[2];
    
    if (!yData || !uData || !vData) {
        return;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t h0 = height;
    size_t d0 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    const int yStride = strides[0];
    unsigned char* dst = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    for (unsigned int rIdx = 0; rIdx < h0; ++rIdx, dst += d0, yData += yStride) {
        memcpy(dst, yData, yStride);
    }
    
    size_t h1 = (height >> 1);
    size_t d1 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    const int uStride = strides[1];
    dst = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    for (unsigned int rIdx = 0; rIdx < h1; ++rIdx, dst += d1, uData += uStride) {
        memcpy(dst, uData, uStride);
    }
    
    size_t h2 = h1;
    size_t d2 = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);
    int vStride = strides[2];
    dst = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    for (unsigned int rIdx = 0; rIdx < h2; ++rIdx, dst += d2, vData += vStride) {
        memcpy(dst, vData, vStride);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

@end
