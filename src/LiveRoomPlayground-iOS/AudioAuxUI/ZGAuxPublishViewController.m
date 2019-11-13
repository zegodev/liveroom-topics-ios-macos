//
//  ZGAuxViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_AudioAux

#import "ZGAuxPublishViewController.h"
#import "ZGAuxDemo.h"

@interface ZGAuxPublishViewController () <ZGAuxDemoProtocol>


@property (weak, nonatomic) IBOutlet UILabel *publishQualityLabel;
@property (weak, nonatomic) IBOutlet UIButton *playBGMButton;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UISwitch *muteAuxSwitch;
@property (weak, nonatomic) IBOutlet UIView *previewView;

@property (nonatomic, strong) ZGAuxDemo *demo;

@property (nonatomic, assign) BOOL isAuxing;

@end

@implementation ZGAuxPublishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demo = [[ZGAuxDemo alloc] initWithRoomID:self.roomID streamID:self.streamID isAnchor:YES];
    self.demo.delegate = self;
    
    [self.demo loginRoom];
    [self.demo startPreview];
    [self.demo startPublish];
    self.isAuxing = NO;
}

- (void)dealloc {
    [self.demo stopPublish];
    [self.demo stopPreview];
    [self.demo logoutRoom];
    self.demo = nil;
}

#pragma mark - Actions

- (IBAction)onPlayBGM:(UIButton *)sender {
    self.isAuxing = !self.isAuxing;
    [self.demo onSwitchAux:self.isAuxing];
    sender.selected = self.isAuxing;
}

- (IBAction)onChangeVolume:(UISlider *)sender {
    int volume = sender.value * 100;
    [self.demo changeAuxVolume:volume];
}

- (IBAction)onSwitchMuteAux:(UISwitch *)sender {
    [self.demo onSwitchMuteAux:sender.on];
}

- (nonnull UIView *)getPlaybackView {
    return self.previewView;
}

// 推流状态回调
- (void)onAuxPublishStateUpdate:(NSString *)state {
    self.title = state;
}

// 推流质量信息更新回调
- (void)onAuxPublishQualityUpdate:(NSString *)state {
    self.publishQualityLabel.text = state;
}



@end

#endif
