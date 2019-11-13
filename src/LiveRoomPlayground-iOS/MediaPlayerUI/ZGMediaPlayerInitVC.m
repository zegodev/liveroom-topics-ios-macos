//
//  ZGMediaPlayerInitVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaPlayer

#import "ZGMediaPlayerInitVC.h"
#import "ZGMediaPlayerChooseFileVC.h"
#import "ZGMediaPlayerPublishStreamVC.h"
#import "ZGMediaPlayerPlayStreamVC.h"

NSString* const ZGMediaPlayerInitVCKey_roomID = @"kRoomID";
NSString* const ZGMediaPlayerInitVCKey_streamID = @"kStreamID";

@interface ZGMediaPlayerInitVC ()

@property (weak, nonatomic) IBOutlet UITextField *roomIDTxf;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTxf;

@end

@implementation ZGMediaPlayerInitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"媒体播放器";
    self.roomIDTxf.text = [self savedValueForKey:ZGMediaPlayerInitVCKey_roomID];
    self.streamIDTxf.text = [self savedValueForKey:ZGMediaPlayerInitVCKey_streamID];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)startPublishStreamButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    [self saveValue:roomID forKey:ZGMediaPlayerInitVCKey_roomID];
    [self saveValue:streamID forKey:ZGMediaPlayerInitVCKey_streamID];
    
    // 先到文件播放选择页面，选择成功后再到推流页面
    ZGMediaPlayerChooseFileVC *fileChooseVC = [ZGMediaPlayerChooseFileVC instanceFromStoryboard];
    fileChooseVC.fileDidSelectedHandler = ^(ZGMediaPlayerMediaItem * _Nonnull mediaItem) {
        [self.navigationController popViewControllerAnimated:NO];
        
        // 到推流页面
        ZGMediaPlayerPublishStreamVC *publishVC = [ZGMediaPlayerPublishStreamVC instanceFromStoryboard];
        publishVC.roomID = roomID;
        publishVC.streamID = streamID;
        publishVC.mediaItem = mediaItem;
        [self.navigationController pushViewController:publishVC animated:YES];
    };
    [self.navigationController pushViewController:fileChooseVC animated:YES];
}

- (IBAction)startPlayStreamButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    ZGMediaPlayerPlayStreamVC *playVC = [ZGMediaPlayerPlayStreamVC instanceFromStoryboard];
    playVC.roomID = roomID;
    playVC.streamID = streamID;
    
    [self saveValue:roomID forKey:ZGMediaPlayerInitVCKey_roomID];
    [self saveValue:streamID forKey:ZGMediaPlayerInitVCKey_streamID];
    
    [self.navigationController pushViewController:playVC animated:YES];
}

- (IBAction)gotoTopicLink:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/282.html"]];
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
