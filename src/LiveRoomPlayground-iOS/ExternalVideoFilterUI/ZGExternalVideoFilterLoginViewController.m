//
//  ZGExternalVideoFilterLoginViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/7/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ExternalVideoFilter

#import "ZGExternalVideoFilterLoginViewController.h"
#import "ZGExternalVideoFilterPublishViewController.h"
#import "ZGExternalVideoFilterPlayViewController.h"

// 检查一下是否有 FaceUnity 的鉴权
#import "authpack.h"

static NSString *ZGExternalVideoFilterRoomID = @"ZGExternalVideoFilterRoomID";
static NSString *ZGExternalVideoFilterStreamID = @"ZGExternalVideoFilterStreamID";

@interface ZGExternalVideoFilterLoginViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UIPickerView *typePickerView;
@property (weak, nonatomic) IBOutlet UIButton *jumpToPublishButton;
@property (weak, nonatomic) IBOutlet UIButton *jumpToPlayButton;

@property (nonatomic, copy) NSArray<NSString *> *filterBufferTypeList;
@property (nonatomic, assign) NSInteger selectedFilterBufferType;

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *userName;

@end

@implementation ZGExternalVideoFilterLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.roomIDTextField.text = [self savedValueForKey:ZGExternalVideoFilterRoomID];
    self.streamIDTextField.text = [self savedValueForKey:ZGExternalVideoFilterStreamID];
    
    // 检查一下是否有 FaceUnity 的鉴权
    [self checkFaceUnityAuthPack];
    
    [self setupUI];
    self.filterBufferTypeList = @[@"AsyncPixelBufferType", @"AsyncI420PixelBufferType", @"SyncPixelBufferType"];
}

- (void)setupUI {
    self.typePickerView.delegate = self;
    self.typePickerView.dataSource = self;
    [self pickerView:self.typePickerView didSelectRow:0 inComponent:0];
}

#pragma mark - Actions

- (IBAction)jumpToExternalVideoFilterPublish:(id)sender {
    if (self.roomIDTextField.text.length > 0 && self.streamIDTextField.text.length > 0) {
        [self saveValue:self.roomIDTextField.text forKey:ZGExternalVideoFilterRoomID];
        [self saveValue:self.streamIDTextField.text forKey:ZGExternalVideoFilterStreamID];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoFilter" bundle:nil];
        ZGExternalVideoFilterPublishViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGExternalVideoFilterPublishViewController"];
        vc.roomID = self.roomIDTextField.text;
        vc.streamID = self.streamIDTextField.text;
        vc.selectedFilterBufferType = self.selectedFilterBufferType;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [ZegoHudManager showMessage:@"未填房间ID或流ID"];
    }
}

- (IBAction)jumpToExternalVideoFilterPlay:(id)sender {
    if (self.roomIDTextField.text.length > 0 && self.streamIDTextField.text.length > 0) {
        [self saveValue:self.roomIDTextField.text forKey:ZGExternalVideoFilterRoomID];
        [self saveValue:self.streamIDTextField.text forKey:ZGExternalVideoFilterStreamID];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"ExternalVideoFilter" bundle:nil];
        ZGExternalVideoFilterPlayViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGExternalVideoFilterPlayViewController"];
        vc.roomID = self.roomIDTextField.text;
        vc.streamID = self.streamIDTextField.text;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [ZegoHudManager showMessage:@"未填房间ID或流ID"];
    }
}

- (IBAction)jumpToExternalVideoFilterTopicLink:(UIButton *)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/273.html"]];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - Private Method

// 检查一下是否有 FaceUnity 的鉴权，证书获取方法详见
// https://github.com/Faceunity/FULiveDemo/blob/master/docs/iOS_Nama_SDK_%E9%9B%86%E6%88%90%E6%8C%87%E5%AF%BC%E6%96%87%E6%A1%A3.md#331-%E5%AF%BC%E5%85%A5%E8%AF%81%E4%B9%A6
// 获取证书后，替换至 /LiveRoomPlayground/Topics/ExternalVideoFilter/FaceUnity-SDK-iOS/authpack.h 内。
- (void)checkFaceUnityAuthPack {
    if (sizeof(g_auth_package) < 1) {
        self.jumpToPlayButton.hidden = YES;
        self.jumpToPublishButton.enabled = NO;
        self.jumpToPublishButton.backgroundColor = [UIColor clearColor];
        self.jumpToPublishButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.jumpToPublishButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.jumpToPublishButton setTitle:@"检测到缺少 FaceUnity 证书\n请联系 FaceUnity 获取测试证书\n并替换到 authpack.h" forState:UIControlStateNormal];
        [self.jumpToPublishButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }
}

#pragma mark - UIPickerViewDataSource, UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.filterBufferTypeList.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.filterBufferTypeList[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row == 0) {
        self.selectedFilterBufferType = ZegoVideoBufferTypeAsyncPixelBuffer;
    } else if (row == 1) {
        self.selectedFilterBufferType = ZegoVideoBufferTypeAsyncI420PixelBuffer;
    } else {
        self.selectedFilterBufferType = ZegoVideoBufferTypeSyncPixelBuffer;
    }
}

@end

#endif
