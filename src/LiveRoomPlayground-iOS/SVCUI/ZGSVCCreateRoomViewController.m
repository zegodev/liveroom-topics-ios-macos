//
//  ZGSVCCreateRoomViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2018/11/12.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCCreateRoomViewController.h"
#import "ZGSVCAnchorViewController.h"

@interface ZGSVCCreateRoomViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *openSvcSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *frontCamSwitch;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

@end

@implementation ZGSVCCreateRoomViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    BOOL openSVC = self.openSvcSwitch.isOn;
    BOOL useFrontCam = self.frontCamSwitch.isOn;
    NSString *roomName = self.nameTextField.text.length > 0 ? self.nameTextField.text:nil;
    
    ZGSVCAnchorViewController *targetVC = (ZGSVCAnchorViewController *)segue.destinationViewController;
    [targetVC setOpenSVC:openSVC useFrontCam:useFrontCam roomName:roomName];
}

@end

#endif
