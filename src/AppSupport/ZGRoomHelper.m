//
//  ZGRoomHelper.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGRoomHelper.h"

@implementation ZGRoomHelper

+ (NSString *)zegoQueryRoomListUrlWithAppID:(unsigned int)appID isTestEnv:(BOOL)isTestEnv {
    NSString *baseUrl = nil;
    if (isTestEnv) {
        baseUrl = @"https://test2-liveroom-api.zego.im";
    }
    else {
        baseUrl = [NSString stringWithFormat:@"https://liveroom%u-api.zego.im", appID];
    }
    return [NSString stringWithFormat:@"%@/demo/roomlist?appid=%u", baseUrl, appID];
}

+ (void)queryRoomListWithAppID:(unsigned int)appID
                     isTestEnv:(BOOL)isTestEnv
                    completion:(void(^)(NSArray<ZGRoomInfo*> *roomList, NSError *error))completion {
    
    NSString *queryUrl = [self zegoQueryRoomListUrlWithAppID:appID isTestEnv:isTestEnv];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:queryUrl]];

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 10;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    Weakify(self);
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        Strongify(self);
        
        if (error && completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        NSArray<ZGRoomInfo *> *roomList = nil;
        NSError *parseError = nil;
        [self parseRoomListQueryResponseData:data parsedRoomList:&roomList parsedError:&parseError];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(roomList, parseError);
            }
        });
    }];
    
    [task resume];
}

/**
 解析房间列表
 
 @param respData 原数据
 @param parsedRoomList 解析到的房间列表
 @param parsedError 解析遇到的错误
 */
+ (void)parseRoomListQueryResponseData:(NSData *)respData
                        parsedRoomList:(NSArray<ZGRoomInfo *> **)parsedRoomList
                           parsedError:(NSError **)parsedError {
    
    NSError *jsonError;
    NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:respData options:0 error:&jsonError];
    if (jsonError) {
        *parsedError = jsonError;
        return;
    }
    
#if DEBUG
    NSLog(@"%@", jsonResponse);
#endif
    NSUInteger code = [jsonResponse[@"code"] integerValue];
    if (code != 0) {
        return;
    }
    
    NSMutableArray *newRoomList = [NSMutableArray<ZGRoomInfo *> array];
    NSArray *roomList = jsonResponse[@"data"][@"room_list"];
    for (int idx = 0; idx < roomList.count; idx++) {
        NSDictionary *infoDict = roomList[idx];
        NSString *roomID = infoDict[@"room_id"];
        NSString *anchorID = infoDict[@"anchor_id_name"];
        if (roomID.length == 0) {
            continue;
        }
        
        ZGRoomInfo *info = [ZGRoomInfo new];
        
        info.roomID = roomID;
        info.anchorID = anchorID;
        info.anchorName = infoDict[@"anchor_nick_name"];
        info.roomName = infoDict[@"room_name"];
        
        info.streamInfo = [[NSMutableArray alloc] init];
        for (NSDictionary *dict in infoDict[@"stream_info"]) {
            [info.streamInfo addObject:dict[@"stream_id"]];
        }
        
        [newRoomList addObject:info];
    }
    
    *parsedRoomList = [newRoomList copy];
}

@end
