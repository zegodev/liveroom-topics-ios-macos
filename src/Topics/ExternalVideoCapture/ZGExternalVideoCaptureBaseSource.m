//
//  ZGExternalVideoCaptureBaseSource.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/1/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoCaptureBaseSource.h"

@implementation ZGExternalVideoCaptureBaseSource

- (BOOL)start {
    if (self.isRunning) {
        return YES;
    }
    
    self.isRunning = YES;
    return YES;
}
- (void)stop {
    if (!self.isRunning) {
        return;
    }
    
    self.isRunning = NO;
}

@end
