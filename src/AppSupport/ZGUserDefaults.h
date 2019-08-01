//
//  ZGUserDefaults.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 子类化 NSUserDefaults，实现中指定了项目要求的特定 suitename，方便使用
 */
@interface ZGUserDefaults : NSUserDefaults

+ (NSUserDefaults *)standardUserDefaults NS_UNAVAILABLE;

- (instancetype)initWithSuiteName:(NSString *)suitename NS_UNAVAILABLE;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
