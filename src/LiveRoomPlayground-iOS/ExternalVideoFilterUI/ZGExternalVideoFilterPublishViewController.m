//
//  ZGExternalVideoFilterPublishViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import "ZGExternalVideoFilterPublishViewController.h"
#import "ZGExternalVideoFilterDemo.h"
#import "FUManager.h"
#import "FUAPIDemoBar.h"
#import "Masonry.h"

@interface ZGExternalVideoFilterPublishViewController () <ZGExternalVideoFilterDemoProtocol, FUAPIDemoBarDelegate>

// 屏幕底部的 FaceUnity 美颜控制条
@property (nonatomic, strong) FUAPIDemoBar *demoBar;

@property (nonatomic, strong) ZGExternalVideoFilterDemo *demo;

@property (weak, nonatomic) IBOutlet UILabel *publishQualityLabel;
@property (weak, nonatomic) IBOutlet UISwitch *previewMirrorSwitch;

@property (nonatomic, assign) BOOL enablePreviewMirror;

@end

@implementation ZGExternalVideoFilterPublishViewController

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.demo = [[ZGExternalVideoFilterDemo alloc] init];
    self.demo.delegate = self;
    
    // 先加载外部滤镜工厂
    [self.demo initFilterFactoryType:self.selectedFilterBufferType];
    
    // 然后初始化 ZegoLiveRoom SDK
    [self.demo initSDKWithRoomID:self.roomID streamID:self.streamID isAnchor:YES];
    
    // 开启 FaceUnity 的滤镜开关
    [[FUManager shareManager] loadFilter];
    
    // 加载 FaceUnity 的轻美妆 Bundle
    [[FUManager shareManager] loadMakeupBundleWithName:@"light_makeup"];
    
    [self setupUI];
    
    // 默认关闭预览镜像
    self.enablePreviewMirror = NO;
    
    [self.demo loginRoom];
    [self.demo startPreview];
    [self.demo enablePreviewMirror:self.enablePreviewMirror];
    [self.demo startPublish];
}

- (void)dealloc {
    [FUManager releaseManager];
    
    [self.demo stopPublish];
    [self.demo stopPreview];
    [self.demo logoutRoom];
    
    self.demo = nil;
    
}

#pragma mark - setup

- (void)setupUI {
    // 设置屏幕底部的 FaceUnity 美颜控制条
    _demoBar = [[FUAPIDemoBar alloc] init];
    [self demoBarSetBeautyDefultParams];
    [self.view addSubview:_demoBar];
    [_demoBar mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.equalTo(self.view.mas_bottom);
        }
        make.left.right.equalTo(self.view);
        make.height.mas_equalTo(231);
    }];
    
    self.previewMirrorSwitch.on = self.enablePreviewMirror;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    [self.demoBar hiddeTopView];
}

- (IBAction)onSwitchPreviewMirror:(UISwitch *)sender {
    self.enablePreviewMirror = sender.on;
    [self.demo enablePreviewMirror:self.enablePreviewMirror];
}


#pragma mark - FaceUnity method
// 以下方法都是 FaceUnity 相关的视图和业务逻辑

- (void)demoBarSetBeautyDefultParams {
    _demoBar.delegate = nil ;
    _demoBar.skinDetect = [FUManager shareManager].skinDetectEnable;
    _demoBar.heavyBlur = [FUManager shareManager].blurShape ;
    _demoBar.blurLevel = [FUManager shareManager].blurLevel ;
    _demoBar.colorLevel = [FUManager shareManager].whiteLevel ;
    _demoBar.redLevel = [FUManager shareManager].redLevel;
    _demoBar.eyeBrightLevel = [FUManager shareManager].eyelightingLevel ;
    _demoBar.toothWhitenLevel = [FUManager shareManager].beautyToothLevel ;
    
    _demoBar.vLevel =  [FUManager shareManager].vLevel;
    _demoBar.eggLevel = [FUManager shareManager].eggLevel;
    _demoBar.narrowLevel = [FUManager shareManager].narrowLevel;
    _demoBar.smallLevel = [FUManager shareManager].smallLevel;
    _demoBar.enlargingLevel = [FUManager shareManager].enlargingLevel ;
    _demoBar.thinningLevel = [FUManager shareManager].thinningLevel ;
    _demoBar.chinLevel = [FUManager shareManager].jewLevel ;
    _demoBar.foreheadLevel = [FUManager shareManager].foreheadLevel ;
    _demoBar.noseLevel = [FUManager shareManager].noseLevel ;
    _demoBar.mouthLevel = [FUManager shareManager].mouthLevel ;
    
    _demoBar.filtersDataSource = [FUManager shareManager].filtersDataSource ;
    _demoBar.beautyFiltersDataSource = [FUManager shareManager].beautyFiltersDataSource ;
    _demoBar.filtersCHName = [FUManager shareManager].filtersCHName ;
    _demoBar.selectedFilter = [FUManager shareManager].selectedFilter ;
    _demoBar.selectedFilterLevel = [FUManager shareManager].selectedFilterLevel;
    _demoBar.delegate = self;
    _demoBar.demoBar.selMakeupIndex = _demoBar.demoBar.makeupView.supIndex;
}

#pragma mark - FUAPIDemoBarDelegate
/**设置美颜参数*/
- (void)demoBarBeautyParamChanged{
    [self syncBeautyParams];
}

-(void)restDefaultValue:(int)type{
    if (type == 1) {//美肤
        [[FUManager shareManager] setBeautyDefaultParameters:FUBeautyModuleTypeSkin];
    }
    
    if (type == 2) {
        [[FUManager shareManager] setBeautyDefaultParameters:FUBeautyModuleTypeShape];
    }
    
    [self demoBarSetBeautyDefultParams];
}

- (void)syncBeautyParams{
    [FUManager shareManager].skinDetectEnable = _demoBar.skinDetect;
    [FUManager shareManager].blurShape = _demoBar.heavyBlur;
    [FUManager shareManager].blurLevel = _demoBar.blurLevel ;
    [FUManager shareManager].whiteLevel = _demoBar.colorLevel;
    [FUManager shareManager].redLevel = _demoBar.redLevel;
    [FUManager shareManager].eyelightingLevel = _demoBar.eyeBrightLevel;
    [FUManager shareManager].beautyToothLevel = _demoBar.toothWhitenLevel;
    [FUManager shareManager].vLevel = _demoBar.vLevel;
    [FUManager shareManager].eggLevel = _demoBar.eggLevel;
    [FUManager shareManager].narrowLevel = _demoBar.narrowLevel;
    [FUManager shareManager].smallLevel = _demoBar.smallLevel;
    [FUManager shareManager].enlargingLevel = _demoBar.enlargingLevel;
    [FUManager shareManager].thinningLevel = _demoBar.thinningLevel;
    [FUManager shareManager].jewLevel = _demoBar.chinLevel;
    [FUManager shareManager].foreheadLevel = _demoBar.foreheadLevel;
    [FUManager shareManager].noseLevel = _demoBar.noseLevel;
    [FUManager shareManager].mouthLevel = _demoBar.mouthLevel;;
    
    /* 暂时解决展示表中，没有显示滤镜，引起bug */
    if (![[FUManager shareManager].beautyFiltersDataSource containsObject:_demoBar.selectedFilter]) {
        return;
    }
    [FUManager shareManager].selectedFilter = _demoBar.selectedFilter ;
    [FUManager shareManager].selectedFilterLevel = _demoBar.selectedFilterLevel;
    
}

#pragma mark - ZGExternalVideoFilterDemoProtocol
- (nonnull UIView *)getPlaybackView {
    return self.view;
}

- (void)onExternalVideoFilterPublishStateUpdate:(NSString *)state {
    self.title = state;
}

- (void)onExternalVideoFilterPublishQualityUpdate:(NSString *)state {
    self.publishQualityLabel.text = state;
}

@end

#endif
