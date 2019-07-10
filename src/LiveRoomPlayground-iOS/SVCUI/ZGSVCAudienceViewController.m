//
//  ZGSVCAudienceViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2018/11/12.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCAudienceViewController.h"
#import "ZGRoomInfo.h"
#import "ZGSVCDemo.h"

@interface ZGSVCAudienceViewController () <ZGSVCDemoProtocol>

@property (weak, nonatomic) IBOutlet UILabel *pubStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *playStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeStateLabel;
@property (weak, nonatomic) IBOutlet UIButton *requestBtn;
@property (weak, nonatomic) IBOutlet UIView *smallPlaybackView;
@property (weak, nonatomic) IBOutlet UIPickerView *layerPicker;

@property (strong, nonatomic) ZGSVCDemo *demo;
@property (assign ,nonatomic) BOOL exchangePlayback;
@property (strong, nonatomic) NSArray *layerOptions;

@end

@implementation ZGSVCAudienceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onExchangePlaybackView)];
    [self.smallPlaybackView addGestureRecognizer:tap];
    
    BOOL openSVC = [self.roomInfo.roomID hasPrefix:@"#svc-on"];
    
    self.demo = [ZGSVCDemo demoWithRole:ZEGO_AUDIENCE openSVC:openSVC roomInfo:self.roomInfo];
    self.demo.videoLayer = VideoStreamLayer_Auto;
    self.demo.useFrontCam = YES;
    self.demo.delegate = self;
    [self.demo startPlay];
}


#pragma mark - Actions

- (void)onExchangePlaybackView {
    self.exchangePlayback = !self.exchangePlayback;
}

- (IBAction)onExitAction:(id)sender {
    [self.demo exit];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onBroadcastAction:(id)sender {
    if (self.demo.isPublishing) {
        [self.demo stopBoardCast];
    }
    else {
        [self.demo startBoardCast];
    }
}

- (IBAction)onFrontCamValueChanged:(UISwitch *)sender {
    self.demo.useFrontCam = sender.isOn;
}


#pragma mark - Picker

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.layerOptions.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSDictionary *config = self.layerOptions[row];
    NSString *title = config[@"title"];
    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSDictionary *config = self.layerOptions[row];
    VideoStreamLayer layer = [config[@"config"] intValue];
    self.demo.videoLayer = layer;
}


#pragma mark - ZGSVCDemoProtocol

- (UIView *)getMainPlaybackView {
    return self.exchangePlayback ? self.smallPlaybackView:self.view;
}

- (UIView *)getSubPlaybackView {
    return self.exchangePlayback ? self.view:self.smallPlaybackView;
}

- (void)onPublishQualityUpdate:(NSString *)state {
    self.pubStateLabel.text = state;
}

- (void)onPlayQualityUpdate:(NSString *)state {
    self.playStateLabel.text = state;
}

- (void)onVideoSizeChanged:(NSString *)state {
    self.sizeStateLabel.text = state;
}

- (void)onPublishStateUpdate {}

- (void)onBoardcastStateUpdate {
    BOOL enableBoardcast = (self.demo.isPublishing == self.demo.isBoardcasting) && !self.demo.isRequestBoardcast;
    NSString *btnTitile = self.demo.isPublishing && self.demo.isBoardcasting ? NSLocalizedString(@"断开连麦", nil):NSLocalizedString(@"请求连麦", nil);
    self.requestBtn.enabled = enableBoardcast;
    [self.requestBtn setTitle:btnTitile forState:UIControlStateNormal];
    if (self.demo.openSVC) {
        self.layerPicker.hidden = !(self.demo.isBoardcasting && self.demo.isPublishing);
    }
}

#pragma mark - Accessor

- (NSArray *)layerOptions {
    if (_layerOptions == nil) {
        _layerOptions = @[
                          @{@"title":@"LayerAuto",@"config":@(VideoStreamLayer_Auto)},
                          @{@"title":@"LayerBase",@"config":@(VideoStreamLayer_BaseLayer)},
                          @{@"title":@"LayerExtend",@"config":@(VideoStreamLayer_ExtendLayer)}
                          ];
    }
    return _layerOptions;
}

- (void)setExchangePlayback:(BOOL)exchangePlayback {
    if (_exchangePlayback == exchangePlayback) {
        return;
    }
    _exchangePlayback = exchangePlayback;
    [self.demo refreshPlaybackView];
}


@end

#endif
