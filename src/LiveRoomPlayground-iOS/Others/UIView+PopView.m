//
//  UIView+PopView.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "UIView+PopView.h"
#import "CMPopTipView.h"

@implementation UIView (PopView)

- (void)showPopViewWithMessage:(NSString *)message {
    CMPopTipView *tipView = [[CMPopTipView alloc] initWithMessage:message];
    tipView.borderWidth = 0.f;
    tipView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8f];;
    tipView.has3DStyle = NO;
    tipView.hasShadow = YES;
    tipView.dismissTapAnywhere = YES;
    
    [tipView presentPointingAtView:self inView:self.superview animated:YES];
}

@end
