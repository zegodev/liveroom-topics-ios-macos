//
//  ZGPublishSettingsViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/5/13.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_Publish

#import "ZGPublishSettingsViewController.h"
#import "ZGApiSettingHelper.h"

@interface ZGPublishSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitrateLabel;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewModeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *hardwareEncodeSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *mirrorSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *frontCamSwitch;

@end

@implementation ZGPublishSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self bindUI];
}

- (void)bindUI {
    ZGApiSettingHelper *sharedHelper = ZGApiSettingHelper.shared;
    
    Weakify(self);
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.resolution) callback:^(id value) {
        Strongify(self);
        CGSize resolution = [value CGSizeValue];
        self.resolutionLabel.text = [NSString stringWithFormat:@"%d x %d", (int)resolution.width, (int)resolution.height];
    }];
    
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.bitrate) callback:^(id value) {
        Strongify(self);
        self.bitrateLabel.text = @([value intValue]).stringValue;
    }];
    
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.fps) callback:^(id value) {
        Strongify(self);
        self.fpsLabel.text = @([value intValue]).stringValue;
    }];
    
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.previewViewMode) callback:^(id value) {
        Strongify(self);
        NSString *text = nil;
        switch ((ZegoVideoViewMode)[value intValue]) {
            case ZegoVideoViewModeScaleAspectFit:
                text = @"等比缩放，可能有黑边";
                break;
            case ZegoVideoViewModeScaleAspectFill:
                text = @"等比缩放填充整个 View，可能有部分被裁减";
                break;
            case ZegoVideoViewModeScaleToFill:
                text = @"填充整个View, 视频可能会变形";
                break;
        }
        
        self.viewModeLabel.text = text;
    }];
    
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.enableHardwareEncode) callback:^(id value) {
        Strongify(self);
        [self.hardwareEncodeSwitch setOn:[value boolValue] animated:YES];
    }];
    
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.previewMirror) callback:^(id value) {
        Strongify(self);
        [self.mirrorSwitch setOn:[value boolValue] animated:YES];
    }];
    
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.useFrontCam) callback:^(id value) {
        Strongify(self);
        [self.frontCamSwitch setOn:[value boolValue] animated:YES];
    }];
}

- (void)showConfigSheet:(NSString *)title options:(NSArray<NSString *>*)options currentIndex:(NSInteger)currentIndex completion:(void(^)(NSInteger selectedIndex))completion {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int i = 0; i < options.count; ++i) {
        BOOL isCurrentOption = i == currentIndex;
        UIAlertActionStyle style = isCurrentOption ? UIAlertActionStyleDestructive:UIAlertActionStyleDefault;
        [alert addAction:[UIAlertAction actionWithTitle:options[i] style:style handler:^(UIAlertAction * _Nonnull action) {
            completion(i);
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completion(NSNotFound);
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - TableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self showResolutionList];
        }
        else if (indexPath.row == 1) {
            [self showBitrateList];
        }
        else if (indexPath.row == 2) {
            [self showFpsList];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self showViewModeList];
        }
    }
    else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            [self toggleEnableHardwareEncode];
        }
        else if (indexPath.row == 1) {
            [self togglePreviewMirror];
        }
        else if (indexPath.row == 2) {
            [self toggleUseFrontCam];
        }
    }
}

#pragma mark - Actions

- (void)showResolutionList {
    NSArray<NSValue*>* sizeList = @[@(CGSizeMake(1080, 1920)),
                                    @(CGSizeMake(720, 1280)),
                                    @(CGSizeMake(540, 960)),
                                    @(CGSizeMake(360, 640)),
                                    @(CGSizeMake(270, 480)),
                                    @(CGSizeMake(180, 320))];
    NSArray<NSString*>* stringList = @[@"(极清)1080x1920",
                                       @"(超清)720x1280",
                                       @"(高清)540x960",
                                       @"(标准)360x640",
                                       @"(流畅)270x480",
                                       @"(低清)180x320"];
    
    NSInteger currentIndex = [sizeList indexOfObject:@(ZGApiSettingHelper.shared.resolution)];
    
    [self showConfigSheet:@"选择分辨率" options:stringList currentIndex:currentIndex completion:^(NSInteger selectedIndex) {
        if (selectedIndex == NSNotFound) {
            return;
        }
        
        CGSize size = sizeList[selectedIndex].CGSizeValue;
        [ZGApiSettingHelper.shared setResolutionValue:size];
    }];
}

- (void)showBitrateList {
    NSArray<NSNumber*>* bitrateList = @[@(3000000),
                                    @(1500000),
                                    @(1200000),
                                    @(600000),
                                    @(400000),
                                    @(300000)];
    NSArray<NSString*>* stringList = @[@"(3M) 3000000",
                                       @"(1.5M) 1500000",
                                       @"(1.2M) 1200000",
                                       @"(600K) 600000",
                                       @"(400K) 400000",
                                       @"(300K) 300000"];
    
    NSInteger currentIndex = [bitrateList indexOfObject:@(ZGApiSettingHelper.shared.bitrate)];
    
    [self showConfigSheet:@"选择视频码率" options:stringList currentIndex:currentIndex completion:^(NSInteger selectedIndex) {
        if (selectedIndex == NSNotFound) {
            return;
        }
        
        int bitrate = bitrateList[selectedIndex].intValue;
        [ZGApiSettingHelper.shared setBitrateValue:bitrate];
    }];
}

- (void)showFpsList {
    NSArray<NSNumber*>* fpsList = @[@(10),@(15),@(20),@(25),@(30)];
    NSArray<NSString*>* stringList = @[@"10",@"15",@"20",@"25",@"30"];
    
    NSInteger currentIndex = [fpsList indexOfObject:@(ZGApiSettingHelper.shared.fps)];
    
    [self showConfigSheet:@"选择视频帧率" options:stringList currentIndex:currentIndex completion:^(NSInteger selectedIndex) {
        if (selectedIndex == NSNotFound) {
            return;
        }
        
        int fps = fpsList[selectedIndex].intValue;
        [ZGApiSettingHelper.shared setFpsValue:fps];
    }];
}

- (void)showViewModeList {
    NSArray<NSNumber*>* modeList = @[@(ZegoVideoViewModeScaleAspectFit),
                                    @(ZegoVideoViewModeScaleAspectFill),
                                    @(ZegoVideoViewModeScaleToFill)];
    
    NSArray<NSString*>* stringList = @[@"等比缩放，可能有黑边",
                                       @"等比缩放填充整个 View，可能有部分被裁减",
                                       @"填充整个View, 视频可能会变形"];
    
    NSInteger currentIndex = [modeList indexOfObject:@(ZGApiSettingHelper.shared.previewViewMode)];
    
    [self showConfigSheet:@"选择渲染模式" options:stringList currentIndex:currentIndex completion:^(NSInteger selectedIndex) {
        if (selectedIndex == NSNotFound) {
            return;
        }
        
        ZegoVideoViewMode mode = modeList[selectedIndex].intValue;
        [ZGApiSettingHelper.shared setPreviewViewModeValue:mode];
    }];
}

- (void)toggleEnableHardwareEncode {
    [ZGApiSettingHelper.shared setSDKEnableHardwareEncode:!ZGApiSettingHelper.shared.enableHardwareEncode];
}

- (void)togglePreviewMirror {
    [ZGApiSettingHelper.shared setPreviewMirrorValue:!ZGApiSettingHelper.shared.previewMirror];
}

- (void)toggleUseFrontCam {
    [ZGApiSettingHelper.shared setUseFrontCamValue:!ZGApiSettingHelper.shared.useFrontCam];
}


@end

#endif
