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
#import "ZGApiManager.h"
#import "ZGHelper.h"

@interface AppDelegate () <ZGTopicsTableViewControllerDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet ZGTopicsTableViewController *topicsController;
@property (weak) IBOutlet NSView *contentContainer;

@property (strong) NSArray<NSString*> *topicList;

@property (strong) NSViewController* currentController;
@property (strong) NSMutableDictionary<NSString*, NSViewController*> *comps;

@end

NSDictionary<NSString*, NSString*>* g_Topic2NibName;

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.comps = [NSMutableDictionary dictionary];
    
    NSMutableArray *topicList = [NSMutableArray array];
    
//#ifdef _Module_Publish
//    [topicList addObject:_Module_Publish];
//#endif
//#ifdef _Module_Play
//    [topicList addObject:_Module_Play];
//#endif
#ifdef _Module_MediaPlayer
    [topicList addObject:_Module_MediaPlayer];
#endif
#ifdef _Module_MediaSideInfo
    [topicList addObject:_Module_MediaSideInfo];
#endif
#ifdef _Module_ScalableVideoCoding
    [topicList addObject:_Module_ScalableVideoCoding];
#endif
#ifdef _Module_MediaRecord
    [topicList addObject:_Module_MediaRecord];
#endif
#ifdef _Module_ExternalVideoCapture
    [topicList addObject:_Module_ExternalVideoCapture];
#endif
#ifdef _Module_ExternalVideoRender
    [topicList addObject:_Module_ExternalVideoRender];
#endif
    self.topicList = topicList;
    
    self.topicsController.delegate = self;
    [self.topicsController setTopicList:self.topicList];
    
    // * init
    (void)[ZGApiManager api];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - ZGTopicTableViewControllerDelegate

- (void)onTopicSelected:(NSString *)topic {
    NSLog(@"%s: %@", __func__, topic);
    
    [self.currentController.view removeFromSuperview];
    
    NSViewController* vc = nil;

#ifdef _Module_MediaPlayer
    if ([topic isEqualToString:_Module_MediaPlayer]) { // show media player page
        vc = [[ZGMediaPlayerViewController alloc] initWithNibName:@"ZGMediaPlayerViewController" bundle:nil];
    }
#endif
    
#ifdef _Module_MediaSideInfo
    if ([topic isEqualToString:_Module_MediaSideInfo]) {
        vc = [[ZGMediaSideInfoViewController alloc] initWithNibName:@"ZGMediaSideInfoViewController" bundle:nil];
    }
#endif
    
#ifdef _Module_ScalableVideoCoding
    if ([topic isEqualToString:_Module_ScalableVideoCoding]) {
        vc = [[NSStoryboard storyboardWithName:@"SVC" bundle:nil] instantiateInitialController];
    };
#endif
    
#ifdef _Module_MediaRecord
    if ([topic isEqualToString:_Module_MediaRecord]) {
        vc = [[ZegoMediaRecordViewController alloc] initWithNibName:@"ZegoMediaRecordViewController" bundle:nil];
    };
#endif
    
#ifdef _Module_ExternalVideoCapture
    if ([topic isEqualToString:_Module_ExternalVideoCapture]) {
        NSStoryboard *sb = [NSStoryboard storyboardWithName:@"ZGExternalVideoCapture" bundle:nil];
        vc = [sb instantiateInitialController];
    };
#endif
    
#ifdef _Module_ExternalVideoRender
    if ([topic isEqualToString:_Module_ExternalVideoRender]) {
        NSStoryboard *sb = [NSStoryboard storyboardWithName:@"ZGExternalVideoRender" bundle:nil];
        vc = [sb instantiateInitialController];
    };
#endif

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
