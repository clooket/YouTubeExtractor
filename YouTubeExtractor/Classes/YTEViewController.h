//
//  YTEViewController.h
//  YouTubeExtractor
//
//  Created by Denis Berton on 31/03/13.
//  Copyright (c) 2013 clooket.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LBYouTube.h"
#import "GDataYouTube.h"
#import <MessageUI/MessageUI.h>
#import "YTETableViewCell.h"

@interface YTEViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,LBYouTubePlayerControllerDelegate,UISearchBarDelegate,MFMailComposeViewControllerDelegate,YTETableViewCellProtocol> {
    GDataFeedYouTubeVideo *mEntriesFeed;
    GDataServiceTicket *mEntriesFetchTicket;
    NSError *mEntriesFetchError;
}

@property (nonatomic, strong) LBYouTubePlayerController* controller;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
