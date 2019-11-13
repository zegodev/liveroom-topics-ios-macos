//
//  ZGExternalVideoRenderPublishStreamVC.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_ExternalVideoRender

#import <UIKit/UIKit.h>
#import <ZegoLiveRoom/zego-api-external-video-render-oc.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGExternalVideoRenderPublishStreamVC : UIViewController

@property (nonatomic, copy) NSString *roomID;
@property (nonatomic, copy) NSString *streamID;
@property (nonatomic, assign) VideoRenderType previewRenderType;

+ (instancetype)instanceFromStoryboard;

@end

NS_ASSUME_NONNULL_END
#endif
