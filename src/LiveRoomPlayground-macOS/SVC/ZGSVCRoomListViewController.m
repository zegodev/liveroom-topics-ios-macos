//
//  ZGSVCRoomListViewController.m
//  LiveRoomPlayground-macOS
//
//  Created by Sky on 2018/11/13.
//  Copyright © 2018 Zego. All rights reserved.
//

#import "ZGSVCRoomListViewController.h"
#import "ZGSVCLiveViewController.h"
#import "ZGRoomInfo.h"
#import "ZGApiManager.h"

@interface ZGSVCRoomListViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *tableView;
@property (strong, nonatomic) NSWindowController *windowC;

@property (nonatomic, strong) NSMutableArray <ZGRoomInfo*>*roomList;

@end

@implementation ZGSVCRoomListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self getLiveRooms];
}

#pragma mark - Private

- (void)getLiveRooms {
    NSString *mainDomain = @"zego.im";
    
    unsigned int appID = ZGApiManager.appID;
    NSString *baseUrl = [NSString stringWithFormat:@"https://liveroom%u-api.%@", appID, mainDomain];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/demo/roomlist?appid=%u", baseUrl, appID]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSLog(@"URL %@", URL.absoluteString);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = 10;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    Weakify(self);
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself onRequestComplete:data resp:response err:error];
        });
    }];
    
    [task resume];
}


#pragma mark - Action

- (IBAction)onRefreshListAction:(id)sender {
    [self getLiveRooms];
}

- (void)onRequestComplete:(NSData *)data resp:(NSURLResponse *)response err:(NSError *)error {
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

- (IBAction)onCreateRoomAction:(id)sender {
    NSStoryboard *sb = [NSStoryboard storyboardWithName:@"SVC" bundle:nil];
    ZGSVCLiveViewController *vc = [sb instantiateControllerWithIdentifier:@"ZGSVCLiveViewController"];
    vc.role = ZEGO_ANCHOR;
    NSWindowController *windowC = [[NSWindowController alloc] init];
    windowC.window = [NSWindow windowWithContentViewController:vc];
    self.windowC = windowC;
    [windowC showWindow:windowC.window];
    
}

- (IBAction)onTableViewDoubleClickAction:(id)sender {
    if (self.tableView.selectedRow < 0 || self.tableView.selectedRow >= self.roomList.count) {
        return;
    }
    
    ZGRoomInfo *info = self.roomList[self.tableView.selectedRow];
    if (info.roomID.length == 0) {
        return;
    }
    
    NSStoryboard *sb = [NSStoryboard storyboardWithName:@"SVC" bundle:nil];
    ZGSVCLiveViewController *vc = [sb instantiateControllerWithIdentifier:@"ZGSVCLiveViewController"];
    vc.roomInfo = info;
    vc.role = ZEGO_AUDIENCE;
    NSWindowController *windowC = [[NSWindowController alloc] init];
    windowC.window = [NSWindow windowWithContentViewController:vc];
    self.windowC = windowC;
    [windowC showWindow:nil];
}

#pragma mark - TableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.roomList.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([tableColumn.title isEqualToString:@"No"]) {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"no" owner:self];
        cell.textField.stringValue = [NSString stringWithFormat:@"%ld",(long)row+1];
        cell.textField.textColor = NSColor.whiteColor;
        
        return cell;
    }
    else {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"title" owner:self];
        ZGRoomInfo *info = self.roomList[row];
        cell.textField.stringValue = info.roomName;
        cell.textField.textColor = NSColor.whiteColor;
        
        return cell;
    }
}

#pragma mark - Access

- (NSMutableArray<ZGRoomInfo *> *)roomList {
    if (_roomList == nil) {
        _roomList = [[NSMutableArray alloc] init];
    }
    return _roomList;
}

@end
