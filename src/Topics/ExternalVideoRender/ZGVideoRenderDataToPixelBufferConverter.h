//
//  ZGVideoRenderDataToPixelBufferConverter.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_ExternalVideoRender

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-external-video-render-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-external-video-render-oc.h>
#endif

@class ZGVideoRenderDataToPixelBufferConverter;

typedef void(^ZGVideoRenderDataToPixelBufferConvertCompletion)(ZGVideoRenderDataToPixelBufferConverter *converter, CVPixelBufferRef buffer);

/**
 视频渲染数据转换成 CVPixelBufferRef 的转换器
 */
@interface ZGVideoRenderDataToPixelBufferConverter : NSObject

/**
 将视频数据塞给 converter 处理，处理完成后将在另一线程中通过 completion 回调输出 CVPixelBufferRef。
 
 由于 CVPixelBufferRef 对于格式的限制，只能生成 BGRA（1平面），NV12（2平面），I420（3平面）的CVPixelBufferRef。
 
 @param data 待渲染数据。根据 pixelFormat 参数的不同可能包含 1 、2、3平面的数据。
 @param dataLen 待渲染数据每个平面的数据大小，根据 pixelFormat 参数的不同可能为 1 、2、3 大小。
 @param width 图像宽
 @param height 图像高
 @param strides 每个平面一行字节数，共 4 个面（RGB类别只需考虑 strides[0]）
 @param pixelFormat format type, 用于指定 data 的数据类型
 */
- (void)convertToPixelBufferWithData:(const unsigned char **)data dataLen:(int*)dataLen width:(int)width height:(int)height strides:(int[])strides pixelFormat:(VideoPixelFormat)pixelFormat completion:(ZGVideoRenderDataToPixelBufferConvertCompletion)completion;

@end

#endif
