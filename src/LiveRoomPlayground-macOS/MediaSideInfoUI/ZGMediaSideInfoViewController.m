//
//  ZGMediaSideInfoViewController.m
//  LiveRoomPlayground-macOS
//
//  Created by Randy Qiu on 2018/10/24.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_MediaSideInfo

#import "ZGMediaSideInfoViewController.h"
#import "ZGApiManager.h"
#import "ZGUserIDHelper.h"
#import <ZegoLiveRoomOSX/zego-api-media-side-info-oc.h>
#import "ZGMediaSideInfoDemo.h"
#import "ZGMediaSideInfoDemoEnvirentmentHelper.h"

@interface ZGMediaSideInfoViewController () <ZGMediaSideInfoDemoEnvirentmentHelperDelegate, ZGMediaSideInfoDemoDelegate, NSTableViewDelegate, NSTableViewDataSource>

#pragma mark IBOutlet

@property (weak) IBOutlet NSTextField *statusLabel;
@property (weak) IBOutlet NSTextField *streamInfoLabel;

@property (weak) IBOutlet NSButton *onlyAudioCheck;
@property (weak) IBOutlet NSButton *customPacketCheck;
@property (weak) IBOutlet NSButton *startPublishingBtn;

@property (weak) IBOutlet NSView *previewView;
@property (weak) IBOutlet NSView *playView;

@property (weak) IBOutlet NSTextField *inputTextField;
@property (weak) IBOutlet NSButton *sendBtn;
@property (weak) IBOutlet NSTextField *dataLengthLabel;

@property (weak) IBOutlet NSTableView *sentMsgTable;
@property (weak) IBOutlet NSTableView *recvMsgTable;

@property (weak) IBOutlet NSTextField *checkSentRecvResult;

#pragma mark My Property
@property (nonatomic) ZGMediaSideTopicStatus status;

@property (strong) ZGMediaSideInfoDemo* demo;
@property (strong) ZGMediaSideInfoDemoEnvirentmentHelper* helper;

@property BOOL isOnlyAudio;

@end

@implementation ZGMediaSideInfoViewController

- (void)viewDidAppear {
    [super viewDidAppear];
    
    // Do view setup here.
    self.status = kZGMediaSideTopicStatus_None;
    
    self.sentMsgTable.delegate = self;
    self.sentMsgTable.dataSource = self;
    
    self.recvMsgTable.delegate = self;
    self.recvMsgTable.dataSource = self;
    
    self.helper = [ZGMediaSideInfoDemoEnvirentmentHelper new];
    self.helper.delegate = self;
    self.helper.previewView = self.previewView;
    self.helper.playView = self.playView;
    
    [self.helper loginRoom];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    self.demo = nil;
    [ZGApiManager.api logoutRoom];
    [ZGApiManager releaseApi];
}

- (IBAction)startPublishing:(id)sender {
    assert(self.status == kZGMediaSideTopicStatus_Login_OK);
    
    ZGMediaSideInfoDemoConfig* config = [ZGMediaSideInfoDemoConfig new];
    config.onlyAudioPublish = (self.onlyAudioCheck.state == NSControlStateValueOn);
    config.customPacket = (self.customPacketCheck.state == NSControlStateValueOn);
    
    self.isOnlyAudio = config.onlyAudioPublish;
    
    self.demo = [[ZGMediaSideInfoDemo alloc] initWithConfig:config];
    self.demo.delegate = self;
    [self.demo activateMediaSideInfoForPublishChannel:ZEGOAPI_CHN_MAIN];
    
    [self.helper publishAndPlayWithConfig:config];
}

- (IBAction)sendMsg:(id)sender {
    assert(self.status == kZGMediaSideTopicStatus_Ready_For_Messaging);
    [self.checkSentRecvResult setStringValue:@""];
    
    NSString* msg = nil;
    if (self.inputTextField.stringValue.length > 0) {
        msg = [self.inputTextField.stringValue copy];

    } else {
        static NSInteger s_i = 0;
        msg = [NSString stringWithFormat:@"[%ld][%f][%@]", ++s_i, [NSDate timeIntervalSinceReferenceDate], [NSDate date] ];
    }
    
    [self.helper addSentMsg:msg];
    [self.sentMsgTable reloadData];
    
    NSData* data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [self.demo sendMediaSideInfo:data];
    
    [self.dataLengthLabel setStringValue:[NSString stringWithFormat:@"%ld Bytes", data.length]];
}

- (IBAction)checkSentRecv:(id)sender {
    // * check if sent msgs are identical to recv msgs
    [self.checkSentRecvResult setStringValue:[self.helper checkSentRecvMsgs]];
}

#pragma mark - ZGMediaSideInfoDemoEnvirentmentHelperDelegate
- (void)onStateChanged:(ZGMediaSideTopicStatus)newState {
    self.status = newState;
}

#pragma mark - ZGMediaSideInfoDemoDelegate
- (void)onReceiveMediaSideInfo:(NSData *)data ofStream:(NSString *)streamID {
    NSString* msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.helper addRecvMsg:msg];
    [self.recvMsgTable reloadData];
    NSLog(@"%s: %@", __func__, msg);
}

#pragma mark - Private

- (void)setStatus:(ZGMediaSideTopicStatus)status {
    _status = status;
    [self updateStatusDesc];
    
    // * enable/disable controls
    self.onlyAudioCheck.enabled = NO;
    self.customPacketCheck.enabled = NO;
    switch (_status) {
        case kZGMediaSideTopicStatus_None:
        case kZGMediaSideTopicStatus_Starting_Login_Room:
        case kZGMediaSideTopicStatus_Starting_Publishing:
        case kZGMediaSideTopicStatus_Starting_Playing:
            self.startPublishingBtn.enabled = NO;
            self.sendBtn.enabled = NO;
            break;
            
        case kZGMediaSideTopicStatus_Login_OK:
            self.onlyAudioCheck.enabled = YES;
            self.customPacketCheck.enabled = YES;
            self.startPublishingBtn.enabled = YES;
            self.sendBtn.enabled = NO;
            break;

        case kZGMediaSideTopicStatus_Ready_For_Messaging:
            self.startPublishingBtn.enabled = NO;
            self.sendBtn.enabled = YES;
            break;
    }
}

- (void)updateStatusDesc {    
    [self.statusLabel setStringValue:[ZGMediaSideInfoDemoEnvirentmentHelper descOfStatus:self.status]];
}

#pragma mark - NSTableViewDelegate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString* identifier = @"";
    NSArray<NSString*>* msgs = nil;
    
    if (tableView == self.sentMsgTable) {
        identifier = @"SentMsgCellView";
        msgs = self.helper.sentMsgs;
    } else {
        identifier = @"RecvMsgCellView";
        msgs = self.helper.recvMsgs;
    }
    
    NSString* msg = @"";
    if (msgs.count > row) {
        msg = msgs[row];
    }
    
    NSTableCellView* cell = [tableView makeViewWithIdentifier:identifier owner:nil];
    [cell.textField setStringValue:msg];
    
    return cell;
}

#pragma mark - NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.sentMsgTable) {
        return self.helper.sentMsgs.count;
    } else {
        return self.helper.recvMsgs.count;
    }
}

@end

#endif
