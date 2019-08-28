//
//  ZGSVCViewController.m
//  LiveRoomPlayground-macOS
//
//  Created by Paaatrick on 2019/8/16.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCViewController.h"
#import "ZGSVCDemo.h"

static NSString *ZGSVCRoomID = @"ZGSVCRoomID";
static NSString *ZGSVCStreamID = @"ZGSVCStreamID";

@interface ZGSVCViewController () <ZGSVCDemoProtocol>
@property (weak) IBOutlet NSView *playView;
@property (weak) IBOutlet NSTextField *roomIDTextField;
@property (weak) IBOutlet NSTextField *streamIDTextField;
@property (weak) IBOutlet NSButton *startPublishButton;
@property (weak) IBOutlet NSButton *startPlayButton;
@property (weak) IBOutlet NSButton *enableSVCSwitch;
@property (weak) IBOutlet NSSegmentedControl *switchResolutionControl;
@property (weak) IBOutlet NSTextField *qualityLabel;

@property (assign) BOOL isPublishing;
@property (assign) BOOL isPlaying;

@property (strong) ZGSVCDemo *demo;

@end

@implementation ZGSVCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isPublishing = NO;
    self.isPlaying = NO;
}

- (void)viewWillAppear {
    [super viewWillAppear];
    self.roomIDTextField.stringValue = [self savedValueForKey:ZGSVCRoomID];
    self.streamIDTextField.stringValue = [self savedValueForKey:ZGSVCStreamID];
}

- (void)dealloc {
    if (self.isPublishing) {
        [self.demo stopPublish];
        [self.demo stopPreview];
    } else if (self.isPlaying) {
        [self.demo stopPlay];
    }
    [self.demo logoutRoom];
    self.demo = nil;
}

#pragma mark - Action

- (IBAction)startPublishAction:(NSButton *)sender {
    if (self.isPublishing) {
        [self.demo stopPublish];
        [self.demo stopPreview];
        [self.demo logoutRoom];
        self.demo = nil;
        
        self.startPlayButton.enabled = YES;
        self.switchResolutionControl.enabled = YES;
        
        self.isPublishing = !self.isPublishing;
        self.qualityLabel.stringValue = @"";
        sender.state = NSOffState;
        
    } else {
        if (!self.demo) {
            [self initSVCDemoWithAnchor:YES];
        }
            
        self.startPlayButton.enabled = NO;
        self.switchResolutionControl.enabled = NO;
        
        self.enableSVCSwitch.state = self.demo.openSVC;
        
        [self.demo loginRoom];
        [self.demo startPreview];
        [self.demo startPublish];
        
        self.isPublishing = !self.isPublishing;
        sender.state = NSOnState;
    }
}

- (IBAction)startPlayAction:(NSButton *)sender {
    if (self.isPlaying) {
        [self.demo stopPlay];
        [self.demo logoutRoom];
        self.demo = nil;
        
        self.startPublishButton.enabled = YES;
        self.enableSVCSwitch.enabled = YES;
        
        self.isPlaying = !self.isPlaying;
        self.qualityLabel.stringValue = @"";
        sender.state = NSOffState;
        
    } else {
        if (!self.demo) {
            [self initSVCDemoWithAnchor:NO];
        }
        
        self.startPublishButton.enabled = NO;
        self.enableSVCSwitch.enabled = NO;
        
        self.switchResolutionControl.selectedSegment = self.demo.streamLayerType;
        
        [self.demo loginRoom];
        [self.demo startPlay];
        
        self.isPlaying = !self.isPlaying;
        sender.state = NSOnState;
    }
}

- (IBAction)onSwitchSVC:(NSButton *)sender {
    [self.demo stopPublish];
    self.demo.openSVC = sender.state;
    [self.demo startPublish];
}

- (IBAction)onSwitchResolution:(NSSegmentedControl *)sender {
    self.demo.streamLayerType = sender.selectedSegment;
    [self.demo switchPlayStreamVideoLayer];
}

- (BOOL)initSVCDemoWithAnchor:(BOOL)isAnchor {
    NSString *roomID = self.roomIDTextField.stringValue.length != 0 ? self.roomIDTextField.stringValue : nil;
    NSString *streamID = self.streamIDTextField.stringValue.length != 0 ? self.streamIDTextField.stringValue : nil;
    
    if (!roomID || !streamID) {
        NSLog(@"❗️未填房间ID或流ID");
        return NO;
    }
    
    [self saveValue:self.roomIDTextField.stringValue forKey:ZGSVCRoomID];
    [self saveValue:self.streamIDTextField.stringValue forKey:ZGSVCStreamID];
    
    self.demo = [[ZGSVCDemo alloc] initWithRoomID:roomID streamID:streamID isAnchor:isAnchor];
    self.demo.delegate = self;
    return YES;
}

#pragma mark - Delegate

- (nonnull NSView *)getPlaybackView { 
    return self.playView;
}

- (void)onSVCPublishQualityUpdate:(NSString *)state {
    self.qualityLabel.stringValue = state;
}

- (void)onSVCPlayQualityUpdate:(NSString *)state {
    self.qualityLabel.stringValue = state;
}

- (void)onSVCVideoSizeChanged:(NSString *)state {
    NSLog(@"%@", state);
}

@end

#endif
