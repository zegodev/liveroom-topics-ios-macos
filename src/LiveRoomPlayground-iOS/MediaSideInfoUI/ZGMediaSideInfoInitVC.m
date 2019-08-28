//
//  ZGMediaSideInfoInitVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/21.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaSideInfo

#import "ZGMediaSideInfoInitVC.h"
#import "ZGMediaSideInfoPublishVC.h"
#import "ZGMediaSideInfoPlayVC.h"

NSString* const ZGMediaSideInfoInitVCKey_roomID = @"kRoomID";
NSString* const ZGMediaSideInfoInitVCKey_streamID = @"kStreamID";
NSString* const ZGMediaSideInfoInitVCKey_onlyPublishAudio = @"onlyPublishAudio";

@interface ZGMediaSideInfoInitVC ()

@property (weak, nonatomic) IBOutlet UITextField *roomIDTxf;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTxf;
@property (weak, nonatomic) IBOutlet UISwitch *onlyPublishAudioSwitch;

@end

@implementation ZGMediaSideInfoInitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.roomIDTxf.text = [self savedValueForKey:ZGMediaSideInfoInitVCKey_roomID];
    self.streamIDTxf.text = [self savedValueForKey:ZGMediaSideInfoInitVCKey_streamID];
    self.onlyPublishAudioSwitch.on = ((NSNumber *)[self savedValueForKey:ZGMediaSideInfoInitVCKey_onlyPublishAudio]).boolValue;
}

- (IBAction)startPublishStreamButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    BOOL onlyPublishAudio = self.onlyPublishAudioSwitch.isOn;
    ZGMediaSideInfoPublishVC *publishVC = [ZGMediaSideInfoPublishVC instanceFromStoryboard];
    publishVC.roomID = roomID;
    publishVC.streamID = streamID;
    publishVC.onlyAudioPublish = onlyPublishAudio;
    
    [self saveValue:roomID forKey:ZGMediaSideInfoInitVCKey_roomID];
    [self saveValue:streamID forKey:ZGMediaSideInfoInitVCKey_streamID];
    [self saveValue:@(onlyPublishAudio) forKey:ZGMediaSideInfoInitVCKey_onlyPublishAudio];
    
    [self.navigationController pushViewController:publishVC animated:YES];
}

- (IBAction)startPlayStreamButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    ZGMediaSideInfoPlayVC *playVC = [ZGMediaSideInfoPlayVC instanceFromStoryboard];
    playVC.roomID = roomID;
    playVC.streamID = streamID;
    
    [self saveValue:roomID forKey:ZGMediaSideInfoInitVCKey_roomID];
    [self saveValue:streamID forKey:ZGMediaSideInfoInitVCKey_streamID];
    
    [self.navigationController pushViewController:playVC animated:YES];
}

- (IBAction)gotoTopicLink:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/276.html"]];
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
