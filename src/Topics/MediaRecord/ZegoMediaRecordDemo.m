//
//  ZegoMediaRecordDemo.m
//  LiveRoomPlayground-macOS
//
//  Created by Sky on 2018/12/17.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_MediaRecord

#import "ZegoMediaRecordDemo.h"
#import "ZGHelper.h"

@interface ZegoMediaRecordDemo () <ZegoRoomDelegate,ZegoLivePublisherDelegate,ZegoMediaRecordDelegage>

@property (assign, nonatomic) BOOL isPublishing;
@property (assign, nonatomic) BOOL isRecording;
@property (weak, nonatomic) id <ZegoMediaRecordDemoProtocol>delegate;
@property (strong, nonatomic) ZegoMediaRecordConfig *config;
@property (strong, nonatomic) ZegoMediaRecorder *recorder;

@end

@implementation ZegoMediaRecordDemo

- (instancetype)init {
    if (self = [super init]) {
        [ZGApiManager releaseApi];
        [self setupLiveRoom];
    }
    return self;
}

- (void)dealloc {
    [ZGApiManager releaseApi];
}

- (BOOL)setRecordConfig:(ZegoMediaRecordConfig *)config {
    if (_isRecording) {
        return NO;
    }
    self.config = config;
    return YES;
}

- (void)startPreview {
    NSLog(NSLocalizedString(@"startPreview", nil));
    
    if ([self.delegate respondsToSelector:@selector(getPlaybackView)]) {
        ZGView *view = [self.delegate getPlaybackView];
        [ZGApiManager.api setPreviewView:view];
    }

    [ZGApiManager.api startPreview];
}

- (void)stopPreview {
    [ZGApiManager.api stopPreview];
}

- (void)startPublish {
    NSLog(NSLocalizedString(@"startPublish", nil));
    
    [self loginLiveRoom];
}

- (void)stopPublish {
    NSLog(NSLocalizedString(@"stopPublish", nil));
    
    [ZGApiManager.api stopPublishing];
    self.isPublishing = NO;
}

- (void)startRecord {
    if (self.isRecording) {
        return;
    }
    if (!self.recorder) {
        self.recorder = [[ZegoMediaRecorder alloc] init];
    }

    [self.recorder setMediaRecordDelegage:self];
    [self.recorder startRecord:self.config.channel
                    recordType:self.config.recordType
                   storagePath:self.config.storagePath
            enableStatusUpdate:self.delegate ? YES:NO
                      interval:self.config.interval
                  recordFormat:self.config.recordFormat];
}

- (void)stopRecord {
    if (!self.isRecording) {
        return;
    }
    [self.recorder stopRecord:self.config.channel];
    self.isRecording = NO;
}

-(void)exit {
    if (self.isPublishing) {
        [self stopPublish];
    }
    if (self.isRecording) {
        [self stopRecord];
    }
    [self stopPreview];
    [ZGApiManager.api logoutRoom];
}


#pragma mark - Private

- (void)setupLiveRoom {
    ZegoAVConfig *avConfig = [ZegoAVConfig presetConfigOf:ZegoAVConfigPreset_High];
#if TARGET_OS_OSX
    CGSize resolution = CGSizeMake(480, 320);
    avConfig.videoEncodeResolution = resolution;
    avConfig.videoCaptureResolution = resolution;
#endif
    [ZGApiManager.api setAVConfig:avConfig];
    [ZGApiManager.api setRoomDelegate:self];
    [ZGApiManager.api setPublisherDelegate:self];
}

- (void)loginLiveRoom {
    NSLog(NSLocalizedString(@"开始登录房间", nil));
    
    NSString *roomID = ZGHelper.userID;
    
    Weakify(self);
    [ZGApiManager.api loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        
        NSLog(@"%s, error: %d", __func__, errorCode);
        if (errorCode == 0) {
            NSLog(NSLocalizedString(@"登录房间成功.", nil));
            [self doPublish];
        }
        else {
            NSLog(NSLocalizedString(@"登录房间失败. error: %d", nil), errorCode);
        }
    }];
}

- (void)doPublish {
    NSString *streamID = ZGHelper.userID;
    bool res = [ZGApiManager.api startPublishing:streamID title:nil flag:ZEGO_JOIN_PUBLISH];
    if (res) {
        NSLog(NSLocalizedString(@"🍏开始直播成功.", nil));
        self.isPublishing = YES;
    }
    else {
        NSLog(NSLocalizedString(@"🍎开始直播失败.", nil));
    }
}


#pragma mark - Delegate

- (void)onMediaRecord:(int)errCode channelIndex:(ZegoAPIMediaRecordChannelIndex)index storagePath:(NSString *)path {
    BOOL success = errCode == 0;
    self.isRecording = success;
}

- (void)onRecordStatusUpdateFromChannel:(ZegoAPIMediaRecordChannelIndex)index storagePath:(NSString *)path duration:(unsigned int)duration fileSize:(unsigned int)size {
    if ([self.delegate respondsToSelector:@selector(onRecordStatusUpdateFromChannel:storagePath:duration:fileSize:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onRecordStatusUpdateFromChannel:index storagePath:path duration:duration fileSize:size];
        });
    }
}

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    BOOL success = stateCode == 0;
    self.isPublishing = success;
    if (!success) {
        NSLog(NSLocalizedString(@"🍎推流失败, error: %d", nil), stateCode);
    }
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    NSLog(NSLocalizedString(@"🍎连接失败, error: %d", nil), errorCode);
    self.isPublishing = NO;
}


#pragma mark - Access

- (void)setIsPublishing:(BOOL)isPublishing {
    _isPublishing = isPublishing;
    if ([self.delegate respondsToSelector:@selector(onPublishStateChange:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onPublishStateChange:isPublishing];
        });
    }
}

- (void)setIsRecording:(BOOL)isRecording {
    _isRecording = isRecording;
    if ([self.delegate respondsToSelector:@selector(onRecordStateChange:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onRecordStateChange:isRecording];
        });
    }
}

@end

#endif
