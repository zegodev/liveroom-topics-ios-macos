//
//  ZGExternalVideoFilterViewController.m
//  LiveRoomPlayground-macOS
//
//  Created by Paaatrick on 2019/8/20.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_ExternalVideoFilter

#import "ZGExternalVideoFilterViewController.h"
#import "ZGExternalVideoFilterConfigViewController.h"
#import "ZGExternalVideoFilterDemo.h"
#import "ZGFUSkinConfig.h"
#import "FUManager-mac.h"

// 检查一下是否有 FaceUnity 的鉴权
#import "authpack_mac.h"

static NSString *ZGEVFRoomID = @"ZGEVFRoomID";
static NSString *ZGEVFStreamID = @"ZGEVFStreamID";

@interface ZGExternalVideoFilterViewController () <ZGExternalVideoFilterDemoProtocol, ZGFUConfigProtocol>

@property (weak) IBOutlet NSView *configView;
@property (weak) IBOutlet NSView *playView;
@property (weak) IBOutlet NSTextField *roomIDTextField;
@property (weak) IBOutlet NSTextField *streamIDTextField;
@property (weak) IBOutlet NSButton *startPublishButton;
@property (weak) IBOutlet NSPopUpButton *popUpTypeButton;


@property (nonatomic, copy) NSArray<NSString *> *filterBufferTypeList;
@property (nonatomic, assign) NSInteger selectedFilterBufferType;
@property (assign) BOOL isPublishing;

@property (strong) ZGExternalVideoFilterDemo *demo;

@end

@implementation ZGExternalVideoFilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self checkFaceUnityAuthPack];
    self.isPublishing = NO;
    // FaceUnity macOS SDK 暂不支持 I420 和 NV12 格式
    self.filterBufferTypeList = @[@"AsyncPixelBufferType", @"AsyncI420PixelBufferType", @"AsyncNV12PixelBufferType", @"SyncPixelBufferType"];
    [self setupUI];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    self.roomIDTextField.stringValue = [self savedValueForKey:ZGEVFRoomID] ? [self savedValueForKey:ZGEVFRoomID] : @"6";
    self.streamIDTextField.stringValue = [self savedValueForKey:ZGEVFStreamID] ? [self savedValueForKey:ZGEVFStreamID] : @"6";
}


- (void)dealloc {
    [FUManager releaseManager];
    
    if (self.isPublishing) {
        [self.demo stopPublish];
        [self.demo stopPreview];
    }
    [self.demo logoutRoom];
    self.demo = nil;
}

- (void)setupUI {
    self.configView.hidden = YES;
    [self.popUpTypeButton removeAllItems];
    [self.popUpTypeButton addItemsWithTitles:self.filterBufferTypeList];
    [self.popUpTypeButton selectItemAtIndex:0];
    [self onSwitchFilterType:self.popUpTypeButton];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"segue:%@, sender:%@", segue, sender);
    [segue.destinationController setZGFUConfigProtocol:self];
}


#pragma mark - Action

- (IBAction)startPublishAction:(NSButton *)sender {
    if (self.isPublishing) {
        [self.demo stopPublish];
        [self.demo stopPreview];
        [self.demo logoutRoom];
        self.demo = nil;
        
        self.isPublishing = !self.isPublishing;
        self.configView.hidden = YES;
        self.popUpTypeButton.enabled = YES;
        sender.state = NSOffState;
        
    } else {
        if (!self.demo) {
            NSString *roomID = self.roomIDTextField.stringValue.length != 0 ? self.roomIDTextField.stringValue : nil;
            NSString *streamID = self.streamIDTextField.stringValue.length != 0 ? self.streamIDTextField.stringValue : nil;
            
            if (!roomID || !streamID) {
                NSLog(@"❗️未填房间ID或流ID");
                return;
            }
            
            [self saveValue:self.roomIDTextField.stringValue forKey:ZGEVFRoomID];
            [self saveValue:self.streamIDTextField.stringValue forKey:ZGEVFStreamID];
            
            self.demo = [[ZGExternalVideoFilterDemo alloc] init];
            self.demo.delegate = self;
            
            // 先加载外部滤镜工厂
            [self.demo initFilterFactoryType:self.selectedFilterBufferType];
            
            // 然后初始化 ZegoLiveRoom SDK
            [self.demo initSDKWithRoomID:roomID streamID:streamID isAnchor:YES];
            
            // 开启 FaceUnity 的滤镜开关
            [[FUManager shareManager] loadFilter];
            
        }
        [self.demo loginRoom];
        [self.demo startPreview];
        [self.demo startPublish];
        
        self.isPublishing = !self.isPublishing;
        self.configView.hidden = NO;
        self.popUpTypeButton.enabled = NO;
        sender.state = NSOnState;
    }
}

- (IBAction)onSwitchFilterType:(NSPopUpButton *)sender {
    if (sender.indexOfSelectedItem == 0) {
        self.selectedFilterBufferType = ZegoVideoBufferTypeAsyncPixelBuffer;
    } else if (sender.indexOfSelectedItem == 1) {
        self.selectedFilterBufferType = ZegoVideoBufferTypeAsyncI420PixelBuffer;
    } else if (sender.indexOfSelectedItem == 2) {
        self.selectedFilterBufferType = ZegoVideoBufferTypeAsyncNV12PixelBuffer;
    } else {
        self.selectedFilterBufferType = ZegoVideoBufferTypeSyncPixelBuffer;
    }
}

#pragma mark - FaceUnity Action



#pragma mark - Private Method

// 检查一下是否有 FaceUnity 的鉴权，证书获取方法详见
// https://github.com/Faceunity/FULiveDemo/blob/master/docs/iOS_Nama_SDK_%E9%9B%86%E6%88%90%E6%8C%87%E5%AF%BC%E6%96%87%E6%A1%A3.md#331-%E5%AF%BC%E5%85%A5%E8%AF%81%E4%B9%A6
// 获取证书后，替换至 /LiveRoomPlayground/Topics/ExternalVideoFilter/FaceUnity-SDK-iOS/authpack.h 内。
- (void)checkFaceUnityAuthPack {
    if (sizeof(g_auth_package) < 1) {
        self.startPublishButton.enabled = NO;
        self.startPublishButton.lineBreakMode = NSLineBreakByWordWrapping;
        self.startPublishButton.alignment = NSTextAlignmentCenter;
        self.startPublishButton.title = @"检测到缺少 FaceUnity 证书\n请联系 FaceUnity 获取测试证书\n并替换到 authpack.h";
    }
}

#pragma mark - ZGExternalVideoFilterDemoProtocol

- (nonnull NSView *)getPlaybackView {
    return self.playView;
}

- (void)skinParamChanged:(nonnull ZGFUSkinConfig *)config {
    [FUManager shareManager].skinDetectEnable = config.skinDetect;
    [FUManager shareManager].blurShape = config.heavyBlur;
    [FUManager shareManager].blurLevel = config.blurLevel ;
    [FUManager shareManager].whiteLevel = config.colorLevel;
    [FUManager shareManager].redLevel = config.redLevel;
    [FUManager shareManager].eyelightingLevel = config.eyeBrightLevel;
    [FUManager shareManager].beautyToothLevel = config.toothWhitenLevel;
    
    [[FUManager shareManager] setAllSkinParam];
}

- (void)filterChanged:(nonnull NSString *)filterName {
    [[FUManager shareManager] changeParamsStr:@"filter_name" index:0 value:filterName];
}

- (void)filterValueChanged:(float)value {
    [[FUManager shareManager] changeParamsStr:@"filter_level" index:0 value:@(value)];
}

- (void)itemChanged:(nonnull NSString *)itemName {
    [[FUManager shareManager] loadItem:itemName];
}


@end

#endif
