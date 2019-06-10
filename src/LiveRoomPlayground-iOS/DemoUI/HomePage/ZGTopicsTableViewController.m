//
//  ZGTopicsTableViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Randy Qiu on 2018/9/27.
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGTopicsTableViewController.h"

@implementation ZGTopicsTableViewController {
    NSArray<NSString*>* _topicList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _topicList = @[kZGTopicPublish, kZGTopicPlay, kZGTopicMediaPlayer, kZGTopicMediaSideInfo, kZGTopicSVC, kZGTopicMediaRecord, kZGTopicExternalVideoCapture, kZGTopicExternalVideoRender];
}

- (IBAction)onOpenDocWeb {
    [UIApplication jumpToWeb:ZGOpenDocURL];
}

- (IBAction)onOpenSourceCodeWeb {
    [UIApplication jumpToWeb:ZGOpenSourceCodeURL];
}

- (IBAction)onOpenQuestionWeb {
    [UIApplication jumpToWeb:ZGOpenQuestionURL];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {//基础
        return 2;
    }
    else {
        return _topicList.count - 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ZGTopicCell"];
    NSString* topicName = indexPath.section == 0 ? _topicList[indexPath.row]:_topicList[indexPath.row+2];
    [cell.textLabel setText:topicName];
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"基础模块";
    }
    
    return @"进阶模块";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    if (indexPath.row >= _topicList.count){
        return;
    }
    
    NSString* topicName = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    UIViewController* vc = nil;
    
    if ([topicName isEqualToString:kZGTopicPublish]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Publish" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    else if ([topicName isEqualToString:kZGTopicPlay]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Play" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    else if ([topicName isEqualToString:kZGTopicMediaPlayer]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaPlayer" bundle:nil];
        vc = [sb instantiateViewControllerWithIdentifier:@"ZGMediaSourceTableViewController"];
    }
    else if ([topicName isEqualToString:kZGTopicMediaSideInfo]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaSideInfo" bundle:nil];
        vc = [sb instantiateViewControllerWithIdentifier:@"ZGMediaSideInfoViewController_iOS"];
    }
    else if ([topicName isEqualToString:kZGTopicSVC]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"SVC" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    else if ([topicName isEqualToString:kZGTopicMediaRecord]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MediaRecord" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    else if ([topicName isEqualToString:kZGTopicExternalVideoCapture]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoCapture" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    else if ([topicName isEqualToString:kZGTopicExternalVideoRender]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoRender" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark - Access

- (void)setTopicList:(NSArray<NSString *> *)topics {
    _topicList = topics;
    [self.tableView reloadData];
}


@end
