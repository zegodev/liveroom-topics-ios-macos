//
//  ZGL3PlayTopicPlayStreamVC.m
//  LiveRoomPlayground-iOS
//
//  Created by joey on 2020/12/30.
//  Copyright © 2020 Zego. All rights reserved.
//

#import "ZGL3PlayTopicPlayStreamVC.h"
#import <ZegoLiveRoom/ZegoLiveRoom.h>
#import "ZGAppGlobalConfigManager.h"
#import "ZGAppSignHelper.h"
#import <ZegoLiveRoom/zego-api-media-side-info-oc.h>

@interface ZGL3PlayTopicPlayStreamVC ()<ZegoRoomDelegate, ZegoMediaSideDelegate>
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIView *playView;
@property (weak, nonatomic) IBOutlet UITextView *processTipTextView;

@property(strong, nonatomic) ZegoLiveRoomApi *api;
@property (strong, nonatomic) ZegoMediaSideInfo* mediaSideInfoApi;
@property(copy, nonatomic) NSString *playStreamID;
@property(copy, nonatomic) NSString *publishStreamID;
@property(copy, nonatomic) NSString *roomID;
@property(copy, nonatomic) NSString *userID;

@end

@implementation ZGL3PlayTopicPlayStreamVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.playStreamID = @"998";
    self.publishStreamID = @"998";
    self.roomID = @"5667";
    self.userID = @([NSDate date].timeIntervalSince1970).stringValue;
    
    ZGAppGlobalConfig *appConfig = [[ZGAppGlobalConfigManager sharedInstance] globalConfig];
    self.api = [[ZegoLiveRoomApi alloc] initWithAppID:(unsigned int)appConfig.appID appSignature:[ZGAppSignHelper convertAppSignFromString:appConfig.appSign] completionBlock:^(int errorCode) {
        [ZegoHudManager hideNetworkLoading];
        self.mediaSideInfoApi = [[ZegoMediaSideInfo alloc] init];
        [self.mediaSideInfoApi setMediaSideDelegate:self];
//        [self appendProcessTipAndMakeVisible:errorCode == 0?@"初始化完成":[NSString stringWithFormat:@"初始化失败，errorCode:%d",errorCode]];
        if (errorCode != 0) {
            ZGLogWarn(@"初始化失败,errorCode:%d", errorCode);
        } else {
            ZGLogInfo(@"初始化成功");
            [self appendProcessTipAndMakeVisible:@"初始化成功"];
            [self.api setPreviewView:self.previewView];
            [self.api startPreview];
        }
    }];
    [self.api setRoomDelegate:self];
    // Do any additional setup after loading the view.
}

- (IBAction)login:(id)sender {
    [ZegoLiveRoomApi setUserID:self.userID userName:self.userID];
    [self.api loginRoom:self.roomID role:ZEGO_ANCHOR withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        NSLog(@"登录 %d", errorCode);
        if (errorCode == 0) {
            [self appendProcessTipAndMakeVisible:@"登录成功"];
            // 登录房间成功
            // 推流前激活媒体次要信息通道，推流之后才能发送次要信息
            [self.mediaSideInfoApi setMediaSideFlags:YES onlyAudioPublish:NO channelIndex:0];
        } else {
            [self appendProcessTipAndMakeVisible:@"登录失败"];
        }
    }];
}
- (IBAction)publish:(id)sender {
    [self.api startPublishing:self.publishStreamID title:self.publishStreamID flag:ZEGOAPI_JOIN_PUBLISH];
    [self appendProcessTipAndMakeVisible:@"开始推流"];

}
- (IBAction)publishDate:(id)sender {
    NSString *timeNow = @([[NSDate date] timeIntervalSince1970]).stringValue;
    [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"发送媒体次要信息时间：%@", timeNow]];

    [self sendMediaSideInfoString: timeNow];
}
- (IBAction)playStream:(id)sender {
    [self.api stopPlayingStream:self.playStreamID];
    [self.api startPlayingStream:self.playStreamID inView:self.playView];
    [self appendProcessTipAndMakeVisible:@"开始拉流"];
}
- (IBAction)l3PlayStream:(id)sender {
    ZegoAPIStreamExtraPlayInfo *info = [[ZegoAPIStreamExtraPlayInfo alloc] init];
    info.mode = L3_ONLY;
    [self.api stopPlayingStream:self.playStreamID];
    [self.api startPlayingStream:self.playStreamID inView:self.playView extraInfo:info];
    [self appendProcessTipAndMakeVisible:@"开始 L3 拉流"];

}
- (IBAction)reset:(id)sender {
    [self.api stopPublishing];
    [self.api stopPlayingStream:self.playStreamID];
    [self appendProcessTipAndMakeVisible:@"重置"];
    [self clearProcessTips];

}



- (void)sendMediaSideInfoString:(NSString *)info {
    NSData *messageData = [info dataUsingEncoding:NSUTF8StringEncoding];
    [self sendMediaSideInfo:messageData];
}

- (void)sendMediaSideInfo:(NSData *)data {
    [self.mediaSideInfoApi sendMediaSideInfo:data
                         packet:NO
                   channelIndex:ZEGOAPI_CHN_MAIN];
}


- (void)appendProcessTipAndMakeVisible:(NSString *)tipText {
    if (!tipText || tipText.length == 0) {
        return;
    }
    
    NSString *oldText = self.processTipTextView.text;
    NSString *newText = [NSString stringWithFormat:@"%@\n%@", oldText, tipText];
    
    self.processTipTextView.text = newText;
    if(newText.length > 0 ) {
        UITextView *textView = self.processTipTextView;
        NSRange bottom = NSMakeRange(newText.length -1, 1);
        [textView scrollRangeToVisible:bottom];
        //        NSRange range = NSMakeRange(textView.text.length, 0);
        //        [textView scrollRangeToVisible:range];
        // an iOS bug, see https://stackoverflow.com/a/20989956/971070
        [textView setScrollEnabled:NO];
        [textView setScrollEnabled:YES];
    }
}

- (void)clearProcessTips {
    self.processTipTextView.text = @"";
}


- (void)onRecvMediaSideInfo:(NSData *)data ofStream:(NSString *)streamID {
    NSLog(@"MEDIA_SIDE_INFO: %@", streamID);
    NSLog(@"MEDIA_SIDE_INFO: %@", data);
    
    uint32_t mediaType = ntohl(*(uint32_t*)data.bytes);
    
    if (mediaType == 1001) {
        // * SDK packet
        NSData* realData = [data subdataWithRange:NSMakeRange(4, data.length - 4)];
        NSLog(@"%s", __func__);
        // 收到媒体次要信息
        if (!realData) { return; }
        NSString *message = [[NSString alloc] initWithData:realData encoding:NSUTF8StringEncoding];
        if (!message) { return; }
        
        ZGLogInfo(@"收到媒体次要信息，message:%@", message);
//        [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"收到媒体次要信息内容：%@", message]];
        NSString *timeNow = @([[NSDate date] timeIntervalSince1970]).stringValue;
        [self appendProcessTipAndMakeVisible:[NSString stringWithFormat:@"收到媒体次要信息时间：%@", timeNow]];
    }

}


@end
