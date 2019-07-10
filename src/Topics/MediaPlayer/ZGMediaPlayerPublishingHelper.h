//
//  ZGMediaPlayerPublishingHelper.h
//  LiveRoomPlayground
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#ifdef _Module_MediaPlayer

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ZGMediaPlayerPublishingStateObserver)(NSString* _Nonnull);

@interface ZGMediaPlayerPublishingHelper : NSObject

- (void)startPublishing;
- (void)setPublishStateObserver:(ZGMediaPlayerPublishingStateObserver _Nullable)observer;

@end

NS_ASSUME_NONNULL_END

#endif
