//
//  ZGSoundLevelViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/9/4.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_SoundLevel

#import "ZGSoundLevelViewController.h"
#import "ZGSoundLevelConfigViewController.h"
#import "ZGSoundLevelTableViewCell.h"
#import "ZGSoundLevelDemo.h"

@interface ZGSoundLevelViewController () <ZGSoundLevelDemoProtocol>

@property (nonatomic, strong) ZGSoundLevelDemo *demo;

@end

@implementation ZGSoundLevelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demo = [[ZGSoundLevelDemo alloc] initWithRoomID:self.roomID];
    if (self.demo) {
        [self.demo setZGSoundLevelDelegate:self];
        self.demo.enableFrequencySpectrumMonitor = YES;
        self.demo.enableSoundLevelMonitor = YES;
        self.demo.frequencySpectrumMonitorCycle = 100;
        self.demo.soundLevelMonitorCycle = 100;
    }
    [self setupUI];
}

- (void)setupUI {
    [self.tableView registerNib:[UINib nibWithNibName:@"ZGSoundLevelTableViewCell" bundle:nil] forCellReuseIdentifier:@"ZGSoundLevelTableViewCell"];
    self.tableView.separatorStyle = UITableViewCellEditingStyleNone;
    self.tableView.backgroundColor = [UIColor colorWithRed:235.0/255.0 green:238.0/255.0 blue:244.0/255/0 alpha:1];
}

- (void)dealloc {
    self.demo = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ZGSoundLevelConfigViewController *vc = segue.destinationViewController;
    vc.demo = self.demo;
}

#pragma mark - Delegate

// 房间内流数量变化刷新
- (void)onRemoteStreamsUpdate {
    [self.tableView reloadData];
}

// 本地推流音频频谱数据刷新
- (void)onCaptureFrequencySpectrumDataUpdate {
    ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.spectrumList = self.demo.captureSpectrumList;
}

// 拉流音频频谱数据刷新
- (void)onRemoteFrequencySpectrumDataUpdate {
    NSInteger rowCount = [self.tableView numberOfRowsInSection:1];
    for (NSInteger row = 0; row < rowCount; row++) {
        ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
        if (self.demo.remoteSpectrumList.count > row) {
            cell.spectrumList = self.demo.remoteSpectrumList[row];
        }
    }
}

// 本地推流声浪数据刷新
- (void)onCaptureSoundLevelDataUpdate {
    ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.soundLevel = self.demo.captureSoundLevel.floatValue;
}

// 拉流声浪数据刷新
- (void)onRemoteSoundLevelDataUpdate {
    NSInteger rowCount = [self.tableView numberOfRowsInSection:1];
    for (NSInteger row = 0; row < rowCount; row++) {
        ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
        if (self.demo.remoteSoundLevelList.count > row) {
            cell.soundLevel = self.demo.remoteSoundLevelList[row].floatValue;
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else {
        long num = self.demo.remoteStreamIDList.count;
        return num;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGSoundLevelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZGSoundLevelTableViewCell"];
    cell.userInteractionEnabled = NO;
    if (indexPath.section == 0) {
        cell.streamID = [NSString stringWithFormat:@"%@(我)", self.demo.localStreamID];
    } else {
        if (self.demo.remoteStreamIDList.count > indexPath.row) {
            cell.streamID = self.demo.remoteStreamIDList[indexPath.row];
        }
    }
    return cell;
}

@end

#endif
