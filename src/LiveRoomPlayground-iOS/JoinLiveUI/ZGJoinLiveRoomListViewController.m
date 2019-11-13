//
//  JoinLiveRoomListViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/11.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_JoinLive

#import "ZGJoinLiveRoomListViewController.h"
#import "ZGJoinLiveCreateRoomViewController.h"
#import "ZGJoinLiveViewController.h"
#import "ZGRoomInfo.h"
#import "ZGRoomHelper.h"
#import "ZGJoinLiveTopicConstants.h"
#import "ZGJoinLiveDemo.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import "ZGUserIDHelper.h"

@interface ZGJoinLiveRoomListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *roomTableView;
@property (nonatomic) UIBarButtonItem *refreshBarButnItem;

@property (nonatomic, copy) NSArray<ZGRoomInfo *> *roomList;
@property (nonatomic, assign) BOOL onRefreshingRoomList;

@property (nonatomic, copy) NSString *zgUserID;
@property (nonatomic, copy) NSString *zgUserName;
@property (nonatomic) ZGJoinLiveDemo *joinLiveDemo;
@property (nonatomic) ZGAppGlobalConfig *appConfig;

@end

@implementation ZGJoinLiveRoomListViewController

- (void)dealloc {
#if DEBUG
    NSLog(@"%@ dealloc.", [self class]);
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    self.appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    
    // 设置该模块的 ZegoLiveRoomApi 默认设置
    [self setupZegoLiveRoomApiDefault:self.appConfig];
    
    // 获取到 userID 和 userName
    self.zgUserID = ZGUserIDHelper.userID;
    self.zgUserName = self.zgUserID;
    
    // 初始化
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    self.joinLiveDemo = [[ZGJoinLiveDemo alloc] initWithAppID:self.appConfig.appID appSign:[ZGAppSignHelper convertAppSignFromString:self.appConfig.appSign] completionBlock:^(ZGJoinLiveDemo * _Nonnull demo, int errorCode) {
        [ZegoHudManager hideNetworkLoading];
        
        // 初始化结果回调，errorCode == 0 表示成功
        NSLog(@"初始化结果, errorCode: %d", errorCode);
        Strongify(self);
        
        if (errorCode == 0) {
            demo.enableMic = YES;
            demo.enableCamera = YES;
            [self refreshRoomList];
        }
        else {
            [ZegoHudManager showMessage:[NSString stringWithFormat:@"初始化失败, errorCode:%d", errorCode] done:^{
                [self.navigationController popViewControllerAnimated:YES];
            }];
        }
    }];
    if (self.joinLiveDemo == nil) {
        [ZegoHudManager hideNetworkLoading];
        [ZegoHudManager showMessage:@"初始化失败，请查看日志"];
    }
}

- (IBAction)createLiveRoom:(id)sender {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"JoinLive" bundle:nil];
    
    ZGJoinLiveCreateRoomViewController *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGJoinLiveCreateRoomViewController class])];
    
    vc.zgUserID = self.zgUserID;
    vc.joinLiveDemo = self.joinLiveDemo;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)gotoJoinLiveTopicLink:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/223.html"]];
}

#pragma mark - private methods

- (void)setupUI {
    self.navigationItem.title = @"直播连麦";
    self.refreshBarButnItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新" style:UIBarButtonItemStylePlain target:self action:@selector(refreshRoomList)];
    self.navigationItem.rightBarButtonItem = self.refreshBarButnItem;
}

- (void)refreshRoomList {
    if (self.onRefreshingRoomList) {
        return;
    }
    
    [self updateOnRefreshingRoomList:YES];
    Weakify(self);
    [ZGRoomHelper queryRoomListWithAppID:self.appConfig.appID isTestEnv:(self.appConfig.environment == ZGAppEnvironmentTest) completion:^(NSArray<ZGRoomInfo *> * _Nonnull roomList, NSError * _Nonnull error) {
        Strongify(self);
        
        if (error) {
            NSLog(@"doQueryRoomList, error: %@", error);
        }
        
        NSArray<ZGRoomInfo *> *fRoomList = [self filterModuleRoomList:roomList];
        
        [self updateOnRefreshingRoomList:NO];
        self.roomList = fRoomList;
        [self.roomTableView reloadData];
    }];
}

- (void)updateOnRefreshingRoomList:(BOOL)onRefreshing {
    self.onRefreshingRoomList = onRefreshing;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshBarButnItem.title = onRefreshing?@"刷新中":@"刷新";
        self.refreshBarButnItem.enabled = !onRefreshing;
    });
}

/**
 过滤该模块的房间列表

 @param srcRoomList 源房间列表
 @return 过滤后的列表
 */
- (NSArray<ZGRoomInfo *> *)filterModuleRoomList:(NSArray<ZGRoomInfo *> *)srcRoomList {
    NSMutableArray<ZGRoomInfo *> *destItems = [NSMutableArray<ZGRoomInfo *> array];
    for (ZGRoomInfo *room in srcRoomList) {
        if (room.roomID == nil || room.roomID.length == 0) {
            continue;
        }
        
        // 忽略无主播（创建者）的房间
        if (room.anchorID == nil || room.anchorID.length == 0) {
            continue;
        }
        
        // 忽略非本专题指定前缀的房间
        if (![room.roomID hasPrefix:ZGJoinLiveTopicRoomPrefix]) {
            continue;
        }
        
        [destItems addObject:room];
    }
    return [destItems copy];
}

/**
 设置该模块的 ZegoLiveRoomApi 默认设置
 */
- (void)setupZegoLiveRoomApiDefault:(ZGAppGlobalConfig *)appConfig {
    // 设置环境
    [ZegoLiveRoomApi setUseTestEnv:(appConfig.environment == ZGAppEnvironmentTest)];
    // 设置硬编硬解
    [ZegoLiveRoomApi requireHardwareEncoder:appConfig.openHardwareEncode];
    [ZegoLiveRoomApi requireHardwareDecoder:appConfig.openHardwareDecode];
    
    [ZegoLiveRoomApi enableExternalRender:NO];
    [ZegoLiveRoomApi setVideoFilterFactory:nil];
    [ZegoLiveRoomApi setVideoCaptureFactory:nil];
}

- (void)gotoLivePageWithRoomAnchorID:(NSString *)roomAnchorID roomID:(NSString *)roomID {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"JoinLive" bundle:nil];
    ZGJoinLiveViewController *liveVC = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGJoinLiveViewController class])];
    liveVC.roomAnchorID = roomAnchorID;
    liveVC.roomID = roomID;
    liveVC.currentUserID = self.zgUserID;
    liveVC.joinLiveDemo = self.joinLiveDemo;
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:liveVC];
    nvc.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:nvc animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.roomList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"roomCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = @"点击进入";
    }
    
    // 设置 cell
    ZGRoomInfo *roomInfo = self.roomList[indexPath.row];
    NSString *roomID = roomInfo.roomID;
    NSString *displayRoomID = roomID;
    NSRange range = [roomID rangeOfString:ZGJoinLiveTopicRoomPrefix];
    if (range.location == 0) {
        displayRoomID = [roomID stringByReplacingCharactersInRange:range withString:@""];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"roomID: %@", displayRoomID];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSUInteger roomCount = self.roomList.count;
    if (roomCount == 0) {
        return @"暂无直播房间";
    }
    return [NSString stringWithFormat:@"%ld 个房间正在直播", roomCount];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ZGRoomInfo *room = self.roomList[indexPath.row];
    [self gotoLivePageWithRoomAnchorID:room.anchorID roomID:room.roomID];
}

@end

#endif
