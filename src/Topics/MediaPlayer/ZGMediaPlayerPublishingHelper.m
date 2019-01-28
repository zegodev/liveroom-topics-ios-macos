//
//  ZGMediaPlayerPublishingHelper.m
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGMediaPlayerPublishingHelper.h"
#import "ZGManager.h"
#import "ZGHelper.h"

@interface ZGMediaPlayerPublishingHelper () <ZegoRoomDelegate, ZegoLivePublisherDelegate> {
    ZGMediaPlayerPublishingStateObserver observer_;
}

@end

@implementation ZGMediaPlayerPublishingHelper

- (void)setPublishStateObserver:(ZGMediaPlayerPublishingStateObserver)observer {
    observer_ = observer;
}

- (void)startPublishing {
    [[ZGManager api] setPublisherDelegate:self];
        
    __weak ZGMediaPlayerPublishingHelper* weak_self = self;
    [[ZGManager api] loginRoom:[ZGHelper getDeviceUUID] role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        ZGMediaPlayerPublishingHelper* strong_self = weak_self;
        if (errorCode == 0) {
            [ZegoLiveRoomApi requireHardwareEncoder:true];
            [[ZGManager api] startPublishing:[ZGHelper getDeviceUUID] title:[ZGHelper getDeviceUUID] flag:ZEGOAPI_SINGLE_ANCHOR];
        } else {
            if (strong_self->observer_) {
                strong_self->observer_(@"LOGIN FAILED!");
            }
        }
    }];
}

#pragma mark - ZegoLivePublisherDelegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    if (!observer_) return;
    
    if (stateCode == 0) {
        observer_([NSString stringWithFormat:@"PUBLISH STARTED: \n%@\n%@\n%@",
                  [info[kZegoRtmpUrlListKey] firstObject],
                  [info[kZegoFlvUrlListKey] firstObject],
                  [info[kZegoHlsUrlListKey] firstObject]]
                  );
    } else {
        observer_([NSString stringWithFormat:@"PUBLISH STOP: %d", stateCode]);
    }
}

#pragma mark - ZegoRoomDelegate

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    if (observer_) {
        observer_([NSString stringWithFormat:@"ROOM DISCONNECTED: %d", errorCode]);
    }
}

@end
