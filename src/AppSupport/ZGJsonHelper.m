//
//  ZGJsonHelper.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/22.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGJsonHelper.h"

@implementation ZGJsonHelper

+ (NSString *)encodeToJSON:(id)object
{
    if (object == nil)
        return nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    if (jsonData)
    {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    
    return nil;
}

+ (id)decodeFromJSON:(NSString *)jsonString
{
    if (jsonString == nil)
        return nil;
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData)
    {
        id object = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
        return object;
    }
    
    return nil;
}

@end
