//
//  ZGJsonHelper.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGJsonHelper : NSObject

+ (NSString *)encodeToJSON:(id)object;

+ (id)decodeFromJSON:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
