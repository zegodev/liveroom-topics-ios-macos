//
//  ZGMixStreamInfoView.h
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/24.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZGMixStreamInfoView : UIView

@property (nonatomic, weak) IBOutlet UILabel *mixStreamInfoLabel;
@property (nonatomic, weak) IBOutlet UILabel *anchorSoundLevelInfoLabel;
@property (nonatomic, weak) IBOutlet UILabel *audienceSoundLevelInfoLabel;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)viewFromNib;

- (CGSize)intrinsicContentSize;

@end

NS_ASSUME_NONNULL_END
