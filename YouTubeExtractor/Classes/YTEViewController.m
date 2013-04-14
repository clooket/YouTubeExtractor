//
//  YTEViewController.m
//  YouTubeExtractor
//
//  Created by Denis Berton on 31/03/13.
//  Copyright (c) 2013 clooket.com. All rights reserved.
//

#import "YTEViewController.h"

#import "LBYouTubeExtractor.h"
#import "LBYouTubePlayerController.h"
#import "DKReachability.h"
#import "AFNetworking.h"
#import "AFDownloadRequestOperation.h"
#import "MBProgressHUD.h"
#import "UIViewController+MJPopupViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

//http://code.google.com/apis/youtube/2.0/developers_guide_protocol_video_feeds.html
static NSString* const kActivityFeed = @"activity";
static NSString* const kChannelsFeed = @"channels";
static NSString* const kMostPopularFeed = @"most popular";

@interface YTEViewController ()

@end

@implementation YTEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.tableView.alpha = 0.0;
    
    [self fetchAllEntries];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	[self.tableView flashScrollIndicators];
    
    
    if(![self reachableYouTube]){
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"YTEViewController.alert.title",@"Error")
                              message:NSLocalizedString(@"YTEViewControlle.alert.error",@"YouTube not reachable, check your internet connection")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"button.confirm",@"OK")
                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)dealloc {
    self.controller.delegate = nil;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - YTETableViewCellProtocol

- (void)videoPreviewTapped:(id)sender event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: currentTouchPosition];
    if (indexPath != nil)
    {
        [self extractVideoWithIndexPath:indexPath];
    }
}

#pragma mark - extract video

-(void)extractVideoWithUrl:(NSString*)url
{
    LBYouTubeExtractor *extractor = [[LBYouTubeExtractor alloc] initWithURL:[NSURL URLWithString:url] quality:LBYouTubeVideoQualityLarge];
    
    [extractor extractVideoURLWithCompletionBlock:^(NSURL *videoURL, NSError *error) {
        if(!error) {
            NSLog(@"Did extract video URL using completion block: %@", videoURL);
        } else {
            NSLog(@"Failed extracting video URL using block due to error:%@", error);
        }
    }];
}

-(void)extractVideoWithIndexPath:(NSIndexPath*)indexPath
{
    NSString* videoId = [self videoIdFromIndexPath:indexPath];    
    LBYouTubeExtractor *extractor = [[LBYouTubeExtractor alloc] initWithID:videoId quality:LBYouTubeVideoQualityLarge];
    
    [extractor extractVideoURLWithCompletionBlock:^(NSURL *videoURL, NSError *error) {
        if(!error) {
            NSLog(@"Did extract video URL using completion block: %@", videoURL);
            [self downloadVideo:videoURL withIndexPath:indexPath];
        } else {
            NSLog(@"Failed extracting video URL using block due to error:%@", error);
        }
    }];
}

-(void) downloadVideo:(NSURL*)videoURL withIndexPath:(NSIndexPath*)indexPath
{
    NSString* videoId = [self videoIdFromIndexPath:indexPath];        
    NSURLRequest *request = [NSURLRequest requestWithURL: videoURL];
    NSString* filename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4v",videoId]];
   [self deleteFile:filename];
    
    AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:filename shouldResume:NO];
  
    YTETableViewCell* cell = (YTETableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateProgress:0.0];
    
    [operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
        [cell updateState:kDownloadStateInProgress];
        [cell updateProgress:totalBytesReadForFile/(float)totalBytesExpectedToReadForFile];
    }];
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:filename append:NO];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"Did save video to disk");
        [self saveVideoToCameraRoll:filename];
        [self extractAudioFromVideoAtPath:filename withIndexPath:indexPath];
        [cell updateState:kDownloadStateVideo];        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"Failed to save video due to error:%@", error); //FIXME:"The operation couldn’t be completed. File exists" 
        [self saveVideoToCameraRoll:filename]; 
        [self extractAudioFromVideoAtPath:filename withIndexPath:indexPath];
        [cell updateState:kDownloadStateVideo];
    }];
    
    [operation start];
}

-(void)saveVideoToCameraRoll:(NSString*)filename
{    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL saveVideo = [defaults boolForKey:@"enabled_save_video_camera_roll"];
    if(!saveVideo)
    {
        return;
    }
    
    NSURL* videoURL = [NSURL fileURLWithPath:filename];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error){
        if(error) {
            NSLog(@"Error on saving movie : %@", error);
            //[self deleteFile:filename];
        }
        else {
            //NSLog(@"URL: %@", assetURL);
            //[self deleteFile:filename];
        }
    }];
}

-(void)deleteFile:(NSString*)filename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath: filename] == YES){
        [fileManager removeItemAtPath: filename error:NULL];
    }
}

#pragma mark - extract audio

- (void)extractAudioFromVideoAtPath:(NSString*)videoPath withIndexPath:(NSIndexPath*)indexPath{
    NSURL *url=[NSURL fileURLWithPath:videoPath];
    AVURLAsset* mAsset=[AVURLAsset URLAssetWithURL:url options:nil];
    
    NSArray *requestedKey=[NSArray arrayWithObject:@"tracks"];
    [mAsset loadValuesAsynchronouslyForKeys:requestedKey completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self extractAudioFromAsset:mAsset withIndexPath:indexPath];
        });
    }];
}
-(void)extractAudioFromAsset:(AVURLAsset*)asset withIndexPath:(NSIndexPath*)indexPath
{
    NSString* videoId = [self videoIdFromIndexPath:indexPath];      
    NSString* filename = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a",videoId]];
    [self deleteFile:filename];    
    NSURL *pathURL=[NSURL fileURLWithPath:filename];
    
    AVAssetExportSession *exportSession=[AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    exportSession.outputURL=pathURL;
    exportSession.outputFileType=AVFileTypeAppleM4A;
    //CMTimeRange range=CMTimeRangeFromTimeToTime(currentSubtitle.startTime, currentSubtitle.endTime);
    //exportSession.timeRange=range;
    
    YTETableViewCell* cell = (YTETableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status==AVAssetExportSessionStatusFailed) {
            NSLog(@"can't export audio!");
            [cell updateState:kDownloadStateFailed];
        }
        else
        {
            [cell updateState:kDownloadStateAudio];
            [self displayComposerSheet:filename withIndexPath:indexPath]; 
        }
    }];
}

-(void)displayComposerSheet:(NSString*)filename withIndexPath:(NSIndexPath*)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL sendEmail = [defaults boolForKey:@"enabled_send_audio_to_email"];
    if(!sendEmail)
    {
        return;
    }
    
    NSString* videoId = [self videoIdFromIndexPath:indexPath];     
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:@"YouTube audio file"];
    
    // Set up recipients
    // NSArray *toRecipients = [NSArray arrayWithObject:@"first@example.com"];
    // NSArray *ccRecipients = [NSArray arrayWithObjects:@"second@example.com", @"third@example.com", nil];
    // NSArray *bccRecipients = [NSArray arrayWithObject:@"fourth@example.com"];    
    // [picker setToRecipients:toRecipients];
    // [picker setCcRecipients:ccRecipients];
    // [picker setBccRecipients:bccRecipients];
    
    NSData *myData = [NSData dataWithContentsOfFile:filename];
    [picker addAttachmentData:myData mimeType:@"audio/m4a" fileName:[NSString stringWithFormat:@"%@.m4a",videoId]];
    
	GDataEntryBase *entry = [[mEntriesFeed entries] objectAtIndex:indexPath.row];
    //GDataYouTubeMediaGroup *mediaGroup = [(GDataEntryYouTubeVideo *)entry mediaGroup];
    //GDataMediaTitle *mTtile = [mediaGroup mediaTitle];
	NSString *title = [[entry title] stringValue];
    
    // Fill out the email body text
    //NSString *emailBody = @"My cool image is attached";
    [picker setMessageBody:title isHTML:NO];
    [self presentViewController:picker animated:YES completion:nil];
    
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // Notifies users about errors associated with the interface
//    switch (result)
//    {
//        case MFMailComposeResultCancelled:
//            break;
//        case MFMailComposeResultSaved:
//            break;
//        case MFMailComposeResultSent:
//            break;
//        case MFMailComposeResultFailed:
//            break;
//        default:
//            break;
//    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - play video

-(void)playVideoWithUrl:(NSString*)url
{
    self.controller = [[LBYouTubePlayerController alloc] initWithYouTubeURL:[NSURL URLWithString:url] quality:LBYouTubeVideoQualityLarge];
    self.controller.delegate = self;
    self.controller.view.frame = CGRectMake(0.0f, 0.0f, 200.0f, 200.0f);
    self.controller.view.center = self.view.center;
    [self.view addSubview:self.controller.view];
}

-(void)playVideoWithIndexPath:(NSIndexPath*)indexPath
{
    NSString* videoId = [self videoIdFromIndexPath:indexPath];
    self.controller = [[LBYouTubePlayerController alloc] initWithYouTubeID:videoId quality:LBYouTubeVideoQualityLarge];
    self.controller.delegate = self;
    UIViewController* tmpController = [[UIViewController alloc] init];
    tmpController.view = self.controller.view;
    tmpController.view.frame = CGRectMake(0.0f, 0.0f, 200.0f, 200.0f);
    [self presentPopupViewController:tmpController animationType:MJPopupViewAnimationSlideBottomBottom];
}

#pragma mark - UIViewController+MJPopupViewController
- (void)dismissPopupViewControllerWithanimationType:(MJPopupViewAnimation)animationType;
{
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    [super dismissPopupViewControllerWithanimationType:animationType];
    if(self.controller)
    {
        [self.controller stop];
    }
}

#pragma mark - LBYouTubePlayerViewControllerDelegate

-(void)youTubePlayerViewController:(LBYouTubePlayerController *)controller didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL {
    NSLog(@"Did extract video source:%@", videoURL);
}

-(void)youTubePlayerViewController:(LBYouTubePlayerController *)controller failedExtractingYouTubeURLWithError:(NSError *)error {
    NSLog(@"Failed loading video due to error:%@", error);
}


#pragma mark - Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[mEntriesFeed entries] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"YTETableViewCell" owner:self options:nil];
    YTETableViewCell *cell = [topLevelObjects objectAtIndex:0];

//    static NSString *youTubeCellIdentifier = @"YouTubeCellIdentifier";
//    YTETableViewCell *cell = (YTETableViewCell *)[aTableView dequeueReusableCellWithIdentifier:youTubeCellIdentifier];
//    if (cell == nil) {
//        cell = [[YTETableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:youTubeCellIdentifier];
//		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//    }
	
	GDataEntryBase *entry = [[mEntriesFeed entries] objectAtIndex:indexPath.row];
    cell.delegate = self;
    [cell displayCellWithGDataEntryYouTubeVideo:(GDataEntryYouTubeVideo*)entry];
    
    return cell;    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self playVideoWithIndexPath:indexPath];
}

#pragma mark - private gdata utils

-(NSString*)videoIdFromIndexPath:(NSIndexPath *)indexPath 
{
    GDataEntryBase *entry = [[mEntriesFeed entries] objectAtIndex:indexPath.row];
    //    GDataYouTubeMediaGroup *mediaGroup = [(GDataEntryYouTubeVideo *)entry mediaGroup];
    /*
     http://code.google.com/apis/youtube/2.0/reference.html#youtube_data_api_tag_media:content
     1 - RTSP streaming URL for mobile video playback. H.263 video (up to 176x144) and AMR audio.
     5 - HTTP URL to the embeddable player (SWF) for this video. This format is not available for a video that is not embeddable. Developers commonly add &format=5 to their queries to restrict results to videos that can be embedded on their sites.
     6 - RTSP streaming URL for mobile video playback. MPEG-4 SP video (up to 176x144) and AAC audio.
     */
    //    GDataMediaContent *mContent = [mediaGroup mediaContentWithFormatNumber:5];
    //NSLog(@"URLString:%@",mContent.URLString);
    NSString *videoID = [[(GDataEntryYouTubeVideo *)entry mediaGroup] videoID];
    ////NSLog(@"videoID:%@",videoID);
    return videoID;
}

- (GDataServiceGoogleYouTube *)youTubeService {
	static GDataServiceGoogleYouTube* _service = nil;
	
	if (!_service) {
		_service = [[GDataServiceGoogleYouTube alloc] init];
		
		[_service setUserAgent:@"AppWhirl-UserApp-1.0"];
		[_service setServiceShouldFollowNextLinks:YES];
        [_service setShouldCacheResponseData:YES];
        [_service setIsServiceRetryEnabled:YES];
	}
	
	// fetch unauthenticated
	[_service setUserCredentialsWithUsername:nil
                                    password:nil];
	
	return _service;
}


// begin retrieving the list of the user's entries
- (void)fetchAllEntries {
    
    [self showSpinner:YES];
    
    mEntriesFetchTicket = nil;
    mEntriesFeed = nil;
    
    GDataServiceGoogleYouTube *service = [self youTubeService];
    GDataServiceTicket *ticket;
    
    // feedID is uploads, favorites, etc
    //
    // note that activity feeds require a developer key
    //NSString *feedID = [[mUserFeedPopup selectedItem] title];
    NSString *feedID = kMostPopularFeed;
    
    NSURL *feedURL;
    if ([feedID isEqual:kActivityFeed]) {
        // the activity feed uses a unique URL
        feedURL = [GDataServiceGoogleYouTube youTubeActivityFeedURLForUserID:kGDataServiceDefaultUser];
    } else if ([feedID isEqual:kChannelsFeed]) {
        feedURL = [GDataServiceGoogleYouTube youTubeURLForChannelsFeeds];
    } else if ([feedID isEqual:kMostPopularFeed]) {
        feedURL = [GDataServiceGoogleYouTube youTubeURLForFeedID:kGDataYouTubeFeedIDMostPopular];
    } //else {
    //  feedURL = [GDataServiceGoogleYouTube youTubeURLForUserID:kGDataServiceDefaultUser
    //                                                userFeedID:feedID];
    //}
    
    //with video id
    //https://gdata.youtube.com/feeds/api/videos/videoid?v=videoID
    
    /*//sample query
     NSString *searchString = [NSString stringWithFormat:@"%@", searchField.text];
     NSURL *feedURL = [GDataServiceGoogleYouTube youTubeURLForFeedID:nil];
     GDataQueryYouTube* query = [GDataQueryYouTube  youTubeQueryWithFeedURL:feedURL];
     [query setStartIndex:1];
     [query setMaxResults:50];
     //[query setFullTextQueryString:searchString];
     [query setVideoQuery:searchString];
     //[service fetchFeedWithQuery:query ...] or the equivalent [service fetchFeedWithURL:[query URL] ...]
     */
    
    //http://code.google.com/intl/ko/apis/youtube/2.0/reference.html
    
    NSString * language = [[[NSLocale preferredLanguages] objectAtIndex:0] uppercaseString];
    
    ////NSLog(@"ISOLanguageCodes:%@", [[[NSLocale ISOLanguageCodes]objectAtIndex:0] uppercaseString]);
    ////NSLog(@"ISOCountryCodes:%@",[[[NSLocale ISOCountryCodes]objectAtIndex:0] uppercaseString]);
    
    if([self checkRegionID:language]){
        //http://gdata.youtube.com/feeds/api/standardfeeds/JP/top_rated?v=2
        feedURL = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@%@",@"https://gdata.youtube.com/feeds/api/standardfeeds/",language,@"/most_viewed?v=2&max-results=30&start-index=1&time=this_week&safeSearch=strict&fields=entry[link/@rel='http://gdata.youtube.com/schemas/2007%23mobile']"]];
    }
    else{
        feedURL = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@", [feedURL absoluteString], @"?v=2&max-results=30&start-index=1&safeSearch=strict&fields=entry[link/@rel='http://gdata.youtube.com/schemas/2007%23mobile']"]];
    }
    
    ////NSLog(@"feed search URL:%@",[feedURL absoluteString]);
    
    ticket = [service fetchFeedWithURL:feedURL
                              delegate:self
                     didFinishSelector:@selector(entryListFetchTicket:finishedWithFeed:error:)];
    
    if ([feedID isEqual:kChannelsFeed] || [feedID isEqual:kMostPopularFeed]) {
        // when using feeds which search all public videos, we don't want
        // to follow the feed's next links, since there could be a huge
        // number of pages of results
        [ticket setShouldFollowNextLinks:NO];
    }
    
    //[self setEntriesFetchTicket:ticket];
    mEntriesFetchTicket = ticket;
    
    //[self updateUI];
}

-(BOOL)checkRegionID:(NSString*)regionID{
    NSArray *regionArray = [NSArray arrayWithObjects:
                            @"AR",@"AU",@"BR",@"CA",@"CZ",@"FR",@"DE",@"GB",@"HK",@"IN",@"IE",@"IL",@"IT",@"JP",@"MX",@"NL",@"NZ",@"PL",@"RU",@"ZA",@"KR",@"ES",@"SE",@"TW",@"US",nil];
    for(int i = 0; i < regionArray.count; i++){
        NSString* youtubeID = [regionArray objectAtIndex:i];
        if([regionID isEqualToString:youtubeID])
            return YES;
    }
    return NO;
}

// feed fetch callback
- (void)entryListFetchTicket:(GDataServiceTicket *)ticket
            finishedWithFeed:(GDataFeedYouTubeVideo *)feed
                       error:(NSError *)error {
    
    mEntriesFeed = feed;
    mEntriesFetchError = error;
    mEntriesFetchTicket = nil;
    
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointZero animated:YES];
    [self showSpinner:NO];
}

- (void)getYouTubeVideoUrl:(NSString*) videoID{
    
    GDataServiceGoogleYouTube *service = [self youTubeService];
    
    NSString *baseURLStr = [[GDataServiceGoogleYouTube
                             youTubeURLForFeedID:nil] absoluteString];
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@", baseURLStr,videoID];
    ////NSLog(@"Video feed URLString:%@",urlStr);
    NSURL *url = [NSURL URLWithString:urlStr];
    
    [service fetchEntryWithURL:url
                      delegate:self
             didFinishSelector:@selector(videoTicket:finishedWithFeed:error:)];
}

#pragma mark UISearchBarDelegate

// called when keyboard search button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if(![self reachableYouTube]){
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"YouTubeViewController.alert.title",@"Error")
                              message:NSLocalizedString(@"YouTubeViewController.alert.error",@"YouTube not reachable, check your internet connection")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"button.confirm",@"OK")
                              otherButtonTitles:nil];
        [alert show];
        [searchBar resignFirstResponder];
        return;
    }
    
    if([searchBar.text isEqualToString: @""]){
        [self fetchAllEntries];
        return;
    }
    
    //TODO: searchBar.text with #videoid option only selected video    
    //https://gdata.youtube.com/feeds/api/videos/videoid?v=2
    
    [self showSpinner:YES];
    mEntriesFeed = nil;
    mEntriesFetchError = nil;
    mEntriesFetchTicket = nil;
    
    GDataServiceGoogleYouTube *service = [self youTubeService];
    GDataServiceTicket *ticket;
    
    
    NSString *searchString = [NSString stringWithFormat:@"%@", searchBar.text];
    NSURL *feedURL = [GDataServiceGoogleYouTube youTubeURLForFeedID:nil];
    
    feedURL = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@", [feedURL absoluteString], @"?v=2&fields=entry[link/@rel='http://gdata.youtube.com/schemas/2007%23mobile']"]];
    ////NSLog(@"feed search URL:%@",[feedURL absoluteString]);
    
    GDataQueryYouTube* query = [GDataQueryYouTube  youTubeQueryWithFeedURL:feedURL];
    [query setStartIndex:1];
    [query setMaxResults:30];
    //[query setFullTextQueryString:searchString];
    [query setVideoQuery:searchString];
    //[service fetchFeedWithQuery:query ...] or the equivalent [service fetchFeedWithURL:[query URL] ...]
    
    ticket = [service fetchFeedWithQuery:query
                                delegate:self
                       didFinishSelector:@selector(entryListFetchTicket:finishedWithFeed:error:)];
    
    //if ([feedID isEqual:kChannelsFeed] || [feedID isEqual:kMostPopularFeed]) {
    // when using feeds which search all public videos, we don't want
    // to follow the feed's next links, since there could be a huge
    // number of pages of results
    [ticket setShouldFollowNextLinks:NO];
    //}
    
    mEntriesFetchTicket = ticket;
    
    
    [searchBar resignFirstResponder];
}

// called when cancel button pressed
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}


#pragma mark - private utils

- (void)showSpinner:(BOOL)show
{
    if(show)
    {
        [UIView animateWithDuration:0.5 animations:^(void){
            self.tableView.alpha = 0.0;
        }];
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    else{
        [UIView animateWithDuration:0.5 animations:^(void){
            self.tableView.alpha = 1.0;
        }];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }
}

-(BOOL)reachableYouTube {
    DKReachability *r = [DKReachability reachabilityWithHostname:@"m.youtube.com"];
    DKNetworkStatus internetStatus = [r currentReachabilityStatus];
    if(internetStatus == DKNotReachable) {
        return NO;
    }
    return YES;
}

@end

