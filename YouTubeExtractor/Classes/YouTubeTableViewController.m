//
//  YouTubeTableViewController.m
//  Viseo
//
//  Created by Denis Berton on 23/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


#import "YouTubeTableViewController.h"
#import "AppDelegate.h"
#import "RecognitionTableViewCell.h"

//http://code.google.com/apis/youtube/2.0/developers_guide_protocol_video_feeds.html
static NSString* const kActivityFeed = @"activity";
static NSString* const kChannelsFeed = @"channels";
static NSString* const kMostPopularFeed = @"most popular";

@interface YouTubeTableViewController (PrivateMethods)
//- (GDataServiceGoogleYouTube *)youTubeService;

//- (void)updateUI;

//- (void)fetchEntryImageURLString:(NSString *)urlString;
//- (void)updateImageForEntry:(GDataEntryBase *)entry;
//- (GDataEntryBase *)selectedEntry;
- (void)fetchAllEntries;
//- (void)uploadVideoFile;
//- (void)restartUpload;

- (GDataFeedYouTubeVideo *)entriesFeed;
- (void)setEntriesFeed:(GDataFeedYouTubeVideo *)feed;

- (NSError *)entriesFetchError;
- (void)setEntriesFetchError:(NSError *)error;

- (GDataServiceTicket *)entriesFetchTicket;
- (void)setEntriesFetchTicket:(GDataServiceTicket *)ticket;

- (NSString *)entryImageURLString;
- (void)setEntryImageURLString:(NSString *)str;

- (void)configureCell:(RecognitionTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (GDataServiceGoogleYouTube *)youTubeService;

//- (void)ticket:(GDataServiceTicket *)ticket
//hasDeliveredByteCount:(unsigned long long)numberOfBytesRead
//ofTotalByteCount:(unsigned long long)dataLength;

//- (void)fetchStandardCategories;
- (void)showSpinner:(BOOL)show;
-(BOOL)checkRegionID:(NSString*)regionID;
@end


@implementation YouTubeTableViewController

@synthesize mEntriesFeed, tableView, pickerDelegate, spinner;//, fetchedResultsController;

/*

//
// tableView
//
// This method connects to the view property by default.
//
- (UITableView *)tableView
{
	return tableView;
}

//
// setTableView
//
// This method connects to the view property by default.
//
- (void)setTableView:(UITableView *)newTableView
{
	[tableView release];
	tableView = [newTableView retain];
	[tableView setDelegate:self];
	[tableView setDataSource:self];
}
*/

- (void)viewDidLoad {
    // Configure the navigation bar
    
    
    UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"RecognitionAddViewController.button.cancel",@"Cancel") style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];
    NSMutableArray *newItems = [toolbar.items mutableCopy];
    [newItems  replaceObjectAtIndex:0 withObject:cancelButton];
    toolbar.items = newItems;
    [cancelButton release];
    [newItems release];    
    
	//AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	//app.overlayContentsListViewController = [[OverlayContentsListViewController alloc] initWithNibName:@"OverlayContentsListViewController" bundle:nil];		
/*
	UITableView *newTableView =
	[[[UITableView alloc]
	  initWithFrame:CGRectZero
	  style:UITableViewStylePlain]
	 autorelease];

	self.tableView = newTableView;
	//[self updateFrameView];
	
	[self.view addSubview: tableView];
	//[self.view addSubview: app.overlayContentsListViewController.view];					
	
    self.title = NSLocalizedString(@"RecognitionListTableViewController.navigation.title",@"Contents");
    
	//self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    //UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)];
    //self.navigationItem.rightBarButtonItem = addButtonItem;
    //[addButtonItem release];
*/	
	// Configure the table view.
    self.tableView.rowHeight = 63.0;
    self.tableView.backgroundColor = [UIColor clearColor];//DARK_BACKGROUND;
    //self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;	
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;	
	self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
	
    //self.saveButton.enabled = NO;
    
    [self fetchAllEntries];
	
    /*
	NSError *error = nil;
	if (![[self fetchedResultsController] performFetch:&error]) {
		abort();
	}
    */
}

/*
-(void)updateFrameView
{
	AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
	//overlayCameraViewController.delegate = self;
	self.view.frame =  [[UIScreen mainScreen] bounds];
	CGRect overlayViewFrame = app.overlayContentsListViewController.view.frame;
	CGRect newFrame = CGRectMake(0.0, //[[UIScreen mainScreen] bounds].size.height
								 //self.view.frame.size.height 
								 [[UIScreen mainScreen] bounds].size.height - CGRectGetHeight(overlayViewFrame), //-20.0,//- 29.0,
								 //[[UIApplication sharedApplication] statusBarFrame];
								 CGRectGetWidth(overlayViewFrame), 
								 CGRectGetHeight(overlayViewFrame));// + 9.0);
	app.overlayContentsListViewController.view.frame = newFrame;
	
    
    CGRect barFrame = self.navigationController.navigationBar.frame;
    //correzione bug di rotazione in apertura contenuti da camera in landscape mode l'altezza era di 32.
    barFrame.size.height = 44;
    self.navigationController.navigationBar.frame = barFrame;
    
	CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
	CGRect tableViewFrame = CGRectMake(0.0,
									   barFrame.size.height,
									   self.view.frame.size.width,
									   [[UIScreen mainScreen] bounds].size.height-CGRectGetHeight(overlayViewFrame)-barFrame.size.height-statusBarFrame.size.height 
									   //newFrame.origin.y-self.navigationController.navigationBar.frame.size.height
									   //self.view.frame.size.height 
									   //self.view.frame.size.height - newFrame.size.height - 29.0
									   );	
	self.tableView.frame = tableViewFrame;
}
*/

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	[self.tableView flashScrollIndicators];
    
    
    if(![DeviceUtils reachableYouTube]){
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"YouTubeViewController.alert.title",@"Error")
                              message:NSLocalizedString(@"YouTubeViewController.alert.error",@"YouTube not reachable, check your internet connection") 
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"button.confirm",@"OK") 
                              otherButtonTitles:nil];
        [alert show];
        [alert release];         
    }
}


/*
- (void)viewDidLoad {
	NSLog(@"loading");
    
    [self fetchAllEntries];
    [super viewDidLoad];	
}
*/
/*
- (void)request:(GDataServiceTicket *)ticket
finishedWithFeed:(GDataFeedBase *)aFeed
          error:(NSError *)error {
    
	self.mEntriesFeed = (GDataFeedYouTubeVideo *)aFeed;
    
	[self.tableView reloadData];
}
*/

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[mEntriesFeed entries] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    static NSString *YouTubeCellIdentifier = @"YouTubeCellIdentifier";
    
    RecognitionTableViewCell *recognitionCell = (RecognitionTableViewCell *)[aTableView dequeueReusableCellWithIdentifier:YouTubeCellIdentifier];
    if (recognitionCell == nil) {
        recognitionCell = [[[RecognitionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:YouTubeCellIdentifier] autorelease];
		recognitionCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
	// Display dark and light background in alternate rows -- see tableView:willDisplayCell:forRowAtIndexPath:.
	recognitionCell.useDarkBackground = (indexPath.row % 2 == 0);
	recognitionCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	[self configureCell:recognitionCell atIndexPath:indexPath];
    
    return recognitionCell;
    
/*    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
 */   

}


- (void)configureCell:(RecognitionTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell
    
	// Configure the cell.
	GDataEntryBase *entry = [[mEntriesFeed entries] objectAtIndex:indexPath.row];
	//NSString *title = [[entry title] stringValue];
	//cell.textLabel.text = title;
    
    GDataYouTubeMediaGroup *mediaGroup = [(GDataEntryYouTubeVideo *)entry mediaGroup];
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
	NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[thumbnails objectAtIndex:0] URLString]]];
	cell.imageView.image = [UIImage imageWithData:data];
	
    //NSString *videoID = [[(GDataEntryYouTubeVideo *)entry mediaGroup] videoID];
    ////NSLog(@"videoID:%@",videoID);
    //http://www.youtube.com/watch?v=videoID";
    //"http://www.youtube.com/v/videoID"
   
    cell.imageContainerView.image = [UIImage imageNamed:@"plaque.png"];
	cell.imageView.image = [UIImage imageWithData:data];
	cell.nameLabel.text = [mTtile stringValue];
	cell.descriptionLabel.text = [[mediaGroup mediaDescription] contentStringValue];    
    cell.ratingView.hidden = YES;
    
    /*
     currentCell = cell;
     [self updateImageForEntry:entry];
     */ 
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
    
    //YouTubeViewController* youTubePicker = [[YouTubeViewController alloc] init];
    AppDelegate *app = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [app.youTubeViewController loadVideo:videoID usingDelegate: self.pickerDelegate];
    [self.navigationController pushViewController:app.youTubeViewController animated:YES];
    
    /*
    if(mContent.URLString != nil && videoID != nil){
        self.saveButton.enabled = YES;
        currentVideoID = videoID;
    }
    else {
        self.saveButton.enabled = NO;
        currentVideoID = nil;
    }
    */ 
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Support all orientations except upside down
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    //[tableView release];
    [mEntriesFeed release];
    [mEntriesFetchError release];
    [mEntriesFetchTicket release];
    [spinner release];
    pickerDelegate = nil;
    [super dealloc];
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
    [self setEntriesFeed:nil];
    [self setEntriesFetchError:nil];
    [self setEntriesFetchTicket:nil];
    
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
    
    //ritorna le informazioni per un solo video
    //https://gdata.youtube.com/feeds/api/videos/videoid?v=videoID
    
    /*//Esempio di query
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
    //TODO: usa il language solo se tra quelli esistenti, altrimenti non usarlo!

    if([self checkRegionID:language]){
    //http://gdata.youtube.com/feeds/api/standardfeeds/JP/top_rated?v=2
    //FILTRO PER VIDEO MOBILE INDISPENSABILE
    feedURL = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@%@",@"https://gdata.youtube.com/feeds/api/standardfeeds/",language,@"/most_viewed?v=2&max-results=30&start-index=1&time=this_week&safeSearch=strict&fields=entry[link/@rel='http://gdata.youtube.com/schemas/2007%23mobile']"]]; 
    }
    else{
        //FILTRO PER VIDEO MOBILE INDISPENSABILE
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
    
    [self setEntriesFetchTicket:ticket];
    
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
    
    [self setEntriesFeed:feed];
    [self setEntriesFetchError:error];
    [self setEntriesFetchTicket:nil];
    
    [self.tableView reloadData];
    [self showSpinner:NO];
    //[self updateUI];
}


- (IBAction)cancel {
    [self.pickerDelegate cancelWebVideo];
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

// feed fetch callback
- (void)videoTicket:(GDataServiceTicket *)ticket
                    finishedWithFeed:(GDataFeedYouTubeVideo *)feed
                               error:(NSError *)error {
    ////NSLog(@"videoTicket:mEntriesFeed count: %d",[[mEntriesFeed entries] count]);
    
    GDataEntryBase *entry = [[mEntriesFeed entries] objectAtIndex:0];
    GDataYouTubeMediaGroup *mediaGroup = [(GDataEntryYouTubeVideo *)entry mediaGroup];
    //NSLog(@"videoTicket:media  group----- \n\n%@",[(GDataEntryYouTubeVideo *)entry mediaGroup]);    
    /*
     http://code.google.com/apis/youtube/2.0/reference.html#youtube_data_api_tag_media:content
     1 - RTSP streaming URL for mobile video playback. H.263 video (up to 176x144) and AMR audio.
     5 - HTTP URL to the embeddable player (SWF) for this video. This format is not available for a video that is not embeddable. Developers commonly add &format=5 to their queries to restrict results to videos that can be embedded on their sites.
     6 - RTSP streaming URL for mobile video playback. MPEG-4 SP video (up to 176x144) and AAC audio.  
     */ 
    GDataMediaContent *mContent = [mediaGroup mediaContentWithFormatNumber:5];
    ////NSLog(@"URLString:%@",mContent.URLString);    
   
    NSURL *movieURL = [NSURL URLWithString:mContent.URLString];
    ////NSLog(@"Youtube url:%@",mContent.URLString);
     
    [self.pickerDelegate openYouTubeVideo:movieURL];  
}

/*
#pragma mark -

// album and photo thumbnail display

// fetch or clear the thumbnail for this specified entry
- (void)updateImageForEntry:(GDataEntryBase *)entry {
    
    if (!entry || ![entry respondsToSelector:@selector(mediaGroup)]) {
        
        // clear the image; no entry is selected, or it's not an entry type with a
        // thumbnail
        //[mEntryImageView setImage:nil];
        currentCell.imageView.image = nil;
        [self setEntryImageURLString:nil];
        
    } else {
        // if the new thumbnail URL string is different from the previous one,
        // save the new URL, clear the existing image and fetch the new image
        GDataEntryYouTubeVideo *video = (GDataEntryYouTubeVideo *)entry;
        
        GDataMediaThumbnail *thumbnail = [[video mediaGroup] highQualityThumbnail];
        if (thumbnail != nil) {
            NSString *imageURLString = [thumbnail URLString];
            if (!imageURLString || ![mEntryImageURLString isEqual:imageURLString]) {
                
                [self setEntryImageURLString:imageURLString];
                //[mEntryImageView setImage:nil];
                currentCell.imageView.image = nil;
                
                if (imageURLString) {
                    [self fetchEntryImageURLString:imageURLString];
                }
            }
        }
    }
}

- (void)fetchEntryImageURLString:(NSString *)urlString {
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithURLString:urlString];
    [fetcher setComment:@"thumbnail"];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(imageFetcher:finishedWithData:error:)];
}

- (void)imageFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
    if (error == nil) {
        // got the data; display it in the image view
        UIImage *image = [[[UIImage alloc] initWithData:data] autorelease];
        
        currentCell.imageView.image = image;
        //[mEntryImageView setImage:image];
    } else {
        NSLog(@"imageFetcher:%@ failedWithError:%@", fetcher,  error);
    }
}

*/

#pragma mark UISearchBarDelegate

// called when keyboard search button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if(![DeviceUtils reachableYouTube]){
        UIAlertView *alert = [[UIAlertView alloc] 
                              initWithTitle:NSLocalizedString(@"YouTubeViewController.alert.title",@"Error")
                              message:NSLocalizedString(@"YouTubeViewController.alert.error",@"YouTube not reachable, check your internet connection") 
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"button.confirm",@"OK") 
                              otherButtonTitles:nil];
        [alert show];
        [alert release];   
        [searchBar resignFirstResponder];
        return;
    }    
    
    if([searchBar.text isEqualToString: @""]){
        [self fetchAllEntries];
        return;
    }
    
    [self showSpinner:YES];
    [self setEntriesFeed:nil];
    [self setEntriesFetchError:nil];
    [self setEntriesFetchTicket:nil];
    
    GDataServiceGoogleYouTube *service = [self youTubeService];
    GDataServiceTicket *ticket;
    

     NSString *searchString = [NSString stringWithFormat:@"%@", searchBar.text];
     NSURL *feedURL = [GDataServiceGoogleYouTube youTubeURLForFeedID:nil];
    
     //LA RICERCA NON è VINCOLATA AL PAESE
     feedURL = [NSURL URLWithString: [NSString stringWithFormat:@"%@%@", [feedURL absoluteString], @"?v=2&fields=entry[link/@rel='http://gdata.youtube.com/schemas/2007%23mobile']&safeSearch=strict"]];    
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
    
    [self setEntriesFetchTicket:ticket];
    
    
    [searchBar resignFirstResponder];
}

// called when cancel button pressed
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}


#pragma mark -
#pragma mark UI Handling

- (void)showSpinner:(BOOL)show
{

    if(self.spinner == nil){
        CGRect frame = [LoadingPanelView getDefaultFrame];
        self.spinner = [[LoadingPanelView alloc] initWithFrame:frame];
        [self.view addSubview: self.spinner];    
    }
    self.spinner.hidden = (show) ? NO : YES;
    if (show)
    {
        self.tableView.allowsSelection = NO;
    }
    else
    {
        self.tableView.allowsSelection = YES;
    }    
    /*
    if(self.spinner == nil){
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        // size and center the spinner
        [self.spinner setFrame:CGRectZero];
        [self.spinner sizeToFit];
        //CGRect frame = self.spinner.frame;
        //CGRect screenRect = [[UIScreen mainScreen] bounds]; 
        
        //frame.origin.x = (self.tableView.frame.size.width - frame.size.width) / 2.0;
        //frame.origin.y = (self.tableView.frame.size.height - frame.size.height) / 2.0;
        //self.spinner.frame = frame;
        [spinnerView addSubview: self.spinner];
    }
    self.spinner.hidden = (show) ? NO : YES;
    if (show)
    {
        self.tableView.allowsSelection = NO;
        [self.spinner startAnimating];
    }
    else
    {
        self.tableView.allowsSelection = YES;
        [self.spinner stopAnimating];
    }
    */ 
    
}


#pragma mark Setters and Getters

- (GDataFeedYouTubeVideo *)entriesFeed {
    return mEntriesFeed;
}

- (void)setEntriesFeed:(GDataFeedYouTubeVideo *)feed {
    [mEntriesFeed autorelease];
    mEntriesFeed = [feed retain];
}

- (NSError *)entryFetchError {
    return mEntriesFetchError;
}

- (void)setEntriesFetchError:(NSError *)error {
    [mEntriesFetchError release];
    mEntriesFetchError = [error retain];
}

- (GDataServiceTicket *)entriesFetchTicket {
    return mEntriesFetchTicket;
}

- (void)setEntriesFetchTicket:(GDataServiceTicket *)ticket {
    [mEntriesFetchTicket release];
    mEntriesFetchTicket = [ticket retain];
}

/*
- (NSString *)entryImageURLString {
    return mEntryImageURLString;
}

- (void)setEntryImageURLString:(NSString *)str {
    [mEntryImageURLString autorelease];
    mEntryImageURLString = [str copy];
}
 */
@end

