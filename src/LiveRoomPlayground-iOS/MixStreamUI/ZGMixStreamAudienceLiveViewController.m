//
//  ZGMixStreamAudienceLiveViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_MixStream

#import "ZGMixStreamAudienceLiveViewController.h"
#import "ZGMixStreamTopicLiveViewLayout.h"
#import "ZGMixStreamDemo.h"
#import "ZGMixStreamTopicConstants.h"
#import "ZGJsonHelper.h"
#import "ZGMixStreamTopicHelper.h"
#import "ZGMixStreamTopicMixStreamFlags.h"
#import "ZGMixStreamInfoView.h"
#import "Masonry.h"
#import <ZegoLiveRoom/zego-api-mix-stream-oc.h>

@interface ZGMixStreamAudienceLiveViewController () <ZGMixStreamDemoDataSource, ZGMixStreamDemoDelegate, ZegoLiveSoundLevelInMixedStreamDelegate>

@property (nonatomic, weak) IBOutlet UISwitch *cameraSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *micSwitch;

// 用户视频容器视图，用户的视频视图需要添加在该容器视图中
@property (nonatomic, weak) IBOutlet UIView *userLiveContainerView;
// 连麦按钮
@property (nonatomic, weak) IBOutlet UIButton *joinLiveButn;

@property (nonatomic) ZGMixStreamInfoView *mixStreamInfoView;


@property (nonatomic) NSMutableArray<ZGMixStreamTopicLiveViewLayout*> *liveViewLayoutList;
@property (nonatomic) NSMutableDictionary<NSString*, UIView*> *streamIDKeyedLiveViews;
@property (nonatomic) NSMutableDictionary<NSString*, NSString*> *userIDKeyedStreamIDsWhenPlayMixStream;

@property (nonatomic, copy) NSString *localLiveStreamID;

// 主播的推流
@property (nonatomic) ZegoStream *anchorStream;
// 主播发起的混流标志信息
@property (nonatomic) ZGMixStreamTopicMixStreamFlags *anchorMixStreamFlags;
// 是否正在播放混流
@property (nonatomic, assign) BOOL isPlayingAnchorMixStream;
@property (nonatomic) ZegoStreamMixer *zgStreamMixer;

@property (nonatomic, assign) NSInteger viewAppearNum;

@end

@implementation ZGMixStreamAudienceLiveViewController

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MixStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMixStreamAudienceLiveViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.liveViewLayoutList = [NSMutableArray array];
    self.streamIDKeyedLiveViews = [NSMutableDictionary dictionary];
    self.userIDKeyedStreamIDsWhenPlayMixStream = [NSMutableDictionary dictionary];

    self.mixStreamDemo.dataSource = self;
    self.mixStreamDemo.delegate = self;
    
    
    // 初始化 localLiveStreamID
    self.localLiveStreamID = [NSString stringWithFormat:@"s-%@", self.mixStreamDemo.localUserID];
    
    [self setupUI];

    // 处理初始存在的远端用户直播
    [self handleInitialExistRemoteUserLives];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewAppearNum ++;
    if (self.viewAppearNum == 1) {
        // 调整视频视图 frame，在 viewDidAppear 后才是真正的 View Size
        // 在第一次调用 viewDidAppear 时处理即可
        [self rearrangeLiveViewsLayoutInfo];
        [self layoutLiveViews];
    }
}

- (IBAction)onToggleCameraSwitch:(UISwitch *)sender {
    self.mixStreamDemo.enableCamera = sender.isOn;
}

- (IBAction)onToggleMicSwitch:(UISwitch *)sender {
    self.mixStreamDemo.enableMic = sender.isOn;
}

- (IBAction)joinLiveButnOnClick:(id)sender {
    
    if (self.mixStreamDemo.localOnLive) {
        // 停止本地直播
        [self.mixStreamDemo stopLocalUserLive];
        
        NSString *localStreamID = self.localLiveStreamID;
        [self removeLiveViewLayout:localStreamID];
        [self removeLiveView:localStreamID];
        
        [self configureMainShowLayoutItemIfNeed];
        [self rearrangeLiveViewsLayoutInfo];
        [self layoutLiveViews];
    }
    else {
        // 停止混流播放
        // 添加layout，view 等信息
        ZGMixStreamTopicMixStreamFlags *mixStreamFlags = self.anchorMixStreamFlags;
        if (mixStreamFlags) {
            [self removeLiveViewLayout:mixStreamFlags.mixStreamID];
            [self removeLiveView:mixStreamFlags.mixStreamID];
            [self stopPlayAnchorMixStream];
        }
        
        // 本地开始直播
        NSString *localStreamID = self.localLiveStreamID;
        [self addLiveViewLayout:localStreamID];
        [self addLiveView:localStreamID];
        [self.mixStreamDemo startLocalUserLive];
        
        // 播放缓存的直播列表,开始单流播放
        NSArray<ZegoStream *> *liveStreams = [self.mixStreamDemo remoteUserLiveStreams];
        if (liveStreams.count > 0) {
            for (ZegoStream *rStream in liveStreams) {
                NSString *rStreamID = rStream.streamID;
                if (![self existLiveViewLayoutItemWithStreamID:rStreamID]) {
                    [self addLiveViewLayout:rStreamID];
                    [self addLiveView:rStreamID];
                    [self.mixStreamDemo playRemoteUserLiveWithStreamID:rStreamID];
                }
            }
        }
        
        // 设置 main show item
        [self configureMainShowLayoutItemIfNeed];
        
        // 更想布局
        [self rearrangeLiveViewsLayoutInfo];
        [self layoutLiveViews];
    }
}

#pragma mark - private methods

- (void)handleInitialExistRemoteUserLives {
    // 添加已存在的远端用户直播到UI
    NSArray<ZegoStream *> *remoteUserStreams = self.mixStreamDemo.remoteUserLiveStreams;
    
    // 获取发起混流的流
    ZGMixStreamTopicMixStreamFlags *mixStreamFlags = nil;
    self.anchorStream = [self parseMixStreamFlagStream:remoteUserStreams withUserID:self.roomAnchorID mixStreamflags:&mixStreamFlags];
    self.anchorMixStreamFlags = mixStreamFlags;
    
    if (mixStreamFlags == nil) {
        // 不存在混流
        Weakify(self);
        [ZegoHudManager showMessage:@"不存在混流，请检查代码是否正确！" done:^{
            Strongify(self);
            [self exitRoomWithRequestLeave:YES];
        }];
        return;
    }
    
    // 添加混流项的 layout，view 等信息
    ZGMixStreamTopicLiveViewLayout *mixStreamLiveItem = [self addLiveViewLayout:mixStreamFlags.mixStreamID];
    mixStreamLiveItem.mainShow = YES;
    [self addLiveView:mixStreamFlags.mixStreamID];
    [self rearrangeLiveViewsLayoutInfo];
    [self layoutLiveViews];
    
    // 设置 userKeyedStreamIDs，用以后续 sound level 更新时，通过映射快速查询 streamID
    for (ZegoStream *stream in remoteUserStreams) {
        self.userIDKeyedStreamIDsWhenPlayMixStream[stream.userID] = stream.streamID;
    }
    
    [self startPlayAnchorMixStream];
}

- (void)setupUI {
    self.navigationItem.title = @"观众";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStylePlain target:self action:@selector(closePage:)];
    
    self.cameraSwitch.on = self.mixStreamDemo.enableCamera;
    self.micSwitch.on = self.mixStreamDemo.enableMic;
    
    
    self.mixStreamInfoView = [ZGMixStreamInfoView viewFromNib];
    self.mixStreamInfoView.backgroundColor = [UIColor clearColor];
    self.mixStreamInfoView.mixStreamInfoLabel.textColor = [UIColor whiteColor];
    self.mixStreamInfoView.anchorSoundLevelInfoLabel.textColor = [UIColor whiteColor];
    self.mixStreamInfoView.audienceSoundLevelInfoLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.mixStreamInfoView];
    [self.mixStreamInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_topLayoutGuide).offset(0);
        make.leading.trailing.offset(0);
    }];
    self.mixStreamInfoView.hidden = YES;
    
    [self invalidateJoinLiveButnUI];
}

- (void)invalidateJoinLiveButnUI {
    BOOL localOnLive = self.mixStreamDemo.localOnLive;
    [self.joinLiveButn setTitle:localOnLive?@"结束连麦":@"视频连麦" forState:UIControlStateNormal];
}

- (void)startPlayAnchorMixStream {
    // 播放混流
    NSString *mixStreamID = self.anchorMixStreamFlags.mixStreamID;
    if (mixStreamID) {
        self.isPlayingAnchorMixStream = YES;
        self.mixStreamInfoView.hidden = NO;
        self.mixStreamInfoView.mixStreamInfoLabel.text = [NSString stringWithFormat:@"混流ID：%@", mixStreamID];
        
        // 设置 zgStreamMixer， 接收混流的音浪信息
        if (!self.zgStreamMixer) {
            self.zgStreamMixer = [[ZegoStreamMixer alloc] init];
            [self.zgStreamMixer setSoundLevelInMixedStreamDelegate:self];
        }
        
        [self.mixStreamDemo playRemoteUserLiveWithStreamID:mixStreamID];
    }
}

- (void)stopPlayAnchorMixStream {
    NSString *mixStreamID = self.anchorMixStreamFlags.mixStreamID;
    if (mixStreamID) {
        self.isPlayingAnchorMixStream = NO;
        self.mixStreamInfoView.hidden = YES;
        
        [self.zgStreamMixer setSoundLevelInMixedStreamDelegate:nil];
        
        [self.mixStreamDemo stopRemoteUserLiveWithStreamID:mixStreamID];
    }
}

- (void)closePage:(id)sender {
    [self stopPlayAnchorMixStream];
    [self.mixStreamDemo stopLocalUserLive];
    [self exitRoomWithRequestLeave:YES];
}

- (ZGMixStreamTopicLiveViewLayout *)addLiveViewLayout:(NSString *)streamID {
    ZGMixStreamTopicLiveViewLayout *viewLayout = [ZGMixStreamTopicLiveViewLayout new];
    viewLayout.streamID = streamID;
    [self.liveViewLayoutList addObject:viewLayout];
    return viewLayout;
}

- (ZGMixStreamTopicLiveViewLayout *)removeLiveViewLayout:(NSString *)streamID {
    __block ZGMixStreamTopicLiveViewLayout *existItem = nil;
    [self.liveViewLayoutList enumerateObjectsUsingBlock:^(ZGMixStreamTopicLiveViewLayout * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.streamID isEqualToString:streamID]) {
            existItem = obj;
            *stop = YES;
        }
    }];
    if (existItem) {
        [self.liveViewLayoutList removeObject:existItem];
    }
    return existItem;
}

- (UIView *)addLiveView:(NSString *)streamID {
    UIView *liveView = [UIView new];
    [self.userLiveContainerView addSubview:liveView];
    self.streamIDKeyedLiveViews[streamID] = liveView;
    return liveView;
}

- (UIView *)removeLiveView:(NSString *)streamID {
    UIView *liveView = self.streamIDKeyedLiveViews[streamID];
    if (liveView) {
        [liveView removeFromSuperview];
        [self.streamIDKeyedLiveViews removeObjectForKey:streamID];
    }
    return liveView;
}

- (NSArray<ZGMixStreamTopicLiveViewLayout*> *)getLiveViewLayoutWithFilter:(BOOL(^)(ZGMixStreamTopicLiveViewLayout *obj, BOOL *stop))filter {
    NSMutableArray<ZGMixStreamTopicLiveViewLayout *> *results = [NSMutableArray array];
    [self.liveViewLayoutList enumerateObjectsUsingBlock:^(ZGMixStreamTopicLiveViewLayout * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (filter) {
            BOOL res = filter(obj, stop);
            if (res) {
                [results addObject:obj];
            }
        }
    }];
    return [results copy];
}

- (ZGMixStreamTopicLiveViewLayout *)getMainShowLiveViewLayoutItem {
    return [self getLiveViewLayoutWithFilter:^BOOL(ZGMixStreamTopicLiveViewLayout *obj, BOOL *stop) {
        if (obj.mainShow) {
            *stop = YES;
            return YES;
        }
        return NO;
    }].firstObject;
}

- (ZGMixStreamTopicLiveViewLayout *)existLiveViewLayoutItemWithStreamID:(NSString *)streamID {
    return [self getLiveViewLayoutWithFilter:^BOOL(ZGMixStreamTopicLiveViewLayout *obj, BOOL *stop) {
        if ([obj.streamID isEqualToString:streamID]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }].firstObject;
}

/**
 重排直播视图的布局信息
 */
- (void)rearrangeLiveViewsLayoutInfo {
    CGSize containerViewSize = self.userLiveContainerView.bounds.size;
    
    // 布局大图
    ZGMixStreamTopicLiveViewLayout *mainShowItem = [self getMainShowLiveViewLayoutItem];
    if (mainShowItem) {
        mainShowItem.left = 0;
        mainShowItem.top = 0;
        mainShowItem.width = containerViewSize.width;
        mainShowItem.height = containerViewSize.height;
        
        // 插入到第一个，排列在最底部
        [self.liveViewLayoutList removeObject:mainShowItem];
        [self.liveViewLayoutList insertObject:mainShowItem atIndex:0];
    }
    
    // 布局小图
    NSInteger columnPerRow = ZGMixStreamTopicLiveViewDisplayColumnPerRow;
    CGFloat viewSpacing = ZGMixStreamTopicLiveViewSpacing;
    CGFloat playViewWidth = (containerViewSize.width - (columnPerRow + 1)*viewSpacing) /columnPerRow;
    CGFloat playViewHeight = playViewWidth;
    
    // 布局小图，前两个位置空开
    NSInteger i = 2;
    for (ZGMixStreamTopicLiveViewLayout *viewLayout in self.liveViewLayoutList) {
        // 遍历忽略 mainShowItem
        if (mainShowItem && [viewLayout isEqual:mainShowItem]) {
            continue;
        }
        
        NSInteger cloumn = i % columnPerRow;
        NSInteger row = i / columnPerRow;
        
        CGFloat x = viewSpacing + cloumn * (playViewWidth + viewSpacing);
        CGFloat y = viewSpacing + row * (playViewHeight + viewSpacing);
        viewLayout.left = x;
        viewLayout.top = y;
        viewLayout.width = playViewWidth;
        viewLayout.height = playViewHeight;
        i++;
    }
}

/**
 对直播视图进行布局
 */
- (void)layoutLiveViews {
    ZGMixStreamTopicLiveViewLayout *mainShowItem = [self getMainShowLiveViewLayoutItem];
    for (ZGMixStreamTopicLiveViewLayout *viewLayout in self.liveViewLayoutList) {
        UIView *liveView = self.streamIDKeyedLiveViews[viewLayout.streamID];
        if (liveView) {
            liveView.frame = CGRectMake(viewLayout.left, viewLayout.top, viewLayout.width, viewLayout.height);
            
            if ([viewLayout isEqual:mainShowItem]) {
                [liveView.superview sendSubviewToBack:liveView];
            }
        }
    }
}

- (void)configureMainShowLayoutItemIfNeed {
    ZGMixStreamTopicLiveViewLayout *mainShowItem = [self getLiveViewLayoutWithFilter:^BOOL(ZGMixStreamTopicLiveViewLayout *obj, BOOL *stop) {
        if (obj.mainShow) {
            *stop = YES;
            return YES;
        }
        return NO;
    }].firstObject;
    
    if (!mainShowItem) {
        // 不存在主图直播，则设置主播直播主图显示
        ZGMixStreamTopicLiveViewLayout *anchorLiveItem =[self getLiveViewLayoutWithFilter:^BOOL(ZGMixStreamTopicLiveViewLayout *obj, BOOL *stop) {
            if ([obj.streamID isEqualToString:self.anchorStream.streamID]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }].firstObject;
        
        if (anchorLiveItem) {
            anchorLiveItem.mainShow = YES;
        }
    }
}

/**
 解析流列表中包含混流发起标志的目标流

 @param streamList 流列表
 @param userID 流的用户 ID
 @param mixStreamflags 用以返回混流标志
 @return 包含混流发起标志的目标流
 */
- (ZegoStream *)parseMixStreamFlagStream:(NSArray<ZegoStream*> *)streamList
                              withUserID:(NSString *)userID
                          mixStreamflags:(ZGMixStreamTopicMixStreamFlags **)mixStreamflags {
    if (streamList.count == 0) {
        return nil;
    }
    
    ZegoStream *tarStream = nil;
    for (ZegoStream *stream in streamList) {
        if (![stream.userID isEqualToString:userID]) {
            continue;
        }
        NSDictionary *dict = [ZGJsonHelper decodeFromJSON:stream.extraInfo];
        if (dict == nil || ![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSString *mixsid = dict[ZGMixStreamTopicStreamExtraInfoKey_MixStreamID];
        BOOL isFirstAnchor = [dict[ZGMixStreamTopicStreamExtraInfoKey_FirstAnchor] boolValue];
        if (mixsid.length != 0 && isFirstAnchor) {
            tarStream = stream;
            *mixStreamflags = [ZGMixStreamTopicMixStreamFlags new];
            (*mixStreamflags).mixStreamID = mixsid;
            (*mixStreamflags).isFirstAnchor = [dict[ZGMixStreamTopicStreamExtraInfoKey_FirstAnchor] boolValue];
            (*mixStreamflags).hls = dict[ZGMixStreamTopicStreamExtraInfoKey_Hls];
            (*mixStreamflags).rtmp = dict[ZGMixStreamTopicStreamExtraInfoKey_Rtmp];
            break;
        }
    }
    return tarStream;
}

- (void)exitRoomWithRequestLeave:(BOOL)requestLeave {
    [self.mixStreamDemo setDataSource:nil];
    [self.mixStreamDemo setDelegate:nil];
    
    if (requestLeave) {
        [self.mixStreamDemo leaveLiveRoom];
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

#pragma mark - ZGMixStreamDemoDataSource

- (NSString *)localUserLiveStreamID:(ZGMixStreamDemo *)demo {
    return self.localLiveStreamID;
}

- (UIView *)localUserLivePreviewView:(ZGMixStreamDemo *)demo {
    return self.streamIDKeyedLiveViews[self.localLiveStreamID];
}

- (UIView *)demo:(ZGMixStreamDemo *)demo livePlayViewForRemoteUserWithStreamID:(NSString *)userLiveStreamID {
    return self.streamIDKeyedLiveViews[userLiveStreamID];
}

#pragma mark - ZGMixStreamDemoDelegate

- (void)demo:(ZGMixStreamDemo *)demo kickOutRoom:(NSString *)roomID {
    [self handleExitRoomWithAlertMessage:@"被踢出房间，或者相同 userID 在别出登录" requestLeaveRoom:NO];
}

- (void)demo:(ZGMixStreamDemo *)demo disConnectRoom:(NSString *)roomID {
    [self handleExitRoomWithAlertMessage:@"您已断开和房间的连接" requestLeaveRoom:NO];
}

- (void)demo:(ZGMixStreamDemo *)demo localUserOnLiveUpdated:(BOOL)onLive {
    [self invalidateJoinLiveButnUI];
}

- (void)demo:(ZGMixStreamDemo *)demo remoteUserOnLiveUpdated:(BOOL)onLive withLiveStreams:(NSArray<ZegoStream*> *)liveStreams {
    if (!self.mixStreamDemo.localOnLive && self.isPlayingAnchorMixStream) {
        // 此时正在播放混流，更新 userIDKeyedStreamIDsWhenPlayMixStream
        for (ZegoStream *rStream in liveStreams) {
            if (onLive) {
                self.userIDKeyedStreamIDsWhenPlayMixStream[rStream.userID] = rStream.streamID;
            }
            else {
                [self.userIDKeyedStreamIDsWhenPlayMixStream removeObjectForKey:rStream.userID];
            }
        }
        return;
    }
    
    // 处理远端用户直播列表更新回调，按照以下步骤进行
    // step1：更新数据源
    for (ZegoStream *rStream in liveStreams) {
        
        NSString *rStreamID = rStream.streamID;
        if (onLive) {
            [self addLiveViewLayout:rStreamID];
            [self addLiveView:rStreamID];
            [self.mixStreamDemo playRemoteUserLiveWithStreamID:rStreamID];
        }
        else {
            [self removeLiveViewLayout:rStreamID];
            [self removeLiveView:rStreamID];
            [self.mixStreamDemo stopRemoteUserLiveWithStreamID:rStreamID];
        }
    }
    [self rearrangeLiveViewsLayoutInfo];
    
    // step2：更新界面布局
    [self layoutLiveViews];
}

- (void)demo:(ZGMixStreamDemo *)demo remoteUserLivePlayStateUpdate:(int)stateCode
  withLiveStreamID:(NSString *)liveStreamID {
    
}

- (void)demo:(ZGMixStreamDemo *)demo remoteUserJoinLiveRoom:(NSArray<NSString *> *)userIDs {
    // 远端用户加入到房间的回调，业务根据需要自行处理
}

- (void)demo:(ZGMixStreamDemo *)demo remoteUserLeaveLiveRoom:(NSArray<NSString *> *)userIDs {
    // 远端用户离开房间的回调
    // 若主播（房间创建者）退出，则弹窗提示并退出
    if ([userIDs containsObject:self.roomAnchorID]) {
        [self handleExitRoomWithAlertMessage:@"主播（房间创建者）已退出直播" requestLeaveRoom:YES];
    }
}

#pragma mark - ZegoLiveSoundLevelInMixedStreamDelegate <NSObject>

/**
 混流中的发言者及其说话音量信息的回调
 @param soundLevelList 混流中各单流的音量信息列表
 @note: 此接口是高频率同步回调，每秒钟10次通知，不拉流没有通知；请勿在该回调中处理耗时任务。
 */
- (void)onSoundLevelInMixedStream:(NSArray<ZegoSoundLevelInMixedStreamInfo *> *)soundLevelList {
    if (soundLevelList == nil) {
        return;
    }
    if (!self.isPlayingAnchorMixStream) {
        return;
    }
    
    for (ZegoSoundLevelInMixedStreamInfo *soundLevelInfo in soundLevelList) {
        // 查找关联的 streamID
        unsigned int timeStamp = soundLevelInfo.soundLevelID;
        NSString *userID = [ZGMixStreamTopicHelper assembleUserIDWithTimestamp:timeStamp];
        NSString *streamID = self.userIDKeyedStreamIDsWhenPlayMixStream[userID];
        if (streamID) {
            // 关联到 view
            if ([streamID isEqualToString:self.anchorStream.streamID]) {
                self.mixStreamInfoView.anchorSoundLevelInfoLabel.text = [NSString stringWithFormat:@"主播音浪（id：%@,值：%@）", @(soundLevelInfo.soundLevelID), @(soundLevelInfo.soundLevel)];
            }
            else {
                self.mixStreamInfoView.audienceSoundLevelInfoLabel.text =[NSString stringWithFormat:@"观众音浪（id：%@,值：%@）", @(soundLevelInfo.soundLevelID), @(soundLevelInfo.soundLevel)];
            }
        }
    }
}

@end

#endif
