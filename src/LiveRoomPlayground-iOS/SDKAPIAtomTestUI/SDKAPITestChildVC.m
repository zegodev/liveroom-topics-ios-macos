//
//  SDKAPITestChildVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2020/3/4.
//  Copyright © 2020 Zego. All rights reserved.
//

#import "SDKAPITestChildVC.h"
#import "ZGAppSignHelper.h"
#import "SDKAPITestMacros.h"
#import "ZGAppGlobalConfigManager.h"
#import <ZegoLiveRoom/ZegoLiveRoomApi.h>

@interface SDKAPITestChildVC ()

@property (nonatomic) ZegoLiveRoomApi *liveRoomApi;

#pragma mark - Property Section: Init

@property (nonatomic, weak) IBOutlet UITextField *appIDTxf;
@property (nonatomic, weak) IBOutlet UITextField *appSignTxf;
@property (nonatomic, weak) IBOutlet UITextField *userIDTxf;
@property (nonatomic, weak) IBOutlet UITextField *userNameTxf;
@property (nonatomic, weak) IBOutlet UITextField *setConfigTxf;
@property (nonatomic, weak) IBOutlet UISwitch *verboseSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *useTestEnvSwitch;
@property (nonatomic, weak) IBOutlet UITextField *logSizeTxf;


#pragma mark - Property Section: Room

@property (nonatomic, weak) IBOutlet UITextField *roomIDTxf;
@property (nonatomic, weak) IBOutlet UITextField *roomNameTxf;
@property (nonatomic, weak) IBOutlet UISegmentedControl *roleSegCtrl;
@property (nonatomic, weak) IBOutlet UITextField *customTokenTxf;
@property (nonatomic, weak) IBOutlet UISwitch *roomConfig_audienceCreateRoomSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *roomConfig_userStateUpdateSwitch;

@end

@implementation SDKAPITestChildVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadDefaults];
}

- (void)loadDefaults {
    self.appIDTxf.text = [self savedValueForKey:SDKAPITestFieldKey_appID];
    self.appSignTxf.text = [self savedValueForKey:SDKAPITestFieldKey_appSign];
    self.userIDTxf.text = [self savedValueForKey:SDKAPITestFieldKey_userID];
    self.userNameTxf.text = [self savedValueForKey:SDKAPITestFieldKey_userName];
    self.setConfigTxf.text = [self savedValueForKey:SDKAPITestFieldKey_setConfigText];
    self.logSizeTxf.text = [self savedValueForKey:SDKAPITestFieldKey_logSize];
    self.roomIDTxf.text = [self savedValueForKey:SDKAPITestFieldKey_roomID];
    self.roomNameTxf.text = [self savedValueForKey:SDKAPITestFieldKey_roomName];
    self.customTokenTxf.text = [self savedValueForKey:SDKAPITestFieldKey_customToken];
}

- (void)handleApiCallLog:(NSString *)logTxt {
    if (self.APICallLogDisplayHandler) {
        self.APICallLogDisplayHandler([NSString stringWithFormat:@"%@\n", logTxt]);
    }
}

#pragma mark - Action Section: Init

- (IBAction)click_setDefaultAppID:(id)sender {
    self.appIDTxf.text = [NSString stringWithFormat:@"%@", @([ZGAppGlobalConfigManager sharedInstance].globalConfig.appID)];
}

- (IBAction)click_setDefaultAppSign:(id)sender {
    self.appSignTxf.text = [ZGAppGlobalConfigManager sharedInstance].globalConfig.appSign;
}

- (IBAction)click_initApi:(id)sender {
    unsigned int appid = (unsigned int)[self.appIDTxf.text longLongValue];
    NSData *appsign = nil;
    NSString *signStr = self.appSignTxf.text;
    if (signStr.length > 0) {
        appsign = [ZGAppSignHelper convertAppSignFromString:signStr];
    }
    
    if (appid <= 0 || appsign == nil) return;
    
    ZegoLiveRoomApi *roomApi = [[ZegoLiveRoomApi alloc] initWithAppID:appid appSignature:appsign completionBlock:^(int errorCode) {
        NSString *log = nil;
        if (errorCode == 0) {
            log = @"初始化回调 SDK，成功";
            ZGLogInfo(log, nil);
        } else {
            log = [NSString stringWithFormat:@"初始化回调 SDK，失败, errorCode:%d", errorCode];
            ZGLogError(log, nil);
        }
        [self handleApiCallLog:log];
    }];
    
    [self saveValue:@(appid).stringValue forKey:SDKAPITestFieldKey_appID];
    [self saveValue:signStr forKey:SDKAPITestFieldKey_appSign];
    
    NSString *log = [NSString stringWithFormat:@"请求初始化SDK。roomApi:%@", roomApi];
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
    self.liveRoomApi = roomApi;
}

- (IBAction)click_UnInitApi:(id)sender {
    self.liveRoomApi = nil;
    NSString *log = @"Uninit ZegoLiveRoomApi.";
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
}

- (IBAction)click_setUserID:(id)sender {
    NSString *userID = self.userIDTxf.text;
    NSString *userName = self.userNameTxf.text;
    if (userID.length > 0 && userName.length > 0) {
        BOOL ret = [ZegoLiveRoomApi setUserID:userID userName:userName];
        
        [self saveValue:userID forKey:SDKAPITestFieldKey_userID];
        [self saveValue:userName forKey:SDKAPITestFieldKey_userName];
        
        NSString *log = [NSString stringWithFormat:@"setUserID:%@ userName:%@, ret:%d", userID, userName, ret];
        ZGLogInfo(log, nil);
        [self handleApiCallLog:log];
    }
}

- (IBAction)click_setConfig:(id)sender {
    NSString *confTxt = self.setConfigTxf.text;
    if (confTxt.length > 0) {
        [ZegoLiveRoomApi setConfig:confTxt];
        
        [self saveValue:confTxt forKey:SDKAPITestFieldKey_setConfigText];
        
        NSString *log = [NSString stringWithFormat:@"setConfig:%@", confTxt];
        ZGLogInfo(log, nil);
        [self handleApiCallLog:log];
    }
}

- (IBAction)click_version:(id)sender {
    NSString *version = [ZegoLiveRoomApi version];
    [self handleApiCallLog:[NSString stringWithFormat:@"version:%@", version]];
}

- (IBAction)click_version2:(id)sender {
    NSString *version2 = [ZegoLiveRoomApi version2];
    [self handleApiCallLog:[NSString stringWithFormat:@"version2:%@", version2]];
}

- (IBAction)click_setUseTestEnv:(id)sender {
    BOOL useTest = self.useTestEnvSwitch.isOn;
    [ZegoLiveRoomApi setUseTestEnv:useTest];
    
    NSString *log = [NSString stringWithFormat:@"setUseTestEnv:%d", useTest];
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
}

- (IBAction)click_setVerbose:(id)sender {
    BOOL verbose = self.verboseSwitch.isOn;
    [ZegoLiveRoomApi setVerbose:verbose];
    
    NSString *log = [NSString stringWithFormat:@"setVerbose:%d", verbose];
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
}

- (IBAction)click_setLogSize:(id)sender {
    unsigned int logSize = (unsigned int)[self.logSizeTxf.text longLongValue];
    [ZegoLiveRoomApi setLogSize:logSize];
    
    [self saveValue:@(logSize).stringValue forKey:SDKAPITestFieldKey_logSize];
    
    NSString *log = [NSString stringWithFormat:@"setLogSize:%d", logSize];
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
}

- (IBAction)click_uploadLog:(id)sender {
    [ZegoLiveRoomApi uploadLog];
    NSString *log = @"uploadLog";
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
}


#pragma mark - Action Section: Room

- (IBAction)click_loginRoom:(id)sender {
    if (!self.liveRoomApi) return;
    
    NSString *roomID = self.roomIDTxf.text;
    NSString *roomName = self.roomNameTxf.text;
    int role = (int)[self.roleSegCtrl selectedSegmentIndex] + 1;
    if (roomID.length == 0 || roomName.length == 0) {
        return;
    }
    
    BOOL ret = [self.liveRoomApi loginRoom:roomID roomName:roomName role:role withCompletionBlock:^(int errorCode, NSArray<ZegoStream *> *streamList) {
        NSString *log = nil;
        if (errorCode == 0) {
            log = [NSString stringWithFormat:@"回调 loginRoom 成功"];
        } else {
            log = [NSString stringWithFormat:@"回调 loginRoom 失败, errorCode:%d", errorCode];
        }
        ZGLogInfo(log, nil);
        [self handleApiCallLog:log];
    }];
    
    NSString *log = [NSString stringWithFormat:@"请求 loginRoom. roomID:%@, roomName:%@ ret:%d", roomID, roomName, ret];
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
}

- (IBAction)click_logoutRoom:(id)sender {
    if (!self.liveRoomApi) return;
    BOOL ret = [self.liveRoomApi logoutRoom];
    
    NSString *log = [NSString stringWithFormat:@"请求 logoutRoom, ret:%d", ret];
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
}

- (IBAction)click_setRoomConfig:(id)sender {
    if (!self.liveRoomApi) return;
    
    BOOL audienceCreateRoom = self.roomConfig_audienceCreateRoomSwitch.isOn;
    BOOL userStateUpdate = self.roomConfig_userStateUpdateSwitch.isOn;
    
    [self.liveRoomApi setRoomConfig:audienceCreateRoom userStateUpdate:userStateUpdate];
    
    NSString *log = [NSString stringWithFormat:@"setRoomConfig:%d userStateUpdate:%d", audienceCreateRoom, userStateUpdate];
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
}

- (IBAction)click_setCustomToken:(id)sender {
    if (!self.liveRoomApi) return;
    
    NSString *customToken = self.customTokenTxf.text;
    if (customToken.length == 0) return;
    
    [self.liveRoomApi setCustomToken:customToken];
    
    NSString *log = [NSString stringWithFormat:@"setCustomToken:%@", customToken];
    ZGLogInfo(log, nil);
    [self handleApiCallLog:log];
}

@end
