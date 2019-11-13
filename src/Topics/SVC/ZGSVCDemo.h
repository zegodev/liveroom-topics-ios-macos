//
//  ZegoSVCDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/14.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, StreamLayerType) {
    StreamLayerTypeAuto = 0,
    StreamLayerTypeBase = 1,
    StreamLayerTypeExtend = 2,
};

@protocol ZGSVCDemoProtocol <NSObject>

- (ZEGOView *)getPlaybackView;

@optional

- (void)onSVCPublishQualityUpdate:(NSString *)state;
- (void)onSVCPlayQualityUpdate:(NSString *)state;
- (void)onSVCVideoSizeChanged:(NSString *)state;

@end

@interface ZGSVCDemo : NSObject

@property (nonatomic, weak) id <ZGSVCDemoProtocol>delegate;

// 拉流的视频分层模式
@property (nonatomic, assign) StreamLayerType streamLayerType;

// 是否开启分层编码
@property (nonatomic, assign) BOOL openSVC;

- (instancetype)initWithRoomID:(NSString *)roomID streamID:(NSString *)streamID isAnchor:(BOOL)isAnchor;

- (void)loginRoom;
- (void)logoutRoom;
- (void)startPreview;
- (void)stopPreview;
- (void)startPublish;
- (void)stopPublish;
- (void)startPlay;
- (void)stopPlay;
- (void)switchPlayStreamVideoLayer;

@end

NS_ASSUME_NONNULL_END

#endif
