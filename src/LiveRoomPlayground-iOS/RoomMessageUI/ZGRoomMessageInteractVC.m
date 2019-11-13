//
//  ZGRoomMessageInteractVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_RoomMessage

#import "ZGRoomMessageInteractVC.h"
#import "ZGRoomMessageCell.h"
#import "ZGRoomMessageChooseUserVC.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>
#import <ZegoLiveRoom/ZegoLiveRoomApi-IM.h>
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import <objc/runtime.h>
//#import <ZegoLiveRoom/ZegoLiveRoomApi-ReliableMessage.h>

NSString* const ZGRoomMessageInteractMessageCellID = @"ZGRoomMessageCell";
static char ZGRoomMessageInteractVCSendMessageTypeKey;

@interface ZGRoomMessageInteractVC () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ZegoRoomDelegate, ZegoIMDelegate /*, ZegoReliableMessageDelegate */>

@property (weak, nonatomic) IBOutlet UITableView *messageTableView;
@property (weak, nonatomic) IBOutlet UILabel *choosedCustomCommandUserTipLabel;

@property (nonatomic, copy) NSString *zgUserID;
@property (nonatomic, copy) NSString *zgUserName;
@property (nonatomic) ZGAppGlobalConfig *appConfig;
@property (nonatomic) ZegoLiveRoomApi *zegoApi;

// 消息列表
@property (nonatomic) NSMutableArray<ZGRoomMessageTopicMessage*> *messageList;
// 房间内的用户列表
@property (nonatomic) NSMutableArray<ZGRoomMessageTopicUser*> *roomUserList;
// 指定用户消息选择用户 view controller
@property (nonatomic) ZGRoomMessageChooseUserVC *customCommandChooseUserVC;

@property (nonatomic) UIAlertController *sendMessageAlertVC;
@property (nonatomic) UITextField *sendMessageTextField;

@end

@implementation ZGRoomMessageInteractVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"RoomMessage" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGRoomMessageInteractVC class])];
}

- (void)dealloc {
#if DEBUG
    NSLog(@"%@ dealloc.", NSStringFromClass([self class]));
#endif
    [_zegoApi logoutRoom];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _messageList = [NSMutableArray array];
    _roomUserList = [NSMutableArray array];
    
    // 获取到 userID 和 userName
    self.zgUserID = [NSString stringWithFormat:@"%@_%ld",[UIDevice currentDevice].name,(long)[NSDate date].timeIntervalSince1970];
    self.zgUserName = self.zgUserID;
    
    self.appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    // 设置该模块的 ZegoLiveRoomApi 默认设置
    [[self class] setupZegoLiveRoomApiDefault:self.appConfig];
    
    self.navigationItem.title = @"房间消息";
    self.messageTableView.delegate = self;
    self.messageTableView.dataSource = self;
    [self.messageTableView registerNib:[UINib nibWithNibName:NSStringFromClass([ZGRoomMessageCell class]) bundle:nil] forCellReuseIdentifier:ZGRoomMessageInteractMessageCellID];
    [self invalidateChoosedCustomCommandUserTip];
    
    // 初始化，然后登录房间
    [self initializeZegoApiThenLoginRoom];
}

- (void)initializeZegoApiThenLoginRoom {
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    self.zegoApi = [[ZegoLiveRoomApi alloc] initWithAppID:self.appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:self.appConfig.appSign] completionBlock:^(int errorCode) {
        [ZegoHudManager hideNetworkLoading];
        Strongify(self);
        if (errorCode != 0) {
            ZGLogWarn(@"初始化失败，errorCode:%d", errorCode);
            [ZegoHudManager showMessage:[NSString stringWithFormat:@"初始化失败，errorCode:%d", errorCode]];
            return;
        }
        
        ZGLogInfo(@"初始化成功");
        // 设置 delegate
        [self.zegoApi setRoomDelegate:self];
        [self.zegoApi setIMDelegate:self];
//        [self.zegoApi setReliableMessageDelegate:self];
        
        // login
        // 登录前必须设置 userID 和 userName
        [ZegoLiveRoomApi setUserID:self.zgUserID userName:self.zgUserName];
        
        // 设置 userStateUpdate=YES，当用户进入或退出房间时，其他用户可以收到通知
        [self.zegoApi setRoomConfig:YES userStateUpdate:YES];
        
        [ZegoHudManager showNetworkLoading];
        Weakify(self);
        BOOL res = [self.zegoApi loginRoom:self.roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
            Strongify(self);
            [ZegoHudManager hideNetworkLoading];
            if (errorCode == 0) {
                ZGLogInfo(@"登录成功");
            } else {
                ZGLogWarn(@"登录失败，errorCode:%d", errorCode);
                [ZegoHudManager showMessage:[NSString stringWithFormat:@"登录失败，errorCode:%d", errorCode]];
            }
        }];
        if (!res) {
            [ZegoHudManager hideNetworkLoading];
            [ZegoHudManager showMessage:@"登录失败，请检查参数是否正确"];
        }
    }];
    if (!self.zegoApi) {
        [ZegoHudManager hideNetworkLoading];
        [ZegoHudManager showMessage:@"初始化失败，请检查参数是否正确"];
    }
}

/**
 设置该模块的 ZegoLiveRoomApi 默认设置
 */
+ (void)setupZegoLiveRoomApiDefault:(ZGAppGlobalConfig *)appConfig {
    // 设置环境
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    // 设置硬编硬解
    [ZegoLiveRoomApi requireHardwareEncoder:appConfig.openHardwareEncode];
    [ZegoLiveRoomApi requireHardwareDecoder:appConfig.openHardwareDecode];
    
    [ZegoLiveRoomApi enableExternalRender:NO];
    [ZegoLiveRoomApi setVideoFilterFactory:nil];
    [ZegoLiveRoomApi setVideoCaptureFactory:nil];
}

- (IBAction)sendRoomMessageButnClick:(id)sender {
    [self showSendMessageUIWithMessageType:1];
}

- (IBAction)sendBigRoomMessageButnClick:(id)sender {
    [self showSendMessageUIWithMessageType:2];
}

- (IBAction)sendCustomCommandButnClick:(id)sender {
    [self showSendMessageUIWithMessageType:3];
}

- (IBAction)chooseCustomCommandUserButnClick:(id)sender {
    [self.navigationController pushViewController:self.customCommandChooseUserVC animated:YES];
}

#pragma mark - private methods

- (ZGRoomMessageChooseUserVC *)customCommandChooseUserVC {
    if (!_customCommandChooseUserVC) {
        _customCommandChooseUserVC = [[ZGRoomMessageChooseUserVC alloc] init];
        Weakify(self);
        _customCommandChooseUserVC.userSelectHandler = ^(ZGRoomMessageTopicUser * _Nonnull user) {
            Strongify(self);
            [self invalidateChoosedCustomCommandUserTip];
        };
        _customCommandChooseUserVC.userDeselectHandler = ^(ZGRoomMessageTopicUser * _Nonnull user) {
            Strongify(self);
            [self invalidateChoosedCustomCommandUserTip];
        };
        
        // 更新用户列表
        [_customCommandChooseUserVC updateRoomUserList:[self.roomUserList copy]];
    }
    return _customCommandChooseUserVC;
}

- (UIAlertController *)sendMessageAlertVC {
    if (!_sendMessageAlertVC) {
        _sendMessageAlertVC = [UIAlertController alertControllerWithTitle:@"发送消息" message:nil preferredStyle:UIAlertControllerStyleAlert];
        Weakify(self);
        [_sendMessageAlertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            Strongify(self);
            self.sendMessageTextField = textField;
            textField.returnKeyType = UIReturnKeySend;
            textField.delegate = self;
        }];
        
        [_sendMessageAlertVC addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
        [_sendMessageAlertVC addAction:[UIAlertAction actionWithTitle:@"发送" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            Strongify(self);
            [self sendCurrentInputTextAsMessage];
            self->_sendMessageTextField.text = nil;
            [self->_sendMessageTextField resignFirstResponder];
        }]];
    }
    return _sendMessageAlertVC;
}

- (void)showSendMessageUIWithMessageType:(NSInteger)messageType {
    NSString *alertTitle = nil;
    if (messageType == 1) {
        alertTitle = @"发送RoomMessage";
    } else if (messageType == 2) {
        alertTitle = @"发送BigRoomMessage";
    } else if (messageType == 3) {
        alertTitle = @"发送CustomCommand";
    } else {
        // 不支持其他类型
        return;
    }
    
    // 弹出输入框进行发消息
    // 在 2 种情况下会触发发送消息：1）在输入框的键盘上点击 return 按钮时；2）在点击弹框的发送按钮。请查看 sendCurrentInputTextAsMessage 方法相关逻辑
    self.sendMessageAlertVC.title = alertTitle;
    [self presentViewController:self.sendMessageAlertVC animated:YES completion:^{
        // 将要发送消息的类型绑定到 sendMessageTextField
        objc_setAssociatedObject(self.sendMessageTextField, &ZGRoomMessageInteractVCSendMessageTypeKey, @(messageType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self.sendMessageTextField becomeFirstResponder];
    }];
}

/*
- (BOOL)test_sendCurrentInputTextAsReliableMessage {
    NSLog(@"begin call test_sendCurrentInputTextAsReliableMessage");
    static NSUInteger latestSeq = 0;
    NSString *messageContent = _sendMessageTextField.text;
    [self.zegoApi sendReliableMessage:messageContent type:@"MyMessageType" latestSeq:(int)latestSeq completion:^(int errorCode, NSString *roomId, NSString *msgType, NSUInteger msgSeq) {
        NSLog(@"send result。errorCode:%d, msgSeq:%lu, msgType:%@", errorCode, (unsigned long)msgSeq, msgType);
        if (errorCode != 0) {
            [self.zegoApi getReliableMessages:@[@"MyMessageType"] completion:^(int errorCode, NSString *roomId, NSArray<ZegoReliableMessage *> *messageList) {
                ZegoReliableMessage *m = messageList.firstObject;
                NSLog(@"get result。errorCode:%d, msgSeq:%lu, msgType:%@", errorCode, (unsigned long)m.latestSeq, m.type);
                if (errorCode == 0) {
                    latestSeq = m.latestSeq;
                    [self test_sendCurrentInputTextAsReliableMessage];
                }
            }];
        } else {
            latestSeq = msgSeq;
        }
    }];
    return YES;
}
*/

/**
 将当前输入的文本作为信息进行发送
 
 @return 是否请求了发送
 */
- (BOOL)sendCurrentInputTextAsMessage {
    // 发送逻辑
    if (!_sendMessageTextField) { return NO; }
    NSNumber *sendMessageTypeObj = objc_getAssociatedObject(_sendMessageTextField, &ZGRoomMessageInteractVCSendMessageTypeKey);
    if (!sendMessageTypeObj) { return NO; }
    
    NSString *messageContent = _sendMessageTextField.text;
    if (messageContent.length == 0) { return NO; }
    
    NSInteger msgType = [sendMessageTypeObj integerValue];
    if (msgType == 1) {
        // Demo 演示发送 TEXT 类型信息
        [self.zegoApi sendRoomMessage:messageContent type:ZEGO_TEXT category:ZEGO_CHAT completion:^(int errorCode, NSString *roomId, unsigned long long messageId) {
            ZGLogInfo(@"发送RoomMessage回调。errorCode:%d",errorCode);
        }];
        return YES;
    } else if (msgType == 2) {
        // Demo 演示发送 TEXT 类型信息
        [self.zegoApi sendBigRoomMessage:messageContent type:ZEGO_TEXT category:ZEGO_CHAT completion:^(int errorCode, NSString *roomId, NSString *messageId) {
            ZGLogInfo(@"发送BigRoomMessage回调。errorCode:%d",errorCode);
        }];
        return YES;
    } else if (msgType == 3) {
        // 获取指定的用户
        NSArray<ZGRoomMessageTopicUser *> *selectedUsers = _customCommandChooseUserVC.selectedUsers;
        if (!selectedUsers || selectedUsers.count == 0) {
            [ZegoHudManager showMessage:@"请指定用户进行发送！"];
            return NO;
        }
        NSMutableArray<ZegoUser*> *targetUsers = [NSMutableArray array];
        for (ZGRoomMessageTopicUser *user in selectedUsers) {
            ZegoUser *zgUser = [[ZegoUser alloc] init];
            zgUser.userId = user.userID;
            zgUser.userName = user.userName;
            [targetUsers addObject:zgUser];
        }
        
        // Demo 演示发送 TEXT 类型信息
        [self.zegoApi sendCustomCommand:[targetUsers copy] content:messageContent completion:^(int errorCode, NSString *roomID) {
            ZGLogInfo(@"发送CustomCommand回调。errorCode:%d",errorCode);
        }];
        return YES;
    }
    return NO;
}

- (void)showMessageOnList:(ZGRoomMessageTopicMessage *)message {
    NSInteger originCount = self.messageList.count;
    [self.messageList addObject:message];
    [self.messageTableView reloadData];
    [self.messageTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:originCount inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
}

- (void)invalidateChoosedCustomCommandUserTip {
    self.choosedCustomCommandUserTipLabel.text = [NSString stringWithFormat:@"已选%@人", @(_customCommandChooseUserVC.selectedUsers.count)];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messageList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGRoomMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:ZGRoomMessageInteractMessageCellID forIndexPath:indexPath];
    
    // 配置 cell
    ZGRoomMessageTopicMessage *message = self.messageList[indexPath.row];
    cell.message = message;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([self sendCurrentInputTextAsMessage]) {
        textField.text = nil;
        [textField resignFirstResponder];
        [_sendMessageAlertVC dismissViewControllerAnimated:YES completion:nil];
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - ZegoRoomDelegate <NSObject>

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    ZGLogWarn(@"被踢出房间, reason:%d", reason);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"已断开和房间的连接, errorCode:%d", errorCode);
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onReconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"和房间重连, errorCode:%d", errorCode);
}

- (void)onReceiveCustomCommand:(NSString *)fromUserID userName:(NSString *)fromUserName content:(NSString*)content roomID:(NSString *)roomID {
    // 收到指定用户消息的回调。
    
    ZGRoomMessageTopicMessage *message = [[ZGRoomMessageTopicMessage alloc] init];
    message.messageType = 3;
    message.userID = fromUserID;
    message.messageContent = content;
    [self showMessageOnList:message];
}

#pragma mark - ZegoIMDelegate

- (void)onUserUpdate:(NSArray<ZegoUserState *> *)userList updateType:(ZegoUserUpdateType)type {
    // 房间成员更新回调，当房间内的成员进入或退出房间时会收到此回调。
    
    // 全量更新，先清空房间列表
    if (type == ZEGO_UPDATE_TOTAL) {
        [self.roomUserList removeAllObjects];
    }
    
    // 退出的用户，从列表中删除
    NSMutableArray<NSString *> *logoutUserIds = [NSMutableArray array];
    for (ZegoUserState *us in userList) {
        if (us.updateFlag == ZEGO_USER_DELETE) {
            [logoutUserIds addObject:us.userID];
        }
    }
    for (NSString *userId in logoutUserIds) {
        __block ZGRoomMessageTopicUser *userObj = nil;
        [self.roomUserList enumerateObjectsUsingBlock:^(ZGRoomMessageTopicUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.userID isEqualToString:userId]) {
                userObj = obj;
                *stop = YES;
            }
        }];
        [self.roomUserList removeObject:userObj];
    }
    
    // 增加的用户，向列表中增加用户
    for (ZegoUserState *us in userList) {
        if (us.updateFlag == ZEGO_USER_ADD) {
            ZGRoomMessageTopicUser *userObj = [[ZGRoomMessageTopicUser alloc] init];
            userObj.userID = us.userID;
            userObj.userName = us.userName;
            [self.roomUserList addObject:userObj];
        }
    }
    
    // 更新界面的用户列表
    [_customCommandChooseUserVC updateRoomUserList:[self.roomUserList copy]];
}

- (void)onRecvRoomMessage:(NSString *)roomId messageList:(NSArray<ZegoRoomMessage*> *)messageList {
    // 收到房间的广播消息的回调。
    
    for (ZegoRoomMessage *roomMsg in messageList) {
        if (roomMsg.type == ZEGO_TEXT) {
            // demo 只处理 TEXT 类型消息
            ZGRoomMessageTopicMessage *message = [[ZGRoomMessageTopicMessage alloc] init];
            message.messageType = 1;
            message.userID = roomMsg.fromUserId;
            message.messageContent = roomMsg.content;
            [self showMessageOnList:message];
        }
    }
}

- (void)onRecvBigRoomMessage:(NSString *)roomId messageList:(NSArray<ZegoBigRoomMessage*> *)messageList {
    // 收到房间的大房间的回调。
    
    for (ZegoBigRoomMessage *roomMsg in messageList) {
        if (roomMsg.type == ZEGO_TEXT) {
            // demo 只处理 TEXT 类型消息
            ZGRoomMessageTopicMessage *message = [[ZGRoomMessageTopicMessage alloc] init];
            message.messageType = 2;
            message.userID = roomMsg.fromUserId;
            message.messageContent = roomMsg.content;
            [self showMessageOnList:message];
        }
    }
}

/*
#pragma mark - ZegoReliableMessageDelegate

- (void)onRecvReliableMessage:(ZegoReliableMessage *)message room:(NSString *)roomId {
    NSLog(@"收到可靠信息。type:%@, latestSeq:%u, content:%@", message.type, message.latestSeq, message.content);
}
*/

@end
#endif
