//
//  ZGUserDefaults.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/23.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 子类化 NSUserDefaults，实现中指定了项目要求的特定 suitename，方便使用
 */
@interface ZGUserDefaults : NSUserDefaults

+ (ZGUserDefaults *)standardUserDefaults;

- (instancetype)initWithSuiteName:(NSString *)suitename NS_UNAVAILABLE;

@end
