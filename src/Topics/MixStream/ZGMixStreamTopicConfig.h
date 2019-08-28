//
//  ZGMixStreamTopicConfig.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 混流专题的混流配置 model
 */
@interface ZGMixStreamTopicConfig : NSObject

/**
 输出分辨率的宽度
 */
@property (nonatomic, assign) NSInteger outputResolutionWidth;

/**
 输出分辨率的高度
 */
@property (nonatomic, assign) NSInteger outputResolutionHeight;

/**
 输出帧率
 */
@property (nonatomic, assign) NSInteger outputFps;

/**
 输出码率
 */
@property (nonatomic, assign) NSInteger outputBitrate;

/**
 混流声道数，1-单声道，2-双声道
 */
@property (nonatomic, assign) NSInteger channels;

/**
 是否开启音浪。YES：开启，NO：关闭；默认值是NO。
 */
@property (nonatomic, assign) BOOL withSoundLevel;


/**
 从字典转化为当前类型实例

 @param dic 字典
 @return 当前类型实例
 */
+ (instancetype)fromDictionary:(NSDictionary *)dic;

/**
 转换成 dictionary
 
 @return dictionary
 */
- (NSDictionary *)toDictionary;

@end

NS_ASSUME_NONNULL_END
