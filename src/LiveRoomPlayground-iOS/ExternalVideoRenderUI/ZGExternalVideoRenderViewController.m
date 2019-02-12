//
//  ZGExternalVideoRenderViewController.m
//  LiveRoomPlayground
//
//  Created by Sky on 2019/1/29.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoRenderViewController.h"
#import "ZGExternalVideoRenderDemo.h"

@interface ZGExternalVideoRenderViewController () <ZGExternalVideoRenderDemoProtocol>

@property (weak, nonatomic) IBOutlet UIButton *liveBtn;
@property (weak, nonatomic) IBOutlet UIView *mainVideoView;
@property (weak, nonatomic) IBOutlet UIView *subVideoView;

@property (strong, nonatomic) ZGExternalVideoRenderDemo *demo;

@end

@implementation ZGExternalVideoRenderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.demo = [ZGExternalVideoRenderDemo new];
    self.demo.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (IBAction)onLive:(id)sender {
    if (self.demo.isLive) {
        [self.demo stop];
    }
    else {
        self.liveBtn.enabled = NO;
        [self.demo startLive];
    }
}

- (IBAction)onExit:(id)sender {
    [self.demo stop];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - ZGExternalVideoRenderDemoProtocol

- (ZGView *)getMainPlaybackView {
    return self.mainVideoView;
}

- (ZGView *)getSubPlaybackView {
    return self.subVideoView;
}

- (void)onLiveStateUpdate {
    self.liveBtn.enabled = YES;
    
    NSString *btnTitle = self.demo.isLive ? @"StopLive":@"StartLive";
    [self.liveBtn setTitle:btnTitle forState:UIControlStateNormal];
}

@end
