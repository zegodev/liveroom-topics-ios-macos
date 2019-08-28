//
//  ZGSVCPlayViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/13.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCPlayViewController.h"
#import "ZGSVCDemo.h"

@interface ZGSVCPlayViewController () <ZGSVCDemoProtocol>
@property (weak, nonatomic) IBOutlet UILabel *playQualityLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchResolutionControl;

@property (nonatomic, strong) ZGSVCDemo *demo;

@end

@implementation ZGSVCPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demo = [[ZGSVCDemo alloc] initWithRoomID:self.roomID streamID:self.streamID isAnchor:NO];
    self.demo.delegate = self;
    
    self.switchResolutionControl.selectedSegmentIndex = self.demo.streamLayerType;
    
    [self.demo loginRoom];
    [self.demo startPlay];
}

- (void)dealloc {
    [self.demo stopPlay];
    [self.demo logoutRoom];
    self.demo = nil;
}

- (IBAction)onSwitchResolution:(UISegmentedControl *)sender {
    self.demo.streamLayerType = sender.selectedSegmentIndex;
    [self.demo switchPlayStreamVideoLayer];
}

- (nonnull UIView *)getPlaybackView {
    return self.view;
}

// 拉流质量信息更新
- (void)onSVCPlayQualityUpdate:(NSString *)state {
    self.playQualityLabel.text = state;
}

// 分辨率切换回调通知
- (void)onSVCVideoSizeChanged:(NSString *)state {
    [ZegoHudManager showMessage:state];
}


@end

#endif
