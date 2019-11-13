//
//  ZGMediaPlayerChooseFileVC.m
//  LiveRoomPlayground-iOS
//
//  Created by jeffreypeng on 2019/8/23.
//  Copyright © 2019 Zego. All rights reserved.
//
#ifdef _Module_MediaPlayer

#import "ZGMediaPlayerChooseFileVC.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ZGMediaPlayerChooseFileVC ()

@property (nonatomic) NSArray<ZGMediaPlayerMediaItem*> *networkItems;
@property (nonatomic) NSArray<ZGMediaPlayerMediaItem*> *localPackageItems;
@property (nonatomic) NSArray<ZGMediaPlayerMediaItem*> *localItems;

@end

@implementation ZGMediaPlayerChooseFileVC

+ (instancetype)instanceFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"NewMediaPlayer" bundle:nil] instantiateViewControllerWithIdentifier:NSStringFromClass([ZGMediaPlayerChooseFileVC class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"选择播放文件";
    [self loadNetworkMediaItems];
    [self loadLocalMediaInPackages];
    [self loadLocalMediaItems];
}

- (void)loadNetworkMediaItems {
    self.networkItems = @[
    [ZGMediaPlayerMediaItem itemWithFileUrl:@"https://storage.zego.im/demo/sample_orig.mp3" mediaName:@"sample.mp3" isVideo:NO],
    [ZGMediaPlayerMediaItem itemWithFileUrl:@"https://storage.zego.im/demo/201808270915.mp4" mediaName:@"大海MV.mp4" isVideo:YES]];
    [self.tableView reloadData];
}

- (void)loadLocalMediaInPackages {
    NSString *mp3ResPath = [[NSBundle mainBundle] pathForResource:@"sample_-50_tempo" ofType:@"mp3"];
    NSString *mp4ResPath = [[NSBundle mainBundle] pathForResource:@"ad" ofType:@"mp4"];
    self.localPackageItems = @[
    [ZGMediaPlayerMediaItem itemWithFileUrl:mp3ResPath mediaName:@"sample_-50_tempo" isVideo:NO],
    [ZGMediaPlayerMediaItem itemWithFileUrl:mp4ResPath mediaName:@"ad.mp4" isVideo:YES]];
    [self.tableView reloadData];
}

- (void)loadLocalMediaItems {
    __block BOOL hasAuth = NO;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    MPMediaLibraryAuthorizationStatus authStatus = [MPMediaLibrary authorizationStatus];
    switch (authStatus) {
        case MPMediaLibraryAuthorizationStatusNotDetermined:
            [MPMediaLibrary requestAuthorization:^(MPMediaLibraryAuthorizationStatus status) {
                NSLog(@"%s, %d", __func__, (int)status);
                if (status == MPMediaLibraryAuthorizationStatusAuthorized) {
                    hasAuth = YES;
                }
            }];
            break;
            
        case MPMediaLibraryAuthorizationStatusDenied:
        case MPMediaLibraryAuthorizationStatusRestricted:
            break;
        case MPMediaLibraryAuthorizationStatusAuthorized:
            hasAuth = YES;
        default:
            break;
    }
#pragma clang diagnostic pop
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray<ZGMediaPlayerMediaItem*> *songList = nil;
        if (hasAuth) {
            songList = [NSMutableArray array];
            MPMediaQuery *query = [MPMediaQuery songsQuery];
            const int MAX_COUNT = 50;
            int cnt = 0;
            for (MPMediaItemCollection *collection in query.collections) {
                for (MPMediaItem *item in collection.items) {
                    
                    NSString* title = [item title];
                    NSString* url = [[item valueForProperty:MPMediaItemPropertyAssetURL] absoluteString];
                    if (url.length == 0 || title.length == 0) continue;
                    
                    [songList addObject:[ZGMediaPlayerMediaItem itemWithFileUrl:url mediaName:title isVideo:NO]];
                    cnt++;
                    if (cnt >= MAX_COUNT) break;
                }
                if (cnt >= MAX_COUNT) break;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.localItems = [songList copy];
            [self.tableView reloadData];
        });
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"网络资源";
    else if (section == 1)
        return @"程序包中资源";
    else if (section == 2)
        return @"本地媒体库";
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return _networkItems.count;
    } else if (section == 1) {
        return _localPackageItems.count;
    } else if (section == 2) {
        return _localItems.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    ZGMediaPlayerMediaItem *item = nil;
    if (indexPath.section == 0) {
        item = _networkItems[indexPath.row];
    } else if (indexPath.section == 1) {
        item = _localPackageItems[indexPath.row];
    } else if (indexPath.section == 2) {
        item = _localItems[indexPath.row];
    }
    cell.textLabel.text = item.mediaName;
    cell.detailTextLabel.text = item.isVideo?@"视频":@"音频";
    
    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ZGMediaPlayerMediaItem *item = nil;
    if (indexPath.section == 0) {
        item = _networkItems[indexPath.row];
    } else if (indexPath.section == 1) {
        item = _localPackageItems[indexPath.row];
    } else if (indexPath.section == 2) {
        item = _localItems[indexPath.row];
    }
    if (!item) return;
    
    if (self.fileDidSelectedHandler) {
        self.fileDidSelectedHandler(item);
    }
}

@end
#endif
