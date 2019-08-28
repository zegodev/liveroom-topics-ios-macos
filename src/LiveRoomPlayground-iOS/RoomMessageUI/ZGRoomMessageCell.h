//
//  ZGRoomMessageCell.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZGRoomMessageTopicMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGRoomMessageCell : UITableViewCell

/**
 消息 model。通过该属性来改变现实内容
 */
@property (nonatomic) ZGRoomMessageTopicMessage *message;

@end

NS_ASSUME_NONNULL_END
