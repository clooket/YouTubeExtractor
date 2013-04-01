//
//  YouTubeTableViewController.h
//  Viseo
//
//  Created by Denis Berton on 23/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GDataYouTube.h"
#import "GDataServiceGoogleYouTube.h"
#import "MediaPickerControllerDelegate.h"
#import "YouTubeViewController.h"
#import "AppDelegate.h"
#import "LoadingPanelView.h"


@interface YouTubeTableViewController : /*UITableViewController*/  UIViewController </*NSFetchedResultsControllerDelegate ,*/ UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate> {
    GDataFeedYouTubeVideo *mEntriesFeed; 
    GDataServiceTicket *mEntriesFetchTicket;
    NSError *mEntriesFetchError;
    
    //NSFetchedResultsController *fetchedResultsController;
    UITableView *tableView;
    id<MediaPickerControllerDelegate> pickerDelegate;	
    //UIBarButtonItem *saveButton;
	//IBOutlet UIBarButtonItem *cancelButton;	
    IBOutlet UIToolbar *toolbar;
    NSString* currentVideoID;
    //NSString *mEntryImageURLString;  
    //UITableViewCell * currentCell;
    //UISearchBar* videoSearchBar;
    //UIActivityIndicatorView *spinner;
    LoadingPanelView *spinner;    
    //IBOutlet UIView *spinnerView;

}

@property (nonatomic, retain) GDataFeedYouTubeVideo *mEntriesFeed;

//@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) id<MediaPickerControllerDelegate> pickerDelegate;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
//@property (nonatomic, retain) IBOutlet UIBarButtonItem *saveButton;
//@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
//@property (nonatomic, retain) IBOutlet UISearchBar* videoSearchBar;
@property (nonatomic, retain) IBOutlet LoadingPanelView *spinner;

- (void)getYouTubeVideoUrl:(NSString*) videoID;
//- (IBAction)save;
- (IBAction)cancel;



@end
