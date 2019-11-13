//
//  ZGRoomMessageTopicMessage.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/20.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 房间消息专题的消息 model
 */
@interface ZGRoomMessageTopicMessage : NSObject

/**
 消息类型。
 1:房间消息（RoomMessage）
 2:大房间消息（BigRoomMessage）
 3:指定用户消息（CustomCommand）
 */
@property (nonatomic, assign) NSInteger messageType;

/**
 消息发送者 user id
 */
@property (nonatomic, copy) NSString *userID;

/**
 消息内容
 */
@property (nonatomic, copy) NSString *messageContent;

@end

NS_ASSUME_NONNULL_END
