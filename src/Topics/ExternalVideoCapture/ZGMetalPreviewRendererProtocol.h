//
//  ZGMetalPreviewRendererProtocol.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGMetalPreviewRendererProtocol <NSObject>

- (id<ZGMetalPreviewRendererProtocol>)initWithDevice:(id<MTLDevice>)device forRenderView:(MTKView *)renderView;

- (void)setRenderViewMode:(ZegoVideoViewMode)renderViewMode;

- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
