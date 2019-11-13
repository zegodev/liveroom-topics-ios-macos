//
//  ZGSoundLevelLoginViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/8/26.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_SoundLevel

#import "ZGSoundLevelLoginViewController.h"
#import "ZGSoundLevelViewController.h"

static NSString *ZGSoundLevelRoomID = @"ZGSoundLevelRoomID";

@interface ZGSoundLevelLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *roomIDTextField;

@end

@implementation ZGSoundLevelLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.roomIDTextField.text = [self savedValueForKey:ZGSoundLevelRoomID];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *roomID = self.roomIDTextField.text;
    if (roomID.length > 0) {
        [self saveValue:roomID forKey:ZGSoundLevelRoomID];
        ZGSoundLevelViewController *vc = segue.destinationViewController;
        vc.roomID = roomID;
        vc.title = [NSString stringWithFormat:@"RoomID: %@", roomID];
    }
}
- (IBAction)jumpToSoundLevelTopicLink:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://doc.zego.im/CN/731.html"]];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end

#endif
