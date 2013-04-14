//
//  GDataEntryYouTubeVideo+YTE.h
//  YouTubeExtractor
//
//  Created by Denis Berton on 14/04/13.
//  Copyright (c) 2013 clooket.com. All rights reserved.
//

#import "GDataYouTube.h"

@interface GDataEntryYouTubeVideo (YTE)
    @property (nonatomic, strong) NSNumber* downloadState;
    @property (nonatomic, strong) NSNumber* downloadProgress;
@end
