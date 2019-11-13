//
//  JoinLiveViewController.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/12.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_JoinLive

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZGJoinLiveDemo;

@interface ZGJoinLiveViewController : UIViewController

// 房间的主播（创建着）ID
@property (nonatomic, copy) NSString *roomAnchorID;

// 房间 ID
@property (nonatomic, copy) NSString *roomID;

// 当前用户 ID
@property (nonatomic, copy) NSString *currentUserID;

@property (nonatomic, strong) ZGJoinLiveDemo *joinLiveDemo;

@end

NS_ASSUME_NONNULL_END

#endif
