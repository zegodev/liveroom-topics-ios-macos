//
//  ZGMetalPreviewRendererProtocol.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-defines-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-defines-oc.h>
#endif


NS_ASSUME_NONNULL_BEGIN

@protocol ZGMetalPreviewRendererProtocol <NSObject>

- (id<ZGMetalPreviewRendererProtocol>)initWithDevice:(id<MTLDevice>)device forRenderView:(MTKView *)renderView;

- (void)setRenderViewMode:(ZegoVideoViewMode)renderViewMode;

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
