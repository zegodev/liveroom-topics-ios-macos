//
//  ZGSoundLevelConfigViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/9/4.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_SoundLevel

#import "ZGSoundLevelConfigViewController.h"

@interface ZGSoundLevelConfigViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enableFrequencyMonitorSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *enableSoundLevelMonitorSwitch;
@property (weak, nonatomic) IBOutlet UISlider *frequencySlider;
@property (weak, nonatomic) IBOutlet UISlider *soundLevelSlider;
@property (weak, nonatomic) IBOutlet UILabel *frequencyMonitorCycleLabel;
@property (weak, nonatomic) IBOutlet UILabel *soundLevelMonitorCycleLabel;

@end

@implementation ZGSoundLevelConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    self.enableFrequencyMonitorSwitch.on = self.manager.enableFrequencySpectrumMonitor;
    self.enableSoundLevelMonitorSwitch.on = self.manager.enableSoundLevelMonitor;
    self.frequencyMonitorCycleLabel.text = [NSString stringWithFormat:@"监控周期：%dms", self.manager.frequencySpectrumMonitorCycle];
    self.soundLevelMonitorCycleLabel.text = [NSString stringWithFormat:@"监控周期：%dms", self.manager.soundLevelMonitorCycle];
    self.frequencySlider.value = self.manager.frequencySpectrumMonitorCycle;
    self.soundLevelSlider.value = self.manager.soundLevelMonitorCycle;
}

#pragma mark - FrequencySpectrum Setting Actions

- (IBAction)enableFrequencySpectrumMonitor:(UISwitch *)sender {
    self.manager.enableFrequencySpectrumMonitor = sender.on;
}

- (IBAction)setFrequencySpectrumMonitorCycle:(UISlider *)sender {
    self.manager.frequencySpectrumMonitorCycle = (unsigned int)sender.value;
}

- (IBAction)didFrequencySpectrumMonitorCycleChanged:(UISlider *)sender {
    self.frequencyMonitorCycleLabel.text = [NSString stringWithFormat:@"监控周期：%dms", (unsigned int)sender.value];
}

#pragma mark - SoundLevel Setting Actions

- (IBAction)enableSoundLevelMonitor:(UISwitch *)sender {
    self.manager.enableSoundLevelMonitor = sender.on;
}

- (IBAction)setSoundLevelMonitorCycle:(UISlider *)sender {
    self.manager.soundLevelMonitorCycle = (unsigned int)sender.value;
}

- (IBAction)didSoundLevelMonitorCycleChanged:(UISlider *)sender {
    self.soundLevelMonitorCycleLabel.text = [NSString stringWithFormat:@"监控周期：%dms", (unsigned int)sender.value];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}


@end

#endif
