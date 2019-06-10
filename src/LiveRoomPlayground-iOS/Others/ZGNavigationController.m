//
//  ZGNavigationController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGNavigationController.h"
#import "ZegoLogView.h"

@implementation ZGNavigationController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.navigationBar.translucent = NO;
    }
    
    return self;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    [ZegoLogView show];
}

@end
