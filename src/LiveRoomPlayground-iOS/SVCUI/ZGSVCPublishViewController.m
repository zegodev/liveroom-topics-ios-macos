//
//  ZGSVCPublishViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/13.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCPublishViewController.h"
#import "ZGSVCDemo.h"

@interface ZGSVCPublishViewController () <ZGSVCDemoProtocol>

@property (weak, nonatomic) IBOutlet UILabel *publishQualityLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enableSVCSwitch;

@property (nonatomic, strong) ZGSVCDemo *demo;

@end

@implementation ZGSVCPublishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demo = [[ZGSVCDemo alloc] initWithRoomID:self.roomID streamID:self.streamID isAnchor:YES];
    self.demo.delegate = self;
    
    self.enableSVCSwitch.on = self.demo.openSVC;
    
    [self.demo loginRoom];
    [self.demo startPreview];
    [self.demo startPublish];
}

- (void)dealloc {
    [self.demo stopPublish];
    [self.demo stopPreview];
    [self.demo logoutRoom];
    self.demo = nil;
}

- (IBAction)onSwitchSVC:(UISwitch *)sender {
    [self.demo stopPublish];
    self.demo.openSVC = sender.on;
    [self.demo startPublish];
}

- (nonnull UIView *)getPlaybackView {
    return self.view;
}

// 推流质量信息更新
- (void)onSVCPublishQualityUpdate:(NSString *)state {
    self.publishQualityLabel.text = state;
}


@end

#endif
