//
//  ZGAudioProcessInitVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessInitVC.h"
#import "ZGAudioProcessPublishStreamVC.h"
#import "ZGAudioProcessPlayStreamVC.h"

NSString* const ZGAudioProcessInitVCKey_roomID = @"kRoomID";
NSString* const ZGAudioProcessInitVCKey_streamID = @"kStreamID";

@interface ZGAudioProcessInitVC ()

@property (weak, nonatomic) IBOutlet UITextField *roomIDTxf;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTxf;

@end

@implementation ZGAudioProcessInitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"变声、立体声、混响";
    self.roomIDTxf.text = [self savedValueForKey:ZGAudioProcessInitVCKey_roomID];
    self.streamIDTxf.text = [self savedValueForKey:ZGAudioProcessInitVCKey_streamID];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)startPublishStreamButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    [self saveValue:roomID forKey:ZGAudioProcessInitVCKey_roomID];
    [self saveValue:streamID forKey:ZGAudioProcessInitVCKey_streamID];
    
    // 到推流页面
    ZGAudioProcessPublishStreamVC *publishVC = [ZGAudioProcessPublishStreamVC instanceFromStoryboard];
    publishVC.roomID = roomID;
    publishVC.streamID = streamID;
    [self.navigationController pushViewController:publishVC animated:YES];
}

- (IBAction)startPlayStreamButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    ZGAudioProcessPlayStreamVC *playVC = [ZGAudioProcessPlayStreamVC instanceFromStoryboard];
    playVC.roomID = roomID;
    playVC.streamID = streamID;
    
    [self saveValue:roomID forKey:ZGAudioProcessInitVCKey_roomID];
    [self saveValue:streamID forKey:ZGAudioProcessInitVCKey_streamID];
    
    [self.navigationController pushViewController:playVC animated:YES];
}

- (IBAction)gotoTopicLink:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/749.html"]];
}

- (BOOL)checkInputNotEmptyAndReturnRoomID:(NSString **)roomID streamID:(NSString **)streamID {
    *roomID = self.roomIDTxf.text;
    *streamID = self.streamIDTxf.text;
    if ((*roomID).length == 0 || (*streamID).length == 0) {
        NSLog(@"`roomID` or `streamID` is empty.");
        return NO;
    }
    return YES;
}

@end
#endif
