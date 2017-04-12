//
//  LiveViewController.m
//  HLSPlayer
//
//  Created by Charles on 12/04/17.
//  Copyright © 2017 Charles. All rights reserved.
//

#import "LiveViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LiveViewController ()

@end

@implementation LiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    AVPlayerViewController *avVC = [[AVPlayerViewController alloc]init];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    __block NSString *urlString = @"";
    [cell.contentView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UILabel class]]) {
            urlString = ((UILabel *)obj).text;
            *stop = YES;
        }
    }];
    
    avVC.player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:urlString]];
    [self presentViewController:avVC animated:YES completion:^{
        [avVC.player play];
    }];
}

@end
