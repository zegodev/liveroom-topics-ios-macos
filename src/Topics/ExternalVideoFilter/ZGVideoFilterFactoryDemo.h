//
//  FaceUVideoFilterFactoryDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-external-video-filter-oc.h>
#elif TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-external-video-filter-oc.h>
#endif
NS_ASSUME_NONNULL_BEGIN


/**
 外部滤镜工厂 Demo
 */
@interface ZGVideoFilterFactoryDemo : NSObject<ZegoVideoFilterFactory>

// 此处的 bufferType 对应四种滤镜类型，以创建不同的外部滤镜实例
@property (nonatomic, assign) ZegoVideoBufferType bufferType;

@end

NS_ASSUME_NONNULL_END

#endif
