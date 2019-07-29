//
//  ZGMediaPlayerViewController.m
//  LiveRoomPlayground
//
//  Created by Randy Qiu on 2018/9/27.
//  Copyright © 2018年 Zego. All rights reserved.
//

#ifdef _Module_MediaPlayer

#import "ZGMediaPlayerViewController.h"
#import "ZGMediaPlayerDemo.h"
#import "ZGApiManager.h"

@interface ZGMediaPlayerViewController () <ZGMediaPlayerDemoDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *playerState;
@property (weak, nonatomic) IBOutlet UILabel *publishInfo;
@property (weak, nonatomic) IBOutlet UIView *videoView;

@property (weak, nonatomic) IBOutlet UISlider *progressSlider;
@property (weak, nonatomic) IBOutlet UILabel *progressText;
@property (weak, nonatomic) IBOutlet UISwitch *repeatSwitch;

@property (weak, nonatomic) IBOutlet UIPickerView *audioTrackPicker;

@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

@property (strong) ZGMediaPlayerDemo* demo;

@end

@implementation ZGMediaPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.demo = [ZGMediaPlayerDemo new];
    self.demo.delegate = self;
    
    self.audioTrackPicker.hidden = YES;
    [self.volumeSlider setValue:50];
    [self.demo setVolume:50];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self.demo stop];
    self.demo = nil;
}

#pragma mark - ZGMediaPlayerDemoDelegate

- (void)onPlayerState:(NSString *)state {
    [self.playerState setText:state];
}

- (void)onPlayerProgress:(long)current max:(long)max desc:(NSString *)desc {
    [self.progressSlider setValue:(float)current];
    [self.progressSlider setMaximumValue:(float)max];
    [self.progressText setText:desc];
}

- (void)onPlayerStop {
    [self.progressSlider setValue:0];
    [self.progressText setText:@"-/-"];
}

- (void)onPublishState:(NSString *)state {
    [self.publishInfo setText:state];
}

- (void)onGetAudioStreamCount:(int)count {
    NSLog(@"%s, %d", __func__, count);
    self.audioTrackPicker.hidden = (count <= 1);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)onProgressSliderDidChange:(id)sender {
    NSLog(@"%s", __func__);
    UISlider* slider = (UISlider*)sender;
    [self.demo seekTo:(long)slider.value];
}

- (IBAction)onMicSwitch:(id)sender {
    NSLog(@"%s", __func__);
    UISwitch* mic = (UISwitch*)sender;
    [[ZGApiManager api] enableMic:mic.on];
}

- (IBAction)onPlayTypeSwitch:(id)sender {
    NSLog(@"%s", __func__);
    
    UISwitch* s = (UISwitch*)sender;
    [self.demo setPlayerType:(s.on ? MediaPlayerTypeAux : MediaPlayerTypePlayer)];
}

- (IBAction)onVolumeDidChange:(id)sender {
    NSLog(@"%s", __func__);
    UISlider* slider = (UISlider*)sender;
    [self.demo setVolume:(int)slider.value];
}

- (IBAction)play:(id)sender {
    [self.demo setVideoView:self.videoView];
    [self.demo startPlaying:self.url repeat:self.repeatSwitch.on];
}

- (IBAction)stop:(id)sender {
    [self.demo stop];
}

- (IBAction)pause:(id)sender {
    [self.demo pause];
}

- (IBAction)resume:(id)sender {
    [self.demo resume];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 2;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%ld", (long)row];
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self.demo setAudioStream:(int)row];
}

@end

#endif
