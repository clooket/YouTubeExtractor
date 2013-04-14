//
//  YTETableViewCell.h
//  YouTubeExtractor
//
//  Created by Denis Berton on 31/03/13.
//  Copyright (c) 2013 clooket.com. All rights reserved.
//
#import "GDataYouTube.h"
#import "GDataEntryYouTubeVideo+YTE.h"

typedef NS_ENUM(NSInteger, tDownloadState) {
    kDownloadStateNone,
    kDownloadStateInProgress,
    kDownloadStateVideo,
    kDownloadStateAudio,
    kDownloadStateFailed
};

@protocol YTETableViewCellProtocol <NSObject>
- (void)videoPreviewTapped:(id)sender event:(id)event;
@end

@interface YTETableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UIButton *videoPreviewButton;
@property (weak, nonatomic) IBOutlet UIImageView *videoPreview;
@property (weak, nonatomic) IBOutlet UILabel *videoTitle;
@property (weak, nonatomic) IBOutlet UILabel *videoDescription;
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgress;
@property (nonatomic, assign) id<YTETableViewCellProtocol> delegate;
@property (nonatomic, readonly) GDataEntryYouTubeVideo* videoEntry;

-(void)displayCellWithGDataEntryYouTubeVideo:(GDataEntryYouTubeVideo *)entry;
-(void)updateState:(tDownloadState)state;
-(void)updateProgress:(float)progress;


@end
