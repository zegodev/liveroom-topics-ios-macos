//
//  ZGTopicsTableViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Randy Qiu on 2018/9/27.
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGTopicsTableViewController.h"
#import "ZGAppGlobalConfigViewController.h"

@implementation ZGTopicsTableViewController {
    NSArray<NSArray<NSString*>*>* _topicList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *goGlobalConfigItem = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(goGlobalConfigPage:)];
    self.navigationItem.rightBarButtonItem = goGlobalConfigItem;
    
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
#ifdef _Module_RoomConfigLive
    [commonTopicList addObject:_Module_RoomConfigLive];
#endif
#ifdef _Module_RoomMessage
    [commonTopicList addObject:_Module_RoomMessage];
#endif
#ifdef _Module_MixStream
    [advancedTopicList addObject:_Module_MixStream];
#endif
#ifdef _Module_AudioAux
    [advancedTopicList addObject:_Module_AudioAux];
#endif
#ifdef _Module_SoundLevel
    [advancedTopicList addObject:_Module_SoundLevel];
#endif
#ifdef _Module_MediaPlayer
    [advancedTopicList addObject:_Module_MediaPlayer];
#endif
#ifdef _Module_AudioPlayer
    [advancedTopicList addObject:_Module_AudioPlayer];
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
#ifdef _Module_ExternalVideoFilter
    [advancedTopicList addObject:_Module_ExternalVideoFilter];
#endif
#ifdef _Module_AudioProcessing
    [advancedTopicList addObject:_Module_AudioProcessing];
#endif
#ifdef _Module_SDKAPITest
    [advancedTopicList addObject:_Module_SDKAPITest];
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

- (void)goGlobalConfigPage:(id)sender {
    ZGAppGlobalConfigViewController *vc = [ZGAppGlobalConfigViewController instanceFromStoryboard];
    [self.navigationController pushViewController:vc animated:YES];
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
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"PublishStream" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    #ifdef _Module_Play
    if ([topicName isEqualToString:_Module_Play]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"PlayStream" bundle:nil];
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
    
#ifdef _Module_RoomConfigLive
    if ([topicName isEqualToString:_Module_RoomConfigLive]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"RoomConfigTopic" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
#endif
    
#ifdef _Module_RoomMessage
    if ([topicName isEqualToString:_Module_RoomMessage]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"RoomMessage" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
#endif

#ifdef _Module_MixStream
    if ([topicName isEqualToString:_Module_MixStream]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MixStream" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
#endif
    
#ifdef _Module_AudioAux
    if ([topicName isEqualToString:_Module_AudioAux]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"AudioAux" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
#endif
    
#ifdef _Module_SoundLevel
    if ([topicName isEqualToString:_Module_SoundLevel]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"SoundLevel" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
#endif
    
    #ifdef _Module_MediaPlayer
    if ([topicName isEqualToString:_Module_MediaPlayer]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"NewMediaPlayer" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif

    #ifdef _Module_AudioPlayer
    if ([topicName isEqualToString:_Module_AudioPlayer]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"AudioPlayer" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    #ifdef _Module_MediaSideInfo
    if ([topicName isEqualToString:_Module_MediaSideInfo]) {
        UIStoryboard* sb = [UIStoryboard storyboardWithName:@"MediaSideInfo" bundle:nil];
        vc = [sb instantiateInitialViewController];
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
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"VideoExternalCapture" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    #ifdef _Module_ExternalVideoRender
    if ([topicName isEqualToString:_Module_ExternalVideoRender]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"NewExternalVideoRender" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
    #ifdef _Module_ExternalVideoFilter
    if ([topicName isEqualToString:_Module_ExternalVideoFilter]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoFilter" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
    #endif
    
#ifdef _Module_AudioProcessing
    if ([topicName isEqualToString:_Module_AudioProcessing]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"AudioProcessing" bundle:nil];
        vc = [sb instantiateInitialViewController];
    }
#endif
    
#ifdef _Module_SDKAPITest
    if ([topicName isEqualToString:_Module_SDKAPITest]) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"SDKAPITest" bundle:nil];
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
