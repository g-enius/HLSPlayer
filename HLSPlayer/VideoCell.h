//
//  VideoCell.h
//  HLSPlayer
//
//  Created by Charles on 12/04/17.
//  Copyright © 2017 Charles. All rights reserved.
//

#import <UIKit/UIKit.h>
@class VideoModel;

@interface VideoCell : UITableViewCell

- (void)configWithModel:(VideoModel *) model;

@end
