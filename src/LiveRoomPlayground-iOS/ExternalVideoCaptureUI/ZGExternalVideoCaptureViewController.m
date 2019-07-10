//
//  ZGExternalVideoCaptureViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoCapture

#import "ZGExternalVideoCaptureViewController.h"
#import "ZGExternalVideoCaptureDemo.h"

@interface ZGExternalVideoCaptureViewController () <ZGExternalVideoCaptureDemoProtocol>

@property (weak, nonatomic) IBOutlet UIButton *liveBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sourceTypeSelector;
@property (weak, nonatomic) IBOutlet UIView *mainVideoView;
@property (weak, nonatomic) IBOutlet UIView *subVideoView;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;

@property (strong, nonatomic) ZGExternalVideoCaptureDemo *demo;

@end

@implementation ZGExternalVideoCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.demo = [ZGExternalVideoCaptureDemo new];
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

- (IBAction)onSourceTypeChange:(UISegmentedControl *)sender {
    [self.demo setCaptureSourceType:sender.selectedSegmentIndex];
    
    BOOL isScreen = sender.selectedSegmentIndex == 3;
    self.tipLabel.hidden = !isScreen;
}

#pragma mark - ZGExternalVideoCaptureDemoProtocol

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

#endif
