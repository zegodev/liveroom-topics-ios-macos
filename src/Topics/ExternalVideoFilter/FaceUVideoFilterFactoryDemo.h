//
//  FaceUVideoFilterFactoryDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZegoLiveRoom/ZegoVideoCapture.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FaceUVideoFilterBufferType) {
    FaceUVideoFilterBufferTypeAsync = 0,
    FaceUVideoFilterBufferTypeSync = 1,
    FaceUVideoFilterBufferTypeI420 = 2,
};


/**
 集成 face unity 滤镜的异步类型滤镜实现
 */
@interface FaceUVideoFilterAsyncDemo : NSObject<ZegoVideoFilter, ZegoVideoBufferPool>

@end

/**
 集成 face unity 滤镜的同步类型滤镜实现
 */
@interface FaceUVideoFilterSyncDemo : NSObject<ZegoVideoFilter, ZegoVideoFilterDelegate>

@end

/**
 集成 face unity 滤镜的 i420 类型滤镜实现
 */
@interface FaceUVideoFilterI420Demo : NSObject<ZegoVideoFilter, ZegoVideoBufferPool>

@end


/**
 face unity 的滤镜工厂 demo
 */
@interface ZGVideoFilterFactoryDemo : NSObject<ZegoVideoFilterFactory>

@property (nonatomic, assign) FaceUVideoFilterBufferType bufferType;

@end

NS_ASSUME_NONNULL_END
