//
//  YTETableViewCell.h
//  YouTubeExtractor
//
//  Created by Denis Berton on 31/03/13.
//  Copyright (c) 2013 clooket.com. All rights reserved.
//

@interface YTETableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *videoPreview;
@property (weak, nonatomic) IBOutlet UILabel *videoTitle;
@property (weak, nonatomic) IBOutlet UILabel *videoDescription;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgress;

@end
