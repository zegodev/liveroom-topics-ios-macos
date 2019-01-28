//
//  ZGMediaSideInfoDemoEnvirentmentHelper.h
//  LiveRoomPlayground
//
//  Created by Randy Qiu on 2018/10/25.
//  Copyright © 2018 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZGManager.h"
#import "ZGMediaSideInfoDemo.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    kZGMediaSideTopicStatus_None,
    kZGMediaSideTopicStatus_Starting_Login_Room,
    kZGMediaSideTopicStatus_Login_OK,
    kZGMediaSideTopicStatus_Starting_Publishing,
    kZGMediaSideTopicStatus_Starting_Playing,
    kZGMediaSideTopicStatus_Ready_For_Messaging
} ZGMediaSideTopicStatus;

@protocol ZGMediaSideInfoDemoEnvirentmentHelperDelegate <NSObject>

@required
- (void)onStateChanged:(ZGMediaSideTopicStatus)newState;

@end


/**
 构造可以收发媒体次要信息的测试环境，包括
 1. 登陆房间
 2. 推流
 3. 拉流
 */
@interface ZGMediaSideInfoDemoEnvirentmentHelper : NSObject

@property (weak) id<ZGMediaSideInfoDemoEnvirentmentHelperDelegate> delegate;
@property (weak) ZGView* previewView;
@property (weak) ZGView* playView;

@property (readonly) NSMutableArray<NSString*>* sentMsgs;
@property (readonly) NSMutableArray<NSString*>* recvMsgs;

- (void)loginRoom;
- (void)publishAndPlayWithConfig:(ZGMediaSideInfoDemoConfig*)config;

- (void)addSentMsg:(NSString*)msg;
- (void)addRecvMsg:(NSString*)msg;
- (NSString*)checkSentRecvMsgs;

+ (NSString*)descOfStatus:(ZGMediaSideTopicStatus)status;

@end

NS_ASSUME_NONNULL_END
