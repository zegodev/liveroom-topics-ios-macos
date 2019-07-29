//
//  UIViewController+TopPresent.m
//  QueuingServices-iOS
//
//  Created by Sky on 2019/1/8.
//  Copyright © 2019 zego. All rights reserved.
//

#import "UIViewController+TopPresent.h"

@implementation UIViewController (TopPresent)

- (UIViewController *)topPresentedViewController {
    UIViewController *vc = self;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    return vc;
}

@end
