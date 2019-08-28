//
//  ZGRoomMessageChooseUserVC.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/20.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_RoomMessage

#import <UIKit/UIKit.h>
#import "ZGRoomMessageTopicUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZGRoomMessageChooseUserVC : UITableViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithStyle:(UITableViewStyle)style NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

@property (nonatomic, readonly) NSArray<ZGRoomMessageTopicUser *> *selectedUsers;

/**
 用户选中 handler
 */
@property (nonatomic, copy) void(^userSelectHandler)(ZGRoomMessageTopicUser *user);

/**
 用户不被选中 handler
 */
@property (nonatomic, copy) void(^userDeselectHandler)(ZGRoomMessageTopicUser *user);

/**
 更新用户列表
 */
- (void)updateRoomUserList:(NSArray<ZGRoomMessageTopicUser *> *)userList;

@end

NS_ASSUME_NONNULL_END
#endif
