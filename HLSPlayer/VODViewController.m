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
static NSUInteger const tagOffset = 64;

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

- (IBAction)playButtonInCellTapped:(UIButton *)sender {
    UIView *superView = sender.superview;
    
    while (![superView isKindOfClass:[VideoCell class]]) {
        superView = superView.superview;
    }
    
    VideoCell *cell = (VideoCell *)superView;
    
    NSString *url = ((VideoModel *)self.dataSource[sender.tag - tagOffset]).m3u8_url;
    cell.player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:url]];
    cell.playerLayer = [AVPlayerLayer playerLayerWithPlayer:cell.player];
    cell.playerLayer.frame = cell.backgroundImageView.frame;
    cell.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [cell.contentView.layer insertSublayer:cell.playerLayer atIndex:0];
    [cell.contentView sendSubviewToBack:cell.backgroundImageView];
    [cell.player play];
    cell.playButton.hidden = YES;
}

- (void)stopCellPlayer:(VideoCell *)cell {
    [cell.playerLayer removeFromSuperlayer];
    
    [cell.player pause];
    [cell.player replaceCurrentItemWithPlayerItem:nil];
    cell.player = nil;
    cell.playButton.hidden = NO;
}

#pragma UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([VideoCell class]) forIndexPath:indexPath];
    cell.playButton.tag = indexPath.row + tagOffset;
    VideoModel *model = self.dataSource[indexPath.row];
    [cell configWithModel:model];
    
    return cell;
}

#pragma UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    VideoCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.player) {
        [self stopCellPlayer:cell];
    } else {
        AVPlayerViewController *vc = [[AVPlayerViewController alloc]init];
        VideoModel *model = self.dataSource[indexPath.row];
        vc.player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString: model.m3u8_url]];
        
        [self presentViewController:vc animated:YES completion:^{
            [vc.player play];
        }];
    }
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoCell *vCell = (VideoCell *)cell;
    [self stopCellPlayer:vCell];
}


@end
