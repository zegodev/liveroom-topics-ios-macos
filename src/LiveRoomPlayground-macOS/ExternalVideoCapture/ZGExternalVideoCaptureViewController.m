//
//  ZGExternalVideoCaptureViewController.m
//  LiveRoomPlayground-macOS
//
//  Created by Sky on 2019/1/25.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoCaptureViewController.h"
#import "ZGExternalVideoCaptureDemo.h"

@interface ZGExternalVideoCaptureViewController () <ZGExternalVideoCaptureDemoProtocol>

@property (weak) IBOutlet NSView *mainVideoView;
@property (weak) IBOutlet NSView *subVideoView;
@property (weak) IBOutlet NSPopUpButton *sourceTypeBtn;
@property (weak) IBOutlet NSButton *liveBtn;

@property (strong, nonatomic) ZGExternalVideoCaptureDemo *demo;

@end

@implementation ZGExternalVideoCaptureViewController

- (void)viewDidAppear {
    [super viewDidAppear];
    self.demo = [ZGExternalVideoCaptureDemo new];
    self.demo.delegate = self;
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    [self.demo stop];
    self.demo = nil;
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

- (IBAction)onSourceTypeChange:(NSPopUpButton *)sender {
    [self.demo setCaptureSourceType:sender.indexOfSelectedItem];
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
    self.liveBtn.title = btnTitle;
}

@end
