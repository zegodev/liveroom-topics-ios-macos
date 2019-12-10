//
//  ZGRoomConfigLiveVC.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/12/1.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_RoomConfigLive

#import <UIKit/UIKit.h>
#import "ZGJoinLiveDemo.h"

@interface ZGRoomConfigLiveVC : UIViewController

// 房间 ID
@property (nonatomic, copy) NSString *roomID;

// 当前用户 ID
@property (nonatomic, copy) NSString *currentUserID;

// 用户角色
@property (nonatomic, assign) ZegoRole userRole;

// 观众是否可以创建房间
@property (nonatomic, assign) BOOL audienceCreateRoomEnabled;

// 要推流的 id
@property (nonatomic, copy) NSString *localLiveStreamID;

@property (nonatomic, strong) ZGJoinLiveDemo *joinLiveDemo;

+ (instancetype)fromStoryboard;

@end

#endif
