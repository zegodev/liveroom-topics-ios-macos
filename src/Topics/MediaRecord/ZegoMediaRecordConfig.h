//
//  ZegoMediaRecordConfig.h
//  LiveRoomPlayground-macOS
//
//  Created by Sky on 2018/12/17.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_MediaRecord

#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
#import <ZegoLiveRoomOSX/zego-api-media-recorder-oc.h>
#elif TARGET_OS_IOS
#import <ZegoLiveRoom/zego-api-media-recorder-oc.h>
#endif


NS_ASSUME_NONNULL_BEGIN

@interface ZegoMediaRecordConfig : NSObject

@property (assign, nonatomic) ZegoAPIMediaRecordChannelIndex channel;
@property (assign, nonatomic) ZegoAPIMediaRecordType recordType;
@property (assign, nonatomic) ZegoAPIMediaRecordFormat recordFormat;
@property (copy, nonatomic) NSString *storagePath;
@property (assign, nonatomic) int interval;

@end

NS_ASSUME_NONNULL_END

#endif
