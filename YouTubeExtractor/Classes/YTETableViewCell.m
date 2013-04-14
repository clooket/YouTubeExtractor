//
//  YTETableViewCell.m
//  YouTubeExtractor
//
//  Created by Denis Berton on 31/03/13.
//  Copyright (c) 2013 clooket.com. All rights reserved.
//

#import "YTETableViewCell.h"
#import "UIImageView+AFNetworking.h"

@implementation YTETableViewCell

-(void)displayCellWithGDataEntryYouTubeVideo:(GDataEntryYouTubeVideo *)entry
{
    _videoEntry = entry;
    
    GDataYouTubeMediaGroup *mediaGroup = [entry mediaGroup];
    //GDataMediaDescription *desc = [mediaGroup mediaDescription];
    GDataMediaTitle *mTtile = [mediaGroup mediaTitle];
    //NSLog(@"media  group----- \n\n%@",[(GDataEntryYouTubeVideo *)entry mediaGroup]);
    //cell.textLabel.text = [mTtile stringValue];
    
    /*
     http://code.google.com/apis/youtube/2.0/reference.html#youtube_data_api_tag_media:content
     1 - RTSP streaming URL for mobile video playback. H.263 video (up to 176x144) and AMR audio.
     5 - HTTP URL to the embeddable player (SWF) for this video. This format is not available for a video that is not embeddable. Developers commonly add &format=5 to their queries to restrict results to videos that can be embedded on their sites.
     6 - RTSP streaming URL for mobile video playback. MPEG-4 SP video (up to 176x144) and AAC audio.
     */
    //GDataMediaContent *mContent = [mediaGroup mediaContentWithFormatNumber:5];
    //NSLog(@"URLString:%@",mContent.URLString);
    
    //cell.videoDesc.text = [desc stringValue];
    // GDataMediaContent has the urls to play the video....
    
    /*
     for (GDataEntryYouTubeVideo *videoEntry in [feed entries]) {
     GDataYouTubeMediaGroup *mediaGroup = [videoEntry mediaGroup];
     NSString *videoURL = @"http://www.youtube.com/embed/%@";
     NSString *videoID = [mediaGroup videoID];
     videoURL = [NSString stringWithFormat:videoURL, videoID];
     }
     */
    
    NSArray *thumbnails = [[(GDataEntryYouTubeVideo *)entry mediaGroup] mediaThumbnails];
	//NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[thumbnails objectAtIndex:0] URLString]]];
	
    //NSString *videoID = [[(GDataEntryYouTubeVideo *)entry mediaGroup] videoID];
    ////NSLog(@"videoID:%@",videoID);
    //http://www.youtube.com/watch?v=videoID";
    //"http://www.youtube.com/v/videoID"
    
	//cell.videoPreview.image = [UIImage imageWithData:data];
    //[self.videoPreviewButton setBackgroundImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
    
    [self.videoPreview setImageWithURL:[NSURL URLWithString:[[thumbnails objectAtIndex:0] URLString]]
                   placeholderImage:[UIImage imageNamed:@"Icon.png"]];
    [self.videoPreviewButton addTarget:self.delegate action:@selector(videoPreviewTapped:event:) forControlEvents:UIControlEventTouchUpInside];
    
	self.videoTitle.text = [mTtile stringValue];
	self.videoDescription.text = [[mediaGroup mediaDescription] contentStringValue];
    
    [self updateInterface];
}

-(void)updateState:(tDownloadState)state
{
    _videoEntry.downloadState = [NSNumber numberWithInteger:state];
    [self updateInterface];
}

-(void)updateProgress:(float)progress
{
    _videoEntry.downloadState = [NSNumber numberWithFloat:progress];
    [self updateInterface];     
}

-(void) updateInterface
{        
    if(!_videoEntry || !_videoEntry.downloadState || [_videoEntry.downloadState isEqualToNumber:[NSNumber numberWithInteger:kDownloadStateNone]])
    {
        self.downloadProgress.hidden = YES;
        self.downloadProgress.progress = 0.0;
        self.downloadProgress.progressTintColor = [UIColor blueColor];
    }
    else
    {
        self.downloadProgress.hidden = NO;
        self.downloadProgress.progress = [_videoEntry.downloadProgress floatValue];
        if([_videoEntry.downloadState isEqualToNumber:[NSNumber numberWithInteger:kDownloadStateAudio]])
        {
            self.downloadProgress.progressTintColor = [UIColor greenColor];
        }
        else if([_videoEntry.downloadState isEqualToNumber:[NSNumber numberWithInteger:kDownloadStateFailed]])
        {
            self.downloadProgress.progressTintColor = [UIColor redColor];
        }
        else
        {
            self.downloadProgress.progressTintColor = [UIColor blueColor];
        }
    }
}

//- (void)prepareForReuse {
//    [super prepareForReuse];
//}

@end
