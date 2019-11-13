//
//  ZGAudioProcessReverbConfigVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessReverbConfigVC.h"
#import "ZGAudioProcessTopicConfigManager.h"
#import "ZGAudioProcessTopicHelper.h"

@interface ZGAudioProcessReverbConfigVC () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UISwitch *openReverbSwitch;
@property (weak, nonatomic) IBOutlet UIView *reverbConfigContainerView;
@property (weak, nonatomic) IBOutlet UIPickerView *modePicker;
@property (weak, nonatomic) IBOutlet UILabel *customRoomSizeValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customRoomSizeSlider;
@property (weak, nonatomic) IBOutlet UILabel *customDryWetRatioValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customDryWetRatioSlider;
@property (weak, nonatomic) IBOutlet UILabel *customDampingValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customDampingSlider;
@property (weak, nonatomic) IBOutlet UILabel *customReverberanceValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customReverberanceSlider;

@property (nonatomic, copy) NSArray<ZGAudioProcessTopicConfigMode*> *reverbOptionModes;

@end

@implementation ZGAudioProcessReverbConfigVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AudioProcessing" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAudioProcessReverbConfigVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.reverbOptionModes = [ZGAudioProcessTopicHelper reverbOptionModes];
    self.navigationItem.title = @"设置-混响";
    
    BOOL reverbOpen = [ZGAudioProcessTopicConfigManager sharedInstance].reverbOpen;
    
    self.reverbConfigContainerView.hidden = !reverbOpen;
    self.openReverbSwitch.on = reverbOpen;
    self.modePicker.delegate = self;
    self.modePicker.dataSource = self;
    
    float customReverbRoomSize = [ZGAudioProcessTopicConfigManager sharedInstance].customReverbRoomSize;
    self.customRoomSizeSlider.minimumValue = 0.0f;
    self.customRoomSizeSlider.maximumValue = 1.0f;
    self.customRoomSizeSlider.value = customReverbRoomSize;
    self.customRoomSizeValueLabel.text = @(customReverbRoomSize).stringValue;
    
    float customDryWetRatio = [ZGAudioProcessTopicConfigManager sharedInstance].customDryWetRatio;
    self.customDryWetRatioSlider.minimumValue = 0.0f;
    self.customDryWetRatioSlider.maximumValue = 2.0f;
    self.customDryWetRatioSlider.value = customDryWetRatio;
    self.customDryWetRatioValueLabel.text = @(customDryWetRatio).stringValue;
    
    float customDamping = [ZGAudioProcessTopicConfigManager sharedInstance].customDamping;
    self.customDampingSlider.minimumValue = 0.0f;
    self.customDampingSlider.maximumValue = 2.0f;
    self.customDampingSlider.value = customDamping;
    self.customDampingValueLabel.text = @(customDamping).stringValue;
    
    float customReverberance =[ZGAudioProcessTopicConfigManager sharedInstance].customReverberance;
    self.customReverberanceSlider.minimumValue = 0.0f;
    self.customReverberanceSlider.maximumValue = 0.5f;
    self.customReverberanceSlider.value = customReverberance;
    self.customReverberanceValueLabel.text = @(customReverberance).stringValue;
}

- (IBAction)reverbValueChanged:(UISwitch*)sender {
    BOOL reverbOpen = sender.isOn;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setReverbOpen:reverbOpen];
    self.reverbConfigContainerView.hidden = !reverbOpen;
}

- (IBAction)customRoomSizeValueChanged:(UISlider*)sender {
    float customReverbRoomSize = sender.value;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setCustomReverbRoomSize:customReverbRoomSize];
    self.customRoomSizeValueLabel.text = @(customReverbRoomSize).stringValue;
}

- (IBAction)customDryWetRationValueChanged:(UISlider*)sender {
    float customDryWetRatio = sender.value;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setCustomDryWetRatio:customDryWetRatio];
    self.customDryWetRatioValueLabel.text = @(customDryWetRatio).stringValue;
}

- (IBAction)customDampingValueChanged:(UISlider*)sender {
    float customDamping = sender.value;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setCustomDamping:customDamping];
    self.customDampingValueLabel.text = @(customDamping).stringValue;
}

- (IBAction)customReverberanceChanged:(UISlider*)sender {
    float customReverberance = sender.value;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setCustomReverberance:customReverberance];
    self.customReverberanceValueLabel.text = @(customReverberance).stringValue;
}

#pragma mark - picker view dataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.reverbOptionModes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.reverbOptionModes[row].modeName;
}

#pragma mark - picker view delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([ZGAudioProcessTopicConfigManager sharedInstance].reverbOpen) {
        ZGAudioProcessTopicConfigMode *mode = self.reverbOptionModes[row];
        if (!mode.isCustom) {
            [[ZGAudioProcessTopicConfigManager sharedInstance] setReverbMode:[mode.modeValue unsignedIntegerValue]];
        } else {
            [[ZGAudioProcessTopicConfigManager sharedInstance] setReverbMode:NSNotFound];
        }
    }
}

@end
#endif
