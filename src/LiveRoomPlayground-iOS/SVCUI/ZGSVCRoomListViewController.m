//
//  ZGSVCRoomListViewController.m
//  LiveRoomPlayground-iOS
//
//  Created by Sky on 2018/11/12.
//  Copyright © 2018 Zego. All rights reserved.
//

#ifdef _Module_ScalableVideoCoding

#import "ZGSVCRoomListViewController.h"
#import "ZGRoomInfo.h"
#import "ZGApiManager.h"
#import "ZGAppGlobalConfigManager.h"
#import "ZGSVCAudienceViewController.h"

@interface ZGSVCRoomListViewController ()

@property (nonatomic, strong) NSMutableArray <ZGRoomInfo*>*roomList;

@end

@implementation ZGSVCRoomListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.refreshControl = ({
        UIRefreshControl *ctrl = [[UIRefreshControl alloc] init];
        [ctrl addTarget:self action:@selector(onRefreshListAction) forControlEvents:UIControlEventValueChanged];
        ctrl;
    });
    
    [self getLiveRooms];
}


#pragma mark - Private

- (void)getLiveRooms {
    [self.refreshControl beginRefreshing];
    
    NSString *mainDomain = @"zego.im";
    
    unsigned int appID = (unsigned int)[[ZGAppGlobalConfigManager sharedInstance] globalConfig].appID;
    NSString *baseUrl = [NSString stringWithFormat:@"https://liveroom%u-api.%@", appID, mainDomain];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/demo/roomlist?appid=%u", baseUrl, appID]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSLog(@"URL %@", URL.absoluteString);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 10;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    Weakify(self);
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        Strongify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onRequestComplete:data resp:response err:error];
        });
    }];
    
    [task resume];
}


#pragma mark - Action

- (void)onRefreshListAction {
    [self getLiveRooms];
}

- (void)onRequestComplete:(NSData *)data resp:(NSURLResponse *)response err:(NSError *)error {
    if (self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
    
    [self.roomList removeAllObjects];
    
    if (error) {
        NSLog(@"get live room error: %@", error);
        return;
    }
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSError *jsonError;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            NSLog(@"parsing json error");
            return;
        }
        else {
            NSLog(@"%@", jsonResponse);
            NSUInteger code = [jsonResponse[@"code"] integerValue];
            if (code != 0) {
                return;
            }
            
            NSArray *roomList = jsonResponse[@"data"][@"room_list"];
            for (int idx = 0; idx < roomList.count; idx++) {
                ZGRoomInfo *info = [ZGRoomInfo new];
                NSDictionary *infoDict = roomList[idx];
                info.roomID = infoDict[@"room_id"];
                if (info.roomID.length == 0 || ![info.roomID hasPrefix:@"#svc-"])
                    continue;
                
                if ([infoDict objectForKey:@"stream_info"]) {
                    NSArray *streamList = infoDict[@"stream_info"];
                    if (streamList.count == 0) {
                        continue;
                    }
                }
                
                info.anchorID = infoDict[@"anchor_id_name"];
                info.anchorName = infoDict[@"anchor_nick_name"];
                info.roomName = infoDict[@"room_name"];
                
                info.streamInfo = [[NSMutableArray alloc] init];
                for (NSDictionary *dict in infoDict[@"stream_info"]) {
                    [info.streamInfo addObject:dict[@"stream_id"]];
                }
                
                [self.roomList addObject:info];
            }
            
            [self.tableView reloadData];
        }
    }
}


#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.roomList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGRoomInfo *info = self.roomList[indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellRid" forIndexPath:indexPath];
    cell.textLabel.text = info.roomName;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ZGRoomInfo *info = self.roomList[indexPath.row];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"SVC" bundle:nil];
    
    ZGSVCAudienceViewController *vc = (ZGSVCAudienceViewController *)[sb instantiateViewControllerWithIdentifier:@"ZGSVCAudienceViewController"];
    vc.roomInfo = info;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Access

- (NSMutableArray<ZGRoomInfo *> *)roomList {
    if (_roomList == nil) {
        _roomList = [[NSMutableArray alloc] init];
    }
    return _roomList;
}

@end

#endif
