//
//  ZegoMTKRenderView.h
//  ZegoLiveRoomWrapper
//
//  Created by Sky on 2019/7/3.
//  Copyright © 2019 zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import <MetalKit/MetalKit.h>
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/ZegoLiveRoomApiDefines.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ZegoMTKRenderView : MTKView

- (void)renderImage:(CVPixelBufferRef)image viewMode:(ZegoVideoViewMode)viewMode;

@end

NS_ASSUME_NONNULL_END

#endif
