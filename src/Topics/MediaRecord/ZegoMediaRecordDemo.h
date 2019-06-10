//
//  ZegoMediaRecordDemo.h
//  LiveRoomPlayground-macOS
//
//  Created by Sky on 2018/12/17.
//  Copyright © 2018 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGApiManager.h"
#import "ZegoMediaRecordConfig.h"

@protocol ZegoMediaRecordDemoProtocol <NSObject>

@optional
- (ZGView *)getPlaybackView;
- (void)onPublishStateChange:(BOOL)isPublishing;
- (void)onRecordStateChange:(BOOL)isRecording;
- (void)onRecordStatusUpdateFromChannel:(ZegoAPIMediaRecordChannelIndex)index storagePath:(NSString *)path duration:(unsigned int)duration fileSize:(unsigned int)size;

@end

NS_ASSUME_NONNULL_BEGIN

@interface ZegoMediaRecordDemo : NSObject

@property (assign, nonatomic, readonly) BOOL isPublishing;
@property (assign, nonatomic, readonly) BOOL isRecording;
@property (strong, nonatomic, readonly) ZegoMediaRecordConfig *config;

- (void)setDelegate:(id <ZegoMediaRecordDemoProtocol>)delegate;
- (BOOL)setRecordConfig:(ZegoMediaRecordConfig *)config;

- (void)startPreview;
- (void)stopPreview;
- (void)startPublish;
- (void)stopPublish;
- (void)startRecord;
- (void)stopRecord;

- (void)exit;

@end

NS_ASSUME_NONNULL_END
