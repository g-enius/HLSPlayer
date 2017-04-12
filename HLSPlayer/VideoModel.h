//
//  VideoModel.h
//  HLSPlayer
//
//  Created by Charles on 12/04/17.
//  Copyright © 2017 Charles. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoModel : NSObject

@property (nonatomic, copy) NSString *cover;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *topicDesc;
@property (nonatomic, copy) NSString *mp4Hd_url;
@property (nonatomic, copy) NSString *mp4_url;
@property (nonatomic, copy) NSString *m3u8Hd_url;
@property (nonatomic, copy) NSString *m3u8_url;

@end
