//
//  ZGExternalVideoFilterViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import "ZGExternalVideoFilterViewController.h"
#import "ZGPublishDemo.h"
#import "ZGLoginRoomDemo.h"
#import "FUManager.h"
#import "FUAPIDemoBar.h"
#import "Masonry.h"

@interface ZGExternalVideoFilterViewController () <ZGPublishDemoDelegate, FUAPIDemoBarDelegate>

// 屏幕底部的 FaceUnity 美颜控制条
@property (nonatomic, strong) FUAPIDemoBar *demoBar;

@property (nonatomic, copy) NSString *streamID;

@end

@implementation ZGExternalVideoFilterViewController

#pragma mark - Life Circle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 开启 FaceUnity 的滤镜开关
    [[FUManager shareManager] loadFilter];
    
    // 加载 FaceUnity 的轻美妆 Bundle
    [[FUManager shareManager] loadMakeupBundleWithName:@"light_makeup"];
    
    ZGPublishDemo.shared.delegate = self;
    self.title = @"外部滤镜预览";
    
    [self setupUI];
    [self startPreview];
    [self startPublish];
}

- (void)dealloc {
    [ZGPublishDemo.shared stopPreview];
    [ZGPublishDemo.shared stopPublish];
    [ZGLoginRoomDemo.shared logoutRoom];//退回上一级需要登出
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
}

#pragma mark - Actions

- (void)startPreview {
    [ZGPublishDemo.shared startPreview];
    [ZGPublishDemo.shared setPreviewView:self.view];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    [self.demoBar hiddeTopView];
}

- (void)startPublish {
    // 流ID 设置为 房间ID 加前缀
    self.streamID = [NSString stringWithFormat:@"ExternalFilter-%@", self.roomID];
    
    BOOL result = [ZGPublishDemo.shared startPublish:self.streamID title:nil flag:ZEGO_JOIN_PUBLISH];
    
    if (result) {
        self.title = @"开始推流";
        [ZegoHudManager showNetworkLoading];
    }
    else {
        [ZegoHudManager showMessage:@"参数不合法或已经推流"];
    }
}

#pragma mark - Publish Delegate

- (void)onPublishStateUpdate:(int)stateCode streamID:(NSString *)streamID streamInfo:(NSDictionary *)info {
    [ZegoHudManager hideNetworkLoading];
    
    BOOL success = stateCode == 0;
    
    if (success) {
        self.title = @"推流中";
    }
    else {
        self.title = @"推流失败";
        [ZegoHudManager showMessage:@"推流失败"];
    }
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

@end

#endif
