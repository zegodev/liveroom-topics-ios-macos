//
//  ZGLiveReplayManager.m
//  LiveDemo
//
//  Copyright © 2015年 Zego. All rights reserved.
//

#import "ZGLiveReplayManager.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import "ZGUserIDHelper.h"
#import "ZGKeyCenter.h"
#import "ZGTopicCommonDefines.h"
#import "ZGUserDefaults.h"
#import "ZGJsonHelper.h"
#import "ZGAppGlobalConfig.h"
#import "ZGAppSignHelper.h"


static ZGLiveReplayManager *_avkitManager;

@interface ZGLiveReplayManager () <ZegoRoomDelegate, ZegoLivePublisherDelegate>

@property (nonatomic, copy) NSString *liveTitle;

@property (nonatomic, copy) NSString *liveChannel;
@property (nonatomic, copy) NSString *streamID;

@property (nonatomic, assign) CGSize videoSize;

@property (strong, nonatomic) ZegoLiveRoomApi *api;

@property (nonatomic, assign) BOOL onStreamPublishing;

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

- (NSString *)createZegoLogDirIfNeed {
    // 设置录屏进程的 Zego SDK 日志路径
    NSURL *groupURL = [[NSFileManager defaultManager]
    containerURLForSecurityApplicationGroupIdentifier:ZGAPP_GROUP_NAME];
    NSURL *replayKitZegoLogDirURL = [groupURL URLByAppendingPathComponent:ZGAPP_REPLAYKIT_UPLOAD_EXTENSION_ZEGO_LOG_DIR isDirectory:YES];
    NSError *err = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:replayKitZegoLogDirURL withIntermediateDirectories:YES attributes:nil error:&err];
    NSString *dir = replayKitZegoLogDirURL.path;
    NSLog(@"create zego log dir:%@, error:%@", dir, err);
    if (err) {
        return nil;
    }
    return dir;
}

- (void)getZegoApiInitConfigOfAppId:(unsigned int *)appId appSign:(NSData **)appSign useTestEnv:(BOOL *)useTestEnv {
    // 默认
    *appId = ZGKeyCenter.appID;
    *appSign = ZGKeyCenter.appSign;
    *useTestEnv = YES;
    
    // 从设置中获取，如果存在则覆盖默认
    ZGUserDefaults *usrDefaults = [ZGUserDefaults standardUserDefaults];
    NSString *confStr = [usrDefaults objectForKey:ZGAPP_GLOBAL_CONFIG_KEY];
    if (confStr) {
        NSDictionary *confDict = [ZGJsonHelper decodeFromJSON:confStr];
        ZGAppGlobalConfig *conf = [ZGAppGlobalConfig fromDictionary:confDict];
        if (conf) {
            if (appId) {
                *appId = conf.appID;
            }
            if (appSign && conf.appSign) {
                *appSign = [ZGAppSignHelper convertAppSignFromString:conf.appSign];
            }
            if (useTestEnv) {
                *useTestEnv = (conf.environment == ZGAppEnvironmentTest);
            }
        }
    }
}

- (void)initZegoLiveApi {
    unsigned int appId = 0;
    NSData *appSign = nil;
    BOOL useTestEnv = NO;
    [self getZegoApiInitConfigOfAppId:&appId appSign:&appSign useTestEnv:&useTestEnv];
    
    NSLog(@"device model:%@", [UIDevice currentDevice].model);
    NSLog(@"system version:%@", [UIDevice currentDevice].systemVersion);
    
    // 设置录屏进程的 Zego SDK 日志路径
    NSString *zegoLogDir = [self createZegoLogDirIfNeed];
    if (zegoLogDir) {
        [ZegoLiveRoomApi setLogDir:zegoLogDir size:20*1024*1024 subFolder:nil];
    }
    
    [ZegoLiveRoomApi prepareReplayLiveCapture];

    [ZegoLiveRoomApi setUserID:ZGUserIDHelper.userID userName:ZGUserIDHelper.userID];
    
    [ZegoLiveRoomApi requireHardwareDecoder:YES];
    [ZegoLiveRoomApi requireHardwareEncoder:YES];
    [ZegoLiveRoomApi setConfig:@"replaykit_handle_rotation=false"];
    [ZegoLiveRoomApi setConfig:@"max_channels=0"];
    [ZegoLiveRoomApi setConfig:@"max_publish_channels=1"];
    
    NSLog(@"appId:%@, useTestEnv:%@", @(appId), @(useTestEnv));
    NSLog(@"call initWithAppID:appSignature:");
    
    [ZegoLiveRoomApi setUseTestEnv:useTestEnv];
    self.api = [[ZegoLiveRoomApi alloc] initWithAppID:appId appSignature:appSign];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"[LiveRoomPlayground-GameLive] Received Memory Warning");
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"[LiveRoomPlayground-GameLive] Received Memory Warning");
    }];
}


#pragma mark - Sample buffer

- (void)handleVideoInputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (self.onStreamPublishing)
        [self.api handleVideoInputSampleBuffer:sampleBuffer];
}

- (void)handleAudioInputSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    if (self.onStreamPublishing)
        [self.api handleAudioInputSampleBuffer:sampleBuffer withType:sampleBufferType];
}

#pragma mark - Start and stop live

- (void)startLiveWithTitle:(NSString *)liveTitle videoSize:(CGSize)videoSize {
    if (liveTitle.length == 0) {
        self.liveTitle = [NSString stringWithFormat:@"#evc-ios-replay-%@", ZGUserIDHelper.userID];
    }
    else {
        self.liveTitle = liveTitle;
    }
    
    self.videoSize = videoSize;
    
    [self.api setPublisherDelegate:self];
    [self loginChatRoom];
}

- (void)stopLive {
    [self.api stopPublishing];
    [self.api logoutRoom];
    self.onStreamPublishing = NO;
}

- (void)loginChatRoom {
    NSString *roomID = [self genRoomID];
    
    __weak typeof(self)weakself = self;
    NSLog(@"call loginRoom.");
    [self.api loginRoom:roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
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
        config.videoEncodeResolution = self.videoSize;
        config.fps = 10;
        config.bitrate = 1500000;
        [self.api setAVConfig:config];
        
        self.streamID = [self genStreamID];
        
        NSLog(@"[LiveRoomPlayground-GameLive] videoEncodeResolution: %@", NSStringFromCGSize(config.videoEncodeResolution));
        NSLog(@"call startPublishing.");
        [self.api startPublishing:self.streamID title:self.liveTitle flag:ZEGO_JOIN_PUBLISH];
    }];
    
    NSLog(@"[LiveRoomPlayground-GameLive] login Room %@", roomID);
}


#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    if (stateCode == 0) {
        NSLog(@"[LiveRoomPlayground-GameLive] publish success，streamID：%@", streamID);
        self.onStreamPublishing = YES;
    }
    else {
        NSLog(@"[LiveRoomPlayground-GameLive] publish failed %d", stateCode);
        self.onStreamPublishing = NO;
    }
}


#pragma mark - Access

- (NSString *)genRoomID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"#evc-ios-replay-%@-%lu", ZGUserIDHelper.userID, currentTime];
}

- (NSString *)genStreamID {
    unsigned long currentTime = (unsigned long)[[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"s-%@-%lu", ZGUserIDHelper.userID, currentTime];
}


@end
