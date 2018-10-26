//
//  ZGMediaSideInfoDemo.h
//  LiveRoomPlayground
//
//  Created by Randy Qiu on 2018/10/25.
//  Copyright © 2018 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-media-side-info-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-media-side-info-oc.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface ZGMediaSideInfoDemoConfig : NSObject

/**
 是否纯音频推流。
 @discussion YES 不传输视频数据；NO 音视频直播，传输视频数据。
 @note 默认为 NO。
 */
@property BOOL onlyAudioPublish;

/**
 是否自定义打包。
 @discussion YES 发送的数据已经打包好了，并且符合打包规范；NO 数据由 SDK 打包。
 @note 默认为 NO。
 */
@property BOOL customPacket;

@end


@protocol ZGMediaSideInfoDemoDelegate <NSObject>

@required
/**
 接收到媒体次要信息回调

 @param data 接收到的数据
 @param streamID 流ID，标记当前回调的信息所属媒体流
 */
- (void)onReceiveMediaSideInfo:(NSData*)data ofStream:(NSString*)streamID;

@optional
- (void)onReceiveMixStreamUserData:(NSData*)data ofStream:(NSString*)streamID;

@end


@interface ZGMediaSideInfoDemo : NSObject

@property (weak) id<ZGMediaSideInfoDemoDelegate> delegate;

- (instancetype)initWithConfig:(ZGMediaSideInfoDemoConfig*)config;

/**
 激活媒体次要信息通道

 @param channelIndex 推流通道
 */
- (void)activateMediaSideInfoForPublishChannel:(ZegoAPIPublishChannelIndex)channelIndex;

/**
 发送媒体次要信息

 @param data 待发送的媒体次要信息
 @param channelIndex 推流通道
 */
- (void)sendMediaSideInfo:(NSData*)data toPublishChannel:(ZegoAPIPublishChannelIndex)channelIndex;

/**
 发送媒体次要信息

 @param data 待发送的媒体次要信息
 @discussion 等同于 [-sendMediaSideInfo:data toPublishChannel:ZEGOAPI_CHN_MAIN]
 */
- (void)sendMediaSideInfo:(NSData*)data;

@end

NS_ASSUME_NONNULL_END
