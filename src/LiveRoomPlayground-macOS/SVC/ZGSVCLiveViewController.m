//
//  ZGSVCLiveViewController.m
//  LiveRoomPlayground-macOS
//
//  Created by Sky on 2018/11/13.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCLiveViewController.h"
#import "ZGSVCDemo.h"
#import "ZGRoomInfo.h"

@interface ZGSVCLiveViewController () <ZGSVCDemoProtocol>

@property (weak) IBOutlet NSView *mainPlayView;
@property (weak) IBOutlet NSTextField *mainPubStateLabel;
@property (weak) IBOutlet NSTextField *mainPlayStateLabel;
@property (weak) IBOutlet NSTextField *mainVideoSizeLabel;
@property (weak) IBOutlet NSButton *startPublishBtn;
@property (weak) IBOutlet NSTextField *roomNameTxf;

@property (weak) IBOutlet NSView *subPlayView;
@property (weak) IBOutlet NSTextField *subPublishLabel;
@property (weak) IBOutlet NSTextField *subPlayStateLabel;
@property (weak) IBOutlet NSTextField *subVideoSizeLabel;
@property (weak) IBOutlet NSButton *reqBoardcastBtn;


@property (weak) IBOutlet NSPopUpButton *svcStateBtn;
@property (weak) IBOutlet NSPopUpButton *videoLayerBtn;

@property (strong, nonatomic) ZGSVCDemo *demo;
@property (strong, nonatomic) NSArray *layerOptions;

@end

@implementation ZGSVCLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL isAnchor = self.role == ZEGO_ANCHOR;
    self.startPublishBtn.enabled = isAnchor;
    self.roomNameTxf.enabled = isAnchor;
    self.svcStateBtn.enabled = isAnchor;
    self.reqBoardcastBtn.enabled = !isAnchor;
    
    if (!isAnchor) {
        [self startPlay];
    }
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    [self.demo exit];
}

- (IBAction)startPublishAction:(id)sender {
    ZGRoomInfo *info = nil;
    NSString *roomName = self.roomNameTxf.stringValue;
    if (roomName.length > 0) {
        info = [ZGRoomInfo new];
        info.roomName = roomName;
    }
    self.demo = [ZGSVCDemo demoWithRole:ZEGO_ANCHOR openSVC:self.isOpenSVC roomInfo:info];
    self.demo.delegate = self;
    self.demo.videoLayer = self.currentVideoStreamLayer;
    
    [self.demo startPublish];
    
    self.startPublishBtn.enabled = NO;
}

- (void)startPlay {
    BOOL isOpenSVC = [self.roomInfo.roomID hasPrefix:@"#svc-on"];
    self.demo = [ZGSVCDemo demoWithRole:ZEGO_AUDIENCE openSVC:isOpenSVC roomInfo:self.roomInfo];
    self.demo.delegate = self;
    self.demo.videoLayer = self.currentVideoStreamLayer;
    
    [self.demo startPlay];
}

- (IBAction)requestBoardcastAction:(id)sender {
    if (self.demo.isPublishing) {
        [self.demo stopBoardCast];
    }
    else {
        [self.demo startBoardCast];
    }
}

- (IBAction)videoLayerChangeAction:(NSPopUpButton *)sender {
    self.demo.videoLayer = self.currentVideoStreamLayer;
}

#pragma mark - ZGSVCDemoProtocol

- (NSView *)getMainPlaybackView {
    return self.mainPlayView;
}

- (NSView *)getSubPlaybackView {
    return self.subPlayView;
}

- (void)onPublishQualityUpdate:(NSString *)state {
    NSTextField *label = self.role == ZEGO_ANCHOR ? self.mainPubStateLabel:self.subPublishLabel;
    label.stringValue = state;
}

- (void)onPlayQualityUpdate:(NSString *)state {
    NSTextField *label = self.role == ZEGO_ANCHOR ? self.mainPlayStateLabel:self.subPlayStateLabel;
    label.stringValue = state;
}

- (void)onVideoSizeChanged:(NSString *)state {
    NSTextField *label = self.role == ZEGO_ANCHOR ? self.mainVideoSizeLabel:self.subVideoSizeLabel;
    label.stringValue = state;
}

- (void)onPublishStateUpdate {
    BOOL isPublishing = self.demo.isPublishing;
    self.svcStateBtn.enabled = !isPublishing;
}

- (void)onBoardcastStateUpdate {
    BOOL isAnchor = self.role == ZEGO_ANCHOR;
    BOOL enableBoardcast = !isAnchor && !self.demo.isRequestBoardcast && (self.demo.isBoardcasting == self.demo.isPublishing);
    NSString *btnTitile = self.demo.isBoardcasting && self.demo.isPublishing ? NSLocalizedString(@"disconnect", nil):NSLocalizedString(@"connect", nil);
    self.reqBoardcastBtn.enabled = enableBoardcast;
    self.reqBoardcastBtn.title = btnTitile;
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

- (BOOL)isOpenSVC {
    return [self.svcStateBtn.selectedItem.title isEqualToString:@"SVC on"] ? YES:NO;
}

- (VideoStreamLayer)currentVideoStreamLayer {
    switch (self.videoLayerBtn.indexOfSelectedItem) {
        case 0:
            return VideoStreamLayer_Auto;
        case 1:
            return VideoStreamLayer_BaseLayer;
        case 2:
            return VideoStreamLayer_ExtendLayer;
        default:
            return -1;
    }
}

@end

#endif
