//
//  ZGAudioPlayerInitVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioPlayer

#import "ZGAudioPlayerInitVC.h"
#import "ZGAudioPlayerPublishStreamVC.h"
#import "ZGAudioPlayerPlayStreamVC.h"

NSString* const ZGAudioPlayerInitVCKey_roomID = @"kRoomID";
NSString* const ZGAudioPlayerInitVCKey_streamID = @"kStreamID";

@interface ZGAudioPlayerInitVC ()

@property (weak, nonatomic) IBOutlet UITextField *roomIDTxf;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTxf;

@end

@implementation ZGAudioPlayerInitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = _Module_AudioPlayer;
    self.roomIDTxf.text = [self savedValueForKey:ZGAudioPlayerInitVCKey_roomID];
    self.streamIDTxf.text = [self savedValueForKey:ZGAudioPlayerInitVCKey_streamID];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)startPublishStreamButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    [self saveValue:roomID forKey:ZGAudioPlayerInitVCKey_roomID];
    [self saveValue:streamID forKey:ZGAudioPlayerInitVCKey_streamID];
    
    ZGAudioPlayerPublishStreamVC *publishVC = [ZGAudioPlayerPublishStreamVC instanceFromStoryboard];
    publishVC.roomID = roomID;
    publishVC.streamID = streamID;
    [self.navigationController pushViewController:publishVC animated:YES];
}

- (IBAction)startPlayStreamButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    ZGAudioPlayerPlayStreamVC *playVC = [[ZGAudioPlayerPlayStreamVC alloc] init];
    playVC.roomID = roomID;
    playVC.streamID = streamID;
    
    [self saveValue:roomID forKey:ZGAudioPlayerInitVCKey_roomID];
    [self saveValue:streamID forKey:ZGAudioPlayerInitVCKey_streamID];
    
    [self.navigationController pushViewController:playVC animated:YES];
}

- (IBAction)gotoTopicLink:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/1222.html"]];
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
