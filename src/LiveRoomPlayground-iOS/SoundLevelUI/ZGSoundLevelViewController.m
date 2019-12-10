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
#import "ZGSoundLevelManager.h"

@interface ZGSoundLevelViewController () <ZGSoundLevelDataSource>

@property (nonatomic, strong) ZGSoundLevelManager *manager;

@end

@implementation ZGSoundLevelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [[ZGSoundLevelManager alloc] initWithRoomID:self.roomID];
    if (self.manager) {
        [self.manager setZGSoundLevelDataSource:self];
        self.manager.enableFrequencySpectrumMonitor = YES;
        self.manager.enableSoundLevelMonitor = YES;
        self.manager.frequencySpectrumMonitorCycle = 100;
        self.manager.soundLevelMonitorCycle = 100;
    }
    [self setupUI];
}

- (void)setupUI {
    [self.tableView registerNib:[UINib nibWithNibName:@"ZGSoundLevelTableViewCell" bundle:nil] forCellReuseIdentifier:@"ZGSoundLevelTableViewCell"];
    self.tableView.separatorStyle = UITableViewCellEditingStyleNone;
}

- (void)dealloc {
    self.manager = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ZGSoundLevelConfigViewController *vc = segue.destinationViewController;
    vc.manager = self.manager;
}

#pragma mark - Delegate

// 房间内流数量变化刷新
- (void)onRemoteStreamsUpdate {
    [self.tableView reloadData];
}

// 本地推流音频频谱数据刷新
- (void)onCaptureFrequencySpectrumDataUpdate:(NSArray<NSNumber *> *)captureSpectrumList {
    ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.spectrumList = captureSpectrumList;
}

// 拉流音频频谱数据刷新
- (void)onRemoteFrequencySpectrumDataUpdate:(NSDictionary<NSString *,NSArray<NSNumber *> *> *)remoteSpectrumDict {
    NSInteger rowCount = [self.tableView numberOfRowsInSection:1];
    for (NSInteger row = 0; row < rowCount; row++) {
        ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
        if ([remoteSpectrumDict objectForKey:cell.streamID]) {
            cell.spectrumList = remoteSpectrumDict[cell.streamID];
        }
    }
}

// 本地推流声浪数据刷新
- (void)onCaptureSoundLevelDataUpdate:(NSNumber *)captureSoundLevel {
    ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    cell.soundLevel = captureSoundLevel;
}

// 拉流声浪数据刷新
- (void)onRemoteSoundLevelDataUpdate:(NSDictionary<NSString *,NSNumber *> *)remoteSoundLevelDict {
    NSInteger rowCount = [self.tableView numberOfRowsInSection:1];
    for (NSInteger row = 0; row < rowCount; row++) {
        ZGSoundLevelTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:1]];
        if ([remoteSoundLevelDict objectForKey:cell.streamID]) {
            cell.soundLevel = remoteSoundLevelDict[cell.streamID];
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
        long num = self.manager.remoteStreamIDList.count;
        return num;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGSoundLevelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZGSoundLevelTableViewCell"];
    cell.userInteractionEnabled = NO;
    if (indexPath.section == 0) {
        cell.streamID = [NSString stringWithFormat:@"%@(我)", self.manager.localStreamID];
    } else {
        if (self.manager.remoteStreamIDList.count > indexPath.row) {
            cell.streamID = self.manager.remoteStreamIDList[indexPath.row];
        }
    }
    return cell;
}

@end

#endif
