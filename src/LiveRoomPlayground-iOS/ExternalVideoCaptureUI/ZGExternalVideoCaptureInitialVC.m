//
//  ZGExternalVideoCaptureInitialVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/15.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_ExternalVideoCapture

#import "ZGExternalVideoCaptureInitialVC.h"
#import "ZGExternalVideoCapturePublishStreamVC.h"
#import "ZGExternalVideoCapturePlayStreamVC.h"


NSString* const ZGExternalVideoCaptureInitialVCKey_roomID = @"kRoomID";
NSString* const ZGExternalVideoCaptureInitialVCKey_streamID = @"kStreamID";

@interface ZGExternalVideoCaptureInitialVC ()

@property (nonatomic, weak) IBOutlet UITextField *roomIDTxf;
@property (nonatomic, weak) IBOutlet UITextField *streamIDTxf;
@property (nonatomic, weak) IBOutlet UISegmentedControl *captureSourceSegCtrl;
@property (nonatomic, weak) IBOutlet UISegmentedControl *captureDataFormatSegCtrl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *resolusionConsistencySegCtrl;

@end

@implementation ZGExternalVideoCaptureInitialVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.roomIDTxf.text = [self savedValueForKey:ZGExternalVideoCaptureInitialVCKey_roomID];
    self.streamIDTxf.text = [self savedValueForKey:ZGExternalVideoCaptureInitialVCKey_streamID];
    [self invalidateCaptureDataFormatSegCtrl];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}
- (IBAction)didChangeCaptureAndEncodeResolution:(UISegmentedControl *)sender {
    
}

- (IBAction)captureSourceValueChanged:(id)sender {
    [self invalidateCaptureDataFormatSegCtrl];
}

- (IBAction)captureDataFormatValueChanged:(id)sender {
    
}

- (IBAction)startPublishButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    ZGExternalVideoCapturePublishStreamVC *vc = [ZGExternalVideoCapturePublishStreamVC instanceFromStoryboard];
    vc.roomID = roomID;
    vc.streamID = streamID;
    vc.captureSource = self.captureSourceSegCtrl.selectedSegmentIndex + 1;
    vc.captureDataFormat = self.captureDataFormatSegCtrl.selectedSegmentIndex + 1;
    [self saveValue:roomID forKey:ZGExternalVideoCaptureInitialVCKey_roomID];
    [self saveValue:streamID forKey:ZGExternalVideoCaptureInitialVCKey_streamID];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)startPlayButnClick:(id)sender {
    NSString *roomID = nil, *streamID = nil;
    if (![self checkInputNotEmptyAndReturnRoomID:&roomID streamID:&streamID]) {
        return;
    }
    
    ZGExternalVideoCapturePlayStreamVC *vc = [ZGExternalVideoCapturePlayStreamVC instanceFromStoryboard];
    vc.roomID = roomID;
    vc.streamID = streamID;
    
    [self saveValue:roomID forKey:ZGExternalVideoCaptureInitialVCKey_roomID];
    [self saveValue:streamID forKey:ZGExternalVideoCaptureInitialVCKey_streamID];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)goTopicSiteButnClick:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/270.html"]];
}

- (void)invalidateCaptureDataFormatSegCtrl {
    NSInteger idx = self.captureSourceSegCtrl.selectedSegmentIndex;
    if (idx == 1) {
        // image source 不支持 YUV format data 获取
        [self.captureDataFormatSegCtrl setTitle:@"YUV(不支持)" forSegmentAtIndex:0];
        [self.captureDataFormatSegCtrl setEnabled:NO forSegmentAtIndex:0];
        self.captureDataFormatSegCtrl.selectedSegmentIndex = 1;
    } else {
        [self.captureDataFormatSegCtrl setTitle:@"YUV" forSegmentAtIndex:0];
        [self.captureDataFormatSegCtrl setEnabled:YES forSegmentAtIndex:0];
        self.captureDataFormatSegCtrl.selectedSegmentIndex = 0;
    }
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
