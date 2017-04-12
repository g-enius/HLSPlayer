//
//  VideoCell.h
//  HLSPlayer
//
//  Created by Charles on 12/04/17.
//  Copyright © 2017 Charles. All rights reserved.
//

#import <UIKit/UIKit.h>
@class VideoModel;
@class AVPlayer;
@class AVPlayerLayer;

@interface VideoCell : UITableViewCell

+ (NSMutableDictionary *)sharedCacheDic;

- (void)configWithModel:(VideoModel *) model;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@end
