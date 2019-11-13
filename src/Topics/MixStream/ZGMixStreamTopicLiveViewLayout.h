//
//  ZGMixStreamTopicLiveViewLayout.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 用户直播视图 layout model
 */
@interface ZGMixStreamTopicLiveViewLayout : NSObject

// stream ID
@property (nonatomic, copy) NSString *streamID;

// 是否主图显示
@property (nonatomic) BOOL mainShow;

// 视图布局信息 left, right, width, height
@property (nonatomic) CGFloat left;
@property (nonatomic) CGFloat top;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;

@end

NS_ASSUME_NONNULL_END
