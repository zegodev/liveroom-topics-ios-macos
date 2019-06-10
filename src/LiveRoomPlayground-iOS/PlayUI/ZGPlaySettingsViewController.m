//
//  ZGPlaySettingsViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/5/15.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGPlaySettingsViewController.h"
#import "ZGApiSettingHelper.h"

@interface ZGPlaySettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *viewModeLabel;
@property (weak, nonatomic) IBOutlet UILabel *volumeLabel;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UISwitch *hardwareDecodeSwitch;

@end

@implementation ZGPlaySettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self bindUI];
}

- (void)bindUI {
    ZGApiSettingHelper *sharedHelper = ZGApiSettingHelper.shared;
    
    Weakify(self);
    
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.playViewMode) callback:^(id value) {
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
    
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.playVolume) callback:^(id value) {
        Strongify(self);
        int volume = [value intValue];
        self.volumeSlider.value = volume;
        self.volumeLabel.text = @(volume).stringValue;
    }];
    
    [self bind:sharedHelper keyPath:ZGBindKeyPath(sharedHelper.enableHardwareDecode) callback:^(id value) {
        Strongify(self);
        [self.hardwareDecodeSwitch setOn:[value boolValue] animated:YES];
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
            [self showViewModeList];
        }
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            [self toggleEnableHardwareDecode];
        }
    }
}

#pragma mark - Actions

- (void)showViewModeList {
    NSArray<NSNumber*>* modeList = @[@(ZegoVideoViewModeScaleAspectFit),
                                     @(ZegoVideoViewModeScaleAspectFill),
                                     @(ZegoVideoViewModeScaleToFill)];
    
    NSArray<NSString*>* stringList = @[@"等比缩放，可能有黑边",
                                       @"等比缩放填充整个 View，可能有部分被裁减",
                                       @"填充整个View, 视频可能会变形"];
    
    NSInteger currentIndex = [modeList indexOfObject:@(ZGApiSettingHelper.shared.playViewMode)];
    
    [self showConfigSheet:@"选择播放模式" options:stringList currentIndex:currentIndex completion:^(NSInteger selectedIndex) {
        if (selectedIndex == NSNotFound) {
            return;
        }
        
        ZegoVideoViewMode mode = modeList[selectedIndex].intValue;
        [ZGApiSettingHelper.shared setPlayViewModeValue:mode];
    }];
}

- (IBAction)changePlayVolume {
    [ZGApiSettingHelper.shared setPlayVolumeValue:(int)self.volumeSlider.value];
}

- (void)toggleEnableHardwareDecode {
    [ZGApiSettingHelper.shared setSDKEnableHardwareDecode:!ZGApiSettingHelper.shared.enableHardwareDecode];
}

@end
