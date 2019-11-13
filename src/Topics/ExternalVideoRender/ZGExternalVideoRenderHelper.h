//
//  ZGExternalVideoRenderHelper.h
//  LiveRoomPlayground
//
//  Created by Sky on 2019/1/29.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoRender

#import <Foundation/Foundation.h>
#import "ZGDemoVideoRenderTypeItem.h"

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-external-video-render-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-external-video-render-oc.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoRenderHelper : NSObject

+ (void)showRenderData:(CVImageBufferRef)image inView:(ZEGOView *)view viewMode:(ZegoVideoViewMode)viewMode;
+ (void)removeRenderDataInView:(ZEGOView *)view;


/**
 专题demo的渲染类型项列表
 */
+ (NSArray<ZGDemoVideoRenderTypeItem*> *)demoRenderTypeItems;


/**
 判断某个视频渲染类型是否会进行内部渲染

 @param renderType 视频渲染类型
 */
+ (BOOL)isInternalVideoRenderType:(VideoRenderType)renderType;

@end

NS_ASSUME_NONNULL_END

#endif
