//
//  ViewController.m
//  HLSPlayer
//
//  Created by Charles on 9/04/17.
//  Copyright © 2017 Charles. All rights reserved.
//

#import "ViewController.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <UITableViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
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
