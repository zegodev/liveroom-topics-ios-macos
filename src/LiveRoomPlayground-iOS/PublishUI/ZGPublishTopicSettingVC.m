//
//  ZGPublishTopicSettingVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import "ZGPublishTopicSettingVC.h"
#import "ZGPublishTopicConfigManager.h"

@interface ZGPublishTopicSettingVC ()

@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitrateLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *hardwareEncodeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *mirrorSwitch;

@end

@implementation ZGPublishTopicSettingVC

static NSArray<NSValue*> *ZGPublishTopicCommonResolutionList;
static NSArray<NSNumber*> *ZGPublishTopicCommonBitrateList;
static NSArray<NSNumber*> *ZGPublishTopicCommonFpsList;
static NSArray<NSNumber*> *ZGPublishTopicCommonVideoViewModeList;

+ (void)initialize {
    ZGPublishTopicCommonResolutionList =
        @[@(CGSizeMake(1080, 1920)),
          @(CGSizeMake(720, 1280)),
          @(CGSizeMake(540, 960)),
          @(CGSizeMake(360, 640)),
          @(CGSizeMake(270, 480)),
          @(CGSizeMake(180, 320))];
    
    ZGPublishTopicCommonBitrateList =
        @[@(3000000),
          @(1500000),
          @(1200000),
          @(600000),
          @(400000),
          @(300000)];
    
    ZGPublishTopicCommonFpsList = @[@(10),@(15),@(20),@(25),@(30)];
    
    ZGPublishTopicCommonVideoViewModeList = @[@(ZegoVideoViewModeScaleAspectFit),
          @(ZegoVideoViewModeScaleAspectFill),
          @(ZegoVideoViewModeScaleToFill)];
}

+ (instancetype)instanceFromStoryboard {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"PublishStream" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ZGPublishTopicSettingVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (IBAction)enableHardwareEncodeSwitchValueChanged:(id)sender {
    [[ZGPublishTopicConfigManager sharedInstance] setEnableHardwareEncode:self.hardwareEncodeSwitch.isOn];
}

- (IBAction)priviewMinnorSwitchValueChanged:(id)sender {
    [[ZGPublishTopicConfigManager sharedInstance] setPreviewMinnor:self.mirrorSwitch.isOn];
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

+ (NSString *)displayTextForResolution:(CGSize)resolution {
    return [NSString stringWithFormat:@"%@ x %@", @(resolution.width), @(resolution.height)];
}

- (void)setupUI {
    self.navigationItem.title = @"常用功能设置";
    
    [self invalidateResolutionUI:[ZGPublishTopicConfigManager sharedInstance].resolution];
    [self invalidateFpsUI:[ZGPublishTopicConfigManager sharedInstance].fps];
    [self invalidateBitrateUI:[ZGPublishTopicConfigManager sharedInstance].bitrate];
    [self invalidatePreviewViewModeUI:[ZGPublishTopicConfigManager sharedInstance].previewViewMode];
    [self invalidateEnableHardwareEncodeUI:[ZGPublishTopicConfigManager sharedInstance].isEnableHardwareEncode];
    [self invalidatePreviewMinnor:[ZGPublishTopicConfigManager sharedInstance].isPreviewMinnor];
}

- (void)invalidateResolutionUI:(CGSize)resolution {
    self.resolutionLabel.text = [[self class] displayTextForResolution:resolution];
}

- (void)invalidateFpsUI:(NSInteger)fps {
    self.fpsLabel.text = @(fps).stringValue;
}

- (void)invalidateBitrateUI:(NSInteger)bitrate {
    self.bitrateLabel.text = @(bitrate).stringValue;
}

- (void)invalidatePreviewViewModeUI:(ZegoVideoViewMode)viewMode {
    self.viewModeLabel.text = [[self class] displayTextForVideoViewMode:viewMode];
}

- (void)invalidateEnableHardwareEncodeUI:(BOOL)enableHardwareEncode {
    self.hardwareEncodeSwitch.on = enableHardwareEncode;
}

- (void)invalidatePreviewMinnor:(BOOL)isPreviewMinnor {
    self.mirrorSwitch.on = isPreviewMinnor;
}

- (void)showResolutionListPickSheet {
    NSArray<NSValue*>* resolutionList = ZGPublishTopicCommonResolutionList;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择分辨率" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        UIPopoverPresentationController *popVC = sheet.popoverPresentationController;
        popVC.sourceView = cell;
        popVC.sourceRect = cell.bounds;
        popVC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    for (NSValue *sizeObj in resolutionList) {
        CGSize size = [sizeObj CGSizeValue];
        NSString *title = [[self class] displayTextForResolution:size];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ZGPublishTopicConfigManager sharedInstance] setResolution:size];
            [self invalidateResolutionUI:size];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showBitratePickSheet {
    NSArray<NSNumber*> *bitrateList = ZGPublishTopicCommonBitrateList;
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择视频码率" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
        UIPopoverPresentationController *popVC = sheet.popoverPresentationController;
        popVC.sourceView = cell;
        popVC.sourceRect = cell.bounds;
        popVC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    for (NSNumber *bitrateObj in bitrateList) {
        [sheet addAction:[UIAlertAction actionWithTitle:[bitrateObj stringValue] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSInteger bitrate = [bitrateObj integerValue];
            [[ZGPublishTopicConfigManager sharedInstance] setBitrate:bitrate];
            [self invalidateBitrateUI:bitrate];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showFpsPickSheet {
    NSArray<NSNumber*>* fpsList = ZGPublishTopicCommonFpsList;
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择视频码率" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        UIPopoverPresentationController *popVC = sheet.popoverPresentationController;
        popVC.sourceView = cell;
        popVC.sourceRect = cell.bounds;
        popVC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    for (NSNumber *fpsObj in fpsList) {
        [sheet addAction:[UIAlertAction actionWithTitle:[fpsObj stringValue] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSInteger fps = [fpsObj integerValue];
            [[ZGPublishTopicConfigManager sharedInstance] setFps:fps];
            [self invalidateFpsUI:fps];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showViewModePickSheet {
    NSArray<NSNumber*>* modeList = ZGPublishTopicCommonVideoViewModeList;
    
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"选择渲染视图模式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        UIPopoverPresentationController *popVC = sheet.popoverPresentationController;
        popVC.sourceView = cell;
        popVC.sourceRect = cell.bounds;
        popVC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    for (NSNumber *modeObj in modeList) {
        ZegoVideoViewMode viewMode = (ZegoVideoViewMode)[modeObj integerValue];
        [sheet addAction:[UIAlertAction actionWithTitle:[[self class] displayTextForVideoViewMode:viewMode] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[ZGPublishTopicConfigManager sharedInstance] setPreviewViewMode:viewMode];
            [self invalidatePreviewViewModeUI:viewMode];
        }]];
    }
    
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:sheet animated:YES completion:nil];
}


#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self showResolutionListPickSheet];
        }
        else if (indexPath.row == 1) {
            [self showFpsPickSheet];
        }
        else if (indexPath.row == 2) {
            [self showBitratePickSheet];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self showViewModePickSheet];
        }
    }
}

@end

#endif
