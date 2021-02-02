//
//  ZGAudioProcessReverbConfigVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_AudioProcessing

#import "ZGAudioProcessReverbConfigVC.h"
#import "ZGAudioProcessTopicConfigManager.h"
#import "ZGAudioProcessTopicHelper.h"
@class ZGAudioProcessReverbConfigCell,ZGAudioProcessReverbConfigModel;
static NSString *cellIdentifier = @"ZGAudioProcessReverbConfigCell";
@protocol ZGAudioProcessReverbConfigCellDelegate <NSObject>
- (void)cell:(ZGAudioProcessReverbConfigCell *)cell valueChange:(NSNumber *)value only:(BOOL)only;
@end

@interface ZGAudioProcessReverbConfigModel : NSObject
@property(nonatomic, copy)NSString *title;
@property(nonatomic, strong)NSNumber *low;
@property(nonatomic, strong)NSNumber *hight;
@property(nonatomic, strong)NSNumber *value;
@property(nonatomic, assign)BOOL only;
+ (NSArray <ZGAudioProcessReverbConfigModel *>*)configModels;
@end

@interface ZGAudioProcessReverbConfigCell : UITableViewCell
@property (weak, nonatomic) id<ZGAudioProcessReverbConfigCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *lowLabel;
@property (weak, nonatomic) IBOutlet UILabel *hightLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onlySwitch;
- (void)bindingModel:(ZGAudioProcessReverbConfigModel *)model only:(BOOL)only;
@end

@interface ZGAudioProcessReverbConfigVC () <UIPickerViewDelegate, UIPickerViewDataSource,UITableViewDataSource,UITableViewDelegate,ZGAudioProcessReverbConfigCellDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *openReverbSwitch;
@property (weak, nonatomic) IBOutlet UIView *reverbConfigContainerView;
@property (weak, nonatomic) IBOutlet UIPickerView *modePicker;
@property (weak, nonatomic) IBOutlet UILabel *customRoomSizeValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customRoomSizeSlider;
@property (weak, nonatomic) IBOutlet UILabel *customDryWetRatioValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customDryWetRatioSlider;
@property (weak, nonatomic) IBOutlet UILabel *customDampingValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customDampingSlider;
@property (weak, nonatomic) IBOutlet UILabel *customReverberanceValueLabel;
@property (weak, nonatomic) IBOutlet UISlider *customReverberanceSlider;
@property (weak, nonatomic) IBOutlet UISwitch *customReverbSwitch;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *reverbs;
@property (nonatomic, copy) NSArray<ZGAudioProcessTopicConfigMode*> *reverbOptionModes;

@end

@implementation ZGAudioProcessReverbConfigVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AudioProcessing" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGAudioProcessReverbConfigVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.reverbOptionModes = [ZGAudioProcessTopicHelper reverbOptionModes];
    self.navigationItem.title = @"设置-混响";
    
    self.reverbs = [ZGAudioProcessReverbConfigModel configModels];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.userInteractionEnabled = NO;
    [self.tableView reloadData];
    
    BOOL reverbOpen = [ZGAudioProcessTopicConfigManager sharedInstance].reverbOpen;
    
    self.reverbConfigContainerView.hidden = !reverbOpen;
    self.openReverbSwitch.on = reverbOpen;
    self.modePicker.delegate = self;
    self.modePicker.dataSource = self;
}

- (IBAction)reverbValueChanged:(UISwitch*)sender {
    BOOL reverbOpen = sender.isOn;
    [[ZGAudioProcessTopicConfigManager sharedInstance] setReverbOpen:reverbOpen];
    self.reverbConfigContainerView.hidden = !reverbOpen;
}


- (IBAction)customReverbValueChange:(UISwitch *)sender {
    BOOL reverbOpen = sender.isOn;
    if (reverbOpen) {
        ZegoAudioAdvancedReverbParam param = [self createReverbParamFromModels:self.reverbs];
        [[ZGAudioProcessTopicConfigManager sharedInstance] setCustomReverbParam:param];
    }
    [ZGAudioProcessTopicConfigManager sharedInstance].customReverbOpen = reverbOpen;
    self.modePicker.userInteractionEnabled = !reverbOpen;
    self.tableView.userInteractionEnabled = sender;
}

#pragma mark - picker view dataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.reverbOptionModes.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.reverbOptionModes[row].modeName;
}

#pragma mark - picker view delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([ZGAudioProcessTopicConfigManager sharedInstance].reverbOpen) {
        ZGAudioProcessTopicConfigMode *mode = self.reverbOptionModes[row];
        if (!mode.isCustom) {
            [[ZGAudioProcessTopicConfigManager sharedInstance] setReverbMode:[mode.modeValue unsignedIntegerValue]];
        } else {
            [[ZGAudioProcessTopicConfigManager sharedInstance] setReverbMode:NSNotFound];
        }
    }
}

#pragma mark - UITableViewDataSoucre/UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.reverbs.count - 1) {
        return 40.0;
    }
    return  104.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.reverbs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGAudioProcessReverbConfigCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    ZGAudioProcessReverbConfigModel *model = [self.reverbs objectAtIndex:indexPath.row];
    cell.delegate = self;
    [cell bindingModel:model only:(indexPath.row == self.reverbs.count - 1)];
    return cell;
}

#pragma mark - ZGAudioProcessReverbConfigCellDelegate
- (void)cell:(ZGAudioProcessReverbConfigCell *)cell valueChange:(NSNumber *)value only:(BOOL)only {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ZGAudioProcessReverbConfigModel *model = [self.reverbs objectAtIndex:indexPath.row];
    model.value = value;
    model.only = only;
    ZegoAudioAdvancedReverbParam param = [self createReverbParamFromModels:self.reverbs];
    [[ZGAudioProcessTopicConfigManager sharedInstance] setCustomReverbParam:param];
}

- (ZegoAudioAdvancedReverbParam)createReverbParamFromModels:(NSArray <ZGAudioProcessReverbConfigModel *> *)models{
    __block ZegoAudioAdvancedReverbParam reverbParam = {};
    [self.reverbs enumerateObjectsUsingBlock:^(ZGAudioProcessReverbConfigModel *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            reverbParam.roomSize = model.value.floatValue;
        }else if (idx == 1){
            reverbParam.preDelay = model.value.floatValue;
        }else if (idx == 2){
            reverbParam.reverberance = model.value.floatValue;
        }else if (idx == 3){
            reverbParam.hfDamping = model.value.floatValue;
        }else if (idx == 4){
            reverbParam.toneLow = model.value.floatValue;
        }else if (idx == 5){
            reverbParam.toneHigh = model.value.floatValue;
        }else if (idx == 6){
            reverbParam.wetGain = model.value.floatValue;
        }else if (idx == 7){
            reverbParam.dryGain = model.value.floatValue;
        }else if (idx == 8){
            reverbParam.stereoWidth = model.value.floatValue;
        }else if (idx == 9){
            reverbParam.wetOnly = model.only;
        }
    }];
    return reverbParam;
}

@end

@implementation ZGAudioProcessReverbConfigCell

- (IBAction)valueChanged:(UISwitch *)sender {
    if([self.delegate respondsToSelector:@selector(cell:valueChange:only:)]){
        [self.delegate cell:self valueChange:@0 only:sender.on];
    }
}

- (IBAction)valueChange:(UISlider *)sender {
    self.valueLabel.text = @(sender.value).stringValue;
    if([self.delegate respondsToSelector:@selector(cell:valueChange:only:)]){
        [self.delegate cell:self valueChange:@(sender.value) only:NO];
    }
}


- (void)bindingModel:(ZGAudioProcessReverbConfigModel *)model only:(BOOL)only{
    self.titleLabel.text = model.title;
    self.lowLabel.text = model.low.stringValue;
    self.hightLabel.text = model.hight.stringValue;
    if (model.value){
        [self.slider setValue:model.value.floatValue];
        [self.slider setMinimumValue:model.low.floatValue];
        [self.slider setMaximumValue:model.hight.floatValue];
        self.valueLabel.text = model.value.stringValue;
    }else{
        self.valueLabel.text = @"0";
    }
    self.valueLabel.hidden = only;
    self.lowLabel.hidden = only;
    self.hightLabel.hidden = only;
    self.slider.hidden = only;
    self.onlySwitch.hidden = !only;
}

@end

@implementation ZGAudioProcessReverbConfigModel
+ (NSArray <ZGAudioProcessReverbConfigModel *>*)configModels {
    NSArray *titles = @[
        @"房间大小Room Size:",
        @"初始延迟时间Pre-delay:",
        @"余响大小Reverberance:",
        @"阻尼控制HfDamping:",
        @"低频衰减ToneLow:",
        @"高频衰减ToneHigh:",
        @"湿信号增益WetGain:",
        @"干信号增益DryGain:",
        @"立体声宽度StereoWidth:",
        @"只有湿信号WetOnly:"
    ];
    NSArray *ranges = @[
        @[@0, @100],
        @[@0, @200],
        @[@0, @100],
        @[@0, @100],
        @[@0, @100],
        @[@0, @100],
        @[@0, @100],
        @[@0, @100],
        @[@0, @100],
        @[@0, @0],
    ];
    NSMutableArray <ZGAudioProcessReverbConfigModel *>*models =[@[] mutableCopy];
    [titles enumerateObjectsUsingBlock:^(NSString*  _Nonnull title, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *range = [ranges objectAtIndex:idx];
        NSNumber *low = range.firstObject;
        NSNumber *hight = range.lastObject;
        ZGAudioProcessReverbConfigModel *model = [[ZGAudioProcessReverbConfigModel alloc] init];
        model.title = title;
        model.low = low;
        model.hight = hight;
        model.value = @(0.0);
        [models addObject:model];
    }];
    return  models;
}

@end

#endif
