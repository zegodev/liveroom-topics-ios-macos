//
//  ZegoHudManager.m
//  Chatroom-iOS
//
//  Created by Sky on 2019/3/13.
//  Copyright © 2019 zego. All rights reserved.
//

#import "ZegoHudManager.h"
#import "MBProgressHUD.h"

@implementation ZegoHudManager

+ (void)hideAllHUD {
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
}

+ (void)showMessage:(NSString *)message{
    [self showMessage:message done:nil];
}

+ (void)showMessage:(NSString *)message done:(void(^)(void))doneHandler{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.yOffset = -100;
        hud.mode = MBProgressHUDModeText;
        hud.detailsLabelText = message;
        hud.detailsLabelFont = [UIFont systemFontOfSize:15];
        [hud hide:YES afterDelay:1.5];
        hud.completionBlock = doneHandler;
    });
}

+(void)showIndeterminateMessage:(NSString *)message done:(void (^)(void))doneHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.yOffset = -100;
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.detailsLabelText = message;
        [hud hide:YES afterDelay:1.5];
        hud.completionBlock = doneHandler;
    });
}

+ (void)showCustomMessage:(NSString *)message customView:(UIView *)customView done:(void(^)(void))doneHandler{
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.yOffset = -100;
        hud.mode = MBProgressHUDModeCustomView;
        hud.customView = customView;
        hud.labelText = message;
        [hud hide:YES afterDelay:1.5];
        hud.completionBlock = doneHandler;
    });
}

+ (void)showNetworkLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.yOffset = -100;
    });
}

+ (void)hideNetworkLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subView in [UIApplication sharedApplication].keyWindow.subviews) {
            if ([subView isKindOfClass:[MBProgressHUD class]]) {
                MBProgressHUD *hud = (MBProgressHUD *)subView;
                if (hud.mode == MBProgressHUDModeIndeterminate && hud.labelText == nil) {
                    hud.removeFromSuperViewOnHide = YES;
                    [hud hide:YES];
                }
            }
        }
    });
}

@end
