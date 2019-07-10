//
//  ZGMediaRecordConfigViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2018/12/18.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_MediaRecord

#import "ZGMediaRecordConfigViewController.h"
#import "ZGMediaRecordViewController.h"

@interface ZGMediaRecordConfigViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *formatSegment;
@property (weak, nonatomic) IBOutlet UISegmentedControl *typeSengment;

@end

@implementation ZGMediaRecordConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)onStart:(id)sender {
    ZGMediaRecordViewController *vc = [[ZGMediaRecordViewController alloc] initWithNibName:@"ZGMediaRecordViewController" bundle:nil];
    int recFormat = (int)self.formatSegment.selectedSegmentIndex + 1;
    int recType = (int)self.typeSengment.selectedSegmentIndex + 1;
    [vc setRecordFormat:recFormat type:recType];
    
    [self presentViewController:vc animated:YES completion:nil];
}

@end

#endif
