//
//  ZGExternalVideoRenderViewController.m
//  LiveRoomPlayground
//
//  Created by Sky on 2019/1/29.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoRender

#import "ZGExternalVideoRenderViewController.h"
#import "ZGExternalVideoRenderDemo.h"

@interface ZGExternalVideoRenderViewController () <ZGExternalVideoRenderDemoProtocol>

@property (weak) IBOutlet NSView *mainVideoView;
@property (weak) IBOutlet NSView *subVideoView;
@property (weak) IBOutlet NSButton *liveBtn;

@property (strong, nonatomic) ZGExternalVideoRenderDemo *demo;

@end

@implementation ZGExternalVideoRenderViewController

- (void)viewDidAppear {
    [super viewDidAppear];
    self.demo = [ZGExternalVideoRenderDemo new];
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

#endif
