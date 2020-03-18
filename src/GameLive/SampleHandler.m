//
//  SampleHandler.m
//  GameLive
//
//  Created by Sky on 2019/1/24.
//  Copyright © 2019 Zego. All rights reserved.
//


#import "SampleHandler.h"
#import "ZGLiveReplayManager.h"

#define GameLiveSampleHandlerLogCapturedAudioSampleInfo 0

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    CGSize videoSize = CGSizeMake(720, 1280);
    [ZGLiveReplayManager.sharedInstance startLiveWithTitle:@"" videoSize:videoSize];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    NSLog(@"[LiveRoomPlayground-GameLive] stop live");
    [ZGLiveReplayManager.sharedInstance stopLive];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
#if GameLiveSampleHandlerLogCapturedAudioSampleInfo
    [self logAudioSampleBuffer:sampleBuffer withType:sampleBufferType];
#endif
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle audio sample buffer
            [ZGLiveReplayManager.sharedInstance handleVideoInputSampleBuffer:sampleBuffer];
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            [ZGLiveReplayManager.sharedInstance handleAudioInputSampleBuffer:sampleBuffer withType:RPSampleBufferTypeAudioApp];
            break;
        case RPSampleBufferTypeAudioMic:
            [ZGLiveReplayManager.sharedInstance handleAudioInputSampleBuffer:sampleBuffer withType:RPSampleBufferTypeAudioMic];
            // Handle audio sample buffer for mic audio
            break;
            
        default:
            break;
    }
}

- (void)logAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    if (!sampleBuffer) return;
    if (sampleBufferType != RPSampleBufferTypeAudioMic
        && sampleBufferType != RPSampleBufferTypeAudioApp) {
        return;
    }
    
    CMFormatDescriptionRef formatDescription =
      CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription* const asbd =
      CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);

    NSString *typeStr = sampleBufferType == RPSampleBufferTypeAudioMic?@"Mic":@"App";
    NSLog(@"audio[%@]: sampleRate:%0.5f, channel:%d, bytes:%d", typeStr, asbd->mSampleRate, asbd->mChannelsPerFrame, asbd-> mBytesPerFrame);
}


@end
