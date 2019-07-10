//
//  ZGHelper.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGHelper : NSObject

@property (class, copy ,nonatomic, readonly) NSString *userID;

+ (NSString *)getDeviceUUID;

@end

NS_ASSUME_NONNULL_END
