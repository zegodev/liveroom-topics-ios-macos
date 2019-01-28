//
//  ZGLiveReplayManager.m
//  LiveDemo
//
//  Copyright © 2015年 Zego. All rights reserved.
//

#import "ZGLiveReplayManager.h"
#import "ZGManager.h"
#import "ZGHelper.h"

NSString *kZegoDemoAppTypeKey          = @"apptype";
NSString *kZegoDemoAppIDKey            = @"appid";
NSString *kZegoDemoAppSignKey          = @"appsign";

static ZGLiveReplayManager *_avkitManager;

@interface ZGLiveReplayManager () <ZegoRoomDelegate, ZegoLivePublisherDelegate>

@property (nonatomic, copy) NSString *liveTitle;

@property (nonatomic, copy) NSString *liveChannel;
@property (nonatomic, copy) NSString *streamID;

@property (nonatomic, assign) CGSize videoSize;

@end

@implementation ZGLiveReplayManager

#pragma mark - Init

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _avkitManager = [[ZGLiveReplayManager alloc] init];
    });
    
    return _avkitManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initZegoLiveApi];
    }
    
    return self;
}

- (void)initZegoLiveApi {
    [ZegoLiveRoomApi prepareReplayLiveCapture];
    [ZGManager api];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"[LiveRoomPlayground-GameLive] Received Memory Warning");
    }];
}


#pragma mark - Sample buffer

- (void)handleVideoInputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [ZGManager.api handleVideoInputSampleBuffer:sampleBuffer];
}

- (void)handleAudioInputSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    [ZGManager.api handleAudioInputSampleBuffer:sampleBuffer withType:sampleBufferType];
}

#pragma mark - Start and stop live

- (void)startLiveWithTitle:(NSString *)liveTitle videoSize:(CGSize)videoSize {
    if (liveTitle.length == 0) {
        self.liveTitle = [NSString stringWithFormat:@"#evc-ios-replay-%@", ZGHelper.userID];
    }
    else {
        self.liveTitle = liveTitle;
    }
    
    self.videoSize = videoSize;
    NSLog(@"[LiveRoomPlayground-GameLive] videoSize at start: %@", NSStringFromCGSize(videoSize));
    
    [ZGManager.api setPublisherDelegate:self];
    
    [self loginChatRoom];
}

- (void)stopLive {
    [ZGManager.api stopPublishing];
    [ZGManager.api logoutRoom];
    [ZGManager releaseApi];
}

- (void)loginChatRoom {
    NSString *roomID = [self genRoomID];
    
    __weak typeof(self)weakself = self;
    [ZGManager.api loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        __strong typeof(weakself)strongself = weakself;
        if (!strongself) {
            return;
        }
        
        BOOL success = errorCode == 0;
        
        if (!success) {
            NSLog(@"[LiveRoomPlayground-GameLive] login room error %d", errorCode);
            return;
        }
        
        NSLog(@"[LiveRoomPlayground-GameLive] login Room success %@", roomID);
        
        ZegoAVConfig *config = [ZegoAVConfig new];
        config.videoEncodeResolution = strongself.videoSize;
        config.fps = 25;
        config.bitrate = 800000;
        [ZGManager.api setAVConfig:config];
        
        strongself.streamID = [strongself genStreamID];
        
        [ZGManager.api startPublishing:strongself.streamID title:strongself.liveTitle flag:ZEGOAPI_SINGLE_ANCHOR];
    }];
    
    NSLog(@"[LiveRoomPlayground-GameLive] login Room %@", roomID);
}


#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    if (stateCode == 0) {
        NSLog(@"[LiveRoomPlayground-GameLive] publish success，streamID：%@", streamID);
    }
    else {
        NSLog(@"[LiveRoomPlayground-GameLive] publish failed %d", stateCode);
    }
}


#pragma mark - Access

- (NSString *)genRoomID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"#evc-ios-replay-%@-%lu", ZGHelper.userID, currentTime];
}

- (NSString *)genStreamID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"s-%@-%lu", ZGHelper.userID, currentTime];
}


@end
