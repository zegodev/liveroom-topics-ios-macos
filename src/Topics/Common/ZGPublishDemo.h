//
//  ZGPublishDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#import <ZegoLiveRoom/zego-api-defines-oc.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZGPublishDemoDelegate <NSObject>

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info;

@optional
- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality;

@end


/**
 推流示例类
 
 @discussion 主要简化SDK推流一系列接口
 @note 开发者可参考该类的代码, 理解SDK接口
 @warning 注意!!! 开发者需要先初始化sdk, 登录房间后, 才能进行推流
 */
@interface ZGPublishDemo : NSObject

@property (assign, nonatomic, readonly) BOOL isPreview;
@property (assign, nonatomic, readonly) BOOL isPublishing;

@property (copy, nonatomic, readonly, nullable) NSString *streamID;

@property (weak, nonatomic) id<ZGPublishDemoDelegate> delegate;

+ (instancetype)shared;

- (BOOL)startPublish:(NSString *)streamID title:(nullable NSString *)title flag:(int)flag;
- (void)stopPublish;

- (void)startPreview;
- (void)stopPreview;

- (void)setPreviewView:(ZEGOView *)view;

@end

NS_ASSUME_NONNULL_END
