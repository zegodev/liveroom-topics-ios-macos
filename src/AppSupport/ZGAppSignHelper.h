//
//  ZGAppSignHelper.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/6.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGAppSignHelper : NSObject

/**
 将 0x01,0x03,0x44,.... 格式的 appSign 字符串转换成 NSData
 
 @param appSignString 0x01,0x03,0x44,.... 格式字符串
 @return NSData 类型的数据 appSign
 */
+ (NSData *)convertAppSignFromString:(NSString *)appSignString;

/**
 将 NSData 类型的 appSign 转换成 0x01,0x03,0x44,.... 格式的字符串
 
 @param appSignData NSData 类型的 appSign
 @return 0x01,0x03,0x44,.... 格式的字符串
 */
+ (NSString *)convertAppSignToString:(NSData *)appSignData;

@end

NS_ASSUME_NONNULL_END
