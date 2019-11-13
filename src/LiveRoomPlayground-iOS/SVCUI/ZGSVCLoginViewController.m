//
//  ZGSVCLoginViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/13.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCLoginViewController.h"
#import "ZGSVCPublishViewController.h"
#import "ZGSVCPlayViewController.h"
#import "ZegoHudManager.h"

static NSString *ZGSVCRoomID = @"ZGSVCRoomID";
static NSString *ZGSVCStreamID = @"ZGSVCStreamID";

@interface ZGSVCLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *jumpToPublishButton;
@property (weak, nonatomic) IBOutlet UIButton *jumpToPlayButton;

@end

@implementation ZGSVCLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.roomIDTextField.text = [self savedValueForKey:ZGSVCRoomID];
    self.streamIDTextField.text = [self savedValueForKey:ZGSVCStreamID];
}

- (IBAction)jumpToSVCPublish:(id)sender {
    if (self.roomIDTextField.text.length > 0 && self.streamIDTextField.text.length > 0) {
        [self saveValue:self.roomIDTextField.text forKey:ZGSVCRoomID];
        [self saveValue:self.streamIDTextField.text forKey:ZGSVCStreamID];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"SVC" bundle:nil];
        ZGSVCPublishViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGSVCPublishViewController"];
        vc.roomID = self.roomIDTextField.text;
        vc.streamID = self.streamIDTextField.text;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [ZegoHudManager showMessage:@"未填房间ID或流ID"];
    }
}

- (IBAction)jumpToSVCPlay:(id)sender {
    if (self.roomIDTextField.text.length > 0 && self.streamIDTextField.text.length > 0) {
        [self saveValue:self.roomIDTextField.text forKey:ZGSVCRoomID];
        [self saveValue:self.streamIDTextField.text forKey:ZGSVCStreamID];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"SVC" bundle:nil];
        ZGSVCPlayViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGSVCPlayViewController"];
        vc.roomID = self.roomIDTextField.text;
        vc.streamID = self.streamIDTextField.text;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [ZegoHudManager showMessage:@"未填房间ID或流ID"];
    }
}

- (IBAction)jumpToSVCTopicLink:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/287.html"]];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end

#endif
