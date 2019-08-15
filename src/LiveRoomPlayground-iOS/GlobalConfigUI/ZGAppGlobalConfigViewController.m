//
//  ZGAppGlobalConfigViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/6.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGAppGlobalConfigViewController.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>

@interface ZGAppGlobalConfigViewController ()

@property (weak, nonatomic) IBOutlet UITextField *appIDTxf;
@property (weak, nonatomic) IBOutlet UITextView *appSignTxv;
@property (weak, nonatomic) IBOutlet UISegmentedControl *environmentSegCtrl;
@property (weak, nonatomic) IBOutlet UILabel *VEVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *SDKVersionLabel;
@property (weak, nonatomic) IBOutlet UILabel *appVersionLabel;

@end

@implementation ZGAppGlobalConfigViewController

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"GlobalConfig" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAppGlobalConfigViewController class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - private methods

- (void)setupUI {
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.navigationItem.title = @"设置";
    UIBarButtonItem *resetItem = [[UIBarButtonItem alloc] initWithTitle:@"重置" style:UIBarButtonItemStylePlain target:self action:@selector(resetConfig:)];
    UIBarButtonItem *saveChangeItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(saveAppGlobalConfig:)];
    self.navigationItem.rightBarButtonItems = @[saveChangeItem,resetItem];
    
    self.appSignTxv.layer.borderColor = [UIColor colorWithWhite:0.6 alpha:1].CGColor;
    self.appSignTxv.layer.borderWidth = 0.5f;
    
    
    self.VEVersionLabel.text = [NSString stringWithFormat:@"VE 版本：%@", [ZegoLiveRoomApi version2]];
    self.SDKVersionLabel.text = [NSString stringWithFormat:@"SDK 版本：%@", [ZegoLiveRoomApi version]];
    self.appVersionLabel.text = [NSString stringWithFormat:@"Demo 版本：%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];

    ZGAppGlobalConfig *config = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    [self applyConfig:config];
}

- (void)resetConfig:(id)sender {
    [self.view endEditing:YES];
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:@"确定重置为默认设置吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"重置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ZGAppGlobalConfig *config = [ZGAppGlobalConfigManager defaultGlobalConfig];
        [[ZGAppGlobalConfigManager sharedInstance] setGlobalConfig:config];
        [ZegoHudManager showMessage:@"已重置为默认设置"];
        [self applyConfig:config];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)saveAppGlobalConfig:(id)sender {
    [self.view endEditing:YES];
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:@"确定保存当前修改的设置吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        ZGAppGlobalConfig *config = [[ZGAppGlobalConfig alloc] init];
        config.appID = (unsigned int)[self.appIDTxf.text longLongValue];
        config.appSign = self.appSignTxv.text;
        config.environment = self.environmentSegCtrl.selectedSegmentIndex == 0?ZGAppEnvironmentTest:ZGAppEnvironmentOfficial;
        
        [[ZGAppGlobalConfigManager sharedInstance] setGlobalConfig:config];
        [ZegoHudManager showMessage:@"已保存设置"];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)applyConfig:(ZGAppGlobalConfig *)configInfo {
    if (!configInfo) {
        return;
    }
    self.appIDTxf.text = @(configInfo.appID).stringValue;
    self.appSignTxv.text = configInfo.appSign;
    self.environmentSegCtrl.selectedSegmentIndex = configInfo.environment == ZGAppEnvironmentTest?0:1;
}

@end
