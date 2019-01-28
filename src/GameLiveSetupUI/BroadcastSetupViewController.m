//
//  BroadcastSetupViewController.m
//  GameLiveSetupUI
//
//  Created by Sky on 2019/1/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "BroadcastSetupViewController.h"
#import <ReplayKit/ReplayKit.h>


@interface BroadcastSetupViewController ()

@property (nonatomic, weak) IBOutlet UIButton *startLiveButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UITextField *liveTitle;

@end

@implementation BroadcastSetupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"[LiveRoomPlayground-GameLiveUI] BroadcastSetupViewController viewDidLoad");
}

// Called when the user has finished interacting with the view controller and a broadcast stream can start
- (void)userDidFinishSetup {
    NSLog(@"[LiveRoomPlayground-GameLiveUI] BroadcastSetupViewController user finish set up");
    
    // Broadcast url that will be returned to the application
    NSURL *broadcastURL = [NSURL URLWithString:@"http://broadcastURL_example/stream1"];
    
    // Service specific broadcast data example which will be supplied to the process extension during broadcast
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat screenScale = 1.0;
    
    NSDictionary *setupInfo = @{@"title": self.liveTitle.text, @"width": @(screenSize.width * screenScale), @"height": @(screenSize.height * screenScale)};
    
    if (@available(iOS 11.0, *)) {
        [self.extensionContext completeRequestWithBroadcastURL:broadcastURL setupInfo:setupInfo];
    }
    else {
#pragma clang diagnostic push
#pragma clang diagnostic ignore "-Wdeprecated-declarations"
        RPBroadcastConfiguration *broadcastConfig = [[RPBroadcastConfiguration alloc] init];
        broadcastConfig.clipDuration = 5.0;
        [self.extensionContext completeRequestWithBroadcastURL:broadcastURL broadcastConfiguration:broadcastConfig setupInfo:setupInfo];
#pragma clang diagnostic pop
    }
}

- (void)userDidCancelSetup {
    // Tell ReplayKit that the extension was cancelled by the user
    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"YourAppDomain" code:-1 userInfo:nil]];
}

- (IBAction)onStartLive:(id)sender
{
    NSLog(@"[LiveRoomPlayground-GameLiveUI] BroadcastSetupViewController user start live");
    [self userDidFinishSetup];
}

- (IBAction)onCancel:(id)sender
{
    NSLog(@"[LiveRoomPlayground-GameLiveUI] BroadcastSetupViewController user cancel live");
    [self userDidCancelSetup];
}

@end
