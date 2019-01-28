//
//  ZGMediaPlayerDemo.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGMediaPlayerDemo.h"
#import "ZGVideoCaptureForMediaPlayer.h"

typedef enum {
    ZGPlayerState_Stopped,
    ZGPlayerState_Stopping,
    ZGPlayerState_Playing
} ZGPlayerState;

typedef enum {
    ZGPlayingSubState_Requesting,
    ZGPlayingSubState_PlayBegin,
    ZGPlayingSubState_Paused,
    ZGPlayingSubState_Buffering
} ZGPlayingSubState;

@interface ZGMediaPlayerDemo () <ZegoMediaPlayerEventDelegate>

@property (strong) ZegoMediaPlayer* player;
@property (nonatomic) ZGPlayerState playerState;
@property (nonatomic) ZGPlayingSubState playingSubState;

@property (nonatomic) int duration;
@property (nonatomic) int currentProgress;
@property (strong) NSTimer* progressUpdateTimer;

@property (strong) ZGVideoCaptureForMediaPlayer* videoCapture;
@property (strong) ZGMediaPlayerPublishingHelper* publishHelper;

@end

@implementation ZGMediaPlayerDemo

- (instancetype)init {

    self = [super init];
    if (self) {
        self.videoCapture = [[ZGVideoCaptureForMediaPlayer alloc] init];
        [ZGManager enableExternalVideoCapture:self.videoCapture videoRenderer:nil];
        
        self.player = [[ZegoMediaPlayer alloc] initWithPlayerType:MediaPlayerTypeAux];
        [self.player setDelegate:self];
        [self.player setVideoPlayDelegate:self.videoCapture format:ZegoMediaPlayerVideoPixelFormatBGRA32];
        
        self.publishHelper = [ZGMediaPlayerPublishingHelper new];
        __weak ZGMediaPlayerDemo* weakSelf = self;
        [self.publishHelper setPublishStateObserver:^(NSString * _Nonnull state) {
            NSLog(@"%s: %@", __func__, state);
            ZGMediaPlayerDemo* strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf.delegate onPublishState: state];
            }
        }];
        [self.publishHelper startPublishing];
    }
    return self;
}

- (void)dealloc {
    if (self.progressUpdateTimer) {
        [self.progressUpdateTimer invalidate];
        self.progressUpdateTimer = nil;
    }
    [ZGManager.api logoutRoom];
    [ZGManager releaseApi];
}

- (void)setPlayerType:(MediaPlayerType)type {
    [self.player setPlayerType:type];
}

- (void)setVideoView:(ZGView *)view {
    [self.player setView:view];
}

- (void)setVolume:(int)volumn {
    [self.player setVolume:volumn];
}

- (void)startPlaying:(NSString *)url repeat:(BOOL)repeat {
    NSLog(@"%s, %@", __func__, url);
    if (self.playerState == ZGPlayerState_Playing) {
        // * 必须先停止
        [self.player stop];
    }
    
    [self.player start:url repeat:repeat];
    
    self.playerState = ZGPlayerState_Playing;
    self.playingSubState = ZGPlayingSubState_Requesting;
}

- (void)stop {
    NSLog(@"%s", __func__);
    [self.player stop];
    self.playerState = ZGPlayerState_Stopping;
}

- (void)pause {
    [self.player pause];
}

- (void)resume {
    [self.player resume];
}

- (void)seekTo:(long)millisecond {
    [self.player seekTo:millisecond];
}

- (void)setAudioStream:(int)stream {
    [self.player setAudioStream:stream];
}

#pragma mark - ZegoMediaPlayerEventDelegate

- (void)onPlayStart {
    NSLog(@"%s", __func__);
    
    assert(self.playerState == ZGPlayerState_Playing);
    assert(self.playingSubState == ZGPlayingSubState_Requesting);
    
    self.playingSubState = ZGPlayingSubState_PlayBegin;
    
    self.currentProgress = 0;
    self.duration = (int)[self.player getDuration];
    
    [self updateProgressDesc];
    
    int audioStreamCount = (int)[self.player getAudioStreamCount];
    [self.delegate onGetAudioStreamCount:audioStreamCount];
}

- (void)onPlayPause {
    NSLog(@"%s", __func__);
    assert(self.playerState == ZGPlayerState_Playing);
    self.playingSubState = ZGPlayingSubState_Paused;
}

- (void)onPlayResume {
    NSLog(@"%s", __func__);
    assert(self.playerState == ZGPlayerState_Playing);
    self.playingSubState = ZGPlayingSubState_PlayBegin;
}

- (void)onPlayError:(int)code  {
    NSLog(@"%s", __func__);
    self.playerState = ZGPlayerState_Stopped;
}

- (void)onVideoBegin  {
    NSLog(@"%s", __func__);
}

- (void)onAudioBegin {
    NSLog(@"%s", __func__);
}

- (void)onPlayEnd {
    NSLog(@"%s", __func__);
    self.playerState = ZGPlayerState_Stopped;
}

- (void)onPlayStop {
    NSLog(@"%s", __func__);
    if (self.playerState == ZGPlayerState_Stopping) {
        self.playerState = ZGPlayerState_Stopped;
    }
}

- (void)onBufferBegin {
    NSLog(@"%s", __func__);
    if (self.playerState == ZGPlayerState_Playing) {
        self.playingSubState = ZGPlayingSubState_Buffering;
    } else {
        assert(false);
    }
}

- (void)onBufferEnd {
    NSLog(@"%s", __func__);
    if (self.playerState == ZGPlayerState_Playing) {
        if (self.playingSubState == ZGPlayingSubState_Buffering) {
            self.playingSubState = ZGPlayingSubState_PlayBegin;
        } else {
            assert(false);
        }
    } else {
        assert(false);
    }
}

- (void)onSeekComplete:(int)code when:(long)millisecond {
    NSLog(@"%s", __func__);
}


#pragma mark - Private

- (void)setPlayerState:(ZGPlayerState)playerState {
    NSLog(@"%s, %d", __func__, playerState);
    
    _playerState = playerState;
    [self updateCurrentState];
    
    if (_playerState == ZGPlayerState_Playing) {
        if (self.progressUpdateTimer) {
            [self.progressUpdateTimer invalidate];
        }
        self.progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    } else if (self.progressUpdateTimer.valid) {
        [self.progressUpdateTimer invalidate];
        self.progressUpdateTimer = nil;
        
        if (self.playerState == ZGPlayerState_Stopped) {
            [self.delegate onPlayerStop];
        }
    }
}

- (void)onTimer:(NSTimer*)timer {
    self.currentProgress = (int)[self.player getCurrentDuration];
    [self updateProgressDesc];
}

- (void)setPlayingSubState:(ZGPlayingSubState)playingSubState {
    _playingSubState = playingSubState;
    [self updateCurrentState];
}

- (void)updateCurrentState {
    NSString* currentStateDesc = nil;
    switch (self.playerState) {
        case ZGPlayerState_Stopped:
            currentStateDesc = @"Stopped";
            break;
        case ZGPlayerState_Stopping:
            currentStateDesc = @"Stopping";
            break;
        case ZGPlayerState_Playing: {
            NSString* prefix = @"Playing";
            NSString* subState = nil;
            switch (self.playingSubState) {
                case ZGPlayingSubState_Requesting:
                    subState = @"Requesting";
                    break;
                case ZGPlayingSubState_PlayBegin:
                    subState = @"Begin";
                    break;
                case ZGPlayingSubState_Paused:
                    subState = @"Paused";
                    break;
                case ZGPlayingSubState_Buffering:
                    subState = @"Buffering";
                    break;
                default:
                    break;
            }
            currentStateDesc = [NSString stringWithFormat:@"%@: %@", prefix, subState];
            break;
        }
    }
    
    [self.delegate onPlayerState:currentStateDesc];
}

- (void)updateProgressDesc {
    [self.delegate onPlayerProgress:self.currentProgress max:self.duration desc:[NSString stringWithFormat:@"%d/%d", self.currentProgress/1000, self.duration/1000]];
}

@end
