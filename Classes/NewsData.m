//
//  NewsData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 31.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "NewsData.h"
#import "SettingsData.h"
#import "Update.h"

@implementation NewsData

@synthesize newsData;
@synthesize numberOfNewEntries;

-(id)initWithParkId:(NSString *)pId {
  self = [super init];
  if (self != nil) {
    parkId = [pId retain];
    newsData = nil;
    [self updateIfNecessary];
  }
  return self;
}

-(void)dealloc {
  [parkId release];
  parkId = nil;
  [newsData release];
  newsData = nil;
  [super dealloc];
}

-(BOOL)update:(BOOL)considerLocalData {
  NSString *data = nil;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SettingsData *settings = [SettingsData getSettingsData];
  NSString *localPath = [NSString stringWithFormat:@"%@/news.txt", [settings languagePath]];
  double timeToConsiderForLocalData = 24.0*settings.newsUpdate-8;
  if (newsData == nil) {
    data = [Update localDataPath:localPath parkId:parkId];
    if (data != nil && [data length] > 0) newsData = [[HelpData alloc] initWithContent:data];
  }
  if (considerLocalData) {
    double modificationTimeOfLocalData = [Update localTimeIntervalSinceNowOfData:localPath parkId:parkId];
    if (modificationTimeOfLocalData >= 0.0 && modificationTimeOfLocalData < timeToConsiderForLocalData*3600.0) {
      [pool release];
      return YES;
    }
  }
  NSArray *currentTitles = [[newsData.titles allValues] retain];
  data = [Update onlineDataPath:[NSString stringWithFormat:@"%@/news.txt", [settings languagePath]] hasPrefix:@"<h1>" useLocalDataIfNotOlder:(considerLocalData)? timeToConsiderForLocalData : -1.0 parkId:parkId online:nil statusCode:nil];
  [newsData release];
  newsData = (data != nil && [data length] > 0)? [[HelpData alloc] initWithContent:data] : nil;
  numberOfNewEntries = 0;
  if (newsData != nil) {
    NSArray *titles = [newsData.titles allValues];
    for (NSString *newsTitle in titles) {
      if (![currentTitles containsObject:newsTitle]) ++numberOfNewEntries;
    }
  }
  [currentTitles release];
  [pool release];
  return (newsData != nil);
}

-(BOOL)updateIfNecessary {
  if (PATHES_EDITION != nil) return NO;
  SettingsData *settings = [SettingsData getSettingsData];  
  return (newsData == nil || settings.newsUpdate >= 0)? [self update:YES] : NO;
}

-(void)resetNumberOfNewEntries {
  numberOfNewEntries = 0;
}

@end
