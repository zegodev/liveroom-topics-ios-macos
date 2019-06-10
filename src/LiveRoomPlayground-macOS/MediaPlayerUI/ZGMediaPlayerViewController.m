//
//  ZGMediaPlayerViewController.m
//  LiveRoomPlayground
//
//  Created by Randy Qiu on 2018/9/19.
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGMediaPlayerViewController.h"
#import "ZGApiManager.h"
#import "ZGMediaPlayerDemo.h"
#import "ZGMediaPlayerDemoHelper.h"

@interface ZGMediaPlayerViewController () <ZGMediaPlayerDemoDelegate>

@property (weak) IBOutlet NSTextField* currentState;
@property (weak) IBOutlet NSTextField *publishingInfo;

@property (weak) IBOutlet NSView* videoView;
@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet NSSlider* playProgressSlider;
@property (weak) IBOutlet NSTextField *playProgressTextField;

@property (weak) IBOutlet NSSlider* volumeSlider;

@property (weak) IBOutlet NSButton *repeatCheck;
@property (weak) IBOutlet NSPopUpButton *audioTrackPicker;

@property (strong) NSArray<NSDictionary*>* mediaList;
@property NSUInteger selectedMediaIndex;

@property (strong) ZGMediaPlayerDemo* demo;

@end


@implementation ZGMediaPlayerViewController

- (void)viewDidAppear {
    [super viewDidAppear];
    
    // Do view setup here.
    self.mediaList = [ZGMediaPlayerDemoHelper mediaList];
    [self.tableView reloadData];
    
    self.demo = [ZGMediaPlayerDemo new];
    self.demo.delegate = self;
    
    [self.playProgressSlider setIntValue:0];
    
    self.audioTrackPicker.hidden = YES;
    int volumn = 50;
    [self.volumeSlider setIntValue:volumn];
    [self.demo setVolume:volumn];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    [self.demo stop];
    self.demo = nil;
}

#pragma mark - ZGMediaPlayerDemoDelegate

- (void)onPlayerState:(NSString *)state {
    [self.currentState setStringValue:state];
}

- (void)onPublishState:(NSString *)state {
    [self.publishingInfo setStringValue:state];
}

- (void)onPlayerProgress:(long)current max:(long)max desc:(NSString *)desc {
    [self.playProgressSlider setMaxValue:max];
    [self.playProgressSlider setIntValue:(int)current];
    [self.playProgressTextField setStringValue:desc];
}

- (void)onPlayerStop {
    [self.playProgressSlider setIntValue:0];
    [self.playProgressTextField setStringValue:@"-/-"];
}

- (void)onGetAudioStreamCount:(int)count {
    NSLog(@"%s, %d", __func__, count);
    self.audioTrackPicker.hidden = (count <= 1);
}

- (IBAction)play:(id)sender {
    NSLog(@"%s", __func__);
    NSDictionary* media = self.mediaList[self.selectedMediaIndex];
    NSString* url = media[kZGMediaURLKey];
    
    [self.demo setVideoView:self.videoView];
    [self.demo startPlaying:url repeat:[self.repeatCheck state] == NSControlStateValueOn];
}

- (IBAction)stop:(id)sender {
    NSLog(@"%s", __func__);
    [self.demo stop];
}

- (IBAction)pause:(id)sender {
    NSLog(@"%s", __func__);
    [self.demo pause];
}

- (IBAction)resume:(id)sender {
    NSLog(@"%s", __func__);
    [self.demo resume];
}

- (IBAction)sliderDidChanged:(id)sender {
    NSSlider* slider = sender;
    
    NSLog(@"%s: %ld", __func__, slider.integerValue);
    
    if (slider == self.volumeSlider) {
        int volumn = (int)slider.integerValue;
        [self.demo setVolume:volumn];
    } else if (slider == self.playProgressSlider) {
        [self.demo seekTo:(long)slider.doubleValue];
    } else {
        assert(false);
    }
}

- (IBAction)pupUpDidChanged:(id)sender {
    NSPopUpButton* popUp = sender;
    NSLog(@"%s, %d", __func__, (int)popUp.selectedTag);
    [self.demo setAudioStream:(int)popUp.selectedTag];
}

- (IBAction)onMicCheck:(id)sender {
    [[ZGApiManager api] enableMic:[sender state] == NSControlStateValueOn];
}

- (IBAction)onPlayTypeChanged:(id)sender {
    [self.demo setPlayerType:([sender state] == NSControlStateValueOn ? MediaPlayerTypeAux : MediaPlayerTypePlayer)];
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionIsChanging:(NSNotification *)notification {
    NSLog(@"%s", __func__);
    NSTableView* tableView = notification.object;
    NSInteger row = tableView.selectedRow;
    if (row != -1) {
        self.selectedMediaIndex = row;
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSLog(@"%s", __func__);
    NSTableCellView* cell = [tableView makeViewWithIdentifier:@"MediaItemCellView" owner:nil];
    
    [cell.textField setStringValue:[ZGMediaPlayerDemoHelper titleForItem:self.mediaList[row]]];
    return cell;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    NSLog(@"%s", __func__);
    return self.mediaList.count;
}

@end
