//
//  ZegoMediaRecordViewController.m
//  LiveRoomPlayground-macOS
//
//  Created by Sky on 2018/12/17.
//  Copyright © 2018 Zego. All rights reserved.
//

#import "ZegoMediaRecordViewController.h"
#import "ZegoMediaRecordDemo.h"

@interface ZegoMediaRecordViewController () <ZegoMediaRecordDemoProtocol>

@property (strong, nonatomic) ZegoMediaRecordDemo *demo;
@property (copy, nonatomic) NSString *path;

@property (weak) IBOutlet NSView *playView;
@property (weak) IBOutlet NSButton *publishBtn;
@property (weak) IBOutlet NSPopUpButton *recordFormatBtn;
@property (weak) IBOutlet NSPopUpButton *recordTypeBtn;
@property (weak) IBOutlet NSButton *pathSelectBtn;
@property (weak) IBOutlet NSTextField *pathLabel;
@property (weak) IBOutlet NSButton *startRecBtn;
@property (weak) IBOutlet NSButton *stopRecButton;

@end

@implementation ZegoMediaRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.demo = [[ZegoMediaRecordDemo alloc] init];
    [self.demo setDelegate:self];
    [self.demo startPreview];
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    [self.demo exit];
}

- (IBAction)startRec:(id)sender {
    if (self.path.length < 1) {
        return;
    }
    
    ZegoMediaRecordConfig *config = [[ZegoMediaRecordConfig alloc] init];
    config.channel = ZEGOAPI_MEDIA_RECORD_CHN_MAIN;
    config.recordFormat = [self recFormat];
    config.recordType = [self recType];
    config.storagePath = self.path;
    config.interval = 1000;
    
    [self.demo setRecordConfig:config];
    [self.demo startRecord];
}

- (IBAction)stopRec:(id)sender {
    [self.demo stopRecord];
    [NSWorkspace.sharedWorkspace openFile:[self.path stringByDeletingLastPathComponent]];
}

- (IBAction)publish:(NSButton *)sender {
    if (sender.state == NSControlStateValueOn) {
        [self.demo startPublish];
    }
    else {
        [self.demo stopPublish];
    }
}

- (IBAction)selectPath:(id)sender {
    __weak typeof(self)weakself = self;
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:@"ZGMediaRec"];
    [panel setMessage:@"Choose the path to save the Record"];
    [panel setAllowedFileTypes:@[@"flv",@"mp4"]];
    [panel setAllowsOtherFileTypes:NO];
    [panel setCanCreateDirectories:YES];
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result){
        __strong typeof(weakself)strongself = weakself;
        if (!strongself) {
            return;
        }
        if (result == NSModalResponseOK) {
            NSString *path = panel.URL.path;
            strongself.path = path;
            strongself.pathLabel.stringValue = path;
        }
    }];
}

#pragma mark - Delegate

- (ZGView *)getPlaybackView {
    return self.playView;
}

- (void)onPublishStateChange:(BOOL)isPublishing {
    self.publishBtn.state = isPublishing ? NSControlStateValueOn:NSControlStateValueOff;
    self.publishBtn.enabled = YES;
}

- (void)onRecordStateChange:(BOOL)isRecording {
    if (isRecording) {
        self.startRecBtn.enabled = NO;
        self.stopRecButton.enabled = YES;
        self.pathSelectBtn.enabled = NO;
        self.recordFormatBtn.enabled = NO;
        self.recordTypeBtn.enabled = NO;
    }
    else {
        self.startRecBtn.enabled = YES;
        self.stopRecButton.enabled = NO;
        self.pathSelectBtn.enabled = YES;
        self.recordFormatBtn.enabled = YES;
        self.recordTypeBtn.enabled = YES;
    }
}

- (void)onRecordStatusUpdateFromChannel:(ZegoAPIMediaRecordChannelIndex)index storagePath:(NSString *)path duration:(unsigned int)duration fileSize:(unsigned int)size {
    NSLog(@"Rec Duration:%ul, FileSize:%ul", duration, size);
}


#pragma mark - Access

- (void)setPath:(NSString *)path {
    _path = path;
    self.startRecBtn.enabled = path.length > 0;
}

- (ZegoAPIMediaRecordFormat)recFormat {
    NSString *title = self.recordFormatBtn.selectedItem.title;
    if ([title isEqualToString:@"FLV"]) {
        return ZEGOAPI_MEDIA_RECORD_FLV;
    }
    else {
        return ZEGOAPI_MEDIA_RECORD_MP4;
    }
}

- (ZegoAPIMediaRecordType)recType {
    NSString *title = self.recordTypeBtn.selectedItem.title;
    if ([title isEqualToString:@"Audio Only"]) {
        return ZEGOAPI_MEDIA_RECORD_AUDIO;
    }
    else if ([title isEqualToString:@"Video Only"]) {
        return ZEGOAPI_MEDIA_RECORD_VIDEO;
    }
    else {
        return ZEGOAPI_MEDIA_RECORD_BOTH;
    }
}

@end
