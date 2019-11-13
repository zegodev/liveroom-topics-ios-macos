//
//  ZGExternalVideoFilterPlayViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import "ZGExternalVideoFilterPlayViewController.h"
#import "ZGExternalVideoFilterDemo.h"
#import "ZGLoginRoomDemo.h"
#import "ZGPlayDemo.h"

@interface ZGExternalVideoFilterPlayViewController () <ZGExternalVideoFilterDemoProtocol>

@property (nonatomic, strong) ZGExternalVideoFilterDemo *demo;

@property (weak, nonatomic) IBOutlet UILabel *playQualityLabel;

@end

@implementation ZGExternalVideoFilterPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demo = [[ZGExternalVideoFilterDemo alloc] init];
    self.demo.delegate = self;
    
    [self.demo initSDKWithRoomID:self.roomID streamID:self.streamID isAnchor:NO];
    [self.demo loginRoom];
    [self.demo startPlay];
}

- (void)dealloc {
    [self.demo stopPlay];
    [self.demo logoutRoom];
    self.demo = nil;
}


#pragma mark - ZGExternalVideoFilterDemoProtocol

- (nonnull UIView *)getPlaybackView {
    return self.view;
}

- (void)onExternalVideoFilterPlayStateUpdate:(NSString *)state {
    self.title = state;
}

- (void)onExternalVideoFilterPlayQualityUpdate:(NSString *)state {
    self.playQualityLabel.text = state;
}

@end

#endif
