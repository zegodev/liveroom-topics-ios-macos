//
//  ZGSoundLevelTableViewCell.m
//  LiveRoomPlayground-iOS
//
//  Created by Paaatrick on 2019/9/4.
//  Copyright © 2019 Zego. All rights reserved.
//

#ifdef _Module_SoundLevel

#import "ZGSoundLevelTableViewCell.h"

@interface ZGSoundLevelTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *streamIDLabel;
@property (weak, nonatomic) IBOutlet UIView *frequencySpectrumView;
@property (weak, nonatomic) IBOutlet UIProgressView *soundLevelView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (nonatomic, strong) CAShapeLayer *spectrumShapeLayer;
@property (nonatomic, strong) CAShapeLayer *soundLevelShapeLayer;

@end

@implementation ZGSoundLevelTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.containerView.layer.borderWidth = 0.5;
    self.containerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.spectrumShapeLayer = [CAShapeLayer layer];
    self.spectrumShapeLayer.fillColor = [UIColor grayColor].CGColor;
    [self.frequencySpectrumView.layer addSublayer:self.spectrumShapeLayer];
    
    self.soundLevelView.transform = CGAffineTransformMakeScale(1.0f, 4.0f);
}

// 设置流 ID 标签
- (void)setStreamID:(NSString *)streamID {
    self.streamIDLabel.text = streamID;
    _streamID = streamID;
}

// 设置声浪 UI, 声浪回调的值的范围是 [0, 100]
- (void)setSoundLevel:(float)soundLevel {
    [self.soundLevelView setProgress:(soundLevel / 100) animated:YES];
    _soundLevel = soundLevel;
}

// 设置音频频谱图层
- (void)setSpectrumList:(NSArray<NSNumber *> *)spectrumList {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat barWidth = self.frequencySpectrumView.frame.size.width / spectrumList.count * 0.8;
    CGFloat space = self.frequencySpectrumView.frame.size.width / spectrumList.count * 0.2;
    CGFloat spectrumViewHeight =  self.frequencySpectrumView.frame.size.height;
    for (int i = 0; i < _spectrumList.count; i++) {
        CGFloat x = i * (barWidth + space) + space;
        CGFloat y = [self translateAmplitudeToYPosition:spectrumList[i].floatValue];
        UIBezierPath *bar = [UIBezierPath bezierPathWithRect:CGRectMake(x, y, barWidth, spectrumViewHeight - y)];
        [path appendPath:bar];
    }
    self.spectrumShapeLayer.path = path.CGPath;
    _spectrumList = spectrumList;
}

// 频谱图 Y 坐标：取频谱幅值的对数来展示, 回调的幅值范围是 [0, 2^30], 但幅值正常时基本在 [0, 2^10] 左右, 为了展示效果明显, 所以取对数后除以10
- (CGFloat)translateAmplitudeToYPosition:(float)amplitude {
    CGFloat spectrumViewHeight =  self.frequencySpectrumView.frame.size.height;
    amplitude = amplitude < 0 ? 0 : amplitude;
    CGFloat barheight;
    if (amplitude > 100) {
        barheight = log10(amplitude) / 10 * spectrumViewHeight;
    } else {
        barheight = amplitude / 10;
    }
    return spectrumViewHeight - barheight;
}

@end

#endif
