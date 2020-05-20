//
//  ZegoLiveRoomOSX.h
//  ZegoLiveRoom
//
//  Created by Realuei on 2019/12/18.
//  Copyright © 2017年 zego. All rights reserved.
//

#import <AppKit/AppKit.h>

//! Project version number for ZegoLiveRoom.
FOUNDATION_EXPORT double ZegoLiveRoomVersionNumber;

//! Project version string for ZegoLiveRoom.
FOUNDATION_EXPORT const unsigned char ZegoLiveRoomVersionString[];

#import <ZegoLiveRoomOSX/ZegoLiveRoomApi.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines.h>

#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Player.h>

#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Publisher.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Publisher2.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines-Publisher.h>

#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-IM.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines-IM.h>

#if __has_include(<ReplayKit/ReplayKit.h>)
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-ReplayLive.h>
#endif

#import <ZegoLiveRoomOSX/zego-api-defines-oc.h>
#import <ZegoLiveRoomOSX/zego-api-error-oc.h>
#import <ZegoLiveRoomOSX/zego-api-audio-device-oc.h>
#import <ZegoLiveRoomOSX/zego-api-mix-stream-oc.h>
#import <ZegoLiveRoomOSX/zego-api-mix-stream-defines-oc.h>
#import <ZegoLiveRoomOSX/zego-api-audio-aux-oc.h>
#import <ZegoLiveRoomOSX/zego-api-external-video-filter-oc.h>
#import <ZegoLiveRoomOSX/zego-api-external-video-capture-oc.h>
#import <ZegoLiveRoomOSX/zego-api-external-audio-device-oc.h>
#import <ZegoLiveRoomOSX/zego-api-audio-frame-oc.h>
#import <ZegoLiveRoomOSX/zego-api-mix-engine-playout-oc.h>
#import <ZegoLiveRoomOSX/zego-api-mediaplayer-oc.h>
#import <ZegoLiveRoomOSX/zego-api-mediaplayer-defines-oc.h>
#import <ZegoLiveRoomOSX/zego-api-audio-processing-oc.h>
#import <ZegoLiveRoomOSX/zego-api-media-side-info-oc.h>
#import <ZegoLiveRoomOSX/zego-api-external-video-render-oc.h>
#import <ZegoLiveRoomOSX/zego-api-audio-encrypt-decrypt-oc.h>
#import <ZegoLiveRoomOSX/zego-api-sound-level-oc.h>
#import <ZegoLiveRoomOSX/zego-api-media-recorder-oc.h>
#import <ZegoLiveRoomOSX/zego-api-frequency-spectrum-oc.h>
#import <ZegoLiveRoomOSX/zego-api-audio-player-oc.h>
#import <ZegoLiveRoomOSX/zego-api-network-trace-oc.h>
#import <ZegoLiveRoomOSX/zego-api-network-trace-defines-oc.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-ReliableMessage.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines-ReliableMessage.h>
