//
//  VideoCell.m
//  HLSPlayer
//
//  Created by Charles on 12/04/17.
//  Copyright © 2017 Charles. All rights reserved.
//

#import "VideoCell.h"
#import "VideoModel.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *downLoadButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic, copy) NSString *imageURL;

@end

@implementation VideoCell

+ (NSMutableDictionary *)sharedCacheDic {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *dict;
    
    dispatch_once(&onceToken, ^{
        dict = [NSMutableDictionary dictionary];
    });
    
    return dict;
}

- (void)configWithModel:(VideoModel *)model {
    self.titleLabel.text = model.title;
    self.descriptionLabel.text = model.topicDesc;
    self.imageURL = model.cover;
    
    if ([[VideoCell sharedCacheDic] objectForKey:self.imageURL]) {
        self.backgroundImageView.image = [[VideoCell sharedCacheDic] objectForKey:self.imageURL];
    } else {
        self.backgroundImageView.image = nil;
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:model.cover]];
            UIImage *image = [UIImage imageWithData:data];
            [[VideoCell sharedCacheDic] setObject:image forKey:model.cover];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([model.cover isEqualToString:self.imageURL]) {
                    self.backgroundImageView.image = image;
                } else {
                    NSLog(@"Opps, Already resued!\nself.imageURL = %@, model.cover = %@", self.imageURL, model.cover);
                }
            });
        });
    }
}

@end
