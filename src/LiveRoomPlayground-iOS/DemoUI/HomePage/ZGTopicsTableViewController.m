//
//  ZGTopicsTableViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Randy Qiu on 2018/9/27.
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGTopicsTableViewController.h"

@implementation ZGTopicsTableViewController {
    NSArray<NSArray<NSString*>*>* _topicList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray *basicTopicList = [NSMutableArray array];
    NSMutableArray *commonTopicList = [NSMutableArray array];
    NSMutableArray *advancedTopicList = [NSMutableArray array];
    NSArray *topicList = @[basicTopicList, commonTopicList, advancedTopicList];
    
#ifdef _Module_Publish
    [basicTopicList addObject:_Module_Publish];
#endif
#ifdef _Module_Play
    [basicTopicList addObject:_Module_Play];
#endif
#ifdef _Module_VideoTalk
    [commonTopicList addObject:_Module_VideoTalk];
#endif
#ifdef _Module_JoinLive
    [commonTopicList addObject:_Module_JoinLive];
#endif
#ifdef _Module_MixStream
    [advancedTopicList addObject:_Module_MixStream];
#endif
#ifdef _Module_MediaPlayer
    [advancedTopicList addObject:_Module_MediaPlayer];
#endif
#ifdef _Module_MediaSideInfo
    [advancedTopicList addObject:_Module_MediaSideInfo];
#endif
#ifdef _Module_ScalableVideoCoding
    [advancedTopicList addObject:_Module_ScalableVideoCoding];
#endif
#ifdef _Module_MediaRecord
    [advancedTopicList addObject:_Module_MediaRecord];
#endif
#ifdef _Module_ExternalVideoCapture
    [advancedTopicList addObject:_Module_ExternalVideoCapture];
#endif
#ifdef _Module_ExternalVideoRender
    [advancedTopicList addObject:_Module_ExternalVideoRender];
#endif
    
    _topicList = topicList;
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
    return _topicList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _topicList[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ZGTopicCell"];
    NSString* topicName = _topicList[indexPath.section][indexPath.row];
    [cell.textLabel setText:topicName];
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"基础模块";
    } else if (section == 1) {
        return @"常用模块";
    }
    
    return @"进阶模块";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >= _topicList.count || indexPath.row >= _topicList[indexPath.section].count){
        return;
    }
    
    NSString* topicName = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    
    UIViewController* vc = nil;
    
    #ifdef _Module_Publish
    if ([topicName isEqualToString:_Module_Publish]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Publish" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    #ifdef _Module_Play
    if ([topicName isEqualToString:_Module_Play]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"Play" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    #ifdef _Module_VideoTalk
    if ([topicName isEqualToString:_Module_VideoTalk]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"VideoTalk" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
#ifdef _Module_JoinLive
    if ([topicName isEqualToString:_Module_JoinLive]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"JoinLive" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
#endif

#ifdef _Module_MixStream
    if ([topicName isEqualToString:_Module_MixStream]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MixStream" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
#endif
    
    #ifdef _Module_MediaPlayer
    if ([topicName isEqualToString:_Module_MediaPlayer]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaPlayer" bundle:nil];
        vc = [sb instantiateViewControllerWithIdentifier:@"ZGMediaSourceTableViewController"];
    }
    #endif
    
    #ifdef _Module_MediaSideInfo
    if ([topicName isEqualToString:_Module_MediaSideInfo]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaSideInfo" bundle:nil];
        vc = [sb instantiateViewControllerWithIdentifier:@"ZGMediaSideInfoViewController_iOS"];
    }
    #endif
    
    #ifdef _Module_ScalableVideoCoding
    if ([topicName isEqualToString:_Module_ScalableVideoCoding]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"SVC" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    #ifdef _Module_MediaRecord
    if ([topicName isEqualToString:_Module_MediaRecord]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MediaRecord" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    #ifdef _Module_ExternalVideoCapture
    if ([topicName isEqualToString:_Module_ExternalVideoCapture]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoCapture" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    #ifdef _Module_ExternalVideoRender
    if ([topicName isEqualToString:_Module_ExternalVideoRender]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoRender" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
}


#pragma mark - Access

- (void)setTopicList:(NSArray<NSArray<NSString*>*>*)topics {
    _topicList = topics;
    [self.tableView reloadData];
}


@end
