//
//  ZGMediaSideInfoDemoEnvirentmentHelper.m
//  LiveRoomPlayground
//
//  Created by Randy Qiu on 2018/10/25.
//  Copyright © 2018 Zego. All rights reserved.
//

#import "ZGMediaSideInfoDemoEnvirentmentHelper.h"
#import "ZGHelper.h"

@interface ZGMediaSideInfoDemoEnvirentmentHelper () <ZegoRoomDelegate, ZegoLivePublisherDelegate, ZegoLivePlayerDelegate>

@property (nonatomic) ZGMediaSideTopicStatus status;
@property (readonly) NSString* streamID;
@property (strong) ZGMediaSideInfoDemoConfig* config;

@end

@implementation ZGMediaSideInfoDemoEnvirentmentHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        _sentMsgs = [NSMutableArray array];
        _recvMsgs = [NSMutableArray array];
        _streamID = [ZGHelper getDeviceUUID];
        
        [ZGManager enableExternalVideoCapture:nil videoRenderer:nil];
        [[ZGManager api] setRoomDelegate:self];
        [[ZGManager api] setPublisherDelegate:self];
        [[ZGManager api] setPlayerDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [[ZGManager api] setRoomDelegate:nil];
    [[ZGManager api] setPublisherDelegate:nil];
    [[ZGManager api] setPlayerDelegate:nil];
}

- (void)loginRoom {
    bool result = [[ZGManager api] loginRoom:@"ZEGO_TOPIC_MEDIA_SIDE_INFO" role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        
        if (errorCode != 0) {
            self.status = kZGMediaSideTopicStatus_None;
            return ;
        }
        
        self.status = kZGMediaSideTopicStatus_Login_OK;
    }];
    
    if (result) {
        self.status = kZGMediaSideTopicStatus_Starting_Login_Room;
    }
}

- (void)publishAndPlayWithConfig:(ZGMediaSideInfoDemoConfig*)config {
    assert(self.status == kZGMediaSideTopicStatus_Login_OK);

    self.config = config;
    if (config.onlyAudioPublish) {
        [[ZGManager api] enableCamera:false];
    } else {
        [[ZGManager api] setPreviewView:self.previewView];
        [[ZGManager api] enableCamera:true];
        [[ZGManager api] startPreview];
    }
    
    bool publishResult = [[ZGManager api] startPublishing:self.streamID title:@"MSI" flag:ZEGOAPI_JOIN_PUBLISH];
    if (publishResult) {
        self.status = kZGMediaSideTopicStatus_Starting_Publishing;
    } else {
        self.status = kZGMediaSideTopicStatus_None;
    }
}

#pragma mark - ZegoRoomDelegate
- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    self.status = kZGMediaSideTopicStatus_None;
}

#pragma mark - ZegoLivePublisherDelegate
- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    if (stateCode == 0) {
        assert(self.status == kZGMediaSideTopicStatus_Starting_Publishing);
        ZGView* v = self.config.onlyAudioPublish ? nil : self.playView;
        bool result = [[ZGManager api] startPlayingStream:self.streamID inView:v];
        if (result) {
            self.status = kZGMediaSideTopicStatus_Starting_Playing;
        }
    } else {
        self.status = kZGMediaSideTopicStatus_None;
    }
}

#pragma mark - ZegoLivePlayerDelegate
- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    assert([streamID isEqualToString:self.streamID]);
    
    if (stateCode == 0) {
        assert(self.status == kZGMediaSideTopicStatus_Starting_Playing);
        self.status = kZGMediaSideTopicStatus_Ready_For_Messaging;
    } else {
        self.status = kZGMediaSideTopicStatus_None;
    }
}

#pragma mark - Private

- (void)setStatus:(ZGMediaSideTopicStatus)status {
    _status = status;
    [self.delegate onStateChanged:_status];
    if (_status == kZGMediaSideTopicStatus_None) {
        // * clear all status
        [[ZGManager api] logoutRoom];
    }
}

- (void)addSentMsg:(NSString *)msg {
    [self.sentMsgs insertObject:msg atIndex:0];
}

- (void)addRecvMsg:(NSString *)msg {
    [self.recvMsgs insertObject:msg atIndex:0];
}

- (NSString*)checkSentRecvMsgs {
    if (self.recvMsgs.count != self.sentMsgs.count) {
        return @"COUNT NOT EQUAL";
    }
    
    for (NSInteger idx = 0; idx < self.recvMsgs.count; ++idx) {
        if (![self.recvMsgs[idx] isEqualToString:self.sentMsgs[idx]]) {
            return [NSString stringWithFormat:@"%ld, recv: %@ - sent: %@", idx, self.recvMsgs[idx], self.sentMsgs[idx]];
        }
    }
    
    [self.sentMsgs removeAllObjects];
    [self.recvMsgs removeAllObjects];
    return @"All the same";
}

+ (NSString*)descOfStatus:(ZGMediaSideTopicStatus)status {
    NSString* desc = @"";
    
    switch (status) {
        case kZGMediaSideTopicStatus_None:
            desc = @"NONE";
            break;
        case kZGMediaSideTopicStatus_Starting_Login_Room:
            desc = @"Logining";
            break;
        case kZGMediaSideTopicStatus_Login_OK:
            desc = @"LoginOK";
            break;
        case kZGMediaSideTopicStatus_Starting_Publishing:
            desc = @"Starting Publishing";
            break;
        case kZGMediaSideTopicStatus_Starting_Playing:
            desc = @"Starting Playing";
            break;
        case kZGMediaSideTopicStatus_Ready_For_Messaging:
            desc = @"Ready";
            break;
        default:
            break;
    }
    
    return desc;
}

@end
