//
//  ZGExternalVideoFilterConfigViewController.m
//  LiveRoomPlayground-macOS
//
//  Created by Paaatrick on 2019/8/21.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGExternalVideoFilterConfigViewController.h"

static float defaultSliderValue = 50.0;

@interface ZGExternalVideoFilterConfigViewController ()

// Slider
@property (weak) IBOutlet NSSlider *skinSlider;
@property (weak) IBOutlet NSSlider *filterSlider;

// 美肤按钮
@property (weak) IBOutlet NSButton *skinDetectButton;
@property (weak) IBOutlet NSButton *blurButton;
@property (weak) IBOutlet NSButton *colorButton;
@property (weak) IBOutlet NSButton *redButton;
@property (weak) IBOutlet NSButton *eyeBrightButton;
@property (weak) IBOutlet NSButton *toothWhitenButton;

// 滤镜按钮
@property (weak) IBOutlet NSButton *originFilterButton;
@property (weak) IBOutlet NSButton *bailiangFilterButton;
@property (weak) IBOutlet NSButton *fennenFilterButton;
@property (weak) IBOutlet NSButton *lengsediaoFilterButton;
@property (weak) IBOutlet NSButton *nuansediaoFilterButton;
@property (weak) IBOutlet NSButton *xiaoqingxinFilterButton;

// 道具按钮
@property (weak) IBOutlet NSButton *deleteItemButton;
@property (weak) IBOutlet NSButton *backgroundSplitItemButton;
@property (weak) IBOutlet NSButton *blingItemButton;
@property (weak) IBOutlet NSButton *hudieItemButton;
@property (weak) IBOutlet NSButton *touhuaItemButton;
@property (weak) IBOutlet NSButton *yazuiItemButton;
@property (weak) IBOutlet NSButton *yuguanItemButton;

// 美肤参数记录
@property (nonatomic, strong) NSMutableArray<NSNumber *> *skinLevelArray;
// 滤镜参数记录
@property (nonatomic, strong) NSMutableArray<NSNumber *> *filterLevelArray;

@property (weak) IBOutlet NSTextField *selectedSkinLabel;
@property (weak) IBOutlet NSTextField *selectedFilterLabel;
@property (nonatomic, assign) int selectedSkinIndex;
@property (nonatomic, assign) int selectedFilterIndex;

@end

@implementation ZGExternalVideoFilterConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.filterSlider.floatValue = defaultSliderValue;
    self.skinSlider.floatValue = defaultSliderValue;
    self.skinSlider.hidden = YES;
    self.filterSlider.hidden = YES;
    [self setupDefaultConfig];
}

- (void)setupDefaultConfig {
    if (!self.skinConfig) {
        self.skinConfig = [[ZGFUSkinConfig alloc] init];
    }
    if (!self.skinLevelArray) {
        self.skinLevelArray = [NSMutableArray arrayWithObjects:@0.0, @0.0, @0.0, @0.0, @0.0, nil];
    }
    self.skinConfig.skinDetect = NO;
    self.skinConfig.heavyBlur = 0;
    self.skinConfig.blurLevel = [self.skinLevelArray[0] doubleValue];
    self.skinConfig.colorLevel = [self.skinLevelArray[1] doubleValue];
    self.skinConfig.redLevel = [self.skinLevelArray[2] doubleValue];
    self.skinConfig.eyeBrightLevel = [self.skinLevelArray[3] doubleValue];
    self.skinConfig.toothWhitenLevel = [self.skinLevelArray[4] doubleValue];
    
    if ([self.delegate respondsToSelector:@selector(skinParamChanged:)]) {
        [self.delegate skinParamChanged:self.skinConfig];
    }
    
    if (!self.filterLevelArray) {
        self.filterLevelArray = [NSMutableArray arrayWithObjects:@0.8, @0.8, @0.8, @0.8, @0.8, nil];
    }
}

- (void)setZGFUConfigProtocol:(id<ZGFUConfigProtocol>)configProtocol {
    self.delegate = configProtocol;
}


#pragma mark - Slider Action

- (IBAction)onChangeSkinSlider:(NSSlider *)sender {
    switch (self.selectedSkinIndex) {
        case 0:
            self.skinLevelArray[0] = @((sender.floatValue/100)*6);
            self.skinConfig.blurLevel = [self.skinLevelArray[0] doubleValue];
            break;
        case 1:
            self.skinLevelArray[1] = @(sender.floatValue/100);
            self.skinConfig.colorLevel = [self.skinLevelArray[1] doubleValue];
            break;
        case 2:
            self.skinLevelArray[2] = @(sender.floatValue/100);
            self.skinConfig.redLevel = [self.skinLevelArray[2] doubleValue];
            break;
        case 3:
            self.skinLevelArray[3] = @(sender.floatValue/100);
            self.skinConfig.eyeBrightLevel = [self.skinLevelArray[3] doubleValue];
            break;
        case 4:
            self.skinLevelArray[4] = @(sender.floatValue/100);
            self.skinConfig.toothWhitenLevel = [self.skinLevelArray[4] doubleValue];
            break;
        default:
            break;
    }
    
    if ([self.delegate respondsToSelector:@selector(skinParamChanged:)]) {
        [self.delegate skinParamChanged:self.skinConfig];
    }
}

- (IBAction)onChangeFilterSlider:(NSSlider *)sender {
    switch (self.selectedFilterIndex) {
        case 0:
            self.filterLevelArray[0] = @(sender.floatValue/100);
            break;
        case 1:
            self.filterLevelArray[1] = @(sender.floatValue/100);
            break;
        case 2:
            self.filterLevelArray[2] = @(sender.floatValue/100);
            break;
        case 3:
            self.filterLevelArray[3] = @(sender.floatValue/100);
            break;
        case 4:
            self.filterLevelArray[4] = @(sender.floatValue/100);
            break;
        default:
            break;
    }
    
    if ([self.delegate respondsToSelector:@selector(filterValueChanged:)]) {
        [self.delegate filterValueChanged:sender.floatValue/100];
    }
}

#pragma mark - Skin Action

- (IBAction)skinDetectButton:(NSButton *)sender {
    self.skinSlider.hidden = YES;
    self.skinConfig.skinDetect = !self.skinConfig.skinDetect;
    self.selectedSkinLabel.stringValue = @"美肤";
}

- (IBAction)blurButton:(NSButton *)sender {
    self.selectedSkinIndex = 0;
    self.skinSlider.hidden = NO;
    self.skinSlider.floatValue = ([self.skinLevelArray[0] floatValue]/6)*100;
    self.selectedSkinLabel.stringValue = @"磨皮";
}

- (IBAction)colorButton:(NSButton *)sender {
    self.selectedSkinIndex = 1;
    self.skinSlider.hidden = NO;
    self.skinSlider.floatValue = [self.skinLevelArray[1] floatValue]*100;
    self.selectedSkinLabel.stringValue = @"美白";
}

- (IBAction)redButton:(NSButton *)sender {
    self.selectedSkinIndex = 2;
    self.skinSlider.hidden = NO;
    self.skinSlider.floatValue = [self.skinLevelArray[2] floatValue]*100;
    self.selectedSkinLabel.stringValue = @"红润";
}

- (IBAction)eyeBrightButton:(NSButton *)sender {
    self.selectedSkinIndex = 3;
    self.skinSlider.hidden = NO;
    self.skinSlider.floatValue = [self.skinLevelArray[3] floatValue]*100;
    self.selectedSkinLabel.stringValue = @"亮眼";
}

- (IBAction)toothWhitenButton:(NSButton *)sender {
    self.selectedSkinIndex = 4;
    self.skinSlider.hidden = NO;
    self.skinSlider.floatValue = [self.skinLevelArray[4] floatValue]*100;
    self.selectedSkinLabel.stringValue = @"美牙";
}

#pragma mark - Filter Action

- (IBAction)originFilterButton:(NSButton *)sender {
    self.filterSlider.hidden = YES;
    self.selectedFilterLabel.stringValue = @"滤镜";
    if ([self.delegate respondsToSelector:@selector(filterChanged:)]) {
        [self.delegate filterChanged:@"origin"];
    }
    
    if ([self.delegate respondsToSelector:@selector(filterValueChanged:)]) {
        [self.delegate filterValueChanged:0.0];
    }
}
- (IBAction)bailiangFilterButton:(NSButton *)sender {
    self.filterSlider.hidden = NO;
    self.selectedFilterLabel.stringValue = @"白亮";
    if ([self.delegate respondsToSelector:@selector(filterChanged:)]) {
        [self.delegate filterChanged:@"bailiang1"];
    }
    
    self.filterSlider.floatValue = [self.filterLevelArray[0] floatValue]*100;
    
    if ([self.delegate respondsToSelector:@selector(filterValueChanged:)]) {
        [self.delegate filterValueChanged:self.filterSlider.floatValue/100];
    }
}
- (IBAction)fennenFilterButton:(NSButton *)sender {
    self.filterSlider.hidden = NO;
    self.selectedFilterLabel.stringValue = @"粉嫩";
    if ([self.delegate respondsToSelector:@selector(filterChanged:)]) {
        [self.delegate filterChanged:@"fennen1"];
    }
    
    self.filterSlider.floatValue = [self.filterLevelArray[1] floatValue]*100;
    
    if ([self.delegate respondsToSelector:@selector(filterValueChanged:)]) {
        [self.delegate filterValueChanged:self.filterSlider.floatValue/100];
    }
}
- (IBAction)lengsediaoFilterButton:(NSButton *)sender {
    self.filterSlider.hidden = NO;
    self.selectedFilterLabel.stringValue = @"冷色调";
    if ([self.delegate respondsToSelector:@selector(filterChanged:)]) {
        [self.delegate filterChanged:@"lengsediao1"];
    }
    
    self.filterSlider.floatValue = [self.filterLevelArray[2] floatValue]*100;
    
    if ([self.delegate respondsToSelector:@selector(filterValueChanged:)]) {
        [self.delegate filterValueChanged:self.filterSlider.floatValue/100];
    }
}
- (IBAction)nuansediaoFilterButton:(NSButton *)sender {
    self.filterSlider.hidden = NO;
    self.selectedFilterLabel.stringValue = @"暖色调";
    if ([self.delegate respondsToSelector:@selector(filterChanged:)]) {
        [self.delegate filterChanged:@"nuansediao1"];
    }
    
    self.filterSlider.floatValue = [self.filterLevelArray[3] floatValue]*100;
    
    if ([self.delegate respondsToSelector:@selector(filterValueChanged:)]) {
        [self.delegate filterValueChanged:self.filterSlider.floatValue/100];
    }
}
- (IBAction)xiaoqingxinFilterButton:(NSButton *)sender {
    self.filterSlider.hidden = NO;
    self.selectedFilterLabel.stringValue = @"小清新";
    if ([self.delegate respondsToSelector:@selector(filterChanged:)]) {
        [self.delegate filterChanged:@"xiaoqingxin1"];
    }
    
    self.filterSlider.floatValue = [self.filterLevelArray[4] floatValue]*100;
    
    if ([self.delegate respondsToSelector:@selector(filterValueChanged:)]) {
        [self.delegate filterValueChanged:self.filterSlider.floatValue/100];
    }
}

#pragma mark - Item Action

- (IBAction)deleteItemButton:(NSButton *)sender {
    if ([self.delegate respondsToSelector:@selector(itemChanged:)]) {
        [self.delegate itemChanged:@"noitem"];
    }
}
- (IBAction)backgroundSplitItemButton:(NSButton *)sender {
    if ([self.delegate respondsToSelector:@selector(itemChanged:)]) {
        [self.delegate itemChanged:@"background_test"];
    }
}
- (IBAction)blingItemButton:(NSButton *)sender {
    if ([self.delegate respondsToSelector:@selector(itemChanged:)]) {
        [self.delegate itemChanged:@"juanhuzi_lm_fu"];
    }
}
- (IBAction)hudieItemButton:(NSButton *)sender {
    if ([self.delegate respondsToSelector:@selector(itemChanged:)]) {
        [self.delegate itemChanged:@"hudie_lm_fu"];
    }
}
- (IBAction)touhuaItemButton:(NSButton *)sender {
    if ([self.delegate respondsToSelector:@selector(itemChanged:)]) {
        [self.delegate itemChanged:@"touhua_ztt_fu"];
    }
}
- (IBAction)yazuiItemButton:(NSButton *)sender {
    if ([self.delegate respondsToSelector:@selector(itemChanged:)]) {
        [self.delegate itemChanged:@"yazui"];
    }
}
- (IBAction)yuguanItemButton:(NSButton *)sender {
    if ([self.delegate respondsToSelector:@selector(itemChanged:)]) {
        [self.delegate itemChanged:@"yuguan"];
    }
}


@end
