//
//  VODViewController.m
//  HLSPlayer
//
//  Created by Charles on 12/04/17.
//  Copyright © 2017 Charles. All rights reserved.
//

#import "VODViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoModel.h"
#import "VideoCell.h"

#define URL [NSURL URLWithString:@"http://c.m.163.com/nc/video/home/0-10.html"]

@interface VODViewController ()

@property(nonatomic, strong) NSMutableArray<VideoModel *> *dataSource;

@end

@implementation VODViewController

#pragma LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self fetchVideoList];
}

#pragma FetchNetwork

- (void)fetchVideoList {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [[[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"%@", error);
                return;
            }
            
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:(NSError * _Nullable __autoreleasing * _Nullable) nil];
            self.dataSource = [[NSMutableArray alloc]init];
            for (NSDictionary *video in dict[@"videoList"]) {
                VideoModel *model = [VideoModel new];
                [model setValuesForKeysWithDictionary:video];
                [self.dataSource addObject:model];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
            
        }] resume];
    });
}


#pragma UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([VideoCell class]) forIndexPath:indexPath];
    VideoModel *model = self.dataSource[indexPath.row];
    [cell configWithModel:model];
    
    return cell;
}

#pragma UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    AVPlayerViewController *vc = [[AVPlayerViewController alloc]init];
    VideoModel *model = self.dataSource[indexPath.row];
    vc.player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString: model.m3u8_url]];
    
    [self presentViewController:vc animated:YES completion:^{
        [vc.player play];
    }];
}

@end
