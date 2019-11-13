//
//  ZGExternalVideoRenderInitialVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/9/3.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_ExternalVideoRender

#import "ZGExternalVideoRenderInitialVC.h"
#import "ZGExternalVideoRenderHelper.h"
#import "ZGExternalVideoRenderPublishStreamVC.h"
#import "ZGExternalVideoRenderPlayStreamVC.h"

NSString* const ZGExternalVideoRenderInitialVCKey_roomID = @"kRoomID";
NSString* const ZGExternalVideoRenderInitialVCKey_streamID = @"kStreamID";

@interface ZGExternalVideoRenderInitialVC () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) IBOutlet UITextField *roomIDTxf;
@property (nonatomic, weak) IBOutlet UITextField *streamIDTxf;
@property (nonatomic, weak) IBOutlet UIPickerView *renderTypePicker;

@property (nonatomic, copy) NSArray<ZGDemoVideoRenderTypeItem*> *renderTypeItems;

@end

@implementation ZGExternalVideoRenderInitialVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.renderTypeItems = [ZGExternalVideoRenderHelper demoRenderTypeItems];
    
    self.navigationItem.title = @"视频外部渲染";
    self.roomIDTxf.text = [self savedValueForKey:ZGExternalVideoRenderInitialVCKey_roomID];
    self.streamIDTxf.text = [self savedValueForKey:ZGExternalVideoRenderInitialVCKey_streamID];
    
    self.renderTypePicker.delegate = self;
    self.renderTypePicker.dataSource = self;
    [self.renderTypePicker reloadAllComponents];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (IBAction)startPublishButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    ZGExternalVideoRenderPublishStreamVC *vc = [ZGExternalVideoRenderPublishStreamVC instanceFromStoryboard];
    vc.roomID = roomID;
    vc.streamID = streamID;
    vc.previewRenderType = [self selectedVideoRenderType];
    
    [self saveValue:roomID forKey:ZGExternalVideoRenderInitialVCKey_roomID];
    [self saveValue:streamID forKey:ZGExternalVideoRenderInitialVCKey_streamID];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)startPlayButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    ZGExternalVideoRenderPlayStreamVC *vc = [ZGExternalVideoRenderPlayStreamVC instanceFromStoryboard];
    vc.roomID = roomID;
    vc.streamID = streamID;
    vc.viewRenderType = [self selectedVideoRenderType];
    
    // TODO: 保存上一次的 renderType
    [self saveValue:roomID forKey:ZGExternalVideoRenderInitialVCKey_roomID];
    [self saveValue:streamID forKey:ZGExternalVideoRenderInitialVCKey_streamID];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)goTopicSiteButnClick:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/267.html"]];
}

#pragma mark - private methods

- (BOOL)checkInputNotEmptyAndReturnRoomID:(NSString **)roomID streamID:(NSString **)streamID {
    *roomID = self.roomIDTxf.text;
    *streamID = self.streamIDTxf.text;
    if ((*roomID).length == 0 || (*streamID).length == 0) {
        NSLog(@"`roomID` or `streamID` is empty.");
        return NO;
    }
    return YES;
}

- (VideoRenderType)selectedVideoRenderType {
    NSInteger idx = [self.renderTypePicker selectedRowInComponent:0];
    return (VideoRenderType)self.renderTypeItems[idx].renderType;
}

#pragma mark - picker view dataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.renderTypeItems.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.renderTypeItems[row].typeName;
}

@end
#endif
