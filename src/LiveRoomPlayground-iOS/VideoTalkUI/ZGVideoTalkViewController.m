//
//  ZGVideoTalkViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/2.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_VideoTalk

#import "ZGVideoTalkViewController.h"
#import "ZGVideoTalkDemo.h"
#import "ZGUserIDHelper.h"

NSInteger const ZGVideoTalkStreamViewColumnPerRow = 3;  // stream 视图每行的显示个数
CGFloat const ZGVideoTalkStreamViewSpacing = 8.f;       // stream 视图间距


@interface ZGVideoTalkUserVideoViewObject : NSObject

@property (nonatomic, assign) BOOL isLocalUser;     // 是否是本人
@property (nonatomic, copy) NSString *userID;       // user ID
@property (nonatomic, strong) UIView *videoView;     // 播放视图

@end

@implementation ZGVideoTalkUserVideoViewObject
@end


@interface ZGVideoTalkViewController () <ZGVideoTalkDemoDataSource, ZGVideoTalkDemoDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *cameraSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *micSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *enableAudioModuleSwitch;

@property (nonatomic, weak) IBOutlet UIView *talkUserContainerView;

// 参与视频通话用户的视频视图
@property (nonatomic, strong) NSMutableArray<ZGVideoTalkUserVideoViewObject *> *joinUserVideoViewObjs;

@property (nonatomic, copy) NSString *joinTalkUserID;
@property (nonatomic, copy) NSString *joinTalkStreamID;

@end

@implementation ZGVideoTalkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if DEBUG
    NSAssert(self.roomID != nil, @"必须设置 roomID");
    NSAssert(self.videoTalkDemo != nil, @"必须设置 videoTalkDemo");
#endif
    
    // 获取到 userID 和 userName
    self.joinTalkUserID = ZGUserIDHelper.userID;
    self.joinTalkStreamID = [NSString stringWithFormat:@"s-%@", self.joinTalkUserID];
    self.joinUserVideoViewObjs = [NSMutableArray<ZGVideoTalkUserVideoViewObject *> array];
    
    [self.videoTalkDemo setDataSource:self];
    [self.videoTalkDemo setDelegate:self];
    
    [self setupUI];
    [self joinVideoTalkRoom];
}

- (IBAction)onToggleCameraSwitch:(UISwitch *)sender {
    [self.videoTalkDemo setEnableCamera:[sender isOn]];
}

- (IBAction)onToggleMicSwitch:(UISwitch *)sender {
    [self.videoTalkDemo setEnableMic:[sender isOn]];
}

- (IBAction)onToggleEnableAudioModuleSwitch:(UISwitch *)sender {
    [self.videoTalkDemo setEnableAudioModule:[sender isOn]];
}

#pragma mark - private methods

- (void)setupUI {
    self.cameraSwitch.on = self.videoTalkDemo.enableCamera;
    self.micSwitch.on = self.videoTalkDemo.enableMic;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closePage:)];
    [self invalidateJoinTalkStateDisplay];
}

- (void)joinVideoTalkRoom {
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    BOOL result = [self.videoTalkDemo joinTalkRoom:self.roomID userID:self.joinTalkUserID callback:^(int errorCode, NSArray<NSString *> *joinTalkUserIDs) {
        [ZegoHudManager hideNetworkLoading];
        
        Strongify(self);
        if (errorCode != 0) {
            [ZegoHudManager showMessage:@"加入视频通话失败"];
            return;
        }
        
        // 刷新数据源
        if (joinTalkUserIDs.count > 0) {
            for (NSString *userID in joinTalkUserIDs) {
                [self addRemoteUserVideoViewObjectIfNeedWithUserID:userID];
            }
            [self rearrangeJoinUserVideoViews];
        }
    }];
    
    if (!result) {
        [ZegoHudManager hideNetworkLoading];
        [ZegoHudManager showMessage:@"参数不合法或已经登录房间"];
    }
}

/**
 添加自己的推流视图 object
 */
- (ZGVideoTalkUserVideoViewObject *)addLocalUserVideoViewObject {
    UIView *view = [UIView new];
    ZGVideoTalkUserVideoViewObject *localVVObj = [ZGVideoTalkUserVideoViewObject new];
    localVVObj.isLocalUser = YES;
    localVVObj.userID = self.joinTalkUserID;
    localVVObj.videoView = view;
    
    [self.joinUserVideoViewObjs addObject:localVVObj];
    return localVVObj;
}

- (ZGVideoTalkUserVideoViewObject *)getLocalUserVideoViewObject {
    ZGVideoTalkUserVideoViewObject *localUserObj = nil;
    for (ZGVideoTalkUserVideoViewObject *obj in self.joinUserVideoViewObjs) {
        if ([obj.userID isEqualToString:self.joinTalkUserID]) {
            localUserObj = obj;
            break;
        }
    }
    return localUserObj;
}

- (void)addRemoteUserVideoViewObjectIfNeedWithUserID:(NSString *)userID {
    if ([self getUserVideoViewObjectWithUserID:userID]) {
        return;
    }
    
    ZGVideoTalkUserVideoViewObject *vvObj = [ZGVideoTalkUserVideoViewObject new];
    vvObj.isLocalUser = NO;
    vvObj.userID = userID;
    vvObj.videoView = [UIView new];
    [self.joinUserVideoViewObjs addObject:vvObj];
}

- (void)removeUserVideoViewObjectWithUserID:(NSString *)userID {
    ZGVideoTalkUserVideoViewObject *obj = [self getUserVideoViewObjectWithUserID:userID];
    if (obj) {
        [self.joinUserVideoViewObjs removeObject:obj];
        [obj.videoView removeFromSuperview];
    }
}

- (void)closePage:(id)sender {
    [self exitRoomWithRequestLeave:YES];
}

- (void)exitRoomWithRequestLeave:(BOOL)requestLeave {
    [self.videoTalkDemo setDataSource:nil];
    [self.videoTalkDemo setDelegate:nil];
    if (requestLeave) {
        [self.videoTalkDemo leaveTalkRoom];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)invalidateJoinTalkStateDisplay {
    ZGVideoTalkJoinRoomState joinRoomState = self.videoTalkDemo.joinRoomState;
    NSString *stateTitle = nil;
    if (joinRoomState == ZGVideoTalkJoinRoomStateJoined) {
        stateTitle = @"推流中（已加入通话）";
    } else if (joinRoomState == ZGVideoTalkJoinRoomStateNotJoin) {
        stateTitle = @"未推流（未加入通话）";
    } else if (joinRoomState == ZGVideoTalkJoinRoomStateOnRequestJoin) {
        stateTitle = @"请求加入通话中";
    }
    self.navigationItem.title = stateTitle;
}

/**
 重排用户视频视图列表
 */
- (void)rearrangeJoinUserVideoViews {
    // 重排参与者流视图
    for (ZGVideoTalkUserVideoViewObject *obj in self.joinUserVideoViewObjs) {
        if (obj.videoView != nil) {
            [obj.videoView removeFromSuperview];
        }
    }
    
    NSInteger columnPerRow = ZGVideoTalkStreamViewColumnPerRow;
    CGFloat viewSpacing = ZGVideoTalkStreamViewSpacing;
    CGFloat screenWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    CGFloat playViewWidth = (screenWidth - (columnPerRow + 1)*viewSpacing) /columnPerRow;
    CGFloat playViewHeight = 1.5f * playViewWidth;
    
    NSInteger i = 0;
    for (ZGVideoTalkUserVideoViewObject *obj in self.joinUserVideoViewObjs) {
        if (obj.videoView == nil) {
            continue;
        }
        
        NSInteger cloumn = i % columnPerRow;
        NSInteger row = i / columnPerRow;
        
        CGFloat x = viewSpacing + cloumn * (playViewWidth + viewSpacing);
        CGFloat y = viewSpacing + row * (playViewHeight + viewSpacing);
        obj.videoView.frame = CGRectMake(x, y, playViewWidth, playViewHeight);
        
        [self.talkUserContainerView addSubview:obj.videoView];
        i++;
    }
}

- (ZGVideoTalkUserVideoViewObject *)getUserVideoViewObjectWithUserID:(NSString *)userID {
    __block ZGVideoTalkUserVideoViewObject *existObj = nil;
    [self.joinUserVideoViewObjs enumerateObjectsUsingBlock:^(ZGVideoTalkUserVideoViewObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userID isEqualToString:userID]) {
            existObj = obj;
            *stop = YES;
        }
    }];
    return existObj;
}

- (NSArray<NSString *> *)getAllJoinUserIDs {
    NSArray<NSString*> *currentJoinUserIDs = [[self.joinUserVideoViewObjs copy]  valueForKeyPath:@"userID"];
    return currentJoinUserIDs;
}

- (void)handleOutTalkRoomWithAlertMessage:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self exitRoomWithRequestLeave:NO];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - ZGVideoTalkDemoDataSource

- (NSString *)localUserJoinTalkStreamID:(ZGVideoTalkDemo *)demo {
    return self.joinTalkStreamID;
}

- (UIView *)localUserPreviewView:(ZGVideoTalkDemo *)demo {
    return [self getLocalUserVideoViewObject].videoView;
}

- (UIView *)videoTalkDemo:(ZGVideoTalkDemo *)demo playViewForRemoteUserWithID:(NSString *)userID {
    return [self getUserVideoViewObjectWithUserID:userID].videoView;
}

#pragma mark - ZGVideoTalkDemoDelegate

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo kickOutTalkRoom:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomID]) {
        return;
    }
    [self handleOutTalkRoomWithAlertMessage:@"被踢出房间，或者相同 userID 在别出登录"];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo disConnectTalkRoom:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomID]) {
        return;
    }
    [self handleOutTalkRoomWithAlertMessage:@"您已断开和房间的连接"];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo
localUserJoinRoomStateUpdated:(ZGVideoTalkJoinRoomState)state
               roomID:(NSString *)roomID {
    if (![roomID isEqualToString:self.roomID]) {
        return;
    }
    
    if (state == ZGVideoTalkJoinRoomStateJoined) {
        // 添加本地画预览视图，准备好数据源
        if (![self getLocalUserVideoViewObject]) {
            // 添加本人通话视图
            [self addLocalUserVideoViewObject];
            [self rearrangeJoinUserVideoViews];
        }
    } else if (state == ZGVideoTalkJoinRoomStateNotJoin) {
        [self removeUserVideoViewObjectWithUserID:self.joinTalkUserID];
        [self rearrangeJoinUserVideoViews];
    }
    [self invalidateJoinTalkStateDisplay];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo
remoteUserDidJoinTalkInRoom:(NSString *)talkRoomID
              userIDs:(NSArray<NSString *> *)userIDs {
    if (![talkRoomID isEqualToString:self.roomID] || userIDs.count == 0) {
        return;
    }
    
    // 刷新数据源
    for (NSString *userID in userIDs) {
        [self addRemoteUserVideoViewObjectIfNeedWithUserID:userID];
    }
    [self rearrangeJoinUserVideoViews];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo
remoteUserDidLeaveTalkInRoom:(NSString *)talkRoomID
              userIDs:(NSArray<NSString *> *)userIDs {
    if (![talkRoomID isEqualToString:self.roomID] || userIDs.count == 0) {
        return;
    }
    
    // 刷新数据源
    for (NSString *userID in userIDs) {
        [self removeUserVideoViewObjectWithUserID:userID];
    }
    [self rearrangeJoinUserVideoViews];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo
remoteUserVideoStateUpdate:(int)stateCode
               userID:(NSString *)userID {
    // 业务处理远端通话用户视频播放状态的变化
}

@end

#endif
