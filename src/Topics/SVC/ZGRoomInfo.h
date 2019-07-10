//
//  ZGRoomInfo.h
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2018/11/12.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGRoomInfo : NSObject

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *anchorID;
@property (nonatomic, copy) NSString *anchorName;
@property (nonatomic, copy) NSString *roomName;
@property (nonatomic, strong) NSMutableArray <NSString*>*streamInfo;   // stream_id 列表

@end

NS_ASSUME_NONNULL_END

#endif
