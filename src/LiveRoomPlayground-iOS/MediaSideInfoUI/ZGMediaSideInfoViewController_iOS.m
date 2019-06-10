//
//  ZGMediaSideInfoViewController_iOS.m
//  LiveRoomPlayground-iOS
//
//  Created by Randy Qiu on 2018/10/25.
//  Copyright © 2018 Zego. All rights reserved.
//

#import "ZGMediaSideInfoViewController_iOS.h"
#import "ZGApiManager.h"
#import "ZGHelper.h"
#import <ZegoLiveRoom/zego-api-media-side-info-oc.h>
#import "ZGMediaSideInfoDemo.h"
#import "ZGMediaSideInfoDemoEnvirentmentHelper.h"

@interface ZGMediaSideInfoViewController_iOS () <ZGMediaSideInfoDemoEnvirentmentHelperDelegate, ZGMediaSideInfoDemoDelegate, UITableViewDelegate, UITableViewDataSource>

#pragma mark IBOutlet

@property (weak, nonatomic) IBOutlet UILabel *topicStateLabel;

@property (weak, nonatomic) IBOutlet UISwitch *onlyAudioSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *customPacketSwitch;
@property (weak, nonatomic) IBOutlet UIButton *startPublishingBtn;

@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIView *playView;

@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendBtn;
@property (weak, nonatomic) IBOutlet UILabel *dataLengthLabel;

@property (weak, nonatomic) IBOutlet UITableView *sentMsgTable;
@property (weak, nonatomic) IBOutlet UITableView *recvMsgTable;

@property (weak, nonatomic) IBOutlet UILabel *checkSentRecvLable;

#pragma mark My Property
@property (nonatomic) ZGMediaSideTopicStatus status;

@property (strong) ZGMediaSideInfoDemo* demo;
@property (strong) ZGMediaSideInfoDemoEnvirentmentHelper* helper;

@property BOOL isOnlyAudio;

@end

@implementation ZGMediaSideInfoViewController_iOS

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.status = kZGMediaSideTopicStatus_None;
    
    [self.sentMsgTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.recvMsgTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[ZGApiManager api] logoutRoom];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)startPublishing:(id)sender {
    assert(self.status == kZGMediaSideTopicStatus_Login_OK);
    
    ZGMediaSideInfoDemoConfig* config = [ZGMediaSideInfoDemoConfig new];
    config.onlyAudioPublish = self.onlyAudioSwitch.on;
    config.customPacket = self.customPacketSwitch.on;
    
    self.isOnlyAudio = config.onlyAudioPublish;
    
    self.demo = [[ZGMediaSideInfoDemo alloc] initWithConfig:config];
    self.demo.delegate = self;
    [self.demo activateMediaSideInfoForPublishChannel:ZEGOAPI_CHN_MAIN];
    
    [self.helper publishAndPlayWithConfig:config];
}

- (IBAction)sendMsg:(id)sender {
    [self.view endEditing:YES];
    [self.checkSentRecvLable setText:@""];
    
    assert(self.status == kZGMediaSideTopicStatus_Ready_For_Messaging);
    
    NSString* msg = nil;
    if (self.inputTextField.text.length > 0) {
        msg = [self.inputTextField.text copy];
        
    } else {
        static NSInteger s_i = 0;
        msg = [NSString stringWithFormat:@"[%ld][%f][%@]", ++s_i, [NSDate timeIntervalSinceReferenceDate], [NSDate date] ];
    }
    
    [self.helper addSentMsg:msg];
    [self.sentMsgTable reloadData];
    
    NSData* data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [self.demo sendMediaSideInfo:data];
    
    [self.dataLengthLabel setText:[NSString stringWithFormat:@"%ld Bytes", data.length]];
}

- (IBAction)checkSentRecv:(id)sender {
    // * check if sent msgs are identical to recv msgs
    [self.checkSentRecvLable setText:[self.helper checkSentRecvMsgs]];
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
    switch (_status) {
        case kZGMediaSideTopicStatus_None:
        case kZGMediaSideTopicStatus_Starting_Login_Room:
        case kZGMediaSideTopicStatus_Starting_Publishing:
        case kZGMediaSideTopicStatus_Starting_Playing:
            self.startPublishingBtn.enabled = NO;
            self.sendBtn.enabled = NO;
            break;
            
        case kZGMediaSideTopicStatus_Login_OK:
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
    [self.topicStateLabel setText:[ZGMediaSideInfoDemoEnvirentmentHelper descOfStatus:self.status]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.sentMsgTable) {
        return self.helper.sentMsgs.count;
    } else {
        return self.helper.recvMsgs.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray<NSString*>* msgs = nil;
    if (tableView == self.sentMsgTable) {
        msgs = self.helper.sentMsgs;
    } else {
        msgs = self.helper.recvMsgs;
    }
    
    NSString* msg = @"";
    if (msgs.count > indexPath.row) {
        msg = msgs[indexPath.row];
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];    
    [cell.textLabel setText:msg];
    
    return cell;
}


@end
