//
//  ZGSDKInitViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2019/4/17.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGSDKInitViewController.h"
#import "UIView+PopView.h"
#import "ZGLoginRoomViewController.h"
#import "ZGApiSettingHelper.h"

@interface ZGSDKInitViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *containerView;

@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UIButton *userTipBtn;
@property (weak, nonatomic) IBOutlet UIButton *appIDTipBtn;
@property (weak, nonatomic) IBOutlet UITextField *appIDTxf;
@property (weak, nonatomic) IBOutlet UIButton *appSignTipBtn;
@property (weak, nonatomic) IBOutlet UITextView *appSignTextView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *envSegmentControl;

@end

static NSString *mapString = @"0123456789abcdef";

@implementation ZGSDKInitViewController

- (void)dealloc {
    [ZGApiSettingHelper.shared reset];
    [ZGApiManager releaseApi];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupBind];
}

- (void)setupUI {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewDidScroll:)];
    [self.containerView addGestureRecognizer:tap];
    
    self.userLabel.text = [NSString stringWithFormat:@"UserID:%@",ZGHelper.userID];
    
    self.appIDTxf.text = @(ZGApiManager.appID).stringValue;
    
    NSString *signString = [self convertSignToSignString:ZGApiManager.appSign];
    self.appSignTextView.text = signString;
    self.appSignTextView.layer.masksToBounds = YES;
    self.appSignTextView.layer.cornerRadius = 5.f;
    self.appSignTextView.layer.borderColor = UIColor.lightGrayColor.CGColor;
    self.appSignTextView.layer.borderWidth = 0.5f;
}

- (void)setupBind {
    ZGApiSettingHelper *settingHelper = ZGApiSettingHelper.shared;
    
    Weakify(self);
    [self bind:settingHelper keyPath:ZGBindKeyPath(settingHelper.useTestEnv) callback:^(id value) {
        Strongify(self);
        self.envSegmentControl.selectedSegmentIndex = [value boolValue] ? 0:1;
    }];
}

- (NSString *)convertSignToSignString:(NSData *)appSign {
    NSMutableString *signString = [NSMutableString string];
    
    Byte *bytes = (Byte*)appSign.bytes;
    for (int i = 0; i < appSign.length; ++i) {
        Byte b = bytes[i];
        NSString *byteString = [self convertByteToByteString:b];
        [signString appendString:byteString];
        
        if (i != appSign.length-1) {
            [signString appendString:@","];
        }
    }
    
    return signString;
}

- (void)initSDK {
    unsigned int appID = self.appIDTxf.text.intValue;
    NSString *appSignStr = self.appSignTextView.text;
    NSData *appSign = [self convertSignStringToSign:appSignStr];
    
    [ZegoHudManager showNetworkLoading];
    
    Weakify(self);
    [ZGApiManager initApiWithAppID:appID appSign:appSign completionBlock:^(int errorCode) {
        [ZegoHudManager hideNetworkLoading];
        
        Strongify(self);
        
        BOOL success = errorCode == 0;
        
        if (!success) {
            [ZegoHudManager showMessage:@"SDK 初始化失败\n请检查网络或参数是否有效"];
            return;
        }
        
        [self jumpToLoginRoom];
    }];
}

- (NSData *)convertSignStringToSign:(NSString *)signString {
    if(signString == nil || signString.length == 0) {
        return nil;
    }
    
    signString = [signString lowercaseString];
    signString = [signString stringByReplacingOccurrencesOfString:@" " withString:@""];
    signString = [signString stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    NSArray<NSString *>* bytes = [signString componentsSeparatedByString:@","];
    
    Byte sign[32];
    int bytesLen = (int)[bytes count];
    
    for(int i = 0; i < bytesLen; i++) {
        NSString *byteStr = [bytes objectAtIndex:i];
        
        if (byteStr.length == 1) {
            sign[i] = [self convertByteStringToByte:byteStr];
        }
        else if (byteStr.length == 2) {
            Byte highByte = [self convertByteStringToByte:[byteStr substringWithRange:NSMakeRange(0, 1)]];
            Byte lowByte = [self convertByteStringToByte:[byteStr substringWithRange:NSMakeRange(1, 1)]];
            sign[i] = highByte<<4 | lowByte;
        }
        else {
            sign[i] = 0;
        }
    }
    
    NSData *signData = [NSData dataWithBytes:sign length:32];
    return signData;
}

- (Byte)convertByteStringToByte:(NSString *)byteString {
    Byte b = [mapString rangeOfString:byteString].location;
    return b;
}

- (NSString *)convertByteToByteString:(Byte)b {
    NSString *highByteStr = [mapString substringWithRange:NSMakeRange((NSUInteger)(b>>4), 1)];
    NSString *lowByteStr = [mapString substringWithRange:NSMakeRange((NSUInteger)(b&0x0f), 1)];
    return [NSString stringWithFormat:@"0x%@%@",highByteStr,lowByteStr];
}

#pragma mark - Actions

- (IBAction)onShowUserIDTip:(UIButton *)sender {
    NSString *tip = @"必须保证 UserID 的唯一性。\n可与 App 业务后台账号进行关联，UserID 还能便于 ZEGO 技术支持帮忙查找定位线上问题，建议定义一个有意义的 UserID。";
    [sender showPopViewWithMessage:tip];
}

- (IBAction)onShowAppIDTip:(UIButton *)sender {
    NSString *tip = @"AppID 和 AppSign 由 ZEGO 分配给各 App。为了安全考虑，建议将 AppSign 存储在 App 的业务后台，使用时从后台获取。";
    [sender showPopViewWithMessage:tip];
}

- (IBAction)onShowAppSignTip:(UIButton *)sender {
    NSString *tip = @"AppID 和 AppSign 由 ZEGO 分配给各 App。为了安全考虑，建议将 AppSign 存储在 App 的业务后台，使用时从后台获取。";
    [sender showPopViewWithMessage:tip];
}

- (IBAction)setSDKEnv:(UISegmentedControl *)sender {
    BOOL useTestEnv = sender.selectedSegmentIndex == 0;
    [ZGApiSettingHelper.shared setSDKUseTestEnv:useTestEnv];
}

- (IBAction)initSDK:(id)sender {
    [self initSDK];
}

- (IBAction)getAppID:(id)sender {
    [UIApplication jumpToWeb:ZGGetAppIDURL];
}

- (IBAction)getSourceCode:(id)sender {
    [UIApplication jumpToWeb:ZGInitSDKDocURL];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
}

- (void)jumpToLoginRoom {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Publish" bundle:nil];
    ZGLoginRoomViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGLoginRoomViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
