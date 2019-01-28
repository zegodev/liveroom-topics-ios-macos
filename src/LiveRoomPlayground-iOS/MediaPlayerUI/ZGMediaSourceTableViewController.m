//
//  ZGMediaSourceTableViewController.m
//  LiveRoomPlayground-iOS
//
//  Copyright © 2018年 Zego. All rights reserved.
//

#import "ZGMediaSourceTableViewController.h"
#import "ZGMediaPlayerDemoHelper.h"
#import "ZGMediaPlayerViewController.h"

@interface ZGMediaSourceTableViewController ()

@end

@implementation ZGMediaSourceTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [ZGMediaPlayerDemoHelper mediaList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MediaSourceCell" forIndexPath:indexPath];
    
    [cell.textLabel setText:[ZGMediaPlayerDemoHelper titleForItem:[ZGMediaPlayerDemoHelper mediaList][indexPath.row]]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    ZGMediaPlayerViewController* vc = (ZGMediaPlayerViewController*)[segue destinationViewController];
    
    NSInteger row = [[self.tableView indexPathForSelectedRow] row];
    if (row >= 0) {
        vc.title = [ZGMediaPlayerDemoHelper titleForItem:[ZGMediaPlayerDemoHelper mediaList][row]];
        vc.url = [ZGMediaPlayerDemoHelper mediaList][row][kZGMediaURLKey];
    }
}

@end
