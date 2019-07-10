//
//  ZGSVCAnchorViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2018/11/12.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCAnchorViewController.h"
#import "ZGSVCDemo.h"
#import "ZGHelper.h"
#import "ZGRoomInfo.h"

@interface ZGSVCAnchorViewController () <ZGSVCDemoProtocol, UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *publishStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *playStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeStateLabel;
@property (weak, nonatomic) IBOutlet UIView *smallPlaybackView;
@property (weak, nonatomic) IBOutlet UIPickerView *layerPicker;

@property (strong, nonatomic) ZGSVCDemo *demo;
@property (assign ,nonatomic) BOOL exchangePlayback;
@property (strong, nonatomic) NSArray *layerOptions;

@end

@implementation ZGSVCAnchorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onExchangePlaybackView)];
    [self.smallPlaybackView addGestureRecognizer:tap];
    
    self.demo.delegate = self;
    [self.demo startPublish];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIApplication.sharedApplication.idleTimerDisabled = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    UIApplication.sharedApplication.idleTimerDisabled = NO;
}


#pragma mark - Public

- (void)setOpenSVC:(BOOL)openSVC useFrontCam:(BOOL)useFrontCam roomName:(NSString *)roomName {
    ZGRoomInfo *info = nil;
    if (roomName.length > 0) {
        info = [ZGRoomInfo new];
        info.roomName = roomName;
    }
    self.demo = [ZGSVCDemo demoWithRole:ZEGO_ANCHOR openSVC:openSVC roomInfo:info];
    self.demo.useFrontCam = useFrontCam;
    self.demo.videoLayer = VideoStreamLayer_Auto;
}

#pragma mark - Action

- (void)onExchangePlaybackView {
    self.exchangePlayback = !self.exchangePlayback;
}

- (IBAction)onExit:(id)sender {
    [self.demo exit];
    [self dismissViewControllerAnimated:YES completion:nil];
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
    self.publishStateLabel.text = state;
}

- (void)onPlayQualityUpdate:(NSString *)state {
    self.playStateLabel.text = state;
}

- (void)onVideoSizeChanged:(NSString *)state {
    self.sizeStateLabel.text = state;
}

- (void)onPublishStateUpdate {}

- (void)onBoardcastStateUpdate {
    if (self.demo.openSVC) {
        self.layerPicker.hidden = !self.demo.isBoardcasting;
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
