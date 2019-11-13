//
//  UIApplication+JumpWeb.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/18.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "UIApplication+JumpWeb.h"

@implementation UIApplication (JumpWeb)

+ (void)jumpToWeb:(NSString *)url {
    NSURL *targetURL = [NSURL URLWithString:url];
    if (targetURL && [self.sharedApplication canOpenURL:targetURL]) {
        [self.sharedApplication openURL:targetURL];
    }
}

@end
