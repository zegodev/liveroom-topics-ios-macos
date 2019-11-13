//
//  ZGRoomMessageCell.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGRoomMessageCell.h"

@interface ZGRoomMessageCell ()

@property (nonatomic, weak) IBOutlet UIView *messageTypeTipView;
@property (nonatomic, weak) IBOutlet UILabel *messageContentLabel;

@end

@implementation ZGRoomMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.messageTypeTipView.backgroundColor = [UIColor clearColor];
    self.messageContentLabel.text = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setMessage:(ZGRoomMessageTopicMessage *)message {
    _message = message;
    
    // message type 处理
    NSInteger messageType = message.messageType;
    if (messageType == 1) {
        self.messageTypeTipView.backgroundColor = [UIColor blueColor];
    } else if (messageType == 2) {
        self.messageTypeTipView.backgroundColor = [UIColor magentaColor];
    } else if (messageType == 3) {
        self.messageTypeTipView.backgroundColor = [UIColor greenColor];
    }
    
    // content 处理
    self.messageContentLabel.text = [NSString stringWithFormat:@"%@:%@", message.userID, message.messageContent];
}

@end
