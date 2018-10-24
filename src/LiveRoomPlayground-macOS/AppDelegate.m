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
#import "ZGManager.h"

@interface AppDelegate () <ZGTopicsTableViewControllerDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet ZGTopicsTableViewController *topicsController;
@property (weak) IBOutlet NSView *contentContainer;

@property (strong) NSArray<NSString *> *topicList;

@property (strong) NSViewController* currentController;
@property (strong) NSMutableDictionary<NSString*, NSViewController*> *comps;

@end

NSString* kZGTopicMediaPlayer = @"Media Player";

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    self.comps = [NSMutableDictionary dictionary];
    
    self.topicList = @[kZGTopicMediaPlayer];
    
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
    NSViewController* vc = nil;
    if ([topic isEqualToString:kZGTopicMediaPlayer]) {
        // show media player page
        vc = [self.comps objectForKey:kZGTopicMediaPlayer];
        if (self.currentController && self.currentController != vc) {
            [self.currentController.view removeFromSuperview];
        }
        
        if (!vc) {
            vc = [[ZGMediaPlayerViewController alloc] initWithNibName:@"ZGMediaPlayerViewController" bundle:nil];
            self.currentController = vc;
            [self.comps setObject:vc forKey:kZGTopicMediaPlayer];
        }
    }
    
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
