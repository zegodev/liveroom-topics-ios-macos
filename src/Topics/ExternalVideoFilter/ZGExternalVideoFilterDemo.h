//
//  ZGExternalVideoFilterDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 外部滤镜入口示例类
 
 @note 管理外部滤镜工厂对象的初始化与手动销毁
 */
@interface ZGExternalVideoFilterDemo : NSObject

+ (instancetype)shared;


/**
 初始化外部滤镜工厂对象
 
 @param type 视频缓冲区类型（Async, Sync, I420）
 @discussion 创建外部滤镜工厂对象后，先释放 ZegoLiveRoomSDK 确保 setVideoFilterFactory:channelIndex: 的调用在 initSDK 前
 */
- (void)initFilterFactoryType:(ZegoVideoBufferType)type;


/**
 释放外部滤镜工厂对象
 */
- (void)releaseFilterFactory;

@end

NS_ASSUME_NONNULL_END

#endif
