//
//  ZGRoomConfigTopicInitVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/12/1.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_RoomConfigLive

#import "ZGRoomConfigTopicInitVC.h"
#import "ZGRoomConfigLiveVC.h"
#import "ZGUserIDHelper.h"
#import "ZGJoinLiveDemo.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"

static NSString *ZGRoomConfigTopicInitVCRoomIDKey = @"ZGRoomConfigTopicInitVCRoomIDKey";
static NSString *ZGRoomConfigTopicInitVCStreamIDKey = @"ZGRoomConfigTopicInitVCStreamIDKey";

@interface ZGRoomConfigTopicInitVC ()

@property (nonatomic, weak) IBOutlet UISwitch *allowAudienceCreateRoomSwitch;
@property (nonatomic, weak) IBOutlet UISegmentedControl *roleTypeSegCtrl;
@property (nonatomic, weak) IBOutlet UITextField *roomIDTxf;
@property (nonatomic, weak) IBOutlet UITextField *streamIDTxf;
@property (nonatomic, weak) IBOutlet UIView *streamIDContainerView;

@property (nonatomic, copy) NSString *zgUserID;
@property (nonatomic, copy) NSString *zgUserName;
@property (nonatomic) ZGJoinLiveDemo *joinLiveDemo;
@property (nonatomic) ZGAppGlobalConfig *appConfig;

@end

@implementation ZGRoomConfigTopicInitVC

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

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)roleTypeSegCtrlChanged:(UISegmentedControl *)sender {
    [self _updateRoleType];
}

- (void)_updateRoleType {
    if (self.roleTypeSegCtrl.selectedSegmentIndex == 0) {
        // 主播
        self.streamIDContainerView.hidden = NO;
    } else {
        // 观众
        self.streamIDContainerView.hidden = YES;
    }
}

- (IBAction)enterRoom:(id)sender {
    NSString *roomID = self.roomIDTxf.text;
    NSString *streamID = self.streamIDTxf.text;
    ZegoRole role = self.roleTypeSegCtrl.selectedSegmentIndex==0?ZEGO_ANCHOR:ZEGO_AUDIENCE;
    BOOL allowAudienceCreateRoom = self.allowAudienceCreateRoomSwitch.isOn;
    if (!roomID) roomID = @"";
    if (!streamID) streamID = @"";
    
    [self saveValue:roomID forKey:ZGRoomConfigTopicInitVCRoomIDKey];
    [self saveValue:streamID forKey:ZGRoomConfigTopicInitVCStreamIDKey];
    
    if (roomID.length == 0) {
        [ZegoHudManager showMessage:@"roomID 必填"];
        return;
    }
    if (role == ZEGO_ANCHOR && streamID.length == 0) {
        [ZegoHudManager showMessage:@"主播身份时，streamID 必填"];
        return;
    }
    
    ZGRoomConfigLiveVC *liveVC = [ZGRoomConfigLiveVC fromStoryboard];
    liveVC.roomID = roomID;
    liveVC.currentUserID = [ZGUserIDHelper userID];
    liveVC.userRole = role;
    liveVC.audienceCreateRoomEnabled = allowAudienceCreateRoom;
    liveVC.localLiveStreamID = streamID;
    liveVC.joinLiveDemo = self.joinLiveDemo;
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:liveVC];
    nvc.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:nvc animated:YES completion:nil];
}

- (void)setupUI {
    self.roomIDTxf.text = [self savedValueForKey:ZGRoomConfigTopicInitVCRoomIDKey];
    self.streamIDTxf.text = [self savedValueForKey:ZGRoomConfigTopicInitVCStreamIDKey];
    self.roleTypeSegCtrl.selectedSegmentIndex = 0;
    [self _updateRoleType];
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
}

@end

#endif
