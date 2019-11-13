//
//  SampleHandler.m
//  GameLive
//
//  Created by Sky on 2019/1/24.
//  Copyright © 2019 Zego. All rights reserved.
//


#import "SampleHandler.h"
#import "ZGLiveReplayManager.h"

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    NSString *liveTitle = (NSString *)setupInfo[@"title"];
    CGFloat videoWidth = [(NSNumber *)setupInfo[@"width"] floatValue] != 0 ? [(NSNumber *)setupInfo[@"width"] floatValue] : [[UIScreen mainScreen] bounds].size.width;
    CGFloat videoHeight = [(NSNumber *)setupInfo[@"height"] floatValue] != 0 ? [(NSNumber *)setupInfo[@"height"] floatValue] : [[UIScreen mainScreen] bounds].size.height;
    
    [ZGLiveReplayManager.sharedInstance startLiveWithTitle:liveTitle videoSize:CGSizeMake(videoWidth, videoHeight)];
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


@end
