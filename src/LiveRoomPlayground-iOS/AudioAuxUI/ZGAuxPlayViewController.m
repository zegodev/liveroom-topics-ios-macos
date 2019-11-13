//
//  ZGAuxPlayViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_AudioAux

#import "ZGAuxPlayViewController.h"
#import "ZGAuxDemo.h"

@interface ZGAuxPlayViewController () <ZGAuxDemoProtocol>

@property (weak, nonatomic) IBOutlet UILabel *playQualityLabel;

@property (nonatomic, strong) ZGAuxDemo *demo;

@end

@implementation ZGAuxPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.demo = [[ZGAuxDemo alloc] initWithRoomID:self.roomID streamID:self.streamID isAnchor:NO];
    self.demo.delegate = self;
    
    [self.demo loginRoom];
    [self.demo startPlay];
}

- (void)dealloc {
    [self.demo stopPlay];
    [self.demo logoutRoom];
    self.demo = nil;
}

- (nonnull UIView *)getPlaybackView {
    return self.view;
}

// 拉流状态回调
- (void)onAuxPlayStateUpdate:(NSString *)state {
    self.title = state;
}

// 拉流质量信息更新回调
- (void)onAuxPlayQualityUpdate:(NSString *)state {
    self.playQualityLabel.text = state;
}



@end

#endif
