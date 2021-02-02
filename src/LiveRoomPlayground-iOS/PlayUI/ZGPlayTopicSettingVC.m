//
//  ZGPlayTopicSettingVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/9.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_Play

#import "ZGPlayTopicSettingVC.h"
#import "ZGPlayTopicConfigManager.h"

@interface ZGPlayTopicSettingVC ()

@property (weak, nonatomic) IBOutlet UILabel *playViewModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *hardwareDecodeSwitch;
@property (weak, nonatomic) IBOutlet UISlider *playVolumeSlider;
@property (weak, nonatomic) IBOutlet UILabel *playVolumeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *previewMirrorSwitch;

@end

@implementation ZGPlayTopicSettingVC

static NSArray<NSNumber*> *ZGPlayTopicCommonVideoViewModeList;

+ (void)initialize {
    ZGPlayTopicCommonVideoViewModeList = @[@(ZegoVideoViewModeScaleAspectFit),
                                           @(ZegoVideoViewModeScaleAspectFill),
                                           @(ZegoVideoViewModeScaleToFill)];
}

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PlayStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGPlayTopicSettingVC class])];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (IBAction)enableHardwareDecodeSwitchValueChanged:(id)sender {
    [[ZGPlayTopicConfigManager sharedInstance] setEnableHardwareDecode:self.hardwareDecodeSwitch.isOn];
}

- (IBAction)playVolumeSwitchValueChanged:(id)sender {
    int volume = (int)self.playVolumeSlider.value;
    [[ZGPlayTopicConfigManager sharedInstance] setPlayStreamVolume:volume];
    self.playVolumeLabel.text = @(volume).stringValue;
}

- (IBAction)playMirrorSwitchValueChange:(id)sender {
    [[ZGPlayTopicConfigManager sharedInstance] setPreviewMinnor:self.previewMirrorSwitch.isOn];
}


#pragma mark - private methods

+ (NSString *)displayTextForVideoViewMode:(ZegoVideoViewMode)viewMode {
    switch (viewMode) {
        case ZegoVideoViewModeScaleAspectFit:
            return @"等比缩放（ScaleAspectFit）";
            break;
        case ZegoVideoViewModeScaleAspectFill:
            return @"等比截取（ScaleAspectFill）";
            break;
        case ZegoVideoViewModeScaleToFill:
            return @"不等比填充（ScaleToFill）";
            break;
    }
}

- (void)setupUI {
    self.navigationItem.title = @"常用功能设置";
    self.playVolumeSlider.minimumValue = 0;
    self.playVolumeSlider.maximumValue = 100;
    
    [self invalidatePlayViewModeUI:[ZGPlayTopicConfigManager sharedInstance].playViewMode];
    [self invalidateEnableHardwareDecodeUI:[ZGPlayTopicConfigManager sharedInstance].isEnableHardwareDecode];
    [self invalidatePlayVolumeUI:[ZGPlayTopicConfigManager sharedInstance].playStreamVolume];
    [self.previewMirrorSwitch setOn:[ZGPlayTopicConfigManager sharedInstance].isPreviewMinnor animated:NO];

}

- (void)invalidatePlayViewModeUI:(ZegoVideoViewMode)viewMode {
    self.playViewModeLabel.text = [[self class] displayTextForVideoViewMode:viewMode];
}

- (void)invalidateEnableHardwareDecodeUI:(BOOL)enableHardwareDecode {
    self.hardwareDecodeSwitch.on = enableHardwareDecode;
}

- (void)invalidatePlayVolumeUI:(int)playVolume {
    self.playVolumeLabel.text = @(playVolume).stringValue;
    self.playVolumeSlider.value = playVolume;
}

- (void)showViewModePickSheet {
    NSArray<NSNumber*>* modeList = ZGPlayTopicCommonVideoViewModeList;
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择渲染视图模式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        UIPopoverPresentationController *popVC = sheet.popoverPresentationController;
        popVC.sourceView = cell;
        popVC.sourceRect = cell.bounds;
        popVC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    for (NSNumber *modeObj in modeList) {
        ZegoVideoViewMode viewMode = (ZegoVideoViewMode)[modeObj integerValue];
        [sheet addAction:[UIAlertAction actionWithTitle:[[self class] displayTextForVideoViewMode:viewMode] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ZGPlayTopicConfigManager sharedInstance] setPlayViewMode:viewMode];
            [self invalidatePlayViewModeUI:viewMode];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self showViewModePickSheet];
        }
    }
}

@end

#endif
