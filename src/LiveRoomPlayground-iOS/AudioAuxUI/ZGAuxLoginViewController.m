//
//  ZGAuxLoginViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/19.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_AudioAux

#import "ZGAuxLoginViewController.h"
#import "ZGAuxPublishViewController.h"
#import "ZGAuxPlayViewController.h"
#import "ZegoHudManager.h"

static NSString *ZGAuxRoomID = @"ZGAuxRoomID";
static NSString *ZGAuxStreamID = @"ZGAuxStreamID";

@interface ZGAuxLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *streamIDTextField;
@property (weak, nonatomic) IBOutlet UIButton *jumpToPublishButton;
@property (weak, nonatomic) IBOutlet UIButton *jumpToPlayButton;

@end

@implementation ZGAuxLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.roomIDTextField.text = [self savedValueForKey:ZGAuxRoomID];
    self.streamIDTextField.text = [self savedValueForKey:ZGAuxStreamID];
}

- (IBAction)jumpToAuxPublish:(id)sender {
    if (self.roomIDTextField.text.length > 0 && self.streamIDTextField.text.length > 0) {
        [self saveValue:self.roomIDTextField.text forKey:ZGAuxRoomID];
        [self saveValue:self.streamIDTextField.text forKey:ZGAuxStreamID];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"AudioAux" bundle:nil];
        ZGAuxPublishViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGAuxPublishViewController"];
        vc.roomID = self.roomIDTextField.text;
        vc.streamID = self.streamIDTextField.text;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [ZegoHudManager showMessage:@"未填房间ID或流ID"];
    }
}

- (IBAction)jumpToAuxPlay:(id)sender {
    if (self.roomIDTextField.text.length > 0 && self.streamIDTextField.text.length > 0) {
        [self saveValue:self.roomIDTextField.text forKey:ZGAuxRoomID];
        [self saveValue:self.streamIDTextField.text forKey:ZGAuxStreamID];
        
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"AudioAux" bundle:nil];
        ZGAuxPlayViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ZGAuxPlayViewController"];
        vc.roomID = self.roomIDTextField.text;
        vc.streamID = self.streamIDTextField.text;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        [ZegoHudManager showMessage:@"未填房间ID或流ID"];
    }
}

- (IBAction)jumpToAuxTopicLink:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/252.html"]];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


@end

#endif
