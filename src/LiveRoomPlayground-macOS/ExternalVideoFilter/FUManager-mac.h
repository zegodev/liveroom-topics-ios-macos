//
//  FUManager.h
//  FULiveDemo
//
//  Created by 刘洋 on 2017/8/18.
//  Copyright © 2017年 刘洋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface FUManager : NSObject
// 是否性能优先
@property (nonatomic, assign) BOOL performance ;

@property (nonatomic, assign) BOOL skinDetectEnable ;   // 精准美肤
@property (nonatomic, assign) NSInteger blurShape;      // 美肤类型 (0、1、) 清晰：0，朦胧：1
@property (nonatomic, assign) double blurLevel;         // 磨皮(0.0 - 6.0)
@property (nonatomic, assign) double whiteLevel;        // 美白
@property (nonatomic, assign) double redLevel;          // 红润
@property (nonatomic, assign) double eyelightingLevel;  // 亮眼
@property (nonatomic, assign) double beautyToothLevel;  // 美牙

+ (FUManager *)shareManager;

+ (void)releaseManager;

/**初始化Faceunity,加载道具*/
//- (void)loadAllItems;

/**加载美颜道具*/
- (void)loadFilter;

//- (void)loadMakeup;

/**销毁全部道具*/
- (void)destoryAllItems;

/**加载普通道具*/
- (void)loadItem:(NSString *)itemName;

/**
 修改sdk参数

 @param sdkStr sdk设置键值
 @param index 设置对于句柄的参数
 index ： 0 - 美颜 ；1 - 贴纸 ；2 - 抗锯齿
 reture : 0 - 失败 ； 1 - 成功
 */
-(int)changeParamsStr:(NSString *)sdkStr index:(int)index value:(id)value;


#pragma mark -  美妆


- (void)setAllSkinParam;

/**将道具绘制到pixelBuffer*/
- (CVPixelBufferRef)renderItemsToPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/**获取错误信息*/
- (NSString *)getError;

@end
