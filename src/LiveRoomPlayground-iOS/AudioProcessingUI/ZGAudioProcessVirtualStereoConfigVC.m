//
//  ZGAudioProcessVirtualStereoConfigVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessVirtualStereoConfigVC.h"
#import "ZGAudioProcessTopicConfigManager.h"
#import "ZGAudioProcessTopicHelper.h"

@interface ZGAudioProcessVirtualStereoConfigVC ()

@property (weak, nonatomic) IBOutlet UISwitch *openVirtaulStereoSwitch;
@property (weak, nonatomic) IBOutlet UIView *virtaulStereoConfigContainerView;
@property (weak, nonatomic) IBOutlet UILabel *angleValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *angleValueSlider;

@end

@implementation ZGAudioProcessVirtualStereoConfigVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AudioProcessing" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAudioProcessVirtualStereoConfigVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"设置-立体声";
    
    BOOL virtualStereoOpen = [ZGAudioProcessTopicConfigManager sharedInstance].virtualStereoOpen;
    
    self.virtaulStereoConfigContainerView.hidden = !virtualStereoOpen;
    self.openVirtaulStereoSwitch.on = virtualStereoOpen;
    
    float virtualStereoAngle = [ZGAudioProcessTopicConfigManager sharedInstance].virtualStereoAngle;
    self.angleValueSlider.minimumValue = 0;
    self.angleValueSlider.maximumValue = 180;
    self.angleValueSlider.value = virtualStereoAngle;
    self.angleValueLabel.text = @(virtualStereoAngle).stringValue;
}

- (IBAction)openVirtaulStereoValueChanged:(UISwitch*)sender {
    float virtualStereoOpen = sender.isOn;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setVirtualStereoOpen:virtualStereoOpen];
    self.virtaulStereoConfigContainerView.hidden = !virtualStereoOpen;
}

- (IBAction)angleValueChanged:(UISlider*)sender {
    float virtualStereoAngle = sender.value;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setVirtualStereoAngle:virtualStereoAngle];
    self.angleValueLabel.text = @(virtualStereoAngle).stringValue;
}

@end
#endif
