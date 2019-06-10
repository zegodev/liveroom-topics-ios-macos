//
//  ZGSVCDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2018/11/12.
//  Copyright © 2018 Zego. All rights reserved.
//

#import "ZGApiManager.h"

@class ZGRoomInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol ZGSVCDemoProtocol <NSObject>

- (ZGView *)getMainPlaybackView;
- (ZGView *)getSubPlaybackView;
- (void)onPublishStateUpdate;
- (void)onBoardcastStateUpdate;
- (void)onPublishQualityUpdate:(NSString *)state;
- (void)onPlayQualityUpdate:(NSString *)state;
- (void)onVideoSizeChanged:(NSString *)state;

@end


@interface ZGSVCDemo : NSObject

@property (assign ,nonatomic) BOOL useFrontCam;
@property (assign ,nonatomic) VideoStreamLayer videoLayer;

@property (assign ,nonatomic, readonly) BOOL openSVC;
@property (strong ,nonatomic, readonly) ZGRoomInfo *roomInfo;
@property (assign ,nonatomic, readonly) BOOL isPublishing;
@property (assign ,nonatomic, readonly) BOOL isBoardcasting;
@property (assign ,nonatomic, readonly) BOOL isRequestBoardcast;

@property (nonatomic, weak) id <ZGSVCDemoProtocol>delegate;

+ (instancetype)demoWithRole:(ZegoRole)role openSVC:(BOOL)openSVC roomInfo:(ZGRoomInfo *)roomInfo;

- (void)startPublish;
- (void)stopPublish;

- (void)startPlay;
- (void)stopPlay;

- (void)startBoardCast;
- (void)stopBoardCast;

- (void)exit;

- (void)refreshPlaybackView;

@end

NS_ASSUME_NONNULL_END
