//
//  ZGRoomMesageInitVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_RoomMessage

#import "ZGRoomMesageInitVC.h"
#import "ZGRoomMessageInteractVC.h"

NSString* const ZGRoomMesageInitVCRoomIDKey = @"roomID";

@interface ZGRoomMesageInitVC ()

@property (weak, nonatomic) IBOutlet UITextField *roomIDTxf;

@end

@implementation ZGRoomMesageInitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"房间消息";
    
    NSString *roomID = [self savedValueForKey:ZGRoomMesageInitVCRoomIDKey];
    self.roomIDTxf.text = roomID;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)loginRoomButnClick:(id)sender {
    NSString *roomID = self.roomIDTxf.text;
    if (roomID.length == 0) {
        return;
    }
    
    [self saveValue:roomID forKey:ZGRoomMesageInitVCRoomIDKey];
    ZGRoomMessageInteractVC *nextVC = [ZGRoomMessageInteractVC instanceFromStoryboard];
    nextVC.roomID = roomID;
    [self.navigationController pushViewController:nextVC animated:YES];
}

- (IBAction)goTopicLink:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/247.html"]];
}

@end
#endif
