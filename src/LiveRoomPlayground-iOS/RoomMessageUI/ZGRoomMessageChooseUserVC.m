//
//  ZGRoomMessageChooseUserVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/20.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_RoomMessage

#import "ZGRoomMessageChooseUserVC.h"

@interface ZGRoomMessageChooseUserVC ()

@property (nonatomic) NSMutableDictionary<NSString*,ZGRoomMessageTopicUser*> *userIDKeyedUserDic;
@property (nonatomic, copy) NSArray<ZGRoomMessageTopicUser *> *userList;

@end

@implementation ZGRoomMessageChooseUserVC

- (instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userIDKeyedUserDic = [NSMutableDictionary dictionary];
    self.navigationItem.title = @"指定用户";
}

- (void)updateRoomUserList:(NSArray<ZGRoomMessageTopicUser *> *)userList {
    self.userList = userList;
    
    // 删除已不存在的 selected user id
    NSArray<NSString*> *userIds = [userList valueForKeyPath:@"userID"];
    NSArray<ZGRoomMessageTopicUser*> *selUsers = [self.userIDKeyedUserDic.allValues copy];
    for (ZGRoomMessageTopicUser *selUser in selUsers) {
        if (![userIds containsObject:selUser.userID]) {
            [self deselectUser:selUser];
        }
    }
    
    [self.tableView reloadData];
}

- (NSArray<ZGRoomMessageTopicUser *> *)selectedUsers {
    return [[self.userIDKeyedUserDic allValues] copy];
}

- (void)selectUser:(ZGRoomMessageTopicUser *)user {
    if (![self.userIDKeyedUserDic.allKeys containsObject:user.userID]) {
        self.userIDKeyedUserDic[user.userID] = user;
        if (self.userSelectHandler) {
            self.userSelectHandler(user);
        }
    }
}

- (void)deselectUser:(ZGRoomMessageTopicUser *)user {
    if ([self.userIDKeyedUserDic.allKeys containsObject:user.userID]) {
        [self.userIDKeyedUserDic removeObjectForKey:user.userID];
        if (self.userDeselectHandler) {
            self.userDeselectHandler(user);
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.userList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    ZGRoomMessageTopicUser *userInfo = self.userList[indexPath.row];
    cell.textLabel.text = userInfo.userName;
    cell.detailTextLabel.text = userInfo.userID;
    cell.accessoryType = [self.userIDKeyedUserDic.allKeys containsObject:userInfo.userID]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ZGRoomMessageTopicUser *userInfo = self.userList[indexPath.row];
    
    // toggle select or deselect this user
    if ([self.self.userIDKeyedUserDic.allKeys containsObject:userInfo.userID]) {
        [self deselectUser:userInfo];
    } else {
        [self selectUser:userInfo];
    }
    
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

@end
#endif
