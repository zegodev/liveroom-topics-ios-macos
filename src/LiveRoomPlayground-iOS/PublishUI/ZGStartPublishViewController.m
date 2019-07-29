//
//  ZGStartPublishViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import "ZGStartPublishViewController.h"
#import "ZGLoginRoomDemo.h"
#import "ZGPublishDemo.h"
#import "ZGApiSettingHelper.h"

@interface ZGStartPublishViewController () <ZGPublishDemoDelegate>

@property (weak, nonatomic) IBOutlet UIView *configView;
@property (weak, nonatomic) IBOutlet UITextField *streamTxf;

@property (weak, nonatomic) IBOutlet UIView *dashboardView;
@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *streamIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitrateLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enableCamSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *enableMicSwitch;

@end

static NSString *ZGPublishStreamIDKey = @"ZGPublishStreamIDKey";

@implementation ZGStartPublishViewController

- (void)dealloc {
    [ZGPublishDemo.shared stopPreview];
    [ZGPublishDemo.shared stopPublish];
    [ZGLoginRoomDemo.shared logoutRoom];//退回上一级需要登出
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    ZGPublishDemo.shared.delegate = self;
    [self setupConfig];
    [self setupBind];
    [self startPreview];
}

- (void)setupUI {
    self.roomIDLabel.text = [NSString stringWithFormat:@"RoomID:%@",ZGLoginRoomDemo.shared.roomID];
    
    NSString *streamID = [self savedValueForKey:ZGPublishStreamIDKey];
    self.streamTxf.text = streamID;
}

- (void)setupBind {
    Weakify(self);
    
    ZGLoginRoomDemo *loginDemo = ZGLoginRoomDemo.shared;
    
    [self bind:loginDemo keyPath:ZGBindKeyPath(loginDemo.isLoginRoom) callback:^(id  _Nullable value) {
        Strongify(self);
        BOOL isLoginRoom = [value boolValue];
        if (!isLoginRoom) {
            [ZegoHudManager showMessage:@"房间连接已断开"];
        }
    }];
    
    ZGPublishDemo *publishDemo = ZGPublishDemo.shared;
    
    [self bind:publishDemo keyPath:ZGBindKeyPath(publishDemo.isPublishing) callback:^(id value) {
        Strongify(self);
        BOOL isPublishing = [value boolValue];
        
        if (isPublishing) {
            self.navigationItem.title = @"推流中";
            [self hideConfigView];
            [self showDashboardView];
        }
        else {
            self.navigationItem.title = @"第三步.开始推流";
            [self showConfigView];
            [self hideDashboradView];
        }
    }];
    
    [self bind:publishDemo keyPath:ZGBindKeyPath(publishDemo.streamID) callback:^(id value) {
        Strongify(self);
        self.streamIDLabel.text = [NSString stringWithFormat:@"StreamID:%@",value];
    }];
    
    ZGApiSettingHelper *settingHelper = ZGApiSettingHelper.shared;
    
    [self bind:settingHelper keyPath:ZGBindKeyPath(settingHelper.enableCam) callback:^(id value) {
        Strongify(self);
        [self.enableCamSwitch setOn:[value boolValue] animated:YES];
    }];
    
    [self bind:settingHelper keyPath:ZGBindKeyPath(settingHelper.enableMic) callback:^(id value) {
        Strongify(self);
        [self.enableMicSwitch setOn:[value boolValue] animated:YES];
    }];
}

- (void)setupConfig {
    [ZGApiSettingHelper.shared setEnableMicValue:ZGApiSettingHelper.shared.enableMic];
    [ZGApiSettingHelper.shared setEnableCamValue:ZGApiSettingHelper.shared.enableCam];
    [ZGApiSettingHelper.shared setResolutionValue:ZGApiSettingHelper.shared.resolution];//设置AVConfig
    [ZGApiSettingHelper.shared setUseFrontCamValue:ZGApiSettingHelper.shared.useFrontCam];
    [ZGApiSettingHelper.shared setPreviewMirrorValue:ZGApiSettingHelper.shared.previewMirror];
    [ZGApiSettingHelper.shared setPreviewViewModeValue:ZGApiSettingHelper.shared.previewViewMode];
    [ZGApiSettingHelper.shared setSDKEnableHardwareEncode:ZGApiSettingHelper.shared.enableHardwareEncode];
}

- (void)startPreview {
    [ZGPublishDemo.shared startPreview];
    [ZGPublishDemo.shared setPreviewView:self.view];
}

#pragma mark - Actions

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)startPublish {
    [self.view endEditing:YES];
    
    NSString *streamID = self.streamTxf.text;

    BOOL result = [ZGPublishDemo.shared startPublish:streamID title:nil flag:ZEGO_JOIN_PUBLISH];
    
    if (result) {
        [ZegoHudManager showNetworkLoading];
    }
    else {
        [ZegoHudManager showMessage:@"参数不合法或已经推流"];
    }
}

- (IBAction)toggleEnableCam {
    [ZGApiSettingHelper.shared setEnableCamValue:!ZGApiSettingHelper.shared.enableCam];
}

- (IBAction)toggleEnableMic {
    [ZGApiSettingHelper.shared setEnableMicValue:!ZGApiSettingHelper.shared.enableMic];
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
    [UIApplication jumpToWeb:ZGPublishDocURL];
}

#pragma mark - Delegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    [ZegoHudManager hideNetworkLoading];
    
    BOOL success = stateCode == 0;
    
    if (success) {
        [self saveValue:streamID forKey:ZGPublishStreamIDKey];
    }
    else {
        [ZegoHudManager showMessage:@"推流失败"];
    }
}

- (void)onPublishQualityUpdate:(NSString *)streamID quality:(ZegoApiPublishQuality)quality {
    self.fpsLabel.text = [NSString stringWithFormat:@"帧率:%.2f",quality.fps];
    self.bitrateLabel.text = [NSString stringWithFormat:@"码率:%.2f kb/s",quality.kbps];
    self.resolutionLabel.text = [NSString stringWithFormat:@"分辨率:%dx%d", quality.width, quality.height];
}

@end

#endif
