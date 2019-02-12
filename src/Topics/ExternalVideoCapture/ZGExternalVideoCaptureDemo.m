//
//  ZGExternalVideoCaptureDemo.m
//  LiveRoomPlayground
//
//  Created by Sky on 2019/1/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoCaptureDemo.h"
#import "ZGHelper.h"

@interface ZGExternalVideoCaptureDemo () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoLivePlayerDelegate>

@property (assign ,nonatomic) BOOL isLoginRoom;
@property (assign ,nonatomic) BOOL isPublishing;
@property (assign ,nonatomic) BOOL isPreview;
@property (assign ,nonatomic) BOOL isPlaying;
@property (copy, nonatomic) NSString *streamID;

@property (strong, nonatomic) ZGExternalVideoCaptureManager *manager;

@end

@implementation ZGExternalVideoCaptureDemo

- (void)dealloc {
    [ZGManager releaseApi];
    [ZegoExternalVideoCapture setVideoCaptureFactory:nil channelIndex:ZEGOAPI_CHN_MAIN];
}

- (instancetype)init {
    if (self = [super init]) {
        [ZGManager releaseApi];
        
        _manager = [ZGExternalVideoCaptureManager new];
        [ZegoExternalVideoCapture setVideoCaptureFactory:_manager channelIndex:ZEGOAPI_CHN_MAIN];
    }
    return self;
}

- (void)startLive {
    [self setupLiveRoom];
    [self loginLiveRoom];
}

- (void)stop {
    [self stopPlay];
    [self stopPublish];
    [self stopPreview];
    [ZGManager.api logoutRoom];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate onLiveStateUpdate];
    });
}

- (void)setCaptureSourceType:(ZGExternalVideoCaptureSourceType)sourceType {
    NSLog(NSLocalizedString(@"setCaptureSourceType:%d", nil), sourceType);
    [self.manager setSourceType:sourceType];
}


#pragma mark - Private

- (void)setupLiveRoom {
    ZegoAVConfig *config = [ZegoAVConfig presetConfigOf:ZegoAVConfigPreset_High];
    
    [ZGManager.api setAVConfig:config];
    [ZGManager.api setRoomDelegate:self];
    [ZGManager.api setPlayerDelegate:self];
    [ZGManager.api setPublisherDelegate:self];
}

- (void)loginLiveRoom {
    NSLog(NSLocalizedString(@"开始登录房间", nil));
    
    NSString *roomID = [self genRoomID];
    
    __weak typeof(self)weakself = self;
    [ZGManager.api loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        __strong typeof(weakself)strongself = weakself;
        if (errorCode == 0) {
            NSLog(NSLocalizedString(@"登录房间成功. roomID: %@", nil), roomID);
            strongself.isLoginRoom = YES;
            [strongself startPreview];
            [strongself startPublish];
        }
        else {
            NSLog(NSLocalizedString(@"登录房间失败. error: %d", nil), errorCode);
            strongself.isLoginRoom = NO;
            [strongself stop];
        }
    }];
}

- (void)startPreview {
    if (self.isPreview) {
        return;
    }
    
    ZGView *view = [self.delegate getMainPlaybackView];
    
    // 由于目前SDK启用外部视频采集时不会自动渲染到preivewView上，所以暂时在此使用manager代为处理
    //    [ZGManager.api setPreviewView:view];
    [ZGManager.api startPreview];
    [self.manager setPreviewView:view viewMode:ZegoVideoViewModeScaleAspectFill];
    
    self.isPreview = YES;
    NSLog(NSLocalizedString(@"startPreview", nil));
}

- (void)stopPreview {
    if (!self.isPreview) {
        return;
    }
    
    [ZGManager.api stopPreview];
    [ZGManager.api setPreviewView:nil];
    
    self.isPreview = NO;
    NSLog(NSLocalizedString(@"stopPreview", nil));
}

- (void)startPublish {
    if (!self.isLoginRoom || self.isPublishing) {
        return;
    }
    
    self.streamID = [self genStreamID];
    [ZGManager.api startPublishing:self.streamID title:nil flag:ZEGO_SINGLE_ANCHOR];
    
    NSLog(NSLocalizedString(@"startPublish:%@", nil), self.streamID);
}

- (void)stopPublish {
    if (!self.isPublishing) {
        return;
    }
    
    NSLog(NSLocalizedString(@"stopPublish", nil));
    
    self.isPublishing = NO;
    self.streamID = nil;

    [ZGManager.api stopPublishing];
}

- (void)startPlay {
    if (!self.isLoginRoom || self.isPlaying) {
        return;
    }
    
    NSAssert(self.streamID, @"streamID invalid");
    NSLog(NSLocalizedString(@"startPlay", nil));
    
    [ZGManager.api startPlayingStream:self.streamID inView:[self.delegate getSubPlaybackView]];
    [ZGManager.api setViewMode:ZegoVideoViewModeScaleToFill ofStream:self.streamID];
}

- (void)stopPlay {
    if (!self.isPlaying) {
        return;
    }
    
    NSAssert(self.streamID, @"streamID invalid");
    NSLog(NSLocalizedString(@"stopPlay", nil));
    [ZGManager.api stopPlayingStream:self.streamID];
    self.isPlaying = NO;
}


#pragma mark - ZegoRoomDelegate

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    NSLog(NSLocalizedString(@"🍎连接失败, error: %d", nil), errorCode);
    self.isPublishing = NO;
    [self stop];
}


#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    BOOL success = stateCode == 0;
    self.isPublishing = success;
    
    NSLog(NSLocalizedString(@"onPublishStateUpdate,success:%d", nil), success);
    
    success ? [self startPlay]:[self stop];
}


#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    BOOL success = stateCode == 0;
    self.isPlaying = success;
    
    NSLog(NSLocalizedString(@"onPlayStateUpdate,success:%d", nil), success);
    
    success ? [self startPublish]:[self stop];
    
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate onLiveStateUpdate];
        });
    }
}


#pragma mark - Access

- (BOOL)isLive {
    return self.isLoginRoom && self.isPublishing && self.isPlaying;
}

- (NSString *)genRoomID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"#evc-%@-%lu", ZGHelper.userID, currentTime];
}

- (NSString *)genStreamID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"s-%@-%lu", ZGHelper.userID, currentTime];
}


@end
