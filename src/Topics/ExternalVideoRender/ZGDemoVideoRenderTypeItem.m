//
//  ZGDemoVideoRenderTypeItem.m
//  LiveRoomPlayGround
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGDemoVideoRenderTypeItem.h"

@implementation ZGDemoVideoRenderTypeItem

+ (instancetype)itemWithRenderType:(NSInteger)renderType typeName:(NSString *)typeName {
    ZGDemoVideoRenderTypeItem *item = [[ZGDemoVideoRenderTypeItem alloc] init];
    item.renderType = renderType;
    item.typeName = typeName;
    return item;
}

@end
