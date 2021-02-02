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

+ (NSArray<NSDictionary *> *)mediaListOfType:(NSString*)ext inDirectory:(NSString*)subDir {
    NSMutableArray* infoList = [NSMutableArray array];
    NSArray<NSString*>* fileList = [[NSBundle mainBundle] pathsForResourcesOfType:ext inDirectory:subDir];
    for (NSString* wav in fileList) {
        [infoList addObject:@{
            kZGMediaNameKey: [[wav pathComponents] lastObject],
            kZGMediaFileTypeKey: ext,
            KZGMediaSourceTypeKey: @"local",
            kZGMediaURLKey: wav
        }];
    }
    
    return infoList;
}

+ (NSArray<NSDictionary *> *)mediaList {
    
    static NSArray* s_mediaList = nil;
    if (!s_mediaList) {
        s_mediaList = [NSArray array];
        s_mediaList = [s_mediaList arrayByAddingObjectsFromArray: [self mediaListOfType:@"mp3" inDirectory:@""]];
        s_mediaList = [s_mediaList arrayByAddingObjectsFromArray: [self mediaListOfType:@"mp4" inDirectory:@""]];
        s_mediaList = [s_mediaList arrayByAddingObjectsFromArray: [self mediaListOfType:@"wav" inDirectory:@"speech"]];
        s_mediaList = [s_mediaList arrayByAddingObjectsFromArray: [self mediaListOfType:@"mp3" inDirectory:@""]];
        
        NSArray* list = @[@{
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
        
        s_mediaList = [s_mediaList arrayByAddingObjectsFromArray:list];
        s_mediaList = [s_mediaList arrayByAddingObjectsFromArray:[self getAVAssetPath]];
        
        s_mediaList = [s_mediaList sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString* type1 = [obj1 objectForKey:kZGMediaFileTypeKey];
            NSString* name1 = [obj1 objectForKey:kZGMediaNameKey];
            NSString* key1 = [NSString stringWithFormat:@"%@%@", type1, name1];
            
            NSString* type2 = [obj2 objectForKey:kZGMediaFileTypeKey];
            NSString* name2 = [obj2 objectForKey:kZGMediaNameKey];
            NSString* key2 = [NSString stringWithFormat:@"%@%@", type2, name2];
                
            return [key1 compare:key2];
        }];
        
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
