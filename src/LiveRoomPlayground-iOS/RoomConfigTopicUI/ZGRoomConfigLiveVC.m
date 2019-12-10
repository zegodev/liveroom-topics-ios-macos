//
//  ZGRoomConfigLiveVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/12/1.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_RoomConfigLive

#import "ZGRoomConfigLiveVC.h"
#import "ZGJoinLiveUserRenderViewRelation.h"


// 每行显示播放视图数目
const NSInteger ZGRoomConfigTopicLiveRenderViewDisplayColumnPerRow = 3;
// 播放视图间距
const CGFloat ZGRoomConfigTopicLiveRenderViewSpacing = 8.f;

@interface ZGRoomConfigLiveVC () <JoinLiveDemoDataSource, JoinLiveDemoDelegate>

@property (nonatomic, weak) IBOutlet UISwitch *cameraSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *micSwitch;

// 用户视频容器视图，用户的视频视图需要添加在该容器视图中
@property (nonatomic, weak) IBOutlet UIView *userLiveContainerView;

@property (nonatomic) NSMutableArray<ZGJoinLiveUserRenderViewRelation*> *userRenderViewRelationList;

@property (nonatomic, assign) NSInteger viewAppearNum;

@end

@implementation ZGRoomConfigLiveVC

+ (instancetype)fromStoryboard {
    return [[UIStoryboard storyboardWithName:@"RoomConfigTopic" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGRoomConfigLiveVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if DEBUG
    NSAssert(self.roomID != nil, @"'roomID' can't be empty.");
    NSAssert(self.currentUserID != nil, @"'currentUserID' can't be empty.");
    NSAssert(self.joinLiveDemo != nil, @"'joinLiveDemo' can't be nil.");
#endif
    
    self.userRenderViewRelationList = [NSMutableArray array];
    
    // 设置 dataSource 和 delegate
    self.joinLiveDemo.dataSource = self;
    self.joinLiveDemo.delegate = self;
    
    [self setupUI];
    // 根据角色，进行合适的登录、推拉流逻辑
    [self joinVideoLiveRoom];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewAppearNum ++;
    if (self.viewAppearNum == 1) {
        // 调整视频视图 frame，在 viewDidAppear 后才是真正的 View Size
        // 在第一次调用 viewDidAppear 时处理即可
        [self invalidateLiveRenderViewFrames];
    }
}

- (IBAction)onToggleCameraSwitch:(UISwitch *)sender {
    self.joinLiveDemo.enableCamera = sender.isOn;
}

- (IBAction)onToggleMicSwitch:(UISwitch *)sender {
    self.joinLiveDemo.enableMic = sender.isOn;
}

- (void)userLiveContainerViewTap:(UITapGestureRecognizer *)tapGR {
    if (![tapGR.view isEqual:self.userLiveContainerView]) {
        return;
    }
    UIView *liveContainerView = tapGR.view;
    CGPoint gLocation = [tapGR locationInView:liveContainerView];
    
    // 处理手势识别，
    // 计算出所点击的点是否落在某个小图上，如果存在，则将小图设置为大图显示
    ZGJoinLiveUserRenderViewRelation *originMainShowItem = [self getMainShowRelationItem];
    __block ZGJoinLiveUserRenderViewRelation *destMainShowItem = nil;
    [self.userRenderViewRelationList enumerateObjectsUsingBlock:^(ZGJoinLiveUserRenderViewRelation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.renderView != nil && !obj.mainShow) {
            if (CGRectContainsPoint(obj.renderView.frame, gLocation)) {
                destMainShowItem = obj;
                *stop = YES;
            }
        }
    }];
    
    if (originMainShowItem != nil && destMainShowItem != nil && originMainShowItem != destMainShowItem) {
        destMainShowItem.mainShow = YES;
        originMainShowItem.mainShow = NO;
        
        // 调换两者的位置
        NSInteger orignItemIdx = [self.userRenderViewRelationList indexOfObject:originMainShowItem];
        NSInteger destItemIdx = [self.userRenderViewRelationList indexOfObject:destMainShowItem];
        [self.userRenderViewRelationList replaceObjectAtIndex:orignItemIdx withObject:destMainShowItem];
        [self.userRenderViewRelationList replaceObjectAtIndex:destItemIdx withObject:originMainShowItem];
        
        [self rearrangeLiveRenderViews];
    }
}

#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStylePlain target:self action:@selector(closePage:)];
    self.navigationItem.title = self.userRole == ZEGO_ANCHOR ? @"主播":@"观众";
    
    self.cameraSwitch.on = self.joinLiveDemo.enableCamera;
    self.micSwitch.on = self.joinLiveDemo.enableMic;
    
    // 给 userLiveContainerView 添加手势处理，以实现大小直播视图切换
    self.userLiveContainerView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userLiveContainerViewTap:)];
    [self.userLiveContainerView addGestureRecognizer:tapGR];
}

- (void)joinVideoLiveRoom {
    BOOL isAnchor = self.userRole == ZEGO_ANCHOR;
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    [self.joinLiveDemo setAudienceCreateRoomEnabled:self.audienceCreateRoomEnabled];
    BOOL result = [self.joinLiveDemo joinLiveRoom:self.roomID userID:self.currentUserID isAnchor:isAnchor callback:^(int errorCode, NSArray<NSString *> *joinTalkUserIDs) {
        [ZegoHudManager hideNetworkLoading];
        Strongify(self);
        if (errorCode != 0) {
            [ZegoHudManager showMessage:[NSString stringWithFormat:@"加入房间失败。errorCode:%d", errorCode]];
            return;
        }
        
        // 房间创建者，在进入房间后，直接开启直播
        if (isAnchor) {
            [self addLocalUserLiveRenderViewRelation];
            [self.joinLiveDemo startLocalUserLive];
        }
        
        // 刷新数据源
        if (joinTalkUserIDs.count > 0) {
            [self addRemoteUserLivesIfNeed:joinTalkUserIDs];
        }
    }];
    if (!result) {
        [ZegoHudManager hideNetworkLoading];
        [ZegoHudManager showMessage:@"加入房间失败，请查看日志"];
    }
}

- (void)addLocalUserLiveRenderViewRelation {
    ZGJoinLiveUserRenderViewRelation *relation = [ZGJoinLiveUserRenderViewRelation new];
    relation.isLocalUser = YES;
    relation.userID = self.currentUserID;
    relation.mainShow = self.userRole == ZEGO_ANCHOR;
    
    UIView *renderView = [UIView new];
    relation.renderView = renderView;
    [self.userLiveContainerView addSubview:renderView];
    
    [self.userRenderViewRelationList addObject:relation];
    
    [self configureMainShowLiveItemIfNeed];
    [self rearrangeLiveRenderViews];
}

- (void)removeLocalUserLiveRenderViewRelation {
    ZGJoinLiveUserRenderViewRelation *rmItem = [self getLocalUserLiveRenderViewRelation];
    if (rmItem) {
        [self.userRenderViewRelationList removeObject:rmItem];
        [rmItem.renderView removeFromSuperview];
        
        [self configureMainShowLiveItemIfNeed];
        [self rearrangeLiveRenderViews];
    }
}

- (ZGJoinLiveUserRenderViewRelation *)getLocalUserLiveRenderViewRelation {
    __block ZGJoinLiveUserRenderViewRelation *localItem = nil;
    [self.userRenderViewRelationList enumerateObjectsUsingBlock:^(ZGJoinLiveUserRenderViewRelation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isLocalUser) {
            localItem = obj;
            *stop = YES;
        }
    }];
    return localItem;
}

- (ZGJoinLiveUserRenderViewRelation *)getUserLiveRenderViewRelationWithUserID:(NSString *)userID {
    __block ZGJoinLiveUserRenderViewRelation *tarItem = nil;
    [self.userRenderViewRelationList enumerateObjectsUsingBlock:^(ZGJoinLiveUserRenderViewRelation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userID isEqualToString:userID]) {
            tarItem = obj;
            *stop = YES;
        }
    }];
    return tarItem;
}

- (void)closePage:(id)sender {
    [self exitRoomWithRequestLeave:YES];
}

- (void)removeAllLives {
    // stop remote users live
    NSArray<NSString *> *userIDs = [[self.userRenderViewRelationList copy] valueForKeyPath:@"userID"];
    [self removeRemoteUserLives:userIDs];
    
    // stop local user live
    [self removeLocalUserLiveRenderViewRelation];
    [self.joinLiveDemo stopLocalUserLive];
}

- (void)exitRoomWithRequestLeave:(BOOL)requestLeave {
    [self removeAllLives];
    [self.joinLiveDemo setDataSource:nil];
    [self.joinLiveDemo setDelegate:nil];
    
    if (requestLeave) {
        [self.joinLiveDemo leaveLiveRoom];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleExitRoomWithAlertMessage:(NSString *)alertMessage requestLeaveRoom:(BOOL)requestLeaveRoom{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self exitRoomWithRequestLeave:requestLeaveRoom];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)rearrangeLiveRenderViews {
    CGSize containerViewSize = self.userLiveContainerView.bounds.size;
    
    // 排列大展示视图
    ZGJoinLiveUserRenderViewRelation *mainShowItem = [self getMainShowRelationItem];
    if (mainShowItem) {
        mainShowItem.renderView.frame = CGRectMake(0, 0, containerViewSize.width, containerViewSize.height);
        [mainShowItem.renderView.superview sendSubviewToBack:mainShowItem.renderView];
    }
    
    // 排列小展示视图
    NSInteger columnPerRow = ZGRoomConfigTopicLiveRenderViewDisplayColumnPerRow;
    CGFloat viewSpacing = ZGRoomConfigTopicLiveRenderViewSpacing;
    CGFloat playViewWidth = (containerViewSize.width - (columnPerRow + 1)*viewSpacing) /columnPerRow;
    CGFloat playViewHeight = 1.5f * playViewWidth;
    
    NSInteger i = 0;
    for (ZGJoinLiveUserRenderViewRelation *obj in self.userRenderViewRelationList) {
        if (obj.renderView == nil) {
            continue;
        }
        if ([obj isEqual:mainShowItem]) {
            // 忽略大展示视图
            continue;
        }
        
        NSInteger cloumn = i % columnPerRow;
        NSInteger row = i / columnPerRow;
        
        CGFloat x = viewSpacing + cloumn * (playViewWidth + viewSpacing);
        CGFloat y = viewSpacing + row * (playViewHeight + viewSpacing);
        obj.renderView.frame = CGRectMake(x, y, playViewWidth, playViewHeight);
        i++;
    }
}

- (void)invalidateLiveRenderViewFrames {
    [self rearrangeLiveRenderViews];
}

- (void)addRemoteUserLivesIfNeed:(NSArray<NSString *> *)remoteUserIDs {
    // 添加至列表
    if (remoteUserIDs.count == 0) {
        return;
    }
    
    for (NSString *userID in remoteUserIDs) {
        if ([self getUserLiveRenderViewRelationWithUserID:userID]) {
            continue;
        }
        ZGJoinLiveUserRenderViewRelation *relation = [ZGJoinLiveUserRenderViewRelation new];
        relation.isLocalUser = NO;
        relation.userID = userID;
        
        UIView *renderView = [UIView new];
        relation.renderView = renderView;
        
        [self.userRenderViewRelationList addObject:relation];
        [self.userLiveContainerView addSubview:renderView];
        
        [self.joinLiveDemo playRemoteUserLive:relation.userID];
    }
    
    [self configureMainShowLiveItemIfNeed];
    [self rearrangeLiveRenderViews];
}

- (void)removeRemoteUserLives:(NSArray<NSString *> *)remoteUserIDs {
    if (remoteUserIDs.count == 0) {
        return;
    }
    
    BOOL hasRemovedItems = NO;
    for (NSString *userID in remoteUserIDs) {
        // 查询是否存在目标
        __block ZGJoinLiveUserRenderViewRelation *rmRelation = nil;
        [self.userRenderViewRelationList enumerateObjectsUsingBlock:^(ZGJoinLiveUserRenderViewRelation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.isLocalUser && [obj.userID isEqualToString:userID]) {
                rmRelation = obj;
                *stop = YES;
            }
        }];
        
        // 若存在，删除视图
        if (rmRelation != nil) {
            [self.userRenderViewRelationList removeObject:rmRelation];
            [rmRelation.renderView removeFromSuperview];
            hasRemovedItems = YES;
        }
        
        // 停止播放直播
        [self.joinLiveDemo stopRemoteUserLive:rmRelation.userID];
    }
    
    if (hasRemovedItems) {
        [self configureMainShowLiveItemIfNeed];
        [self rearrangeLiveRenderViews];
    }
}

- (ZGJoinLiveUserRenderViewRelation *)getMainShowRelationItem {
    __block ZGJoinLiveUserRenderViewRelation *mainShowItem = nil;
    [self.userRenderViewRelationList enumerateObjectsUsingBlock:^(ZGJoinLiveUserRenderViewRelation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.mainShow) {
            mainShowItem = obj;
            *stop = YES;
        }
    }];
    return mainShowItem;
}

- (void)configureMainShowLiveItemIfNeed {
    ZGJoinLiveUserRenderViewRelation *mainShowItem = [self getMainShowRelationItem];
    if (!mainShowItem) {
        // 如果不存在 main show，则设置主播的live视图 main show
        __block ZGJoinLiveUserRenderViewRelation *anchorItem = nil;
        [self.userRenderViewRelationList enumerateObjectsUsingBlock:^(ZGJoinLiveUserRenderViewRelation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.userID isEqualToString:self.currentUserID] && self.userRole == ZEGO_ANCHOR) {
                anchorItem = obj;
                *stop = YES;
            }
        }];
        if (anchorItem) {
            anchorItem.mainShow = YES;
        }
    }
}

#pragma mark - JoinLiveDemoDataSource

- (NSString *)localUserLiveStreamID:(ZGJoinLiveDemo *)demo {
    return self.localLiveStreamID;
}

- (UIView *)localUserLivePreviewView:(ZGJoinLiveDemo *)demo {
    ZGJoinLiveUserRenderViewRelation *localItem = [self getLocalUserLiveRenderViewRelation];
    return localItem.renderView;
}

- (UIView *)demo:(ZGJoinLiveDemo *)demo livePlayViewForRemoteUser:(NSString *)remoteUserID {
    __block ZGJoinLiveUserRenderViewRelation *existRelation = nil;
    [self.userRenderViewRelationList enumerateObjectsUsingBlock:^(ZGJoinLiveUserRenderViewRelation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.isLocalUser && [obj.userID isEqualToString:remoteUserID]) {
            existRelation = obj;
            *stop = YES;
        }
    }];
    return existRelation.renderView;
}

#pragma mark - JoinLiveDemoDelegate

- (void)demo:(ZGJoinLiveDemo *)demo kickOutRoom:(NSString *)roomID {
    [self handleExitRoomWithAlertMessage:@"被踢出房间，或者相同 userID 在别出登录" requestLeaveRoom:NO];
}

- (void)demo:(ZGJoinLiveDemo *)demo disConnectRoom:(NSString *)roomID {
    [self handleExitRoomWithAlertMessage:@"您已断开和房间的连接" requestLeaveRoom:NO];
}

- (void)demo:(ZGJoinLiveDemo *)demo localUserOnLiveUpdated:(BOOL)onLive {
    NSLog(@"本地用户是否在直播。onLive: %@", @(onLive));
}

- (void)demo:(ZGJoinLiveDemo *)demo remoteUserOnLiveUpdated:(BOOL)onLive withUserIDs:(NSArray<NSString*> *)remoteUserIDs {
    if (onLive) {
        [self addRemoteUserLivesIfNeed:remoteUserIDs];
    }
    else {
        [self removeRemoteUserLives:remoteUserIDs];
    }
}

- (void)demo:(ZGJoinLiveDemo *)demo remoteUserLivePlayStateUpdate:(int)stateCode
  withUserID:(NSString *)userID {
    // 远端用户的直播播放状态回调，业务根据需要自行处理
}

- (void)demo:(ZGJoinLiveDemo *)demo remoteUserJoinLiveRoom:(NSArray<NSString *> *)userIDs {
    // 远端用户加入到房间的回调，业务根据需要自行处理
}

- (void)demo:(ZGJoinLiveDemo *)demo remoteUserLeaveLiveRoom:(NSArray<NSString *> *)userIDs {
    // 远端用户离开房间的回调
}

@end
#endif
