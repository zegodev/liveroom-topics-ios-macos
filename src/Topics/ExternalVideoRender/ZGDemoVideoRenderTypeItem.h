//
//  ZGDemoVideoRenderTypeItem.h
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGDemoVideoRenderTypeItem : NSObject

@property (nonatomic, assign) NSInteger renderType;
@property (nonatomic, copy) NSString *typeName;

+ (instancetype)itemWithRenderType:(NSInteger)renderType typeName:(NSString *)typeName;

@end

NS_ASSUME_NONNULL_END
