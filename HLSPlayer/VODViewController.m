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
#import "HTTPServer.h"

#define VideoListURL [NSURL URLWithString:@"http://c.m.163.com/nc/video/home/0-10.html"]
#define M3U8FILEPATH(URL) [NSString stringWithFormat:@"%@/%@/index.m3u8", DownloadFolder, URL_UUID(URL)]

static NSUInteger const tagOffset = 64;

@interface VODViewController () <M3U8HandlerDelegate, VideoDownloadDelegate>

@property(nonatomic, strong) NSMutableArray<VideoModel *> *dataSource;

//local server
@property (nonatomic, strong) HTTPServer * httpServer;

@property (nonatomic, strong) NSMutableArray *downloaderArray;

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
        [[[NSURLSession sharedSession] dataTaskWithURL:VideoListURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
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
    NSURL *playerURL = nil;

    if([[NSFileManager defaultManager] fileExistsAtPath:M3U8FILEPATH(url)]) {
        /** Open local server */
        [self openHttpServer];
        
        NSString *localServerURL = [NSString stringWithFormat:@"http://127.0.0.1:12345/%@/index.m3u8", URL_UUID(url)];
        playerURL = [NSURL URLWithString:localServerURL];
    } else {
        playerURL = [NSURL URLWithString:url];
    }
    
    cell.player = [[AVPlayer alloc]initWithURL:playerURL];
    cell.playerLayer = [AVPlayerLayer playerLayerWithPlayer:cell.player];
    cell.playerLayer.frame = cell.backgroundImageView.frame;
    cell.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [cell.contentView.layer insertSublayer:cell.playerLayer atIndex:0];
    [cell.contentView sendSubviewToBack:cell.backgroundImageView];
    [cell.player play];
    cell.playButton.hidden = YES;
}

- (IBAction)CleanCache:(UIBarButtonItem *)sender {
    [[NSFileManager defaultManager] removeItemAtPath:DownloadFolder error:nil];
    for (VideoModel *model in self.dataSource) {
        model.progress = 0;
    }
    [self.tableView reloadData];
}

#pragma mark - Only concerned about download

- (IBAction)DownloadVideo:(UIButton *)sender {
    M3U8Handler *handle = [[M3U8Handler alloc]init];
    handle.delegate = self;
    
    NSUInteger row = sender.tag - tagOffset;
    handle.indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    self.dataSource[row].progress = 0.01;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
        //parse m3u8 URLx
        [handle praseUrl:self.dataSource[row].m3u8_url];
    });
    
    //start network activity indicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

#pragma mark - M3U8HandlerDelegate

- (void)praseM3U8Finished:(M3U8Handler *)handler {
    handler.playlist.uuid = URL_UUID(handler.urlStr);
    VideoDownloader *downloader = [[VideoDownloader alloc]initWithM3U8List:handler.playlist];
    downloader.indexPath = handler.indexPath;
    [self.downloaderArray addObject:downloader];
    downloader.delegate = self;
    
    //observer current progress
    [downloader addObserver:self forKeyPath:@"currentProgress" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    
    [downloader startDownloadVideo];
}

- (void)praseM3U8Failed:(M3U8Handler *)handler error:(NSError *)error {
    NSLog(@"parse error");
}

#pragma mark - VideoDownloadDelegate

- (void)videoDownloaderFinished:(VideoDownloader *)request {
    NSLog(@"Download completed!");
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [request createLocalM3U8file];
    
    [request removeObserver:self forKeyPath:@"currentProgress"];
    
    [self.downloaderArray removeObject:request];
    
    [self.tableView reloadRowsAtIndexPaths:@[request.indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)videoDownloaderFailed:(VideoDownloader *)request {
    NSLog(@"Download failed!");
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(VideoDownloader *)downloader change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentProgress"]) {
        self.dataSource[downloader.indexPath.row].progress = [change[@"new"] floatValue];

        [self.tableView reloadRowsAtIndexPaths:@[downloader.indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [self.tableView reloadData];
    }
}

- (void)dealloc {
    for (VideoDownloader *downloader in self.downloaderArray) {
        [downloader removeObserver:self forKeyPath:@"currentProgress"];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([VideoCell class]) forIndexPath:indexPath];

    cell.playButton.tag = indexPath.row + tagOffset;
    cell.downLoadButton.tag = indexPath.row + tagOffset;
    VideoModel *model = self.dataSource[indexPath.row];
    [cell configWithModel:model];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    VideoCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.player) {
        [cell.playerLayer removeFromSuperlayer];
        
        [cell.player pause];
        [cell.player replaceCurrentItemWithPlayerItem:nil];
        cell.player = nil;
        cell.playButton.hidden = NO;
    } else {
        AVPlayerViewController *vc = [[AVPlayerViewController alloc]init];
        VideoModel *model = self.dataSource[indexPath.row];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *playerURL = nil;
        
        if([fileManager fileExistsAtPath:M3U8FILEPATH(model.m3u8_url)]) {
            /** Open local server */
            [self openHttpServer];
            
            NSString *localServerURL = [NSString stringWithFormat:@"http://127.0.0.1:12345/%@/index.m3u8", URL_UUID(model.m3u8_url)];
            playerURL = [NSURL URLWithString:localServerURL];
        } else {
            playerURL = [NSURL URLWithString:model.m3u8_url];
        }
        
        vc.player = [[AVPlayer alloc]initWithURL:playerURL];
        
        [self presentViewController:vc animated:YES completion:^{
            [vc.player play];
        }];
    }
}

#pragma mark - Local server

- (void)openHttpServer
{
    self.httpServer = [[HTTPServer alloc] init];
    [self.httpServer setType:@"_http._tcp."];  // set server type
    [self.httpServer setPort:12345]; // set server port

    NSLog(@"-------------\nSetting document root: %@\n", DownloadFolder);
    // 设置服务器路径
    [self.httpServer setDocumentRoot:DownloadFolder];
    NSError *error;
    if(![self.httpServer start:&error])
    {
        NSLog(@"-------------\nError starting HTTP Server: %@\n", error);
    }
}

@end
