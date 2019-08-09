//
//  ZGVideoFilterSyncDemo.h
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/30.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 同步类型外部滤镜实现
 */
@interface ZGVideoFilterSyncDemo : NSObject<ZegoVideoFilter, ZegoVideoFilterDelegate>

@end

NS_ASSUME_NONNULL_END

#endif
