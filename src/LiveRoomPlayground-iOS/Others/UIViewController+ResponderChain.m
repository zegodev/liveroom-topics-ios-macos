//
//  UIViewController+ResponderChain.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "UIViewController+ResponderChain.h"

@implementation UIViewController (ResponderChain)

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    [self.nextResponder motionBegan:motion withEvent:event];
}

@end
