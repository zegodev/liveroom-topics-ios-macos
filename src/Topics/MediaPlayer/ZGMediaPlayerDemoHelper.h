//
//  ZGMediaPlayerDemoHelper.h
//  LiveRoomPlayground
//
//  Created by Randy Qiu on 2018/9/27.
//  Copyright © 2018年 Zego. All rights reserved.
//

#ifdef _Module_MediaPlayer

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString* kZGMediaNameKey;
extern NSString* kZGMediaFileTypeKey;
extern NSString* KZGMediaSourceTypeKey;
extern NSString* kZGMediaURLKey;

@interface ZGMediaPlayerDemoHelper : NSObject

+ (NSArray<NSDictionary*>*)mediaList;
+ (NSString*)titleForItem:(NSDictionary*)item;

@end

NS_ASSUME_NONNULL_END

#endif
