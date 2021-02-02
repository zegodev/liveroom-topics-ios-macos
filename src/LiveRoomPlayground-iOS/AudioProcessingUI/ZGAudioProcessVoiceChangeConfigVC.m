//
//  ZGAudioProcessVoiceChangeConfigVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessVoiceChangeConfigVC.h"
#import "ZGAudioProcessTopicConfigManager.h"
#import "ZGAudioProcessTopicHelper.h"

@interface ZGAudioProcessVoiceChangeConfigVC () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UISwitch *openVoiceChangerSwitch;
@property (weak, nonatomic) IBOutlet UIView *voiceChargerConfigContainerView;
@property (weak, nonatomic) IBOutlet UIPickerView *modePicker;
@property (weak, nonatomic) IBOutlet UILabel *customModeValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customModeValueSlider;
@property (weak, nonatomic) IBOutlet UISwitch *customVoiceChangerSwitch;

@property (nonatomic, copy) NSArray<ZGAudioProcessTopicConfigMode*> *voiceChangerOptionModes;

@end

@implementation ZGAudioProcessVoiceChangeConfigVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AudioProcessing" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAudioProcessVoiceChangeConfigVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.voiceChangerOptionModes = [ZGAudioProcessTopicHelper voiceChangerOptionModes];
    
    self.navigationItem.title = @"设置-变声";
    
    BOOL voiceChangerOpen = [ZGAudioProcessTopicConfigManager sharedInstance].voiceChangerOpen;
    self.voiceChargerConfigContainerView.hidden = !voiceChangerOpen;
    self.openVoiceChangerSwitch.on = voiceChangerOpen;
    self.modePicker.dataSource = self;
    self.modePicker.delegate = self;
    
    float voiceChangerParam = [ZGAudioProcessTopicConfigManager sharedInstance].voiceChangerParam;
    self.customModeValueSlider.minimumValue = -8.f;
    self.customModeValueSlider.maximumValue = 8.f;
    self.customModeValueSlider.value = voiceChangerParam;
    self.customModeValueLabel.text = @(voiceChangerParam).stringValue;
    
    [self.modePicker reloadAllComponents];
}

- (IBAction)customVoiceChangerValueChanged:(UISwitch *)sender {
    BOOL customVoiceChangerOpen = sender.isOn;
    [ZGAudioProcessTopicConfigManager sharedInstance].customVoiceChangerOpen = customVoiceChangerOpen;
    self.modePicker.userInteractionEnabled = !customVoiceChangerOpen;
}

- (IBAction)voiceChangerOpenValueChanged:(UISwitch *)sender {
    BOOL voiceChangerOpen = sender.isOn;
    [self.customVoiceChangerSwitch setOn:!voiceChangerOpen];
    self.modePicker.userInteractionEnabled = !self.customVoiceChangerSwitch.isOn;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setVoiceChangerOpen:voiceChangerOpen];
    self.voiceChargerConfigContainerView.hidden = !voiceChangerOpen;
}

- (IBAction)customModeValueChanged:(UISlider*)sender {
    float voiceChangerParam = sender.value;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setVoiceChangerParam:voiceChangerParam];
    self.customModeValueLabel.text = @(voiceChangerParam).stringValue;
    self.modePicker.userInteractionEnabled = !self.customVoiceChangerSwitch.isOn;
}

- (void)invalidateModePickerSelection {
    float voiceChangerParam = [ZGAudioProcessTopicConfigManager sharedInstance].voiceChangerParam;
    NSInteger selectionRow = NSNotFound;
    for (NSInteger i=0; i<self.voiceChangerOptionModes.count; i++) {
        ZGAudioProcessTopicConfigMode *mode = self.voiceChangerOptionModes[i];
        if (!mode.isCustom && mode.modeValue.floatValue == voiceChangerParam) {
            selectionRow = i;
        }
    }
    if (selectionRow != NSNotFound) {
        [self.modePicker selectRow:selectionRow inComponent:0 animated:NO];
    } else {
        // 选中到‘自定义’行
        ZGAudioProcessTopicConfigMode *customMode = [self customModeInModeList];
        NSInteger customModeIdx = [self.voiceChangerOptionModes indexOfObject:customMode];
        if (customModeIdx != NSNotFound) {
            [self.modePicker selectRow:customModeIdx inComponent:0 animated:NO];
        }
    }
}

- (ZGAudioProcessTopicConfigMode*)customModeInModeList {
    ZGAudioProcessTopicConfigMode *tarMode =nil;
    for (ZGAudioProcessTopicConfigMode *m in self.voiceChangerOptionModes) {
        if (m.isCustom) {
            tarMode = m;
            break;
        }
    }
    return tarMode;
}

#pragma mark - picker view dataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.voiceChangerOptionModes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.voiceChangerOptionModes[row].modeName;
}

#pragma mark - picker view delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([ZGAudioProcessTopicConfigManager sharedInstance].voiceChangerOpen) {
        ZGAudioProcessTopicConfigMode *mode = self.voiceChangerOptionModes[row];
        if (!mode.isCustom) {
            [ZGAudioProcessTopicConfigManager sharedInstance].voiceChangerType = mode.modeValue.unsignedIntegerValue;
        }
    }
}

@end
#endif
