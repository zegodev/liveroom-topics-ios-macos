//
//  ZGVideoTalkViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/7/2.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ZGVideoTalkViewController.h"
#import "ZGVideoTalkDemo.h"

const NSInteger ZGVideoTalkStreamViewColumnPerRow = 3;  // stream 视图每行的显示个数
const CGFloat ZGVideoTalkStreamViewSpacing = 8.f;       // stream 视图间距


@interface ZGVideoTalkUserVideoViewObject : NSObject

@property (nonatomic, assign) BOOL isLocalUser;     // 是否是本人
@property (nonatomic, copy) NSString *userID;       // user ID
@property (nonatomic, strong) UIView *videoView;     // 播放视图

@end

@implementation ZGVideoTalkUserVideoViewObject
@end


@interface ZGVideoTalkViewController () <ZGVideoTalkDemoDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *cameraSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *micSwitch;

@property (nonatomic, weak) IBOutlet UIView *talkUserContainerView;

// 参与视频通话用户的视频视图
@property (nonatomic, strong) NSMutableArray<ZGVideoTalkUserVideoViewObject *> *joinUserVideoViewObjs;

@end

@implementation ZGVideoTalkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if DEBUG
    NSAssert(self.videoTalkDemo != nil, @"必须设置 videoTalkDemo 属性。");
#endif
    
    [self.videoTalkDemo setDelegate:self];
    
    self.joinUserVideoViewObjs = [NSMutableArray<ZGVideoTalkUserVideoViewObject *> array];
    
    [self setupUI];
    
    
    // 添加本人通话视图
    ZGVideoTalkUserVideoViewObject *localUserVVObj = [self addLocalUserVideoViewObject];
    [self reArrangeJoinUserVideoViews];
    // 设置本人通话视频的渲染视图
    [self.videoTalkDemo setLocalUserVideoPreviewView:localUserVVObj.videoView];
    
    // 添加已存在的其他用户视频
    NSArray<NSString *> *remoteUserIDs = [self.videoTalkDemo.remoteUserIDList copy];
    [self addRemoteJoinUsers:remoteUserIDs];
}

- (void)setupUI {
    self.cameraSwitch.on = self.videoTalkDemo.enableCamera;
    self.micSwitch.on = self.videoTalkDemo.enableMic;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closePage:)];
    [self invalidatePublishStateDisplay];
}

- (IBAction)onToggleCameraSwitch:(UISwitch *)sender {
    [self.videoTalkDemo setEnableCamera:[sender isOn]];
}

- (IBAction)onToggleMicSwitch:(UISwitch *)sender {
    [self.videoTalkDemo setEnableMic:[sender isOn]];
}


#pragma mark - private methods

/**
 添加自己的推流视图 object
 */
- (ZGVideoTalkUserVideoViewObject *)addLocalUserVideoViewObject {
    UIView *view = [UIView new];
    ZGVideoTalkUserVideoViewObject *localVVObj = [ZGVideoTalkUserVideoViewObject new];
    localVVObj.isLocalUser = YES;
    localVVObj.userID = self.videoTalkDemo.localUserID;
    localVVObj.videoView = view;
    
    [self.joinUserVideoViewObjs addObject:localVVObj];
    return localVVObj;
}

- (void)closePage:(id)sender {
    [self exitRoomWithRequestLeave:YES];
}

- (void)exitRoomWithRequestLeave:(BOOL)requestLeave {
    [self removeJoinUsers:[self getAllJoinUserIDs]];
    [self.videoTalkDemo setDelegate:nil];
    if (requestLeave) {
        [self.videoTalkDemo leaveTalkRoom];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)invalidatePublishStateDisplay {
    self.navigationItem.title = self.videoTalkDemo.onPublishLocalStream?@"推流中":@"未推流";
}

/**
 重排用户视频视图列表
 */
- (void)reArrangeJoinUserVideoViews {
    // 重排参与者流视图
    for (ZGVideoTalkUserVideoViewObject *obj in self.joinUserVideoViewObjs) {
        if (obj.videoView != nil) {
            [obj.videoView removeFromSuperview];
        }
    }
    
    NSInteger columnPerRow = ZGVideoTalkStreamViewColumnPerRow;
    CGFloat viewSpacing = ZGVideoTalkStreamViewSpacing;
    CGFloat screenWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    CGFloat playViewWidth = (screenWidth - (columnPerRow + 1)*viewSpacing) /columnPerRow;
    CGFloat playViewHeight = 1.5f * playViewWidth;
    
    NSInteger i = 0;
    for (ZGVideoTalkUserVideoViewObject *obj in self.joinUserVideoViewObjs) {
        if (obj.videoView == nil) {
            continue;
        }
        
        NSInteger cloumn = i % columnPerRow;
        NSInteger row = i / columnPerRow;
        
        CGFloat x = viewSpacing + cloumn * (playViewWidth + viewSpacing);
        CGFloat y = viewSpacing + row * (playViewHeight + viewSpacing);
        obj.videoView.frame = CGRectMake(x, y, playViewWidth, playViewHeight);
        
        [self.talkUserContainerView addSubview:obj.videoView];
        i++;
    }
}

- (void)addRemoteJoinUsers:(NSArray<NSString *> *)userIDs {
    if (userIDs == nil) return;
    
    BOOL needArrangeViews = NO;
    NSArray<NSString*> *currentJoinUserIds = [[self.joinUserVideoViewObjs copy] valueForKeyPath:@"userID"];
    for (NSString *userID in userIDs) {
        // 不存在相同的 user
        NSInteger existIdx = [currentJoinUserIds indexOfObject:userID];
        if (existIdx == NSNotFound) {
            needArrangeViews = YES;
            ZGVideoTalkUserVideoViewObject *vvObj = [ZGVideoTalkUserVideoViewObject new];
            vvObj.isLocalUser = NO;
            vvObj.userID = userID;
            vvObj.videoView = [UIView new];
            
            [self.joinUserVideoViewObjs addObject:vvObj];
            // 开始拉流
            [self.videoTalkDemo startPlayRemoteUserVideo:userID inView:vvObj.videoView];
        }
    }
    
    if (needArrangeViews) {
        [self reArrangeJoinUserVideoViews];
    }
}

- (void)removeJoinUsers:(NSArray<NSString *> *)userIDs {
    if (userIDs == nil) {
        return;
    }
    
    BOOL needArrangeViews = NO;
    for (NSString *userID in userIDs) {
        // 删除已有相同的 stream
        // 暂停拉流
        ZGVideoTalkUserVideoViewObject *existObj = [self findJoinUserVideoViewInListWithUserId:userID];
        if (existObj) {
            needArrangeViews = YES;
            [self.joinUserVideoViewObjs removeObject:existObj];
            
            [self.videoTalkDemo stopPlayRemoteUserVideo:existObj.userID];
            [existObj.videoView removeFromSuperview];
        }
    }
    
    if (needArrangeViews) {
        [self reArrangeJoinUserVideoViews];
    }
}

- (ZGVideoTalkUserVideoViewObject *)findJoinUserVideoViewInListWithUserId:(NSString *)userID {
    __block ZGVideoTalkUserVideoViewObject *existObj = nil;
    [self.joinUserVideoViewObjs enumerateObjectsUsingBlock:^(ZGVideoTalkUserVideoViewObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userID isEqualToString:userID]) {
            existObj = obj;
            *stop = YES;
        }
    }];
    return existObj;
}

- (NSArray<NSString *> *)getAllJoinUserIDs {
    NSArray<NSString*> *currentJoinUserIDs = [[self.joinUserVideoViewObjs copy]  valueForKeyPath:@"userID"];
    return currentJoinUserIDs;
}

- (void)handleOutTalkRoomWithAlertMessage:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self exitRoomWithRequestLeave:NO];
    }]];
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - ZGVideoTalkDemoDelegate

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo kickOutTalkRoom:(NSString *)roomID {
    [self handleOutTalkRoomWithAlertMessage:@"被踢出房间，或者相同 userID 在别出登录"];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo disConnectTalkRoom:(NSString *)roomID {
    [self handleOutTalkRoomWithAlertMessage:@"您已断开和房间的连接"];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo roomLoginStateUpdated:(ZGVideoTalkDemoRoomLoginState)state
               roomID:(NSString *)roomID {
    // 业务处理房间登录状态的变化
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo didJoinTalkRoom:(NSString *)talkRoomID
          withUserIDs:(NSArray<NSString *> *)userIDs {
    [self addRemoteJoinUsers:userIDs];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo didLeaveTalkRoom:(NSString *)talkRoomID
          withUserIDs:(NSArray<NSString *> *)userIDs {
    [self removeJoinUsers:userIDs];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo localUserOnPublishVideoUpdated:(BOOL)onPublishVideo {
    [self invalidatePublishStateDisplay];
}

- (void)videoTalkDemo:(ZGVideoTalkDemo *)demo remoteUserVideoStateUpdate:(int)stateCode
           withUserID:(NSString *)userID {
    // 业务处理远端通话用户视频播放状态的变化
}

@end
