//
//  ZGExternalVideoFilterConfigViewController.h
//  LiveRoomPlayground-macOS
//
//  Created by Paaatrick on 2019/8/21.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZGFUSkinConfig.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ZGFUConfigProtocol <NSObject>

- (void)skinParamChanged:(ZGFUSkinConfig *)config;
- (void)filterChanged:(NSString *)filterName;
- (void)filterValueChanged:(float)value;
- (void)itemChanged:(NSString *)itemName;

@end

@interface ZGExternalVideoFilterConfigViewController : NSViewController

@property (nonatomic, weak) id<ZGFUConfigProtocol> delegate;

@property (nonatomic, strong) ZGFUSkinConfig *skinConfig;

- (void)setZGFUConfigProtocol:(id<ZGFUConfigProtocol>)configProtocol;

@end

NS_ASSUME_NONNULL_END
