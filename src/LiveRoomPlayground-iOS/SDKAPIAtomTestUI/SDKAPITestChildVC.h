//
//  SDKAPITestChildVC.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2020/3/4.
//  Copyright © 2020 Zego. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDKAPITestChildVC : UITableViewController

@property (nonatomic, copy) UIView* (^nextPreviewViewObtainBlock)(void);

@property (nonatomic, copy) UIView* (^nextPlayRenderViewObtainBlock)(void);

@property (nonatomic, copy) void (^APICallLogDisplayHandler)(NSString *logStr);

@end
