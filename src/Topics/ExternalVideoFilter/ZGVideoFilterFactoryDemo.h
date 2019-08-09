//
//  FaceUVideoFilterFactoryDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 外部滤镜工厂 Demo
 */
@interface ZGVideoFilterFactoryDemo : NSObject<ZegoVideoFilterFactory>

// 此处的 bufferType 对应三种滤镜类型，以创建不同的外部滤镜实例
@property (nonatomic, assign) ZegoVideoBufferType bufferType;

@end

NS_ASSUME_NONNULL_END

#endif
