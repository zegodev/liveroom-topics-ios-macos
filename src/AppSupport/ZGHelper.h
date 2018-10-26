//
//  ZGHelper.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString* kZGTopicMediaPlayer;
extern NSString* kZGTopicMediaSideInfo;

@interface ZGHelper : NSObject

+ (NSString *)getDeviceUUID;

@end

NS_ASSUME_NONNULL_END
