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
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Player.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-Publisher.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-IM.h>
#if __has_include(<ReplayKit/ReplayKit.h>)
#import <ZegoLiveRoomOSX/ZegoLiveRoomApi-ReplayLive.h>
#endif
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines-Publisher.h>
#import <ZegoLiveRoomOSX/ZegoLiveRoomApiDefines-IM.h>
