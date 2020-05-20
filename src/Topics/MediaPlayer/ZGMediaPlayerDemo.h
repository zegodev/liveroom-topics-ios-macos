//
//  ZGMediaPlayerDemo.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#ifdef _Module_MediaPlayer

#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#import <ZegoLiveRoomOSX/zego-api-mediaplayer-oc.h>
#import <ZegoLiveRoomOSX/zego-api-external-video-capture-oc.h>
#elif TARGET_OS_IOS
#import <UIKit/UIKit.h>
#import <ZegoLiveRoom/zego-api-mediaplayer-oc.h>
#endif

#import "ZGMediaPlayerPublishingHelper.h"


NS_ASSUME_NONNULL_BEGIN

@protocol ZGMediaPlayerDemoDelegate

- (void)onPlayerState:(NSString*)state;
- (void)onPlayerProgress:(long)current max:(long)max desc:(NSString*)desc;
- (void)onPlayerStop;
- (void)onPublishState:(NSString*)state;

- (void)onGetAudioStreamCount:(int)count;

@end

@interface ZGMediaPlayerDemo : NSObject

@property (weak) id<ZGMediaPlayerDemoDelegate> delegate;

- (void)setPlayerType:(MediaPlayerType)type;
- (void)setVideoView:(ZEGOView* _Nullable)view;
- (void)setVolume:(int)volume;
- (void)startPlaying:(NSString* _Nonnull)url repeat:(BOOL)repeat;
- (void)stop;
- (void)pause;
- (void)resume;

- (void)seekTo:(long)millisecond;

- (void)setAudioStream:(int)stream;

@end

NS_ASSUME_NONNULL_END

#endif
