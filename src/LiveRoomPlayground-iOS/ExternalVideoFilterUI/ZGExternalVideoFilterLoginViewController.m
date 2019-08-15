//
//  ZGExternalVideoFilterViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import "ZGExternalVideoFilterDemo.h"
#import "ZGVideoFilterFactoryDemo.h"
#import "ZGExternalVideoFilterLoginViewController.h"
#import "ZGExternalVideoFilterViewController.h"
#import "ZGExternalVideoFilterPlayViewController.h"
#import "ZGLoginRoomDemo.h"
#import "FUManager.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"

// 检查一下是否有 FaceUnity 的鉴权
#import "authpack.h"

static NSString *ZGLoginRoomIDKey = @"ZGLoginRoomIDKey";

@interface ZGExternalVideoFilterLoginViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *roomIDTxf;
@property (weak, nonatomic) IBOutlet UIPickerView *typePickerView;
@property (weak, nonatomic) IBOutlet UIButton *jumpToPublishButton;
@property (weak, nonatomic) IBOutlet UIButton *jumpToPlayButton;

@property (nonatomic, copy) NSArray<NSString *> *filterBufferTypeList;
@property (nonatomic, assign) NSInteger selectedFilterBufferType;

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *userName;

@end

@implementation ZGExternalVideoFilterLoginViewController

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 检查一下是否有 FaceUnity 的鉴权
    [self checkFaceUnityAuthPack];
    
    [self setupUI];
    self.filterBufferTypeList = @[@"AsyncPixelBufferType", @"AsyncI420PixelBufferType", @"SyncPixelBufferType"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 切换 BufferType 需要重建外部滤镜工厂
    [ZGExternalVideoFilterDemo.shared releaseFilterFactory];
}

- (void)dealloc {
    // 释放外部滤镜工厂
    [ZGExternalVideoFilterDemo.shared releaseFilterFactory];
    
    // 释放 FaceUnity SDK
    [FUManager releaseManager];
    
    // 释放 ZegoLiveRoom SDK
    [ZGApiManager releaseApi];
}

#pragma mark - setup

- (void)setupUI {
    NSString *roomID = [self savedValueForKey:ZGLoginRoomIDKey];
    self.roomIDTxf.text = roomID;
    
    self.typePickerView.delegate = self;
    self.typePickerView.dataSource = self;
    [self pickerView:self.typePickerView didSelectRow:0 inComponent:0];
}

- (void)initSDK {
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    [ZGApiManager initApiWithAppID:appConfig.appID appSign:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign] completionBlock:^(int errorCode) {
        [ZegoHudManager hideNetworkLoading];
        
        Strongify(self);
        
        BOOL success = errorCode == 0;
        
        if (!success) {
            [ZegoHudManager showMessage:@"SDK 初始化失败\n请检查网络或参数是否有效"];
            return;
        }
    }];
}

#pragma mark - Actions

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)onTryEnterPublishRoom:(id)sender {
    
    // 先加载外部滤镜工厂
    [ZGExternalVideoFilterDemo.shared initFilterFactoryType:self.selectedFilterBufferType];
    
    // 加载外部滤镜工厂后，再初始化 ZegoLiveRoom SDK
    [self initSDK];
    
    // 尝试进入房间
    NSString *roomID = self.roomIDTxf.text;
    
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    BOOL result = [ZGLoginRoomDemo.shared loginRoom:roomID role:ZEGO_ANCHOR completion:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        
        [ZegoHudManager hideNetworkLoading];
        
        Strongify(self);
        BOOL success = errorCode == 0;
        if (!success) {
            [ZegoHudManager showMessage:@"登录房间失败"];
            return;
        }
        
        [self saveValue:roomID forKey:ZGLoginRoomIDKey];
        [self jumpToStartPublish];
    }];
    
    if (!result) {
        [ZegoHudManager hideNetworkLoading];
        [ZegoHudManager showMessage:@"参数不合法或已经登录房间"];
    }
}


- (void)jumpToStartPublish {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoFilter" bundle:nil];
    ZGExternalVideoFilterViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGExternalVideoFilterViewController"];
    vc.roomID = [self savedValueForKey:ZGLoginRoomIDKey];
    [self.navigationController pushViewController:vc animated:YES];
}


- (IBAction)onTryEnterPlayRoom:(id)sender {
    
    // 初始化 ZegoLiveRoom SDK
    [self initSDK];
    
    // 尝试进入房间
    NSString *roomID = self.roomIDTxf.text;
    
    [ZegoHudManager showNetworkLoading];
    Weakify(self);
    BOOL result = [ZGLoginRoomDemo.shared loginRoom:roomID role:ZEGO_ANCHOR completion:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        
        [ZegoHudManager hideNetworkLoading];
        
        Strongify(self);
        BOOL success = errorCode == 0;
        if (!success) {
            [ZegoHudManager showMessage:@"登录房间失败"];
            return;
        }
        
        [self saveValue:roomID forKey:ZGLoginRoomIDKey];
        [self jumpToStartPlay];
    }];
    
    if (!result) {
        [ZegoHudManager hideNetworkLoading];
        [ZegoHudManager showMessage:@"参数不合法或已经登录房间"];
    }
    
}

- (void)jumpToStartPlay {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoFilter" bundle:nil];
    ZGExternalVideoFilterPlayViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGExternalVideoFilterPlayViewController"];
    vc.roomID = [self savedValueForKey:ZGLoginRoomIDKey];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private Method

// 检查一下是否有 FaceUnity 的鉴权，证书获取方法详见
// https://github.com/Faceunity/FULiveDemo/blob/master/docs/iOS_Nama_SDK_%E9%9B%86%E6%88%90%E6%8C%87%E5%AF%BC%E6%96%87%E6%A1%A3.md#331-%E5%AF%BC%E5%85%A5%E8%AF%81%E4%B9%A6
// 获取证书后，替换至 /LiveRoomPlayground/Topics/ExternalVideoFilter/FaceUnity-SDK-iOS/authpack.h 内。
- (void)checkFaceUnityAuthPack {
    if (sizeof(g_auth_package) < 1) {
        self.jumpToPlayButton.hidden = YES;
        self.jumpToPublishButton.enabled = NO;
        self.jumpToPublishButton.backgroundColor = [UIColor clearColor];
        self.jumpToPublishButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.jumpToPublishButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.jumpToPublishButton setTitle:@"检测到缺少 FaceUnity 证书\n请联系 FaceUnity 获取测试证书\n并替换到 authpack.h" forState:UIControlStateNormal];
        [self.jumpToPublishButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
}

#pragma mark - UIPickerViewDataSource, UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.filterBufferTypeList.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.filterBufferTypeList[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row == 0) {
        self.selectedFilterBufferType = ZegoVideoBufferTypeAsyncPixelBuffer;
    } else if (row == 1) {
        self.selectedFilterBufferType = ZegoVideoBufferTypeAsyncI420PixelBuffer;
    } else {
        self.selectedFilterBufferType = ZegoVideoBufferTypeSyncPixelBuffer;
    }
}

@end

#endif
