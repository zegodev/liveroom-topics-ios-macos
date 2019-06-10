//
//  ZGStartPlayViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/5/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGStartPlayViewController.h"
#import "ZGLoginRoomDemo.h"
#import "ZGPlayDemo.h"
#import "ZGApiSettingHelper.h"
#import "UIViewController+TopPresent.h"

@interface ZGStartPlayViewController () <ZGPlayDemoDelegate>

@property (weak, nonatomic) IBOutlet UIView *configView;
@property (weak, nonatomic) IBOutlet UITextField *streamTxf;

@property (weak, nonatomic) IBOutlet UIView *dashboardView;
@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *streamIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitrateLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enableSpeakerSwitch;

@property (assign, nonatomic) BOOL isPlaying;
@property (copy, nonatomic) NSString *streamID;

@end


static NSString *ZGPlayStreamIDKey = @"ZGPlayStreamIDKey";


@implementation ZGStartPlayViewController

- (void)dealloc {
    [ZGPlayDemo.shared stopPlay];
    [ZGLoginRoomDemo.shared logoutRoom];//退回上一级需要登出
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    ZGPlayDemo.shared.delegate = self;
    [self setupConfig];
    [self setupBind];
}

- (void)setupUI {
    self.roomIDLabel.text = [NSString stringWithFormat:@"RoomID:%@",ZGLoginRoomDemo.shared.roomID];
    
    NSString *streamID = [self savedValueForKey:ZGPlayStreamIDKey];
    self.streamTxf.text = streamID;
}

- (void)setupBind {
    Weakify(self);
    
    ZGLoginRoomDemo *loginDemo = ZGLoginRoomDemo.shared;
    
    [self bind:loginDemo keyPath:ZGBindKeyPath(loginDemo.isLoginRoom) callback:^(id value) {
        Strongify(self);
        BOOL isLoginRoom = [value boolValue];
        if (!isLoginRoom) {
            [ZegoHudManager showMessage:@"房间连接已断开"];
        }
    }];
    
    [self bind:loginDemo keyPath:ZGBindKeyPath(loginDemo.streamIDList) callback:^(id value) {
        Strongify(self);
        
        if (!self.isPlaying) {
            return;
        }

        BOOL currentStreamExist = [value containsObject:self.streamID];
        if (currentStreamExist) {
            if (!ZGPlayDemo.shared.isPlaying) {
                [self startPlay];
            }
        }
        else {
            if (ZGPlayDemo.shared.isPlaying) {
                self.title = @"拉流停止";
                [ZGPlayDemo.shared stopPlay];
            }
        }
    }];
    
    ZGApiSettingHelper *settingHelper = ZGApiSettingHelper.shared;
    
    [self bind:settingHelper keyPath:ZGBindKeyPath(settingHelper.playViewMode) callback:^(id value) {
        Strongify(self);
        [ZGPlayDemo.shared updatePlayViewMode:[value intValue]];
    }];
    
    [self bind:settingHelper keyPath:ZGBindKeyPath(settingHelper.enableSpeaker) callback:^(id value) {
        Strongify(self);
        [self.enableSpeakerSwitch setOn:[value boolValue] animated:YES];
    }];
}

- (void)setupConfig {
    [ZGApiSettingHelper.shared setPlayVolumeValue:ZGApiSettingHelper.shared.playVolume];
    [ZGApiSettingHelper.shared setPlayViewModeValue:ZGApiSettingHelper.shared.playViewMode];
    [ZGApiSettingHelper.shared setEnableSpeakerValue:ZGApiSettingHelper.shared.enableSpeaker];
    [ZGApiSettingHelper.shared setSDKEnableHardwareDecode:ZGApiSettingHelper.shared.enableHardwareDecode];
}

#pragma mark - Actions

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)startPlay {
    [self.view endEditing:YES];
    
    NSString *streamID = self.streamTxf.text;

    BOOL result = [ZGPlayDemo.shared startPlayingStream:streamID inView:self.view];
    
    if (result) {
        self.title = @"开始拉流";
        self.streamID = streamID;
        self.isPlaying = YES;
        
        [self hideConfigView];
        [self showDashboardView];
        self.streamIDLabel.text = [NSString stringWithFormat:@"StreamID:%@",streamID];
        
        [ZegoHudManager showNetworkLoading];
        
        //开始拉流后即可设置 viewMode
        [ZGPlayDemo.shared updatePlayViewMode:ZGApiSettingHelper.shared.playViewMode];
    }
    else {
        [ZegoHudManager showMessage:@"参数不合法或已经开始拉流"];
    }
}

- (IBAction)toggleEnableSpeaker {
    [ZGApiSettingHelper.shared setEnableSpeakerValue:!ZGApiSettingHelper.shared.enableSpeaker];
}

- (void)showConfigView {
    [UIView animateWithDuration:0.5f animations:^{
        self.configView.alpha = 1;
    }];
}

- (void)hideConfigView {
    [UIView animateWithDuration:0.5f animations:^{
        self.configView.alpha = 0;
    }];
}

- (void)showDashboardView {
    [UIView animateWithDuration:0.5f animations:^{
        self.dashboardView.alpha = 1;
    }];
}

- (void)hideDashboradView {
    [UIView animateWithDuration:0.5f animations:^{
        self.dashboardView.alpha = 0;
    }];
}

- (IBAction)getSourceCode:(id)sender {
    [UIApplication jumpToWeb:ZGPlayDocURL];
}

#pragma mark - Delegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    [ZegoHudManager hideNetworkLoading];
    
    BOOL success = stateCode == 0;
    
    if (success) {
        self.title = @"拉流成功";
        
        [self saveValue:streamID forKey:ZGPlayStreamIDKey];
    }
    else {
        self.title = @"拉流失败";
        [ZegoHudManager showMessage:@"拉流失败"];
    }
}

- (void)onPlayQualityUpdate:(NSString *)streamID quality:(ZegoApiPlayQuality)quality {
    self.fpsLabel.text = [NSString stringWithFormat:@"帧率:%.2f",quality.fps];
    self.bitrateLabel.text = [NSString stringWithFormat:@"码率:%.2f kb/s",quality.kbps];
    self.resolutionLabel.text = [NSString stringWithFormat:@"分辨率:%dx%d", quality.width, quality.height];
}

@end
