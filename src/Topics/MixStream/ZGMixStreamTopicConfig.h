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
 混流专题的混流配置 model。每个配置项都配有 isSet_ 的一个标志属性，上游配置选项后再设置相关的 isSet_ 属性为 YES，下游通过 isSet_ 判断是否需要使用该项设置。
 
 
 下面为正确的使用示例：
 
 A(上游)：
 ZGMixStreamTopicConfig *config = [ZGMixStreamTopicConfig new];
 config.outputResolutionWidth = 320;
 config.isSet_outputResolutionWidth = YES;
 config.outputFps = 15;
 config.isSet_outputFps = YES;
 // ...
 
 B *b = [B new];
 [b updateConfig:config];
 
 ---------------------------------------------------------
 
 B(下游)：
 - (void)updateConfig:(ZGMixStreamTopicConfig *)config {
    ZegoMixStreamConfig *streamConfig = [ZegoMixStreamConfig new];
    if (config.isSet_outputResolutionWidth) {
        streamConfig.outputResolutionWidth = config.outputResolutionWidth;
    }
    if (config.isSet_outputFps) {
        streamConfig.outputFps = config.outputFps;
    }
    // ...
 }
 
 */
@interface ZGMixStreamTopicConfig : NSObject

/**
 输出分辨率的宽度
 */
@property (nonatomic, assign) NSInteger outputResolutionWidth;
@property (nonatomic, assign) BOOL isSet_outputResolutionWidth;

/**
 输出分辨率的高度
 */
@property (nonatomic, assign) NSInteger outputResolutionHeight;
@property (nonatomic, assign) BOOL isSet_outputResolutionHeight;

/**
 输出帧率
 */
@property (nonatomic, assign) NSInteger outputFps;
@property (nonatomic, assign) BOOL isSet_outputFps;

/**
 输出码率
 */
@property (nonatomic, assign) NSInteger outputBitrate;
@property (nonatomic, assign) BOOL isSet_outputBitrate;

/**
 混流声道数，1-单声道，2-双声道
 */
@property (nonatomic, assign) NSInteger channels;
@property (nonatomic, assign) BOOL isSet_channels;

/**
 是否开启音浪。YES：开启，NO：关闭；默认值是NO。
 */
@property (nonatomic, assign) BOOL withSoundLevel;
@property (nonatomic, assign) BOOL isSet_withSoundLevel;


/**
 获取默认配置

 @return 默认配置
 */
+ (instancetype)configWithDefault;


/**
 从字典转化为当前类型实例

 @param dic 字典
 @return 当前类型实例
 */
+ (instancetype)fromDictionary:(NSDictionary *)dic;

/**
 转换成 dictionary。当设置 keyedByIsSet = YES 时，加入到字典的依据为该属性的 isSet 属性是否为 YES，否则都加入到 dictionary 中

 @param keyedByIsSet 是否根据 isSet 属性来将属性加入到字典中
 @return dictionary
 */
- (NSDictionary *)toDictionaryKeyedByIsSet:(BOOL)keyedByIsSet;

@end

NS_ASSUME_NONNULL_END
