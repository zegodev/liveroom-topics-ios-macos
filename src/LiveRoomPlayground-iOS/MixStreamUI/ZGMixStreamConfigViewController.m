//
//  ZGMixStreamConfigViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_MixStream

#import "ZGMixStreamConfigViewController.h"
#import "ZGMixStreamTopicConfigManager.h"

@interface ZGMixStreamConfigViewController ()

@property (weak, nonatomic) IBOutlet UITextField *outputResolutionWidthTxf;
@property (weak, nonatomic) IBOutlet UITextField *outputResolutionHeightTxf;
@property (weak, nonatomic) IBOutlet UITextField *outputFpsTxf;
@property (weak, nonatomic) IBOutlet UITextField *outputBitrateTxf;
@property (weak, nonatomic) IBOutlet UISwitch *twoChannelSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *soundLevelSwitch;

@end

@implementation ZGMixStreamConfigViewController

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MixStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMixStreamConfigViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)setupUI {
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.navigationItem.title = @"混流配置";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存修改" style:UIBarButtonItemStylePlain target:self action:@selector(saveMixStreamConfig:)];
    
    ZGMixStreamTopicConfig *config = [[ZGMixStreamTopicConfigManager sharedInstance] loadConfig];
    if (!config) {
        config = [ZGMixStreamTopicConfig configWithDefault];
    }
    
    self.outputResolutionWidthTxf.text = @(config.outputResolutionWidth).stringValue;
    self.outputResolutionHeightTxf.text = @(config.outputResolutionHeight).stringValue;
    self.outputFpsTxf.text = @(config.outputFps).stringValue;
    self.outputBitrateTxf.text = @(config.outputBitrate).stringValue;
    self.twoChannelSwitch.on = config.channels == 2;
    self.soundLevelSwitch.on = config.withSoundLevel;
}

- (void)saveMixStreamConfig:(id)sender {
    ZGMixStreamTopicConfig *config = [ZGMixStreamTopicConfig new];
   
    config.outputResolutionWidth = self.outputResolutionWidthTxf.text.integerValue;
    config.isSet_outputResolutionWidth = YES;
    
    config.outputResolutionHeight = self.outputResolutionHeightTxf.text.integerValue;
    config.isSet_outputResolutionHeight = YES;
    
    config.outputFps = self.outputFpsTxf.text.integerValue;
    config.isSet_outputFps = YES;
    
    config.outputBitrate = self.outputBitrateTxf.text.integerValue;
    config.isSet_outputBitrate = YES;
    
    config.channels = self.twoChannelSwitch.isOn?2:1;
    config.isSet_channels = YES;
    
    config.withSoundLevel = self.soundLevelSwitch.isOn;
    config.isSet_withSoundLevel = YES;
    
    [[ZGMixStreamTopicConfigManager sharedInstance] updateConfig:config];
    
    [ZegoHudManager showMessage:@"已保存修改"];
}

@end

#endif
