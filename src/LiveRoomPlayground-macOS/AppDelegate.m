//
//  AppDelegate.m
//  LiveRoomPlayground
//
//  Created by Randy Qiu on 2018/9/19.
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "AppDelegate.h"
#import "./ZGTopicsTableViewController.h"
#import "./MediaPlayerUI/ZGMediaPlayerViewController.h"
#import "./MediaSideInfoUI/ZGMediaSideInfoViewController.h"
#import "./SVC/ZGSVCRoomListViewController.h"
#import "./MediaRecord/ZegoMediaRecordViewController.h"
#import "./ExternalVideoCapture/ZGExternalVideoCaptureViewController.h"
#import "./ExternalVideoRender/ZGExternalVideoRenderViewController.h"
#import "ZGManager.h"
#import "ZGHelper.h"

@interface AppDelegate () <ZGTopicsTableViewControllerDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet ZGTopicsTableViewController *topicsController;
@property (weak) IBOutlet NSView *contentContainer;

@property (strong) NSArray<NSString *> *topicList;

@property (strong) NSViewController* currentController;
@property (strong) NSMutableDictionary<NSString*, NSViewController*> *comps;

@end

NSDictionary<NSString*, NSString*>* g_Topic2NibName;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.comps = [NSMutableDictionary dictionary];
    self.topicList = @[kZGTopicMediaPlayer, kZGTopicMediaSideInfo, kZGTopicSVC, kZGTopicMediaRecord, kZGTopicExternalVideoCapture, kZGTopicExternalVideoRender];
    self.topicsController.delegate = self;
    [self.topicsController setTopicList:self.topicList];
    
    // * init
    (void)[ZGManager api];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - ZGTopicTableViewControllerDelegate

- (void)onTopicSelected:(NSString *)topic {
    NSLog(@"%s: %@", __func__, topic);
    
    [self.currentController.view removeFromSuperview];
    
    NSViewController* vc = nil;

    if ([topic isEqualToString:kZGTopicMediaPlayer]) { // show media player page
        vc = [[ZGMediaPlayerViewController alloc] initWithNibName:@"ZGMediaPlayerViewController" bundle:nil];
    } else if ([topic isEqualToString:kZGTopicMediaSideInfo]) {
        vc = [[ZGMediaSideInfoViewController alloc] initWithNibName:@"ZGMediaSideInfoViewController" bundle:nil];
    } else if ([topic isEqualToString:kZGTopicSVC]) {
        vc = [[NSStoryboard storyboardWithName:@"SVC" bundle:nil] instantiateInitialController];
    } else if ([topic isEqualToString:kZGTopicMediaRecord]) {
        vc = [[ZegoMediaRecordViewController alloc] initWithNibName:@"ZegoMediaRecordViewController" bundle:nil];
    } else if ([topic isEqualToString:kZGTopicExternalVideoCapture]) {
        NSStoryboard *sb = [NSStoryboard storyboardWithName:@"ZGExternalVideoCapture" bundle:nil];
        vc = [sb instantiateInitialController];
    } else if ([topic isEqualToString:kZGTopicExternalVideoRender]) {
        NSStoryboard *sb = [NSStoryboard storyboardWithName:@"ZGExternalVideoRender" bundle:nil];
        vc = [sb instantiateInitialController];
    }
    
    self.currentController = vc;
    [self.comps setObject:vc forKey:topic];

    if (vc) {
        NSView* view = vc.view;
        [self.contentContainer addSubview:view];
        NSArray* v = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)];
        NSArray* h = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view)];
        
        [self.contentContainer addConstraints:v];
        [self.contentContainer addConstraints:h];
    }
}

@end
