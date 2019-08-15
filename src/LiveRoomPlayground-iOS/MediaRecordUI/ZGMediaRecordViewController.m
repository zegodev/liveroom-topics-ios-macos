//
//  ZGMediaRecordViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/9.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGMediaRecordViewController.h"
#import "ZegoMediaRecordDemo.h"
#import <AVKit/AVKit.h>

@interface ZGMediaRecordViewController () <ZegoMediaRecordDemoProtocol>

@property (strong, nonatomic) ZegoMediaRecordDemo *demo;
@property (weak, nonatomic) IBOutlet UIView *publishView;
@property (weak, nonatomic) IBOutlet UIView *configView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *formatSegment;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UILabel *recordStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *publishStateLabel;
@property (assign, nonatomic) ZegoAPIMediaRecordFormat recordFormat;
@property (assign, nonatomic) ZegoAPIMediaRecordType recordType;
@property (nonatomic, copy) NSString *path;


@end

@implementation ZGMediaRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demo = [[ZegoMediaRecordDemo alloc] init];
    [self.demo setDelegate:self];
    self.recordButton.enabled = NO;
    self.recordStateLabel.hidden = YES;
    self.publishStateLabel.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.demo startPreview];
    [self.demo startPublish];
}

- (void)dealloc {
    [self.demo exit];
}

- (IBAction)onRecord:(UIButton *)sender {
    if (self.demo.isRecording) {
        [self.demo stopRecord];
        self.formatSegment.enabled = YES;
        self.typeSegment.enabled = YES;
        
        [self saveToAlbum];
        
        // AVPlayer 不支持播放 FLV 格式，请在沙盒中查看
        if (self.recordFormat == ZEGOAPI_MEDIA_RECORD_MP4) {
            if (self.demo.isPublishing) {
                [self.demo stopPublish];
            }
            [self.demo stopPreview];
            
            [self playRecordedVideo];
        }
    } else {
        self.recordFormat = self.formatSegment.selectedSegmentIndex + 1;
        self.recordType = self.typeSegment.selectedSegmentIndex + 1;
        self.recordButton.enabled = NO;
        self.formatSegment.enabled = NO;
        self.typeSegment.enabled = NO;
        
        ZegoMediaRecordConfig *config = [[ZegoMediaRecordConfig alloc] init];
        config.channel = ZEGOAPI_MEDIA_RECORD_CHN_MAIN;
        config.recordFormat = self.recordFormat;
        config.recordType = self.recordType;
        config.storagePath = self.path;
        config.interval = 1000;
        
        [self.demo setRecordConfig:config];
        [self.demo startRecord];
    }
}

- (void)saveToAlbum {
    UISaveVideoAtPathToSavedPhotosAlbum(self.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo; {
    if (error) {
        ZGLogError(@"保存到相册出错!");
    }
    else {
        if (self.recordFormat == ZEGOAPI_MEDIA_RECORD_MP4) {
            ZGLogInfo(@"保存到相册成功，请在相册中查看录制的视频");
        }
        else {
            ZGLogInfo(@"相册不支持存储FLV，请在沙盒中查看录制的视频");
            [ZegoHudManager showMessage:@"相册不支持存储 FLV，请在沙盒中查看录制的视频"];
        }
        ZGLogInfo(@"Media Record VideoPath:%@", videoPath);
    }
}

- (void)playRecordedVideo {
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:self.path]];
    [self presentViewController:playerViewController animated:YES completion:nil];
    [playerViewController.player play];
}

#pragma mark - Delegate

- (ZGView *)getPlaybackView {
    return self.publishView;
}

- (void)onPublishStateChange:(BOOL)isPublishing {
    self.recordButton.enabled = YES;
    self.publishStateLabel.hidden = !isPublishing;
}

- (void)onRecordStateChange:(BOOL)isRecording {
    self.recordButton.enabled = YES;
    self.recordStateLabel.hidden = !isRecording;
    NSString *endPlayTitle = self.recordFormat == ZEGOAPI_MEDIA_RECORD_MP4 ? @"结束录制并播放视频" : @"结束录制并保存 FLV 到本地";
    [self.recordButton setTitle:isRecording ? endPlayTitle : @"开始录制" forState:UIControlStateNormal];
}

- (void)onRecordStatusUpdateFromChannel:(ZegoAPIMediaRecordChannelIndex)index storagePath:(NSString *)path duration:(unsigned int)duration fileSize:(unsigned int)size {
    ZGLogInfo(@"🔴 REC Duration: %u ms FileSize: %u Byte", duration, size);
    self.recordStateLabel.text = [NSString stringWithFormat:@"🔴 REC \nDuration: %.2u ms \nFileSize: %.2u KB", duration, size/1024];
}

#pragma mark - Access

- (NSString *)path {
    NSString *doc = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *format = self.recordFormat == ZEGOAPI_MEDIA_RECORD_MP4 ? @"mp4" : @"flv";
    NSString *path = [doc stringByAppendingPathComponent:[NSString stringWithFormat:@"MediaRecorder.%@", format]];
    return path;
}


@end
