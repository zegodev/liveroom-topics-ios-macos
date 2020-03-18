//
//  SDKAPITestMainVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2020/3/3.
//  Copyright © 2020 Zego. All rights reserved.
//

#import "SDKAPITestMainVC.h"
#import "SDKAPITestChildVC.h"

#define SDKAPITest_PreviewView_Preinstall_Num 4
#define SDKAPITest_PlayRenderView_Preinstall_Num 4

@interface SDKAPITestMainVC ()

@property (nonatomic, weak) IBOutlet UIView *previewViewContainerView;
@property (nonatomic, weak) IBOutlet UIView *playViewContainerView;
@property (nonatomic, weak) IBOutlet UITextView *APICallLogTextView;

// 预设置若干个 preview view，用于更新 preview view
@property (nonatomic) NSMutableArray<UIView*> *previewViews;
// 预设置若干个 play render view，用于更新 play view
@property (nonatomic) NSMutableArray<UIView*> *playRenderViews;

@property (nonatomic, assign) NSUInteger currentPreviewIdx;
@property (nonatomic, assign) NSUInteger currentPlayRenderViewIdx;

@property (nonatomic, assign) NSUInteger viewDidAppearCallNum;


/// 获取下一个用于预览的视图，适用于 Demo 中的切换视图
- (UIView *)obtainNextPreviewView;

/// 获取下一个用于播放渲染的视图，适用于 Demo 中的切换视图
- (UIView *)obtainNextPlayRenderView;

@end

@implementation SDKAPITestMainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self preinstallPreviewViews];
    [self preinstallPlayRenderViews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewDidAppearCallNum++;
    if (self.viewDidAppearCallNum == 1) {
        [self invalidateLayoutPreviewViews];
        [self invalidatelayoutPlayRenderViews];
    }
}

- (NSMutableArray<UIView *> *)previewViews {
    if (!_previewViews) {
        _previewViews = [NSMutableArray array];
    }
    return _previewViews;
}

- (NSMutableArray<UIView *> *)playRenderViews {
    if (!_playRenderViews) {
        _playRenderViews = [NSMutableArray array];
    }
    return _playRenderViews;
}

- (void)setupUI {
    self.APICallLogTextView.text = nil;
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pageEndEditing)];
    [self.previewViewContainerView addGestureRecognizer:tap1];
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pageEndEditing)];
    [self.playViewContainerView addGestureRecognizer:tap2];
}

- (void)pageEndEditing {
    [self.view endEditing:YES];
}

- (void)preinstallPreviewViews {
    NSUInteger viewNum = SDKAPITest_PreviewView_Preinstall_Num;
    for (NSUInteger i = 0; i < viewNum; i++) {
        UIView *v = [UIView new];
        [self.previewViews addObject:v];
        [self.previewViewContainerView addSubview:v];
    }
}

- (void)preinstallPlayRenderViews {
    NSUInteger viewNum = SDKAPITest_PlayRenderView_Preinstall_Num;
    for (NSUInteger i = 0; i < viewNum; i++) {
        UIView *v = [UIView new];
        [self.playRenderViews addObject:v];
        [self.playViewContainerView addSubview:v];
    }
}

- (void)invalidateLayoutPreviewViews {
    CGSize containerSize = self.previewViewContainerView.frame.size;
    for (int i = 0; i < _previewViews.count; i++) {
        UIView *v = _previewViews[i];
        v.frame = CGRectMake(i*containerSize.width, 0, containerSize.width, containerSize.height);
    }
}

- (void)invalidatelayoutPlayRenderViews {
    CGSize containerSize = self.obtainNextPlayRenderView.frame.size;
    for (int i = 0; i < _playRenderViews.count; i++) {
        UIView *v = _playRenderViews[i];
        v.frame = CGRectMake(i*containerSize.width, 0, containerSize.width, containerSize.height);
    }
}

- (UIView *)obtainNextPreviewView {
    NSUInteger viewNum = self.previewViews.count;
    if (viewNum > 0) {
        NSUInteger currIdx = self.currentPreviewIdx%viewNum;
        UIView *previewView = self.previewViews[currIdx];
        self.currentPreviewIdx = ++currIdx/viewNum;
        return previewView;
    }
    return nil;
}

- (UIView *)obtainNextPlayRenderView {
    NSUInteger viewNum = self.playRenderViews.count;
    if (viewNum > 0) {
        NSUInteger currIdx = self.currentPlayRenderViewIdx%viewNum;
        UIView *renderView = self.playRenderViews[currIdx];
        self.currentPlayRenderViewIdx = ++currIdx/viewNum;
        return renderView;
    }
    return nil;
}

- (void)appendAPICallLogAndMakeVisible:(NSString *)newLog {
    if (newLog.length == 0) {
        return;
    }
    
    static NSUInteger limitCharNum = 1000;
    NSMutableString *newTxt = [NSMutableString string];
    
    // append newLog if need
    NSString *appendNewLog = newLog;
    if (newLog.length > limitCharNum) {
         appendNewLog = [newLog substringFromIndex:(newLog.length-limitCharNum)];
    }
    [newTxt appendString:appendNewLog];
    
    // insert oldText if need
    NSString *oldText = self.APICallLogTextView.text;
    if (newTxt.length < limitCharNum) {
        NSString *appendOldTxt = oldText;
        NSUInteger rest = limitCharNum - newTxt.length;
        if (oldText.length > rest) {
            appendOldTxt = [oldText substringFromIndex:(oldText.length - rest)];
        }
        if (appendOldTxt.length > 0) {
            [newTxt insertString:appendOldTxt atIndex:0];
        }
    }
    
    // show text and scroll to bottom
    self.APICallLogTextView.text = newTxt;
    if(newTxt.length > 0 ) {
        UITextView *textView = self.APICallLogTextView;
        NSRange bottom = NSMakeRange(newTxt.length -1, 1);
        [textView scrollRangeToVisible:bottom];
        //        NSRange range = NSMakeRange(textView.text.length, 0);
        //        [textView scrollRangeToVisible:range];
        // an iOS bug, see https://stackoverflow.com/a/20989956/971070
        [textView setScrollEnabled:NO];
        [textView setScrollEnabled:YES];
    }
}


#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EmbedChild"]) {
        SDKAPITestChildVC *childVC = (SDKAPITestChildVC*)segue.destinationViewController;
        __weak typeof(self) weakSelf = self;
        childVC.nextPreviewViewObtainBlock = ^UIView *{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return nil;
            return [self obtainNextPreviewView];
        };
        
        childVC.nextPlayRenderViewObtainBlock = ^UIView *{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return nil;
            return [self obtainNextPlayRenderView];
        };
        
        childVC.APICallLogDisplayHandler = ^(NSString *logStr) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            [self appendAPICallLogAndMakeVisible:logStr];
        };
    }
    
    [super prepareForSegue:segue sender:sender];
}

@end
