//
//  ZGTopicsTableViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Randy Qiu on 2018/9/27.
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGTopicsTableViewController.h"
#import "ZGManager.h"
#import "ZGHelper.h"

@implementation ZGTopicsTableViewController {
    NSArray<NSString*>* _topicList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _topicList = @[kZGTopicMediaPlayer, kZGTopicMediaSideInfo];
}

- (void)setTopicList:(NSArray<NSString *> *)topics {
    _topicList = topics;
    [self.tableView reloadData];
}

- (void)uploadLog:(id)sender {
    [ZGManager api];
    [ZegoLiveRoomApi uploadLog];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _topicList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ZGTopicCell"];
    [cell.textLabel setText:[_topicList objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s, %@", __func__, indexPath);
    
    if (indexPath.row >= _topicList.count) return;
    
    NSString* topicName = _topicList[indexPath.row];
    
    UIViewController* vc = nil;
    
    if ([topicName isEqualToString:kZGTopicMediaPlayer]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaPlayer" bundle:[NSBundle mainBundle]];
        vc = [sb instantiateViewControllerWithIdentifier:@"ZGMediaSourceTableViewController"];
    } else if ([topicName isEqualToString:kZGTopicMediaSideInfo]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaSideInfo" bundle:[NSBundle mainBundle]];
        vc = [sb instantiateViewControllerWithIdentifier:@"ZGMediaSideInfoViewController_iOS"];
    }
    
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
