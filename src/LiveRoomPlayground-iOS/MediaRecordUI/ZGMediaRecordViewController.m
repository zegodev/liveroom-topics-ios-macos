//
//  ZGMediaRecordViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2018/12/18.
//  Copyright © 2018 Zego. All rights reserved.
//

#import "ZGMediaRecordViewController.h"
#import "ZegoMediaRecordDemo.h"

@interface ZGMediaRecordViewController () <ZegoMediaRecordDemoProtocol>

@property (strong, nonatomic) ZegoMediaRecordDemo *demo;
@property (weak, nonatomic) IBOutlet UIView *playbackView;
@property (weak, nonatomic) IBOutlet UIButton *startPublishBtn;
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (assign, nonatomic) ZegoAPIMediaRecordFormat recFormat;
@property (assign, nonatomic) ZegoAPIMediaRecordType recType;

@end

@implementation ZGMediaRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.demo = [[ZegoMediaRecordDemo alloc] init];
    [self.demo setDelegate:self];
    [self.demo startPreview];
}

#pragma mark - Actions

- (IBAction)onExit:(id)sender {
    [self.demo exit];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onPublish:(UIButton *)sender {
    if (self.demo.isPublishing) {
        [self.demo stopPublish];
    }
    else {
        [self.demo startPublish];
        self.startPublishBtn.enabled = NO;
    }
}

- (IBAction)onRecord:(UIButton *)sender {
    if (self.demo.isRecording) {
        [self.demo stopRecord];
        [self saveToAlbum];
    }
    else {
        ZegoMediaRecordConfig *config = [[ZegoMediaRecordConfig alloc] init];
        config.channel = ZEGOAPI_MEDIA_RECORD_CHN_MAIN;
        config.recordFormat = self.recFormat;
        config.recordType = self.recType;
        config.storagePath = self.path;
        config.interval = 1000;
        
        [self.demo setRecordConfig:config];
        [self.demo startRecord];
        self.startRecordBtn.enabled = NO;
    }
}

- (void)saveToAlbum {
    UISaveVideoAtPathToSavedPhotosAlbum(self.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo; {
    if (error) {
        NSLog(@"保存到相册出错!");
    }
    else {
        if (self.recType == ZEGOAPI_MEDIA_RECORD_MP4) {
            NSLog(@"保存到相册成功，请在相册中查看录制的视频!");
        }
        else {
            NSLog(@"相册不支持存储FLV，请在沙盒中查看录制的视频!");
        }
        NSLog(@"Media Record VideoPath:%@", videoPath);
    }
}

#pragma mark - Delegate

- (ZGView *)getPlaybackView {
    return self.playbackView;
}

- (void)onPublishStateChange:(BOOL)isPublishing {
    self.startPublishBtn.enabled = YES;
    [self.startPublishBtn setTitle:isPublishing ? @"Stop Publish":@"Start Publish" forState:UIControlStateNormal];
}

- (void)onRecordStateChange:(BOOL)isRecording {
    self.startRecordBtn.enabled = YES;
    [self.startRecordBtn setTitle:isRecording ? @"Stop Record":@"Start Record" forState:UIControlStateNormal];
}

- (void)onRecordStatusUpdateFromChannel:(ZegoAPIMediaRecordChannelIndex)index storagePath:(NSString *)path duration:(unsigned int)duration fileSize:(unsigned int)size {
    NSLog(@"Rec Duration:%ul, FileSize:%ul", duration, size);
}

#pragma mark - Access

- (NSString *)path {
    NSString *doc = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *format = self.recFormat == ZEGOAPI_MEDIA_RECORD_FLV ? @"flv":@"mp4";
    NSString *path = [doc stringByAppendingPathComponent:[NSString stringWithFormat:@"MediaRecorder.%@", format]];
    NSLog(@"VIDEO PATH:%@", path);
    return path;
}

- (void)setRecordFormat:(int)format type:(int)type {
    self.recFormat = format;
    self.recType = type;
}

@end
