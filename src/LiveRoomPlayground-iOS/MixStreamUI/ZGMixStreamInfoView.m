//
//  ZGMixStreamInfoView.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGMixStreamInfoView.h"

@implementation ZGMixStreamInfoView

+ (instancetype)viewFromNib {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([ZGMixStreamInfoView class]) bundle:nil];
    ZGMixStreamInfoView *view = [nib instantiateWithOwner:nil options:nil].firstObject;
    return view;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(CGRectGetWidth(self.frame), 104);
}

@end
