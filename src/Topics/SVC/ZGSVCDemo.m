//
//  ZGSVCDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2018/11/12.
//  Copyright © 2018 Zego. All rights reserved.
//

#import "ZGSVCDemo.h"
#import "ZGHelper.h"
#import "ZGRoomInfo.h"

@interface ZGSVCDemo () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoLivePlayerDelegate>

@property (assign ,nonatomic) ZegoRole role;
@property (assign ,nonatomic) BOOL openSVC;
@property (strong ,nonatomic) ZGRoomInfo *roomInfo;
@property (copy ,nonatomic) NSString *streamID;
@property (copy ,nonatomic) NSString *boardcastStreamID;

@property (assign ,nonatomic) BOOL isPublishing;
@property (assign ,nonatomic) BOOL isBoardcasting;
@property (assign ,nonatomic) BOOL isRequestBoardcast;

@property (strong, nonatomic) NSMutableArray<ZegoStream *> *streamList;
@property (copy ,nonatomic) NSMutableDictionary <NSString*,NSString*>*streamSizeDic;

@end

@implementation ZGSVCDemo

+ (instancetype)demoWithRole:(ZegoRole)role openSVC:(BOOL)openSVC roomInfo:(ZGRoomInfo *)roomInfo {
    ZGSVCDemo *instance = [[ZGSVCDemo alloc] init];
    instance.role = role;
    instance.openSVC = openSVC;
    
    if (!roomInfo) {
        roomInfo = [ZGRoomInfo new];
    }
    if (role == ZEGO_ANCHOR) {
        roomInfo.roomID = [instance genRoomID];
        roomInfo.anchorID = ZGHelper.userID;
        roomInfo.roomName = roomInfo.roomName ?:[instance genRoomName];
    }
    
    instance.roomInfo = roomInfo;
    return instance;
}

- (void)dealloc {
    [ZGManager releaseApi];
}

- (void)startPublish {
    NSLog(NSLocalizedString(@"startPublish", nil));
    
    self.role = ZEGO_ANCHOR;
    [self setupLiveRoom];
    [self loginLiveRoom];
}

- (void)stopPublish {
    NSLog(NSLocalizedString(@"stopPublish", nil));
    
    self.isPublishing = NO;
    self.streamID = nil;
    [ZGManager.api stopPreview];
    [ZGManager.api setPreviewView:nil];
    [ZGManager.api stopPublishing];
    
    [self.delegate onPublishStateUpdate];
}

- (void)startPlay {
    NSLog(NSLocalizedString(@"startPlay", nil));
    
    self.role = ZEGO_AUDIENCE;
    [self setupLiveRoom];
    [self loginLiveRoom];
}

- (void)stopPlay {
    NSLog(NSLocalizedString(@"stopPlay", nil));
    
    for (ZegoStream *stream in self.streamList) {
        [ZGManager.api stopPlayingStream:stream.streamID];
    }
}

- (void)startBoardCast {
    self.isRequestBoardcast = YES;
    
    __weak typeof(self)weakself = self;
    BOOL res = [ZGManager.api requestJoinLive:^(int result, NSString *fromUserID, NSString *fromUserName) {
        if (result != 0) {
            NSLog(NSLocalizedString(@"主播同意了你的请求", nil));
            [self doBoardcast];
        }
        else {
            NSLog(NSLocalizedString(@"主播拒绝请求连麦", nil));
        }
        
        weakself.isRequestBoardcast = NO;
    }];
    
    NSLog(NSLocalizedString(@"startBoardCast %@", nil), res ? @"success":@"failed");
}

- (void)stopBoardCast {
    NSLog(NSLocalizedString(@"stopBoardCast", nil));
    
    self.isPublishing = NO;
    self.isBoardcasting = NO;
    self.boardcastStreamID = nil;
    [ZGManager.api stopPreview];
    [ZGManager.api setPreviewView:nil];
    [ZGManager.api stopPublishing];
    
    [self.delegate onPublishStateUpdate];
    [self.delegate onBoardcastStateUpdate];
}

- (void)exit {
    if (self.isPublishing) {
        [self stopPublish];
    }
    if (self.isBoardcasting) {
        [self stopBoardCast];
    }
    
    [self stopPlay];
    [ZGManager.api logoutRoom];
    
    [self.delegate onPublishStateUpdate];
}

- (void)refreshPlaybackView {
    if (self.role == ZEGO_ANCHOR) {//主播
        if (self.isBoardcasting) {
            [ZGManager.api updatePlayView:[self.delegate getSubPlaybackView] ofStream:self.boardcastStreamID];
        }
        [ZGManager.api setPreviewView:[self.delegate getMainPlaybackView]];
    }
    else {
        if (self.isBoardcasting && self.isPublishing) {//连麦者
            ZegoStream *mainStream = [self getStreamWithUserID:self.roomInfo.anchorID];
            [ZGManager.api updatePlayView:[self.delegate getMainPlaybackView] ofStream:mainStream.streamID];
            [ZGManager.api setPreviewView:[self.delegate getSubPlaybackView]];
        }
        else {//观众
            ZegoStream *mainStream = [self getStreamWithUserID:self.roomInfo.anchorID];
            if (mainStream) {
                [ZGManager.api updatePlayView:[self.delegate getMainPlaybackView] ofStream:mainStream.streamID];
            }
            if (self.streamList.count > 1) {
                NSInteger mainIndex = [self.streamList indexOfObject:mainStream];
                ZegoStream *subStream = self.streamList[mainIndex == 0 ? 1:0];
                [ZGManager.api updatePlayView:[self.delegate getSubPlaybackView] ofStream:subStream.streamID];
            }
        }
    }
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
    
    __weak typeof(self)weakself = self;
    [ZGManager.api loginRoom:self.roomInfo.roomID roomName:self.roomInfo.roomName role:self.role withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        NSLog(@"%s, error: %d", __func__, errorCode);
        if (errorCode == 0) {
            NSLog(NSLocalizedString(@"登录房间成功. roomID: %@", nil),self.roomInfo.roomID);
            if (weakself.role == ZEGO_ANCHOR) {
                [weakself doPublish];
            }
            else {
                weakself.streamList = streamList.mutableCopy;
                [weakself doPlay];
            }
        }
        else {
            NSLog(NSLocalizedString(@"登录房间失败. error: %d", nil), errorCode);
        }
    }];
}

- (void)doPublish {
    [ZGManager.api setFrontCam:self.useFrontCam];
    [ZGManager.api setPreviewView:[self.delegate getMainPlaybackView]];
    [ZGManager.api startPreview];
    
    if (self.openSVC) {
        [ZGManager.api setLatencyMode:ZEGOAPI_LATENCY_MODE_LOW3];
        [ZGManager.api setVideoCodecId:VIDEO_CODEC_MULTILAYER ofChannel:ZEGOAPI_CHN_MAIN];
        [ZGManager.api enableTrafficControl:true properties: (ZEGOAPI_TRAFFIC_NONE | ZEGOAPI_TRAFFIC_FPS | ZEGOAPI_TRAFFIC_RESOLUTION)];
    }
    
    self.streamID = [self genStreamID];
    bool res = [ZGManager.api startPublishing:self.streamID title:nil flag:ZEGO_JOIN_PUBLISH];
    if (res) {
        NSLog(NSLocalizedString(@"🍏开始直播成功，流ID:%@", nil), self.streamID);
        self.isPublishing = YES;
        [self.delegate onPublishStateUpdate];
    }
    else {
        NSLog(NSLocalizedString(@"🍎开始直播失败，流ID:%@", nil), self.streamID);
    }
}

- (void)doPlay {
    ZegoStream *mainStream = [self getStreamWithUserID:self.roomInfo.anchorID];
    if (mainStream) {
        [ZGManager.api startPlayingStream:mainStream.streamID inView:[self.delegate getMainPlaybackView]];
        if (self.openSVC) {
            [ZGManager.api activateVideoPlayStream:mainStream.streamID active:true videoLayer:self.videoLayer];
        }
    }
    
    if (self.streamList.count > 1) {
        NSInteger mainIndex = [self.streamList indexOfObject:mainStream];
        ZegoStream *subStream = self.streamList[mainIndex == 0 ? 1:0];
        [ZGManager.api startPlayingStream:subStream.streamID inView:[self.delegate getSubPlaybackView]];
        if (self.openSVC) {
            [ZGManager.api activateVideoPlayStream:subStream.streamID active:true videoLayer:self.videoLayer];
        }
        
        self.isBoardcasting = YES;
        [self.delegate onBoardcastStateUpdate];
    }
}

- (void)doBoardcast {
    [ZGManager.api setFrontCam:self.useFrontCam];
    [ZGManager.api setPreviewView:[self.delegate getSubPlaybackView]];
    [ZGManager.api startPreview];
    
    if (self.openSVC) {
        [ZGManager.api setLatencyMode:ZEGOAPI_LATENCY_MODE_LOW3];
        [ZGManager.api setVideoCodecId:VIDEO_CODEC_MULTILAYER ofChannel:ZEGOAPI_CHN_MAIN];
        [ZGManager.api enableTrafficControl:true properties: (ZEGOAPI_TRAFFIC_NONE | ZEGOAPI_TRAFFIC_FPS | ZEGOAPI_TRAFFIC_RESOLUTION)];
    }
    
    self.boardcastStreamID = [self genStreamID];
    bool res = [ZGManager.api startPublishing:self.boardcastStreamID title:nil flag:ZEGO_JOIN_PUBLISH];
    if (res) {
        NSLog(NSLocalizedString(@"🍏连麦成功，流ID:%@", nil), self.boardcastStreamID);
        self.isPublishing = YES;
        self.isBoardcasting = YES;
        
        [self.delegate onPublishStateUpdate];
        [self.delegate onBoardcastStateUpdate];
    }
    else {
        NSLog(NSLocalizedString(@"🍎连麦失败，流ID:%@", nil), self.boardcastStreamID);
    }
}

- (void)onStreamUpdateForAdd:(NSArray<ZegoStream *> *)streamList {
    for (ZegoStream *stream in streamList) {
        NSString *streamID = stream.streamID;
        if (streamID.length == 0)
            continue;
        
        if ([self isStreamIDExist:streamID]) {
            continue;
        }
        
        [ZGManager.api startPlayingStream:streamID inView:[self.delegate getSubPlaybackView]];
        [ZGManager.api setViewMode:ZegoVideoViewModeScaleAspectFit ofStream:streamID];
        if (self.openSVC) {
            [ZGManager.api activateVideoPlayStream:streamID active:true videoLayer:self.videoLayer];
        }
        
        [self.streamList addObject:stream];
        self.isBoardcasting = YES;
        self.boardcastStreamID = streamID;
        [self.delegate onBoardcastStateUpdate];
        
        NSLog(NSLocalizedString(@"新增一条流, 流ID:%@", nil), streamID);
    }
}

- (void)onStreamUpdateForDelete:(NSArray<ZegoStream *> *)streamList {
    for (ZegoStream *stream in streamList) {
        NSString *streamID = stream.streamID;
        if (![self isStreamIDExist:streamID]) {
            continue;
        }
        
        [ZGManager.api stopPlayingStream:streamID];
        
        [self removeStreamInfo:streamID];
        self.isBoardcasting = NO;
        self.boardcastStreamID = nil;
        [self.delegate onBoardcastStateUpdate];
        
        NSLog(NSLocalizedString(@"删除一条流, 流ID:%@", nil), streamID);
    }
}

- (ZegoStream *)getStreamWithUserID:(NSString *)userID {
    for (ZegoStream *info in self.streamList) {
        if ([info.userID isEqualToString:userID]) {
            return info;
        }
    }
    return nil;
}

- (BOOL)isStreamIDExist:(NSString *)streamID {
    if ([self.streamID isEqualToString:streamID]) {
        return YES;
    }
    
    for (ZegoStream *info in self.streamList) {
        if ([info.streamID isEqualToString:streamID]) {
            return YES;
        }
    }
    
    return NO;
}

- (void)removeStreamInfo:(NSString *)streamID {
    NSInteger index = NSNotFound;
    for (ZegoStream *info in self.streamList) {
        if ([info.streamID isEqualToString:streamID]) {
            index = [self.streamList indexOfObject:info];
            break;
        }
    }
    
    if (index != NSNotFound) {
        self.streamSizeDic[streamID] = nil;
        [self.streamList removeObjectAtIndex:index];
    }
}

- (NSString *)addStaticsInfo:(BOOL)publish stream:(NSString *)streamID fps:(double)fps kbs:(double)kbs akbs:(double)akbs rtt:(int)rtt pktLostRate:(int)pktLostRate {
    if (streamID.length == 0) {
        return nil;
    }
    
    // 丢包率的取值为 0~255，需要除以 256.0 得到丢包率百分比
    NSString *qualityString = [NSString stringWithFormat:NSLocalizedString(@"[%@] 帧率: %.3f, 视频码率: %.3f kb/s, 音频码率: %.3f kb/s, 延时: %d ms, 丢包率: %.3f%%", nil), publish ? NSLocalizedString(@"推流", nil): NSLocalizedString(@"拉流", nil), fps, kbs, akbs, rtt, pktLostRate/256.0 * 100];

    return qualityString;
}

- (NSString *)addStaticsInfo:(BOOL)publish stream:(NSString *)streamID fps:(double)fps kbs:(double)kbs akbs:(double)akbs rtt:(int)rtt pktLostRate:(int)pktLostRate delay:(int)delay {
    if (streamID.length == 0) {
        return nil;
    }
    
    // 丢包率的取值为 0~255，需要除以 256.0 得到丢包率百分比
    NSString *qualityString = [NSString stringWithFormat:NSLocalizedString(@"[%@] 帧率: %.3f, 视频码率: %.3f kb/s, 音频码率: %.3f kb/s, 延时: %d ms, 丢包率: %.3f%%, 语音延时: %d ms", nil), publish ? NSLocalizedString(@"推流", nil): NSLocalizedString(@"拉流", nil), fps, kbs, akbs, rtt, pktLostRate/256.0 * 100, delay];
    
    return qualityString;
}

- (void)updatePlayVideoStreamLayer {
    for (ZegoStream *stream in self.streamList) {
        [ZGManager.api activateVideoPlayStream:stream.streamID active:true videoLayer:self.videoLayer];
    }
}

- (NSString *)stringFromCGSize:(CGSize)size {
    return [NSString stringWithFormat:@"{%f,%f}", size.width, size.height];
}


#pragma mark - ZegoRoomDelegate

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    NSLog(NSLocalizedString(@"🍎连接失败, error: %d", nil), errorCode);
    self.isPublishing = NO;
    [self.delegate onPublishStateUpdate];
}

- (void)onStreamUpdated:(int)type streams:(NSArray<ZegoStream *> *)streamList roomID:(NSString *)roomID {
    if (type == ZEGO_STREAM_ADD)
        [self onStreamUpdateForAdd:streamList];
    else if (type == ZEGO_STREAM_DELETE)
        [self onStreamUpdateForDelete:streamList];
}

- (void)onStreamExtraInfoUpdated:(NSArray<ZegoStream *> *)streamList roomID:(NSString *)roomID {
    for (ZegoStream *stream in streamList) {
        for (ZegoStream *stream1 in self.streamList) {
            if (stream.streamID == stream1.streamID) {
                stream1.extraInfo = stream.extraInfo;
                break;
            }
        }
    }
}


#pragma mark - ZegoLivePublisherDelegate

- (void)onJoinLiveRequest:(int)seq fromUserID:(NSString *)userId fromUserName:(NSString *)userName roomID:(NSString *)roomID {
    if (seq == 0 || userId.length == 0) {
        return;
    }
    
    NSLog(NSLocalizedString(@"收到连麦请求, userName: %@", nil), userName);
    
    if (self.isBoardcasting) {
        [ZGManager.api respondJoinLiveReq:seq result:NO];
    }
    else {
        [ZGManager.api respondJoinLiveReq:seq result:YES];
    }
}

- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    NSString *detail = [self addStaticsInfo:YES stream:streamID fps:quality.fps kbs:quality.kbps akbs:quality.akbps rtt:quality.rtt pktLostRate:quality.pktLostRate];
    [self.delegate onPublishQualityUpdate:detail];
}

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {}



#pragma mark - ZegoLivePlayerDelegate

- (void)onPlayQualityUpate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    NSString *detail = [self addStaticsInfo:NO stream:streamID fps:quality.fps kbs:quality.kbps akbs:quality.akbps rtt:quality.rtt pktLostRate:quality.pktLostRate];
    [self.delegate onPlayQualityUpdate:detail];
}

- (void)onVideoSizeChangedTo:(CGSize)size ofStream:(NSString *)streamID {
    if (streamID.length == 0) {
        return;
    }
    self.streamSizeDic[streamID] = [self stringFromCGSize:size];
    NSMutableString *videoSize = [NSMutableString string];
    
    for (NSString *key in self.streamSizeDic.allKeys) {
        NSString *size = self.streamSizeDic[key];
        [videoSize appendString:[NSString stringWithFormat:@"streamID:%@  size:%@\n", key, size]];
    }
    
    [self.delegate onVideoSizeChanged:videoSize];
}

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {}

#pragma mark - Accessor

- (NSMutableArray<ZegoStream *> *)streamList {
    if (_streamList == nil) {
        _streamList = [[NSMutableArray alloc] init];
    }
    return _streamList;
}

- (NSMutableDictionary <NSString*,NSString*>*)streamSizeDic {
    if (_streamSizeDic == nil) {
        _streamSizeDic = [[NSMutableDictionary alloc] init];
    }
    return _streamSizeDic;
}

- (NSString *)genRoomName {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"svc-%@-%lu", ZGHelper.userID, currentTime];
}

- (NSString *)genRoomID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"#svc-%@-%@-%lu", self.openSVC ? @"on":@"off",ZGHelper.userID, currentTime];
}

- (NSString *)genStreamID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"s-%@-%lu", ZGHelper.userID, currentTime];
}

- (void)setUseFrontCam:(BOOL)useFrontCam {
    if (_useFrontCam == useFrontCam) {
        return;
    }
    _useFrontCam = useFrontCam;
    if (self.isPublishing) {
        [ZGManager.api setFrontCam:useFrontCam];
    }
}

- (void)setVideoLayer:(VideoStreamLayer)videoLayer {
    if (_videoLayer == videoLayer) {
        return;
    }
    _videoLayer = videoLayer;
    
    if (self.openSVC) {
        [self updatePlayVideoStreamLayer];
    }
}

- (void)setIsRequestBoardcast:(BOOL)isRequestBoardcast {
    if (_isRequestBoardcast == isRequestBoardcast) {
        return;
    }
    _isRequestBoardcast = isRequestBoardcast;
    
    [self.delegate onBoardcastStateUpdate];
}

@end
