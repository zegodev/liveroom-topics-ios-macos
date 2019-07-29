//
//  ZGPlayDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/5/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Play

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGPlayDemoDelegate <NSObject>

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID;

@optional
- (void)onPlayQualityUpdate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality;

@end

/**
 拉流帮助类
 
 @discussion 主要简化SDK推流一系列接口
 @note 开发者可参考该类的代码, 理解SDK接口
 @warning 注意!!! 开发者需要先初始化sdk, 登录房间后, 才能进行拉流
 */
@interface ZGPlayDemo : NSObject

@property (assign, nonatomic, readonly) BOOL isPlaying;

@property (copy, nonatomic, readonly, nullable) NSString *streamID;

@property (weak, nonatomic) id<ZGPlayDemoDelegate> delegate;

+ (instancetype)shared;

- (BOOL)startPlayingStream:(NSString *)streamID inView:(nullable ZEGOView *)view;
- (void)stopPlay;

- (void)updatePlayView:(nullable ZEGOView *)view;
- (void)updatePlayViewMode:(ZegoVideoViewMode)mode;

@end

NS_ASSUME_NONNULL_END

#endif
