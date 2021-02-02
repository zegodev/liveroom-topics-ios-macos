//
//  ZGAppGlobalConfig.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/8/6.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 app 环境

 - ZGAppEnvironmentTest: 测试
 - ZGAppEnvironmentOfficial: 正式
 */
typedef NS_ENUM(NSUInteger, ZGAppEnvironment) {
    ZGAppEnvironmentTest = 0,
    ZGAppEnvironmentOfficial = 1
};

/**
 全局配置 model
 *
 */
@interface ZGAppGlobalConfig : NSObject

// app ID
@property (nonatomic, assign) unsigned int appID;

// app sign
@property (nonatomic, copy) NSString *appSign;

// 环境
@property (nonatomic, assign) ZGAppEnvironment environment;

// 是否开启硬件编码
@property (nonatomic, assign) BOOL openHardwareEncode;

// 是否开启硬件解码
@property (nonatomic, assign) BOOL openHardwareDecode;


@property (nonatomic, assign) BOOL showLogUnCrypt;

@property (nonatomic, assign) int logFileSize;

@property (nonatomic, copy) NSString *logFileBaseDirName;

/**
 从字典转化为当前类型实例。
 
 @param dic 字典
 @return 当前类型实例
 */
+ (instancetype)fromDictionary:(NSDictionary *)dic;

/**
 转换成 dictionary。

 @return dictionary
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END
