//
//  ZGMediaPlayerDemoHelper.m
//  LiveRoomPlayground
//
//  Created by Randy Qiu on 2018/9/27.
//  Copyright © 2018年 Zego. All rights reserved.
//

#ifdef _Module_MediaPlayer

#import "ZGMediaPlayerDemoHelper.h"

#if TARGET_OS_OSX
#import <MediaLibrary/MediaLibrary.h>
#endif

#import <MediaPlayer/MediaPlayer.h>

NSString* kZGMediaNameKey = @"name";
NSString* kZGMediaFileTypeKey = @"file-type";
NSString* KZGMediaSourceTypeKey = @"source-type";
NSString* kZGMediaURLKey = @"url";

@implementation ZGMediaPlayerDemoHelper

+ (NSArray<NSDictionary *> *)mediaList {
    
    static NSArray* s_mediaList = nil;
    if (!s_mediaList) {
        NSArray* list = @[@{
                              kZGMediaNameKey: @"audio clip(-50% tempo)",
                              kZGMediaFileTypeKey: @"mp3",
                              KZGMediaSourceTypeKey: @"local",
                              kZGMediaURLKey: [[NSBundle mainBundle] pathForResource:@"sample_-50_tempo" ofType:@"mp3"]
                              },
                          @{
                              kZGMediaNameKey: @"ad",
                              kZGMediaFileTypeKey: @"mp4",
                              KZGMediaSourceTypeKey: @"local",
                              kZGMediaURLKey: [[NSBundle mainBundle] pathForResource:@"ad" ofType:@"mp4"]
                              },
                          @{
                              kZGMediaNameKey: @"audio clip",
                              kZGMediaFileTypeKey: @"mp3",
                              KZGMediaSourceTypeKey: @"online",
                              kZGMediaURLKey: @"http://www.surina.net/soundtouch/sample_orig.mp3"
                              },
                          @{
                              kZGMediaNameKey: @"大海",
                              kZGMediaFileTypeKey: @"mp4",
                              KZGMediaSourceTypeKey: @"online",
                              kZGMediaURLKey: @"http://lvseuiapp.b0.upaiyun.com/201808270915.mp4"
                              }];
                          
        s_mediaList = [list arrayByAddingObjectsFromArray:[self getAVAssetPath]];
    }
    
    return s_mediaList;
}

+ (NSString*)titleForItem:(NSDictionary*)item {
    NSString* name = item[kZGMediaNameKey];
    NSString* fileType = item[kZGMediaFileTypeKey];
    NSString* source = item[KZGMediaSourceTypeKey];
    
    return [NSString stringWithFormat:@"[%@][%@] %@", source, fileType, name];
}

+ (NSArray*)getAVAssetPath {
#if TARGET_OS_IOS
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.3) {
        return @[];
    }
    
    __block BOOL hasAuth = NO;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    MPMediaLibraryAuthorizationStatus authStatus = [MPMediaLibrary authorizationStatus];
    switch (authStatus) {
        case MPMediaLibraryAuthorizationStatusNotDetermined:
            [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
                NSLog(@"%s, %d", __func__, (int)status);
                if (status == MPMediaLibraryAuthorizationStatusAuthorized) {
                    hasAuth = YES;
                }
            }];
            break;
            
        case MPMediaLibraryAuthorizationStatusDenied:
        case MPMediaLibraryAuthorizationStatusRestricted:
            break;
        case MPMediaLibraryAuthorizationStatusAuthorized:
            hasAuth = YES;
        default:
            break;
    }
#pragma clang diagnostic pop
    
    if (!hasAuth) return @[];
    
    MPMediaQuery *query = [MPMediaQuery songsQuery];

    const int MAX_COUNT = 50;
    NSMutableArray* songList = [NSMutableArray array];
    
    int cnt = 0;
    for (MPMediaItemCollection *collection in query.collections) {
        for (MPMediaItem *item in collection.items) {
            
            NSString* title = [item title];
            NSString* url = [[item valueForProperty:MPMediaItemPropertyAssetURL] absoluteString];
            if (url.length == 0 || title.length == 0) continue;
            
            [songList addObject:@{
                                  kZGMediaNameKey: title,
                                  kZGMediaFileTypeKey: @"itunes",
                                  KZGMediaSourceTypeKey: @"local",
                                  kZGMediaURLKey: url
                                  }];
            cnt++;
            
            if (cnt >= MAX_COUNT) break;
        }
        if (cnt >= MAX_COUNT) break;
    }
    
    return songList;
#else
    return @[];
#endif
}

@end

#endif
