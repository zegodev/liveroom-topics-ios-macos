//
//  ZGLoginRoomDemo.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/18.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGLoginRoomDemo.h"
#import "ZegoLog.h"

@interface ZGLoginRoomDemo () <ZegoRoomDelegate>

@property (assign, nonatomic) BOOL isLoginRoom;
@property (copy, nonatomic) NSString *roomID;
@property (strong, nonatomic) NSMutableSet<NSString*>* streamIDList;

@end

@implementation ZGLoginRoomDemo

+ (instancetype)shared {
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    //通过设置 SDK 房间代理，可以收到房间内的一些信息回调。开发者可以按自己的需求在回调里实现自己的业务
    [ZGApiManager.api setRoomDelegate:instance];
    
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _streamIDList = [NSMutableSet set];
    }
    return self;
}

- (BOOL)loginRoom:(NSString *)roomID role:(ZegoRole)role completion:(ZegoLoginCompletionBlock)completion {
    if (self.isLoginRoom) {
        return NO;
    }
    
    //设置用户及用户名接口需要在 LoginRoom 之前调用
    //必须保证 UserID 的唯一性。可与App业务后台账号进行关联，UserID 还能便于 ZEGO 技术支持帮忙查找定位线上问题，请定义一个有意义的 UserID。
    NSString *userID = ZGHelper.userID;
    [ZegoLiveRoomApi setUserID:userID userName:userID];
    ZGLogInfo(@"设置UserID:%@,UserName:%@",userID, userID);
    
    ZGLogInfo(@"开始登陆房间:%@,身份:%@",roomID,role == ZEGO_ANCHOR ? @"主播":@"观众");
    
    //注意!!! SDK 的推拉流以及信令服务等常用功能都需要登录房间后才能使用,
    //在退出房间时时候必须要调用退出房间接口。
    
    //RoomID:房间ID，只支持长度不超过 128 byte 的数字，下划线，字母。每个房间 ID 代表着一个房间，App 需保证房间 ID 的全局唯一。
    //Role:用户角色，分主播和观众。请根据场景选择对应角色。
    
    Weakify(self);
    bool result = [ZGApiManager.api loginRoom:roomID role:role withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        Strongify(self);
        
        BOOL success = errorCode == 0;
        
        if (success) {
            self.isLoginRoom = YES;
            ZGLogInfo(@"登录房间成功");
            
            [self addStreams:streamList];
            
            for (ZegoStream *stream in streamList) {
                ZGLogInfo(@"房间内已存在流:%@",stream.streamID);
            }
        }
        else {
            self.roomID = nil;
            ZGLogError(@"登录房间失败");
        }
        
        completion(errorCode, streamList);
    }];
    
    if (result) {
        self.roomID = roomID;
    }
    else {
        ZGLogWarn(@"登录房间出错，参数不合法");
    }
    
    return result ? YES:NO;
}

/**
 * 登出房间
 * 注意!!! 当用户退出时需要退出登录房间。
 * 否则会影响房间业务.
 */
- (void)logoutRoom {
    if (!self.isLoginRoom) {
        return;
    }
    
    ZGLogInfo(@"登出房间:%@", self.roomID);
    
    [ZGApiManager.api logoutRoom];
    
    self.isLoginRoom = NO;
    self.roomID = nil;
    
    [self willChangeValueForKey:ZGBindKeyPath(self.streamIDList)];
    [self.streamIDList removeAllObjects];
    [self didChangeValueForKey:ZGBindKeyPath(self.streamIDList)];
}

#pragma mark - Stream Manage

- (void)addStreams:(NSArray<ZegoStream*>*)streams {
    [self willChangeValueForKey:ZGBindKeyPath(self.streamIDList)];
    
    for (ZegoStream *stream in streams) {
        [self.streamIDList addObject:stream.streamID];
    }
    
    [self didChangeValueForKey:ZGBindKeyPath(self.streamIDList)];
}

- (void)deleteStreams:(NSArray<ZegoStream*>*)streams {
    [self willChangeValueForKey:ZGBindKeyPath(self.streamIDList)];
    
    for (ZegoStream *stream in streams) {
        [self.streamIDList removeObject:stream.streamID];
    }
    
    [self didChangeValueForKey:ZGBindKeyPath(self.streamIDList)];
}

#pragma mark - ZegoRoomDelegate

- (void)onKickOut:(int)reason roomID:(NSString *)roomID {
    self.isLoginRoom = NO;
    self.roomID = nil;
    
    ZGLogWarn(@"被踢出房间，原因:%d，房间号:%@",reason, roomID);
    
    // 原因，16777219 表示该账户多点登录被踢出，16777220 表示该账户是被手动踢出，16777221 表示房间会话错误被踢出
    // 注意!!! 业务侧确保分配的userID保持唯一，不然会造成互相抢占。
}

- (void)onDisconnect:(int)errorCode roomID:(NSString *)roomID {
    self.isLoginRoom = NO;
    self.roomID = nil;
    
    ZGLogWarn(@"房间连接断开，错误码:%d，房间号:%@",errorCode, roomID);
    
    // 原因，16777219 网络断开。 断网90秒仍没有恢复后会回调这个错误，onDisconnect后会停止推流和拉流
}

- (void)onTempBroken:(int)errorCode roomID:(NSString *)roomID {
    ZGLogWarn(@"房间与 Server 中断，SDK会尝试自动重连，房间号:%@",roomID);
}

- (void)onReconnect:(int)errorCode roomID:(NSString *)roomID {
    ZGLogInfo(@"房间与 Server 重新连接，房间号:%@",roomID);
}

- (void)onStreamUpdated:(int)type streams:(NSArray<ZegoStream *> *)streamList roomID:(NSString *)roomID {
    // 当登陆房间成功后，如果房间内中途有人推流或停止推流。房间内其他人就能通过该回调收到流更新通知。
    
    BOOL isTypeAdd = type == ZEGO_STREAM_ADD;//流变更类型：增加/删除
    
    for (ZegoStream *stream in streamList) {
        ZGLogInfo(@"收到流更新:%@，类型:%@，房间号:%@",stream.streamID, isTypeAdd ? @"增加":@"删除", roomID);
    }
    
    isTypeAdd ? [self addStreams:streamList]:[self deleteStreams:streamList];
}

- (void)onStreamExtraInfoUpdated:(NSArray<ZegoStream *> *)streamList roomID:(NSString *)roomID {
    // 开发者可以通过流额外信息回调，来实现主播设备状态同步的功能，
    // 比如主播关闭麦克风，这个时候主播可以通过更新流额外信息发送主播当前的设备状态
    // 观众则可以通过此回调拿到流额外信息，更新主播设备状态。
    
    for (ZegoStream *stream in streamList) {
        ZGLogInfo(@"收到流附加信息更新:%@，流ID:%@，房间号:%@",stream.extraInfo, stream.streamID, roomID);
    }
}


@end
