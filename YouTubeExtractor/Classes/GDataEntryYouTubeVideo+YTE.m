//
//  GDataEntryYouTubeVideo+YTE.m
//  YouTubeExtractor
//
//  Created by Denis Berton on 14/04/13.
//  Copyright (c) 2013 clooket.com. All rights reserved.
//

#import "GDataEntryYouTubeVideo+YTE.h"
#import <objc/runtime.h>

NSString * const kDownloadStatePropertyKey = @"downloadState";
NSString * const kDownloadProgressPropertyKey = @"downloadProgress";

@implementation GDataEntryYouTubeVideo (YTE)
@dynamic downloadState;
@dynamic downloadProgress;
- (void)setDownloadState:(NSNumber *)downloadState
{
    objc_setAssociatedObject(self, CFBridgingRetain(kDownloadStatePropertyKey), downloadState, OBJC_ASSOCIATION_RETAIN);
}
- (NSNumber*)downloadState
{
    return objc_getAssociatedObject(self, CFBridgingRetain(kDownloadStatePropertyKey));
}
- (void)setDownloadProgress:(NSNumber *)downloadProgress
{
    objc_setAssociatedObject(self, CFBridgingRetain(kDownloadStatePropertyKey), downloadProgress, OBJC_ASSOCIATION_RETAIN);
}
- (NSNumber*)downloadProgress
{
    return objc_getAssociatedObject(self, CFBridgingRetain(kDownloadStatePropertyKey));
}
@end