//
//  ZGTopicsTableViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Randy Qiu on 2018/9/27.
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGTopicsTableViewController.h"
#import "ZGManager.h"

@implementation ZGTopicsTableViewController {
    NSArray<NSString*>* _topicList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _topicList = @[@"Media Player"];
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
    
    UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaPlayer" bundle:[NSBundle mainBundle]];
    UIViewController* vc = [sb instantiateViewControllerWithIdentifier:@"ZGMediaSourceTableViewController"];
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
