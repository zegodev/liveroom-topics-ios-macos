//
//  UIViewController+TopPresent.h
//  QueuingServices-iOS
//
//  Created by Sky on 2019/1/8.
//  Copyright © 2019 zego. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (TopPresent)

- (UIViewController *)topPresentedViewController;//便于modal，如果当前控制器没有modal的控制器的话，则返回其自身

@end

NS_ASSUME_NONNULL_END
