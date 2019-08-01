//
//  ZGMixStreamAnchorLiveViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_MixStream

#import "ZGMixStreamAnchorLiveViewController.h"
#import "ZGMixStreamTopicLiveViewLayout.h"
#import "ZGMixStreamDemo.h"
#import "ZGMixStreamTopicConstants.h"
#import "ZGJsonHelper.h"
#import "ZGMixStreamTopicHelper.h"
#import "ZGMixStreamConfigViewController.h"
#import "ZGMixStreamTopicConfigManager.h"
#import "ZGMixStreamInfoView.h"
#import "Masonry.h"
#import <ZegoLiveRoom/zego-api-mix-stream-oc.h>

@interface ZGMixStreamAnchorLiveViewController () <ZGMixStreamDemoDataSource, ZGMixStreamDemoDelegate, ZGMixStreamTopicConfigUpdatedHandler>

@property (nonatomic, weak) IBOutlet UISwitch *cameraSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *micSwitch;

// 用户视频容器视图，用户的视频视图需要添加在该容器视图中
@property (nonatomic, weak) IBOutlet UIView *userLiveContainerView;
@property (nonatomic) ZGMixStreamInfoView *mixStreamInfoView;

@property (nonatomic) NSMutableArray<ZGMixStreamTopicLiveViewLayout*> *liveViewLayoutList;
@property (nonatomic) NSMutableDictionary<NSString*, UIView*> *streamIDKeyedLiveViews;
@property (nonatomic) NSMutableDictionary<NSString*, NSString*> *userIDKeyedStreamIDs;
@property (nonatomic) NSMutableDictionary<NSString*, NSNumber*> *streamIDKeyedMixStreamInputSoundLevelIDs;

@property (nonatomic, assign) NSInteger viewAppearNum;

@end

@implementation ZGMixStreamAnchorLiveViewController

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MixStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMixStreamAnchorLiveViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.liveViewLayoutList = [NSMutableArray array];
    self.streamIDKeyedLiveViews = [NSMutableDictionary dictionary];
    self.userIDKeyedStreamIDs = [NSMutableDictionary dictionary];
    self.streamIDKeyedMixStreamInputSoundLevelIDs = [NSMutableDictionary dictionary];
    
    [[ZGMixStreamTopicConfigManager sharedInstance] addConfigUpdatedHandler:self];
    
    self.mixStreamDemo.dataSource = self;
    self.mixStreamDemo.delegate = self;
    
    // 在进入房间时，直接开启直播
    NSString *localUserID = self.mixStreamDemo.localUserID;
    NSString *localStreamID = self.liveStreamID;
    
    self.userIDKeyedStreamIDs[localUserID] = localStreamID;
    [self addMixStreamInputSoundLevelIDWithUserID:self.mixStreamDemo.localUserID forStreamID:localStreamID];
    ZGMixStreamTopicLiveViewLayout *layoutItem = [self addLiveViewLayout:localStreamID];
    layoutItem.mainShow = YES;
    [self addLiveView:localStreamID];
    [self rearrangeLiveViewsLayoutInfo];
    [self layoutLiveViews];
    [self.mixStreamDemo startLocalUserLive];
    
    // 添加已存在的远端用户直播到UI
    NSArray<ZegoStream *> *remoteLiveStreams = self.mixStreamDemo.remoteUserLiveStreams;
    if (remoteLiveStreams.count > 0) {
        for (ZegoStream *rStream in remoteLiveStreams) {
            NSString *rStreamID = rStream.streamID;
            
            self.userIDKeyedStreamIDs[rStream.userID] = rStreamID;
            [self addMixStreamInputSoundLevelIDWithUserID:rStream.userID forStreamID:rStreamID];
            [self addLiveViewLayout:rStreamID];
            [self addLiveView:rStreamID];
            [self.mixStreamDemo playRemoteUserLiveWithStreamID:rStreamID];
        }
        [self rearrangeLiveViewsLayoutInfo];
        [self layoutLiveViews];
    }
    
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewAppearNum ++;
    if (self.viewAppearNum == 1) {
        // 调整视频视图 frame，在 viewDidAppear 后才是真正的 View Size
        // 在第一次调用 viewDidAppear 时处理即可
        [self rearrangeLiveViewsLayoutInfo];
        [self layoutLiveViews];
        [self.mixStreamDemo startOrUpdateMixStream];
    }
}

- (IBAction)onToggleCameraSwitch:(UISwitch *)sender {
    self.mixStreamDemo.enableCamera = sender.isOn;
}

- (IBAction)onToggleMicSwitch:(UISwitch *)sender {
    self.mixStreamDemo.enableMic = sender.isOn;
}

#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"主播";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"退出" style:UIBarButtonItemStylePlain target:self action:@selector(closePage:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"混流配置" style:UIBarButtonItemStylePlain target:self action:@selector(gotoMixStreamSettingPage:)];
    
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
}

- (void)closePage:(id)sender {
    [self.mixStreamDemo stopCurrentMixStream];
    [self.mixStreamDemo stopLocalUserLive];
    [self exitRoomWithRequestLeave:YES];
}

- (void)gotoMixStreamSettingPage:(id)sender {
    ZGMixStreamConfigViewController *confVC = [ZGMixStreamConfigViewController instanceFromStoryboard];
    [self.navigationController pushViewController:confVC animated:YES];
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

- (NSNumber *)addMixStreamInputSoundLevelIDWithUserID:(NSString *)userID forStreamID:(NSString *)streamID {
    // 根据 userID 获取时间戳，然后设置为 sound level ID
    BOOL parseErr = NO;
    unsigned int soundLevelID = [ZGMixStreamTopicHelper parseTimestampFromUserID:userID occurError:&parseErr];
    if (!parseErr) {
        NSNumber *soundLevelIDObj = @(soundLevelID);
        [self.streamIDKeyedMixStreamInputSoundLevelIDs setObject:soundLevelIDObj forKey:streamID];
        return soundLevelIDObj;
    } else {
        ZGLogWarn(@"解析出错");
        return nil;
    }
}

- (void)removeMixStreamInputSoundLevelIDForStreamID:(NSString *)streamID {
    [self.streamIDKeyedMixStreamInputSoundLevelIDs removeObjectForKey:streamID];
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
    return self.liveStreamID;
}

- (BOOL)shouldUpdateLocalLiveStreamExtraInfoOnPublishStarted:(ZGMixStreamDemo *)demo streamInfo:(NSDictionary *)streamInfo {
    return YES;
}

- (NSString *)localLiveStreamExtraInfoToUpdateOnPublishStarted:(ZGMixStreamDemo *)demo streamInfo:(NSDictionary *)streamInfo {
    
    // 将混流信息封装在推流的 extraInfo 中，其他用户通过解析 ZegoStream 的 extraInfo 可以获得混流 ID，然后进行播放
    NSString *sharedHls = [streamInfo[kZegoHlsUrlListKey] firstObject];
    NSString *sharedRtmp = [streamInfo[kZegoRtmpUrlListKey] firstObject];
    NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
    extraInfo[ZGMixStreamTopicStreamExtraInfoKey_FirstAnchor] = @(YES);
    extraInfo[ZGMixStreamTopicStreamExtraInfoKey_MixStreamID] = self.mixStreamID;
    if (sharedHls) {
        extraInfo[ZGMixStreamTopicStreamExtraInfoKey_Hls] = sharedHls;
    }
    if (sharedRtmp) {
        extraInfo[ZGMixStreamTopicStreamExtraInfoKey_Rtmp] = sharedRtmp;
    }
    
    NSString *exStr = [ZGJsonHelper encodeToJSON:extraInfo];
    return exStr;
}

- (UIView *)localUserLivePreviewView:(ZGMixStreamDemo *)demo {
    return self.streamIDKeyedLiveViews[self.liveStreamID];
}

- (UIView *)demo:(ZGMixStreamDemo *)demo livePlayViewForRemoteUserWithStreamID:(nonnull NSString *)userLiveStreamID {
    return self.streamIDKeyedLiveViews[userLiveStreamID];
}

- (NSString *)liveMixStreamID:(ZGMixStreamDemo *)demo {
    return self.mixStreamID;
}

- (ZegoMixStreamConfig *)demo:(ZGMixStreamDemo *)demo liveMixStreamConfigForMixStream:(NSString *)mixStreamID {
    if (![mixStreamID isEqualToString:self.mixStreamID]) {
        return nil;
    }
    
    // 构造布局信息
    NSMutableArray<ZegoMixStreamInput *> *inputStreams = [NSMutableArray<ZegoMixStreamInput*> array];
    for (ZGMixStreamTopicLiveViewLayout *item in self.liveViewLayoutList) {
        ZegoMixStreamInput *msi = [ZegoMixStreamInput new];
        msi.streamID = item.streamID;
        msi.left = item.left;
        msi.top = item.top;
        msi.right = msi.left + item.width;
        msi.bottom = msi.top + item.height;
        
        // 设置 soundLevelID
        NSNumber *levelID = self.streamIDKeyedMixStreamInputSoundLevelIDs[item.streamID];
        if (levelID) {
            msi.soundLevelID = [levelID unsignedIntValue];
        }
        
        [inputStreams addObject:msi];
    }
    
    // 根据界面的混流配置填充以下参数
    ZGMixStreamTopicConfig *myConfig = [[ZGMixStreamTopicConfigManager sharedInstance] loadConfig];
    if (myConfig == nil) {
        myConfig = [ZGMixStreamTopicConfig configWithDefault];
    }
    
    ZegoMixStreamConfig *mixConfig = [[ZegoMixStreamConfig alloc] init];
    mixConfig.outputFps = (int)myConfig.outputFps;
    mixConfig.outputBitrate = (int)myConfig.outputBitrate;
    mixConfig.outputBackgroundColor = 0xc8c8c800;
    mixConfig.outputResolution = CGSizeMake(myConfig.outputResolutionWidth, myConfig.outputResolutionHeight);
    mixConfig.channels = (int)myConfig.channels;
    mixConfig.withSoundLevel = myConfig.withSoundLevel;
    
    mixConfig.inputStreamList = inputStreams;
    
    ZegoMixStreamOutput *o1 = [ZegoMixStreamOutput new];
    o1.isUrl = NO;
    o1.target = self.mixStreamID;
    mixConfig.outputList = [NSMutableArray arrayWithObject:o1];
    
    return mixConfig;
}

#pragma mark - ZGMixStreamDemoDelegate

- (void)demo:(ZGMixStreamDemo *)demo kickOutRoom:(NSString *)roomID {
    [self handleExitRoomWithAlertMessage:@"被踢出房间，或者相同 userID 在别出登录" requestLeaveRoom:NO];
}

- (void)demo:(ZGMixStreamDemo *)demo disConnectRoom:(NSString *)roomID {
    [self handleExitRoomWithAlertMessage:@"您已断开和房间的连接" requestLeaveRoom:NO];
}

- (void)demo:(ZGMixStreamDemo *)demo localUserOnLiveUpdated:(BOOL)onLive {
    if (onLive) {
        // 主播开启直播后，开始混流
        [self.mixStreamDemo startOrUpdateMixStream];
    }
}

- (void)demo:(ZGMixStreamDemo *)demo remoteUserOnLiveUpdated:(BOOL)onLive withLiveStreams:(nonnull NSArray<ZegoStream *> *)liveStreams {
    
    // 处理远端用户直播列表更新回调，按照以下步骤进行
    
    // step1：更新数据源
    for (ZegoStream *rStream in liveStreams) {
        NSString *rStreamID = rStream.streamID;
        if (onLive) {
            self.userIDKeyedStreamIDs[rStream.userID] = rStreamID;
            [self addMixStreamInputSoundLevelIDWithUserID:rStream.userID forStreamID:rStreamID];
            [self addLiveViewLayout:rStreamID];
            [self addLiveView:rStreamID];
            [self.mixStreamDemo playRemoteUserLiveWithStreamID:rStreamID];
        }
        else {
            [self.userIDKeyedStreamIDs removeObjectForKey:rStream.userID];
            [self removeMixStreamInputSoundLevelIDForStreamID:rStreamID];
            [self removeLiveViewLayout:rStreamID];
            [self removeLiveView:rStreamID];
            [self.mixStreamDemo stopRemoteUserLiveWithStreamID:rStreamID];
        }
    }
    [self rearrangeLiveViewsLayoutInfo];
    
    // step2：更新界面布局
    [self layoutLiveViews];
    
    // step3：数据源准备好后，更新混流
    [self.mixStreamDemo startOrUpdateMixStream];
}

- (void)demo:(ZGMixStreamDemo *)demo remoteUserLivePlayStateUpdate:(int)stateCode withLiveStreamID:(nonnull NSString *)liveStreamID {
    
}

- (void)demo:(ZGMixStreamDemo *)demo remoteUserJoinLiveRoom:(NSArray<NSString *> *)userIDs {
    // 远端用户加入到房间的回调，业务根据需要自行处理
}

- (void)demo:(ZGMixStreamDemo *)demo remoteUserLeaveLiveRoom:(NSArray<NSString *> *)userIDs {
    // 远端用户离开房间的回调，业务根据需要自行处理
}

- (void)demo:(ZGMixStreamDemo *)demo onMixStreamUpdated:(BOOL)onMixStream mixStreamID:(NSString *)mixStreamID {
    // 混流状态变化（进行中/停止）
    
    if (![self.mixStreamID isEqualToString:mixStreamID]) {
        return;
    }
    // 混流开启后，显示混流信息，否则隐藏
    self.mixStreamInfoView.hidden = !onMixStream;
    if (onMixStream) {
        self.mixStreamInfoView.mixStreamInfoLabel.text = [NSString stringWithFormat:@"混流ID：%@", mixStreamID];
    } else {
        self.mixStreamInfoView.mixStreamInfoLabel.text = @"混流ID：";
    }
}

#pragma mark - ZGMixStreamTopicConfigUpdatedHandler

- (void)configManager:(ZGMixStreamTopicConfigManager *)configManager mixStreamTopicConfigUpdated:(ZGMixStreamTopicConfig *)updatedConfig {
    [self.mixStreamDemo startOrUpdateMixStream];
}

@end

#endif
