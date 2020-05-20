//
//  ZGCVPixelBufferHelper.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

@interface ZGCVPixelBufferHelper : NSObject

/**
 创建 RGB 类别的 CVPixelBufferRef
 
 @param width 图片 width
 @param height 图片 height
 @param format 数据格式
 @return 创建的 CVPixelBufferRef
 */
+ (CVPixelBufferRef)createRGBCategoryPixelBufferWithWidth:(size_t)width
                                                   height:(size_t)height format:(OSType)format;

/**
 创建 NV12 类别的 CVPixelBufferRef
 
 @param width 图片 width
 @param height 图片 height
 @param format 数据格式
 @return 创建的 CVPixelBufferRef
 */
+ (CVPixelBufferRef)createNV12PixelBufferWithWidth:(size_t)width
                                            height:(size_t)height;

/**
 创建 I420 类别的 CVPixelBufferRef
 
 @param width 图片 width
 @param height 图片 height
 @param format 数据格式
 @return 创建的 CVPixelBufferRef
 */
+ (CVPixelBufferRef)createI420PixelBufferWithWidth:(size_t)width
                                            height:(size_t)height;

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
                         height:(size_t)height;

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
                         height:(size_t)height;

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
                         height:(size_t)height;

@end
