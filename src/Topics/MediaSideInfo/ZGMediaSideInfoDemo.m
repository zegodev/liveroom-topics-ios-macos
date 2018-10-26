//
//  ZGMediaSideInfoDemo.m
//  LiveRoomPlayground
//
//  Created by Randy Qiu on 2018/10/25.
//  Copyright © 2018 Zego. All rights reserved.
//

#import "ZGMediaSideInfoDemo.h"

@interface ZGMediaSideInfoDemo () <ZegoMediaSideDelegate>

@property (readonly) ZegoMediaSideInfo* api;
@property (readonly) ZGMediaSideInfoDemoConfig* config;

@end

@implementation ZGMediaSideInfoDemo

- (instancetype)initWithConfig:(ZGMediaSideInfoDemoConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        
        _api = [ZegoMediaSideInfo new];
        [_api setMediaSideDelegate:self];
    }
    
    return self;
}

- (void)activateMediaSideInfoForPublishChannel:(ZegoAPIPublishChannelIndex)channelIndex {
    [self.api setMediaSideFlags:true onlyAudioPublish:self.config.onlyAudioPublish channelIndex:channelIndex];
}

- (void)sendMediaSideInfo:(NSData *)data {
    [self sendMediaSideInfo:data toPublishChannel:ZEGOAPI_CHN_MAIN];
}

- (void)sendMediaSideInfo:(NSData *)data toPublishChannel:(ZegoAPIPublishChannelIndex)channelIndex {
    if (self.config.customPacket) {
        char headerBuffer[5];
        
        // * packet length: 4 bytes
        uint32_t* length = (uint32_t*)headerBuffer;
        // * need to convert to network order (big-endian)
        *length = htonl(data.length + 1);
        
        // * packet NAL type
        headerBuffer[4] = 26; // [26, 31)
        
        NSMutableData* h = [NSMutableData dataWithBytes:headerBuffer length:5];
        [h appendData:data];
        data = h;
    }
    
    [self.api sendMediaSideInfo:data
                         packet:self.config.customPacket
                   channelIndex:channelIndex];
}

#pragma mark - ZegoMediaSideDelegate
- (void)onRecvMediaSideInfo:(NSData *)data ofStream:(NSString *)streamID {
    
    id<ZGMediaSideInfoDemoDelegate> delegate = self.delegate;
    if (!delegate) {
        NSLog(@"%s: NO DELEGATE", __func__);
        return;
    }
    
    if (!self.config.customPacket) {
        uint32_t mediaType = ntohl(*(uint32_t*)data.bytes);
        NSData* realData = [data subdataWithRange:NSMakeRange(4, data.length - 4)];
        
        if (mediaType == 1001) {
            if ([delegate respondsToSelector:@selector(onReceiveMediaSideInfo:ofStream:)]) {
                [delegate onReceiveMediaSideInfo:realData ofStream:streamID];
            }
        } else if (mediaType == 1002) {
            // * mix stream user data
            if ([delegate respondsToSelector:@selector(onReceiveMixStreamUserData:ofStream:)]) {
                [delegate onReceiveMixStreamUserData:realData ofStream:streamID];
            }
        }
    } else {
        uint8_t* bytes = (uint8_t*)data.bytes;
        uint32_t length = bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3];
        // ntohl(*(uint32_t*)data.bytes);
        char nalType = *(char*)(data.bytes + 4);
        
        NSLog(@"%s, len: %d, nal: %d", __func__, length, (int)nalType);
        
        NSData* realData = [data subdataWithRange:NSMakeRange(5, data.length - 5)];
        if ([delegate respondsToSelector:@selector(onReceiveMediaSideInfo:ofStream:)]) {
            [delegate onReceiveMediaSideInfo:realData ofStream:streamID];
        }
    }
}

@end

@implementation ZGMediaSideInfoDemoConfig

@end
