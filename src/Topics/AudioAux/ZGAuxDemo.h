//
//  ZGAuxDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/16.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_AudioAux

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGAuxDemoProtocol <NSObject>

- (ZGView *)getPlaybackView;

@optional

- (void)onAuxPublishStateUpdate:(NSString *)state;
- (void)onAuxPublishQualityUpdate:(NSString *)state;

- (void)onAuxPlayStateUpdate:(NSString *)state;
- (void)onAuxPlayQualityUpdate:(NSString *)state;

@end

@interface ZGAuxDemo : NSObject

@property (nonatomic, weak) id <ZGAuxDemoProtocol>delegate;

- (instancetype)initWithRoomID:(NSString *)roomID streamID:(NSString *)streamID isAnchor:(BOOL)isAnchor;

- (void)loginRoom;
- (void)logoutRoom;
- (void)startPreview;
- (void)stopPreview;
- (void)startPublish;
- (void)stopPublish;
- (void)startPlay;
- (void)stopPlay;

- (void)onSwitchAux:(BOOL)enable;
- (void)changeAuxVolume:(int)volume;
- (void)onSwitchMuteAux:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END

#endif
