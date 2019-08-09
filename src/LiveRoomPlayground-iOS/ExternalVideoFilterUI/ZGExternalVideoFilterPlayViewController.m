//
//  ZGExternalVideoFilterPlayViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/7.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import "ZGExternalVideoFilterPlayViewController.h"
#import "ZGLoginRoomDemo.h"
#import "ZGPlayDemo.h"

@interface ZGExternalVideoFilterPlayViewController () <ZGPlayDemoDelegate>

@property (nonatomic, copy) NSString *streamID;

@end

@implementation ZGExternalVideoFilterPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ZGPlayDemo.shared.delegate = self;
    [self setupBind];
    [self startPlay];
}

- (void)dealloc {
    [ZGPlayDemo.shared stopPlay];
    [ZGLoginRoomDemo.shared logoutRoom];//退回上一级需要登出
}

- (void)setupBind {
    Weakify(self);
    
    ZGLoginRoomDemo *loginDemo = ZGLoginRoomDemo.shared;
    
    [self bind:loginDemo keyPath:ZGBindKeyPath(loginDemo.streamIDList) callback:^(id value) {
        Strongify(self);
        BOOL currentStreamExist = [value containsObject:self.streamID];
        if (currentStreamExist) {
            if (!ZGPlayDemo.shared.isPlaying) {
                [self startPlay];
            }
        }
        else {
            if (ZGPlayDemo.shared.isPlaying) {
                self.title = @"拉流停止";
                [ZGPlayDemo.shared stopPlay];
            }
        }
    }];
}

- (void)startPlay {
    // 流ID 设置为 房间ID 加前缀
    self.streamID = [NSString stringWithFormat:@"ExternalFilter-%@", self.roomID];
    
    BOOL result = [ZGPlayDemo.shared startPlayingStream:self.streamID inView:self.view];
    
    if (result) {
        self.title = @"开始拉流";
        [ZegoHudManager showNetworkLoading];
    }
    else {
        [ZegoHudManager showMessage:@"参数不合法或已经开始拉流"];
    }
}

#pragma mark - Play Delegate

- (void)onPlayStateUpdate:(int)stateCode streamID:(NSString *)streamID {
    [ZegoHudManager hideNetworkLoading];
    
    BOOL success = stateCode == 0;
    
    if (success) {
        self.title = @"拉流中";
    }
    else {
        self.title = @"拉流失败";
        [ZegoHudManager showMessage:@"拉流失败\n请确认是否有在同一个房间内开启了推流"];
    }
}


@end

#endif
