//
//  ParkData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "ParkData.h"
#import "MenuData.h"
#import "ImageData.h"
#import "SettingsData.h"
#import "LocationData.h"
#import "Attraction.h"
#import "Comment.h"
#import "Update.h"
#import "Categories.h"

@implementation ParkData

@synthesize rulesForCommentsAccepted, tutorialWaitTimeViewed;
@synthesize versionOfDataFile, versionOfIndexFile, versionOfData, lastUpdateCheck;
@synthesize numberOfAvailableUpdates, numberOfNewNewsEntries;
@synthesize timeZoneAbbreviation;
@synthesize attractionComments, personalAttractionRatings, attractionFavorites, completedTourData, toursData;
@synthesize currentTrackData;
@synthesize lastTrackFromParking;
@synthesize lastParkingNotes;
@synthesize trackSegments;
@synthesize allAttractionIds;
@synthesize parkId, parkGroupId, fastLaneId, mapCopyright, currentTourName;
@synthesize hasWinterData, winterDataEnabled;
@synthesize adultAge;
@synthesize parkAttractionLocations, sameAttractionIds;

static NSMutableDictionary *allParkData = nil;

#define getShortestPathPos(n, i, j)	((i < j)? 2*(i*n+j-1)-i*(i+3) : 2*(j*n+i-1)-j*(j+3))

+(ParkData *)getParkData:(NSString *)parkId reload:(BOOL)reload {
  @synchronized([ParkData class]) {
    if (allParkData == nil || reload) {
      NSLog(@"initialize park data");
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      NSString *documentPath = [MenuData documentPath];
      NSString *oldParkDataPath = [documentPath stringByAppendingPathComponent:@"InPark.dat"];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      if ([fileManager fileExistsAtPath:oldParkDataPath]) { // migrate park data
        NSDictionary *data = [NSKeyedUnarchiver unarchiveObjectWithFile:oldParkDataPath];
        [allParkData release];
        allParkData = (data == nil)? [[NSMutableDictionary alloc] initWithCapacity:20] : [[NSMutableDictionary alloc] initWithDictionary:data];
        [allParkData enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
          NSString *path = [[NSString alloc] initWithFormat:@"%@/%@.dat", documentPath, key];
          [NSKeyedArchiver archiveRootObject:object toFile:path];
          [path release];
        }];
        NSError *error = nil;
        [fileManager removeItemAtPath:oldParkDataPath error:&error];
        if (error != nil) NSLog(@"remove park data - %@", [error localizedDescription]);
      } else {
        [allParkData release];
        allParkData = [[NSMutableDictionary alloc] initWithCapacity:20];
        NSError *error = nil;
        NSArray *files = [fileManager contentsOfDirectoryAtPath:documentPath error:&error];
        if (error == nil) {
          for (NSString *path in files) {
            if ([path hasSuffix:@".dat"] && ![path isEqualToString:@"index.dat"] && ![path hasSuffix:@"_types.dat"]) {
              ParkData *parkData = [NSKeyedUnarchiver unarchiveObjectWithFile:[documentPath stringByAppendingPathComponent:path]];
              if (parkData != nil) [allParkData setObject:parkData forKey:[path substringToIndex:path.length-4]];
            }
          }
        } else NSLog(@"Error get content of document path %@  (%@)", documentPath, [error localizedDescription]);
      }
      if (PARK_ID_EDITION == nil) {
        NSArray *parkIds = [MenuData getParkIds];
        for (NSString *pId in parkIds) {
          if ([allParkData objectForKey:pId] == nil) {
#ifdef DEBUG_MAP
            // mehr für Debug, wenn Parkdaten einfach ins Datenverzeichnis hereinkopiert werden
            NSLog(@"Create empty park data for %@", pId);
            [self addParkData:pId versionOfData:0.0];
#else
            NSLog(@"Remove park data of %@", pId);
            [self removeParkData:pId];
#endif
          }
        }
        NSLog(@"Parks:%d  allParksData:%d", [parkIds count], [allParkData count]);
      }
      [pool release];
    }
  }
  return (parkId == nil)? nil : [allParkData objectForKey:parkId];
}

+(ParkData *)getParkData:(NSString *)parkId {
  return [ParkData getParkData:parkId reload:NO];
}

+(NSArray *)getInstalledParkIds { // incl. CORE_DATA_ID
  @synchronized([ParkData class]) {
    if (allParkData == nil) [ParkData getParkData:nil reload:YES];
    return [allParkData allKeys];
  }
}

+(NSArray *)getMissingParkIds:(NSArray *)parkIds { // could happen if iOS is deleting files outside Document folder; or if backup on new device!
  NSArray *installedParkIds = [ParkData getInstalledParkIds];
  NSMutableArray *parkDataList = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
  for (NSString *parkId in installedParkIds) {
    BOOL missingData = YES;
    if ([parkId isEqualToString:CORE_DATA_ID]) {
      NSError *error = nil;
      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSString *dataPath = [MenuData dataPath];
      NSArray *files = [fileManager contentsOfDirectoryAtPath:dataPath error:&error];
      if (error == nil) {
        ParkData *parkData = [ParkData getParkData:parkId];
        if (parkData.versionOfData <= 0.0) {
          missingData = NO;
        } else {
          for (NSString *path in files) {
            NSString *fullPath = [dataPath stringByAppendingPathComponent:path];
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPath error:&error];
            if (error == nil && [attributes objectForKey:NSFileType] != NSFileTypeDirectory) {
              missingData = NO;
              break;
            }
          }
        }
      }
    } else if ([parkIds containsObject:parkId]) {
      missingData = NO;
    }
    if (missingData) {
      NSLog(@"Park ID %@ was installed (in database) but missing folder", parkId);
      ParkData *parkData = [ParkData getParkData:parkId];
      [parkData resetVersionOfData];
      [parkDataList addObject:parkId];
    }
  }
  return parkDataList;
}

+(BOOL)hasParkDataFor:(NSString *)parkGroupId {
  @synchronized([ParkData class]) {
    if (allParkData == nil) [ParkData getParkData:nil reload:YES];
    NSEnumerator *i = [allParkData objectEnumerator];
    while (TRUE) {
      ParkData *parkData = [i nextObject];
      if (!parkData) break;
      if ([parkGroupId isEqualToString:parkData.parkGroupId] || [parkGroupId isEqualToString:parkData.parkId]) return YES;
    }
    return NO;
  }
}

+(NSArray *)getParkDataListFor:(NSString *)parkGroupId {
  @synchronized([ParkData class]) {
    if (allParkData == nil) [ParkData getParkData:nil reload:YES];
    NSMutableArray *parkDataList = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
    NSEnumerator *i = [allParkData objectEnumerator];
    while (TRUE) {
      ParkData *parkData = [i nextObject];
      if (!parkData) break;
      if ([parkGroupId isEqualToString:parkData.parkGroupId] || [parkGroupId isEqualToString:parkData.parkId]) [parkDataList addObject:parkData];
    }
    [parkDataList sortUsingSelector:@selector(compare:)];
    return parkDataList;
  }
}

#pragma mark -
#pragma mark Lifecycle

-(id)init {
  self = [super init];
  if (self != nil) {
    rulesForCommentsAccepted = NO;
    tutorialWaitTimeViewed = NO;
    isInitialized = NO;
    dataChanges = NO;
    currentTourNotInitialized = YES;
    parkAttractionLocations = nil;
    trackSegments = nil;
    shortestPath = NULL;
    allAttractionIds = nil;
    allRelatedAttractionIds = nil;
    calendarData = nil;
    newsData = nil;
    sameAttractionIds = nil;
    versionOfDataFile = 0.0;
    versionOfIndexFile = 0.0;
    versionOfData = 0.0;
    lastUpdateCheck = 0.0;
    numberOfAvailableUpdates = 0;
    numberOfNewNewsEntries = 0;
    timeZoneAbbreviation = nil;
    hasWinterData = NO;
    winterDataEnabled = NO;
    parkRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0.0, 0.0), MKCoordinateSpanMake(0.0, 0.0));
    cachedMainEntryOfPark = nil;
    lastTrackPointForEntryOfPark = nil;
    lastIdEntryOfPark = nil;
    cachedMainExitOfPark = nil;
    lastTrackPointForExitOfPark = nil;
    lastIdExitOfPark = nil;
    cachedParkClosedDate = nil;
  }
  return self;
}

-(id)initWithParkId:(NSString *)pId versionOfData:(double)version {
  self = [self init];
  if (self != nil) {
    parkId = [pId retain];
    versionOfData = version;
    if ([parkId isEqualToString:CORE_DATA_ID]) {
      adultAge = 0;
      parkGroupId = nil;
      fastLaneId = nil;
      mapCopyright = nil;
      currentTourName = nil;
      completedTourData = nil;
      toursData = nil;
      currentTrackData = nil;
      attractionComments = nil;
      personalAttractionRatings = nil;
      attractionFavorites = nil;
    } else {
      completedTourData = [[NSMutableDictionary alloc] initWithCapacity:5];
      toursData = [[NSMutableDictionary alloc] initWithCapacity:5];
      attractionComments = [[NSMutableDictionary alloc] initWithCapacity:25];
      personalAttractionRatings = [[NSMutableDictionary alloc] initWithCapacity:25];
      attractionFavorites = [[NSMutableSet alloc] initWithCapacity:25];
      currentTrackData = nil;
      NSDictionary *details = [[MenuData getParkDetails:parkId cache:YES] retain];
      timeZoneAbbreviation = [[details objectForKey:@"Time_zone"] retain];
      parkGroupId = [[details objectForKey:@"Parkgruppe"] retain];
      adultAge = [[details objectForKey:@"Adult_age"] intValue];
      fastLaneId = [[details objectForKey:@"Fast_lane"] retain];
      mapCopyright = [[details objectForKey:@"Map_copyright"] retain];
      hasWinterData = [[details objectForKey:@"Winterplan"] boolValue];
      [self addNewTourName:[details objectForKey:@"Parkname"]];
      [details release];
      lastTrackFromParking = nil;
      lastParkingNotes = nil;
    }
    // Achtung: siehe copyParkData
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [self init];
  if (self != nil) {
    parkId = [[coder decodeObjectForKey:@"PARK_ID"] retain];
    versionOfData = [coder decodeDoubleForKey:@"VERSION"];
    // added with v 1.1
    numberOfNewNewsEntries = [coder containsValueForKey:@"NEW_NEWS_ENTRIES"]? [coder decodeIntForKey:@"NEW_NEWS_ENTRIES"] : 0;
    if ([parkId isEqualToString:CORE_DATA_ID]) {
      rulesForCommentsAccepted = [coder containsValueForKey:@"RULES_FOR_COMMENTS_ACCEPTED"]? [coder decodeBoolForKey:@"RULES_FOR_COMMENTS_ACCEPTED"] : NO;
      tutorialWaitTimeViewed = [coder containsValueForKey:@"TUTORIAL_WAIT_TIME_VIEWED"]? [coder decodeBoolForKey:@"TUTORIAL_WAIT_TIME_VIEWED"] : NO;
      versionOfDataFile = [coder containsValueForKey:@"VERSION_OF_DATA_FILE"]? [coder decodeDoubleForKey:@"VERSION_OF_DATA_FILE"] : 0.0;
      versionOfIndexFile = [coder containsValueForKey:@"VERSION_OF_INDEX_FILE"]? [coder decodeDoubleForKey:@"VERSION_OF_INDEX_FILE"] : 0.0;
      lastUpdateCheck = [coder containsValueForKey:@"LAST_UPDATE_CHECK"]? [coder decodeDoubleForKey:@"LAST_UPDATE_CHECK"] : 0.0;
      numberOfAvailableUpdates = [coder containsValueForKey:@"AVAILABLE_UPDATES"]? [coder decodeIntForKey:@"AVAILABLE_UPDATES"] : 0;
      adultAge = 0;
      parkGroupId = nil;
      fastLaneId = nil;
      mapCopyright = nil;
      currentTourName = nil;
      completedTourData = nil;
      toursData = nil;
      currentTrackData = nil;
      attractionComments = nil;
      personalAttractionRatings = nil;
      attractionFavorites = nil;
    } else {
      NSDictionary *details = [[MenuData getParkDetails:parkId cache:YES] retain];
      adultAge = [[details objectForKey:@"Adult_age"] intValue];
      parkGroupId = [[details objectForKey:@"Parkgruppe"] retain];
      fastLaneId = [[details objectForKey:@"Fast_lane"] retain];
      mapCopyright = [[details objectForKey:@"Map_copyright"] retain];
      hasWinterData = [[details objectForKey:@"Winterplan"] boolValue];
      timeZoneAbbreviation = [[details objectForKey:@"Time_zone"] retain];
      currentTourName = [[coder decodeObjectForKey:@"CURRENT_TOUR_NAME"] retain];
      completedTourData = [[NSMutableDictionary alloc] initWithDictionary:[coder decodeObjectForKey:@"COMPLETED_TOURS"]];
      toursData = [[NSMutableDictionary alloc] initWithDictionary:[coder decodeObjectForKey:@"TOURS"]];
      currentTrackData = [[coder decodeObjectForKey:@"CURRENT_TRACK"] retain];
      attractionComments = [[NSMutableDictionary alloc] initWithDictionary:[coder decodeObjectForKey:@"ATTRACTION_COMMENTS"]];
      personalAttractionRatings = [[NSMutableDictionary alloc] initWithDictionary:[coder decodeObjectForKey:@"PERSONAL_ATTRACTION_RATINGS"]];
      if ([coder containsValueForKey:@"ATTRACTION_FAVORITES"]) attractionFavorites = [[NSMutableSet alloc] initWithSet:[coder decodeObjectForKey:@"ATTRACTION_FAVORITES"]];
      else attractionFavorites = [[NSMutableSet alloc] initWithCapacity:25];
      lastTrackFromParking = [[coder decodeObjectForKey:@"LAST_TRACK_FROM_PARKING"] retain];
      lastParkingNotes = [[coder decodeObjectForKey:@"LAST_PARKING_NOTES"] retain];
      [details release];
    }
    //[self setupData];
    // Achtung: siehe copyParkData
  }
  return self;
}

-(BOOL)copyParkData:(ParkData *)oldParkData lastUpdateCheck:(double)lastUpdate {
  dataChanges = YES;
  numberOfNewNewsEntries = oldParkData.numberOfNewNewsEntries;
  if ([parkId isEqualToString:CORE_DATA_ID]) {
    lastUpdateCheck = lastUpdate;
    versionOfDataFile = oldParkData.versionOfDataFile;
    versionOfIndexFile = oldParkData.versionOfIndexFile;
    rulesForCommentsAccepted = oldParkData.rulesForCommentsAccepted;
    tutorialWaitTimeViewed = oldParkData.tutorialWaitTimeViewed;
    numberOfAvailableUpdates = oldParkData.numberOfAvailableUpdates;
    return YES;
  }
  [completedTourData release];
  completedTourData = [[NSMutableDictionary alloc] initWithDictionary:oldParkData.completedTourData];
  [toursData release];
  toursData = [[NSMutableDictionary alloc] initWithCapacity:[oldParkData.toursData count]];
  __block BOOL completeDataCopied = YES;
  [oldParkData.toursData enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    TourData *tourData = object;
    TourData *newTourData = [[TourData alloc] initWithTourData:tourData];
    if (tourData.count != newTourData.count) {
      NSLog(@"Count of tour entries %d of original %d", newTourData.count, tourData.count);
      completeDataCopied = (tourData.count < newTourData.count);
    }
    [toursData setObject:newTourData forKey:key];
    [newTourData release];
  }];
  [currentTourName release];
  currentTourName = [oldParkData.currentTourName retain];
  [attractionComments release];
  attractionComments = [[NSMutableDictionary alloc] initWithDictionary:oldParkData.attractionComments];
  [personalAttractionRatings release];
  personalAttractionRatings = [[NSMutableDictionary alloc] initWithDictionary:oldParkData.personalAttractionRatings];
  [attractionFavorites release];
  attractionFavorites = [[NSMutableSet alloc] initWithSet:oldParkData.attractionFavorites];
  // check the correctness of favorites, ratings and comments
  for (NSString *attractionId in oldParkData.attractionFavorites) {
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
    if (attraction == nil) {
      NSLog(@"Unkown favorite attraction %@ removed", attractionId);
      [attractionFavorites removeObject:attractionId];
      completeDataCopied = NO;
    }
  }
  for (NSString *attractionId in oldParkData.attractionComments) {
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
    if (attraction == nil) {
      NSLog(@"Unkown attraction %@ of rating comment removed", attractionId);
      [attractionComments removeObjectForKey:attractionId];
      completeDataCopied = NO;
    }
  }
  for (NSString *attractionId in oldParkData.personalAttractionRatings) {
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
    if (attraction == nil) {
      NSLog(@"Unkown attraction %@ of rating removed", attractionId);
      [personalAttractionRatings removeObjectForKey:attractionId];
      completeDataCopied = NO;
    }
  }
  if (lastTrackFromParking == nil) {
    lastTrackFromParking = [oldParkData.lastTrackFromParking retain];
    [lastParkingNotes release];
    lastParkingNotes = [oldParkData.lastParkingNotes retain];
  }
  [oldParkData completeCurrentTrack];
  currentTrackData = nil;
  return completeDataCopied;
}

-(void)dealloc {
  [parkAttractionLocations release];
  parkAttractionLocations = nil;
  [trackSegments release];
  trackSegments = nil;
  if (shortestPath != NULL) {
    free(shortestPath);
    shortestPath = NULL;
  }
  [allAttractionIds release];
  allAttractionIds = nil;
  [allRelatedAttractionIds release];
  allRelatedAttractionIds = nil;
  [sameAttractionIds release];
  sameAttractionIds = nil;
  [parkId release];
  parkId = nil;
  [parkGroupId release];
  parkGroupId = nil;
  [fastLaneId release];
  fastLaneId = nil;
  [mapCopyright release];
  mapCopyright = nil;
  [calendarData release];
  calendarData = nil;
  [newsData release];
  newsData = nil;
  [waitingTimeData release];
  waitingTimeData = nil;
  [currentTourName release];
  currentTourName = nil;
  [completedTourData release];
  completedTourData = nil;
  [toursData release];
  toursData = nil;
  [currentTrackData release];
  currentTrackData = nil;
  [timeZoneAbbreviation release];
  timeZoneAbbreviation = nil;
  [attractionComments release];
  attractionComments = nil;
  [personalAttractionRatings release];
  personalAttractionRatings = nil;
  [attractionFavorites release];
  attractionFavorites = nil;
  [lastTrackFromParking release];
  lastTrackFromParking = nil;
  [lastParkingNotes release];
  lastParkingNotes = nil;
  [cachedMainEntryOfPark release];
  cachedMainEntryOfPark = nil;
  [lastTrackPointForEntryOfPark release];
  lastTrackPointForEntryOfPark = nil;
  [lastIdEntryOfPark release];
  lastIdEntryOfPark = nil;
  [cachedMainExitOfPark release];
  cachedMainExitOfPark = nil;
  [lastTrackPointForExitOfPark release];
  lastTrackPointForExitOfPark = nil;
  [lastIdExitOfPark release];
  lastIdExitOfPark = nil;
  [cachedParkClosedDate release];
  cachedParkClosedDate = nil;
  [super dealloc];
}

-(void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:parkId forKey:@"PARK_ID"];
  [coder encodeDouble:versionOfData forKey:@"VERSION"];
  [coder encodeInt:numberOfNewNewsEntries forKey:@"NEW_NEWS_ENTRIES"];
  if ([parkId isEqualToString:CORE_DATA_ID]) {
    [coder encodeBool:rulesForCommentsAccepted forKey:@"RULES_FOR_COMMENTS_ACCEPTED"];
    [coder encodeBool:tutorialWaitTimeViewed forKey:@"TUTORIAL_WAIT_TIME_VIEWED"];
    [coder encodeDouble:versionOfDataFile forKey:@"VERSION_OF_DATA_FILE"];
    [coder encodeDouble:versionOfIndexFile forKey:@"VERSION_OF_INDEX_FILE"];
    [coder encodeDouble:lastUpdateCheck forKey:@"LAST_UPDATE_CHECK"];
    [coder encodeInt:numberOfAvailableUpdates forKey:@"AVAILABLE_UPDATES"];
  } else {
    [coder encodeObject:currentTourName forKey:@"CURRENT_TOUR_NAME"];
    [coder encodeObject:completedTourData forKey:@"COMPLETED_TOURS"];
    [coder encodeObject:toursData forKey:@"TOURS"];
    [coder encodeObject:currentTrackData forKey:@"CURRENT_TRACK"];
    [coder encodeObject:attractionComments forKey:@"ATTRACTION_COMMENTS"];
    [coder encodeObject:personalAttractionRatings forKey:@"PERSONAL_ATTRACTION_RATINGS"];
    [coder encodeObject:attractionFavorites forKey:@"ATTRACTION_FAVORITES"];
    [coder encodeObject:lastTrackFromParking forKey:@"LAST_TRACK_FROM_PARKING"];
    [coder encodeObject:lastParkingNotes forKey:@"LAST_PARKING_NOTES"];
  }
}

#pragma mark -
#pragma mark Park data

-(NSComparisonResult)compare:(ParkData *)otherParkData {
  if ([parkId isEqualToString:otherParkData.parkId]) return NSOrderedSame;
  NSDictionary *details1 = [MenuData getParkDetails:parkId cache:NO];
  NSDictionary *details2 = [MenuData getParkDetails:otherParkData.parkId cache:NO];
  if (details1 != nil && details2 != nil) {
    int order1 = [[details1 objectForKey:@"Rang"] intValue];
    int order2 = [[details2 objectForKey:@"Rang"] intValue];
    if (order1 == order2) return NSOrderedSame;
    return (order1 < order2)? NSOrderedAscending : NSOrderedDescending;
  }
  NSComparisonResult result = [parkGroupId compare:otherParkData.parkGroupId];
  if (result == NSOrderedSame) {
    NSString *parkName1 = [details1 objectForKey:@"Parkname"];
    NSString *parkName2 = [details2 objectForKey:@"Parkname"];
    result = [parkName1 compare:parkName2];
  }
  return result;
}

-(BOOL)isInitialized {
  return (isInitialized && parkAttractionLocations != nil && [parkAttractionLocations count] > 0);
}

-(BOOL)isTodayClosed {
  NSDate *date = [CalendarData toLocalTime:[NSDate date] considerTimeZoneAbbreviation:timeZoneAbbreviation];
  @synchronized([ParkData class]) {
    if (cachedParkClosedDate != nil) {
      NSTimeInterval i = [date timeIntervalSinceDate:cachedParkClosedDate];
      if (i >= 0.0 && i < 3600.0) return parkIsTodayClosed;
    }
    [cachedParkClosedDate release];
    cachedParkClosedDate = [date retain];
    [self getCalendarData];
    NSDateFormatter *hours = [[NSDateFormatter alloc] init];
    [hours setTimeZone:[NSTimeZone timeZoneWithAbbreviation:timeZoneAbbreviation]];
    [hours setDateFormat:@"HH"];
    NSString *entryId = [self getEntryOfPark:nil];
    int h = [[hours stringFromDate:date] intValue];
    // check if park opened on previous day; hack with fix hours up to 5am
    NSArray *calendarItems = [[calendarData getCalendarItemsFor:entryId forDate:((h <= 5)? [date dateByAddingTimeInterval:-6*3600.0] : date)] retain];
    if ((calendarItems == nil || [calendarItems count] == 0) && [calendarData hasCalendarItems:entryId]) {
      [hours release];
      [calendarItems release];
      parkIsTodayClosed = YES;
      return YES;
    }
    NSCalendar *localCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    //[localCalendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:timeZoneAbbreviation]];
    const unsigned units = NSHourCalendarUnit | NSMinuteCalendarUnit;
    //NSDateComponents *components = [localCalendar components:units fromDate:date];
    //date = [localCalendar dateFromComponents:components];
    [hours setDateFormat:@"HH mm"];
    NSString *s = [hours stringFromDate:[NSDate date]];
    int currentHour = [s intValue];
    int currentMinute = [[s substringFromIndex:3] intValue];
    BOOL isClosed = YES;
    for (int i = 0; i < 2; ++i) {
      for (CalendarItem *item in calendarItems) {
        if (!item.extraHours) {
          NSDateComponents *components = [localCalendar components:units fromDate:item.startTime];
          int startHour = [components hour];
          int startMinute = [components minute];
          NSDate *d = [calendarData getEarliestStartTimeFor:entryId forDate:date forItem:item];
          if (![item.startTime isEqualToDate:d]) {
            components = [localCalendar components:units fromDate:d];
            startHour = [components hour];
            startMinute = [components minute];
          }
          components = [localCalendar components:units fromDate:item.endTime];
          int endHour = [components hour];
          int endMinute = [components minute];
          d = [calendarData getLatestEndTimeFor:entryId forDate:date forItem:item];
          if (![item.endTime isEqualToDate:d]) {
            components = [localCalendar components:units fromDate:d];
            endHour = [components hour];
            endMinute = [components minute];
          }
          if (i == 0) { // assume a park is never continuously opened 24h or longer
            if (currentHour < startHour) calendarItems = [[calendarData getCalendarItemsFor:entryId forDate:[date dateByAddingTimeInterval:-24*60*60]] retain];
            else i = 1;
          }
          if (endHour < startHour) endHour += 24;
          int cHour = (currentHour < startHour || (currentHour == startHour && currentMinute < startMinute))? currentHour+24 : currentHour;
          isClosed = (cHour > endHour || (cHour == endHour && currentMinute > endMinute));
          //NSLog(@"start: %02d:%02d (%@)  -  date: %02d:%02d (%@)  -  end: %02d:%02d (%@)", startHour, startMinute, item.startTime, currentHour, currentMinute, date, endHour, endMinute, item.endTime);
          break;
        }
      }
    }
    [hours release];
    [localCalendar release];
    [calendarItems release];
    parkIsTodayClosed = isClosed;
    return isClosed;
  }
}

-(void)clearCachedData {
  if ([self completeCurrentTrack] != nil) {
    if ([LocationData isLocationDataActive]) {
      LocationData *locData = [LocationData getLocationData];
      [locData unregisterViewController];
      [locData stop];
    }
  }
  [allRelatedAttractionIds release];
  allRelatedAttractionIds = nil;
  [parkAttractionLocations release];
  parkAttractionLocations = nil;
  [trackSegments release];
  trackSegments = nil;
  if (shortestPath != NULL) {
    free(shortestPath);
    shortestPath = NULL;
  }
  [sameAttractionIds release];
  sameAttractionIds = nil;
  isInitialized = NO;
}

-(void)resetVersionOfData {
  dataChanges = YES;
  versionOfData = 0.0;
}

-(void)setupData {
  if (![self isInitialized]) {
    if ([self readGPSData]) {
      if ([toursData count] == 0) [self addNewTourName:(currentTourName == nil)? [MenuData getParkName:parkId cache:YES] : currentTourName];
      [self addEntryExitToTourData:[self getTourData:currentTourName]];
      NSDictionary *allAttractions = [Attraction getAllAttractions:parkId reload:NO];
      [ImageData validateImageProperiesForParkId:parkId attractionIds:[allAttractions allKeys] data:[ImageData localData]];
#if TARGET_IPHONE_SIMULATOR
      // check if all attraction locations data is complete
      NSLog(@"Park entry: %@  -  exit: %@", [self getAttractionDataId:[self getEntryOfPark:nil]], [self getAttractionDataId:[self getExitOfPark:nil]]);
      //NSMutableDictionary *parkDetails = [[NSMutableDictionary alloc] initWithDictionary:[MenuData getParkDetails:parkId cache:YES]];
      NSDictionary *parkDetails = [MenuData getParkDetails:parkId cache:YES];
      if ([[parkDetails objectForKey:@"MENU_TOUR"] count] == 0) NSLog(@"Missing tour suggestions");
      else {
        for (NSString *tourName in [self getTourSuggestions]) {
          NSArray *tourSuggestion = [self getTourSuggestion:tourName];
          if ([tourSuggestion count] == 0) NSLog(@"Empty tour suggestion %@", tourName);
        }
      }
      Categories *categories = [Categories getCategories];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      [allAttractions enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        NSString *attractionId = key;
        Attraction *attraction = object;
        if ([categories getTypeName:attraction.typeId] == nil) NSLog(@"Missing type definition %@ for attraction %@", attraction.typeId, attractionId);
        if ([categories getCategoryNames:attraction.typeId] == nil) NSLog(@"Missing categories definition for type %@ for attraction %@", attraction.typeId, attractionId);
        if ([attraction isRealAttraction] && attraction.duration <= 0 && ![attractionId hasPrefix:@"WP"] && ![attractionId hasPrefix:@"ch"] && ![attractionId hasPrefix:@"ar"] && ![attractionId hasPrefix:@"g"] && ![attractionId hasPrefix:@"s"]) NSLog(@"Missing duration for attraction %@", attractionId);
        NSString *aId = [self getRootAttractionId:attractionId];
        TrackPoint *p = [parkAttractionLocations objectForKey:aId];
        if (p == nil) p = [parkAttractionLocations objectForKey:[aId stringByAppendingString:@"@0"]];
        if (p == nil) {
          if (![attractionId hasPrefix:@"WP"]) //NSLog(@"Delete %@ in plist", aId);
            //else
            NSLog(@"NO location for attraction %s (%@)", attraction.attractionName, aId);
        }
        if (![fileManager fileExistsAtPath:[attraction imagePath:parkId]]) NSLog(@"NO image for attraction %@ (%@)", [attraction imageName:parkId], aId);
      }];
      NSError *error = nil;
      NSString *parkDataPath = [MenuData parkDataPath:parkId];
      NSArray *files = [fileManager contentsOfDirectoryAtPath:parkDataPath error:&error];
      if (error != nil) {
        NSLog(@"Error get content of park data path %@  (%@)", parkDataPath, [error localizedDescription]);
      } else {
        NSString *imagePrefix = [NSString stringWithFormat:@"%@ - ", parkId];
        NSString *exludeImagePrefix1 = [NSString stringWithFormat:@"%@icon_", imagePrefix];
        NSString *exludeImagePrefix2 = [NSString stringWithFormat:@"%@background", imagePrefix];
        NSString *exludeImagePrefix3 = [NSString stringWithFormat:@"%@logo", imagePrefix];
        NSString *exludeImagePrefix4 = [NSString stringWithFormat:@"%@main background", imagePrefix];
        for (NSString *path in files) {
          if ([path hasSuffix:@".jpg"] && [path hasPrefix:imagePrefix] && ![path hasPrefix:exludeImagePrefix1] && ![path hasPrefix:exludeImagePrefix2] && ![path hasPrefix:exludeImagePrefix3] && ![path hasPrefix:exludeImagePrefix4]) {
            BOOL found = NO;
            NSEnumerator *i = [allAttractions objectEnumerator];
            while (TRUE) {
              Attraction *attraction = [i nextObject];
              if (!attraction) break;
              if ([[attraction imageName:parkId] isEqualToString:path]) {
                found = YES;
                break;
              }
            }
            if (!found) NSLog(@"image %@ not assigned to an attraction in plist", path);
          }
        }
      }
      __block NSString *highestInternalPoint = nil;
      [parkAttractionLocations enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        NSString *attractionId = key;
        if ([Attraction isInternalId:attractionId]) {
          if (highestInternalPoint == nil || [highestInternalPoint length] < [attractionId length] || ([highestInternalPoint length] == [attractionId length] &&[highestInternalPoint compare:attractionId] < 0)) {
            highestInternalPoint = attractionId;
          }
        }
       }];
      if (highestInternalPoint != nil) NSLog(@"Internal points are defined up to %@ (including)", highestInternalPoint);
      __block TrackSegment *longestTrackSegment = nil;
      [trackSegments enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        TrackSegment *segment = object;
        if (longestTrackSegment == nil || [longestTrackSegment count] < [segment count]) longestTrackSegment = segment;
      }];
      if (longestTrackSegment != nil) {
        Attraction *fA = [Attraction getAttraction:parkId attractionId:longestTrackSegment.from];
        Attraction *tA = [Attraction getAttraction:parkId attractionId:longestTrackSegment.to];
        NSLog(@"longest segment of %d points between attraction %s (%@) and %s (%@)", [longestTrackSegment count], fA.attractionName,  longestTrackSegment.from, tA.attractionName, longestTrackSegment.to);
      }
#ifdef CREATE_PARK_DOCUMENT
      NSString *document = [Attraction createAllAttractionsDocument:parkId];
      [document writeToFile:[[[MenuData documentPath] stringByAppendingPathComponent:parkId] stringByAppendingString:@".html"] atomically:YES encoding:NSUTF8StringEncoding error:&error];
#endif
#endif
      /*const char *data[] = {"453","48.2657132","7.72217","463","48.2662691","7.7222226","4","48.2675308","7.7237931","002","48.2654166","7.7221617","a01","48.2645215","7.7222941","a03","48.2642587","7.7226767","702","48.2625721","7.723088","710","48.2620597","7.7226377","701","48.2620629","7.7226546","800","48.2623279","7.7225947","600","48.2628644","7.7215004","553","48.26378","7.7213992","554","48.2639614","7.720844","552","48.2639494","7.7207305","701","48.2622937","7.7229312","702","48.2637933","7.7236369","552","48.2638407","7.7207279","550","48.2638519","7.7207644","300","48.2645068","7.7205929","650","48.2621493","7.7195707","405","48.2661923","7.7198597","201","48.2671933","7.7215348","100","48.2676554","7.7219365","350","48.2631225","7.720471","403","48.2675213","7.7195767","404","48.2661887","7.7206335","453","48.2654047","7.7222059","463","48.2658424","7.7222304","4","48.267567","7.723776","002","48.2654166","7.7221617","a01","48.2633848","7.7221313","a03/e","48.2640828","7.7228471","702","48.2623505","7.7230466","710","48.2633848","7.7221313","701/e","48.2620629","7.7226546","800","48.2620437","7.7214495","600/e","48.2633848","7.7221313","553","48.26378","7.7213992","554","48.2639614","7.720844","552","48.2639494","7.7207305","701/e","48.2624674","7.7228522","702","48.2623989","7.7229942","552","48.2641924","7.7210287","582","48.2638514","7.7207494","852","48.2618269","7.7201448","650/e","48.2625679","7.7193194","405","48.2660937","7.7199983","201/e","48.2678351","7.7206308","100","48.2676554","7.7219365","350/e","48.267101","7.7216015","435","48.2675213","7.7195767","404","48.2664542","7.7197588",""};
      for (int i = 0; data[i][0]; i += 3) {
        TrackPoint *p = [parkAttractionLocations objectForKey:[NSString stringWithUTF8String:data[i]]];
        TrackPoint *q = [[TrackPoint alloc] initWithLatitude:[[NSString stringWithUTF8String:data[i+1]] doubleValue] longitude:[[NSString stringWithUTF8String:data[i+2]] doubleValue]];
        double d = [p distanceTo:q];
        [q release];
        NSLog(@"%s: distance:%.2f", data[i], d);
      }*/
    }
  }
  [self getWaitingTimeData]; // contains information if calendar data update is necessary
  [self getCalendarData]; // update calendar data if necessary
  isInitialized = YES;
}

-(void)setDataChanges {
  dataChanges = YES;
}

-(void)setVersionOfIndexFile:(double)d {
  if (d != versionOfIndexFile) {
    dataChanges = YES;
    versionOfIndexFile = d;
  }
}

-(void)setVersionOfDataFile:(double)d {
  if (d != versionOfDataFile) {
    dataChanges = YES;
    versionOfDataFile = d;
  }
}

-(void)setRulesForCommentsAccepted:(BOOL)b {
  if (b != rulesForCommentsAccepted) {
    dataChanges = YES;
    rulesForCommentsAccepted = b;
  }
}

-(void)setTutorialWaitTimeViewed:(BOOL)b {
  if (b != tutorialWaitTimeViewed) {
    dataChanges = YES;
    tutorialWaitTimeViewed = b;
  }
}

-(void)setLastUpdateCheck:(double)d {
  if (d != lastUpdateCheck) {
    dataChanges = YES;
    lastUpdateCheck = d;
  }
}

-(void)setNumberOfAvailableUpdates:(int)i {
  if (i != numberOfAvailableUpdates) {
    dataChanges = YES;
    numberOfAvailableUpdates = i;
  }
}

-(void)setCurrentTrackData:(TrackData *)trackData {
  [currentTrackData release];
  currentTrackData = [trackData retain];
  [self save:YES];
}

-(void)save:(BOOL)save {
  if (save || dataChanges) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"save park data %@", parkId);
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@.dat", [MenuData documentPath], parkId];
    [NSKeyedArchiver archiveRootObject:self toFile:path];
    [path release];
    dataChanges = NO;
    [pool release];
  }
}

+(void)save {
  @synchronized([ParkData class]) {
    if (allParkData != nil) {
      //[NSKeyedArchiver archiveRootObject:allParkData toFile:[ParkData parkDataPath]];
      NSEnumerator *i = [allParkData objectEnumerator];
      while (TRUE) {
        ParkData *parkData = [i nextObject];
        if (!parkData) break;
        [parkData save:NO];
      }
    }
  }
}

+(BOOL)addParkData:(NSString *)parkId versionOfData:(double)version {
  NSLog(@"add park %@ version %f", parkId, version);
  BOOL completeDataCopied = YES;
  @synchronized([ParkData class]) {
    if (![parkId isEqualToString:CORE_DATA_ID]) [Attraction getAllAttractions:parkId reload:YES];  // important if IDs are changing during update
    ParkData *newParkData = [[ParkData alloc] initWithParkId:parkId versionOfData:version];
    ParkData *parkData = [ParkData getParkData:parkId];  // important also if allParkData == nil
    if (parkData != nil) completeDataCopied = [newParkData copyParkData:parkData lastUpdateCheck:[[NSDate date] timeIntervalSince1970]];
    [allParkData setObject:newParkData forKey:parkId];
    [newParkData save:YES];
    [newParkData release];
  }
  return completeDataCopied;
}

+(void)removeParkData:(NSString *)parkId {
  @synchronized([ParkData class]) {
    if (allParkData == nil) [ParkData getParkData:parkId];
    [allParkData removeObjectForKey:parkId];
    //[ParkData save];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[MenuData parkDataPath:parkId] error:&error];
    if (error != nil) {
      NSLog(@"remove park %@ data path - %@", parkId, [error localizedDescription]);
      error = nil;
    }
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@.dat", [MenuData documentPath], parkId];
    [fileManager removeItemAtPath:path error:&error];
    if (error != nil) NSLog(@"remove park %@ data - %@", parkId, [error localizedDescription]);
    [path release];
    [ImageData deleteParkId:parkId];
  }
}

+(NSString *)getParkDataVersions {
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:200] autorelease];
  BOOL first = YES;
  NSArray *parkIds = [MenuData getParkIds];
  for (NSString *parkId in parkIds) {
    ParkData *parkData = [ParkData getParkData:parkId];
    if (parkData != nil) {
      [s appendFormat:(first)? @"%@&nbsp;&nbsp;:%@" : @"\n%@&nbsp;&nbsp;:%@", [MenuData getParkName:parkId cache:YES], [CalendarData stringFromDate:[NSDate dateWithTimeIntervalSince1970:parkData.versionOfData] considerTimeZoneAbbreviation:parkData.timeZoneAbbreviation]];
      first = NO;
    }
  }
  return s;
}

+(BOOL)checkIfUpdateIsNeeded:(NSString*)parkId {
  if (parkId == nil || (parkId != nil && [parkId length] == 0)) return NO;
  ParkData *parkData = [ParkData getParkData:parkId];
  if (parkData == nil) return YES;
  Categories *categories = [Categories getCategories];
  if ([categories getCategoryName:@"DINING"] == nil) return YES;  // ToDo: remove later; introduced with v1.6.1 (Feb 2013)
  if ([parkId isEqualToString:@"dhep"]) return (parkData.versionOfData < 1359816164.0);
  if ([parkId isEqualToString:@"dmp"]) return (parkData.versionOfData < 1359928878.0);
  if ([parkId isEqualToString:@"dphl"]) return (parkData.versionOfData < 1359788283.0);
  if ([parkId isEqualToString:@"ep"]) return (parkData.versionOfData < 1359788283.0);
  if ([parkId isEqualToString:@"fdlp"]) return (parkData.versionOfData < 1359788283.0);
  if ([parkId isEqualToString:@"fdsp"]) return (parkData.versionOfData < 1359816164.0);
  if ([parkId isEqualToString:@"nlde"]) return (parkData.versionOfData < 1359788283.0);
  if ([parkId isEqualToString:@"usdakfl"]) return (parkData.versionOfData < 1359816164.0);
  if ([parkId isEqualToString:@"usdcaca"]) return (parkData.versionOfData < 1359817072.0);
  if ([parkId isEqualToString:@"usdefl"]) return (parkData.versionOfData < 1359788283.0);
  if ([parkId isEqualToString:@"usdhsfl"]) return (parkData.versionOfData < 1359817072.0);
  if ([parkId isEqualToString:@"usdlca"]) return (parkData.versionOfData < 1359792285.0);
  if ([parkId isEqualToString:@"usdmkfl"]) return (parkData.versionOfData < 1359788283.0);
  if ([parkId isEqualToString:@"usuifl"]) return (parkData.versionOfData < 1359788283.0);
  if ([parkId isEqualToString:@"ususfl"]) return (parkData.versionOfData < 1359816164.0);
  return NO;
}

+(BOOL)isUpdateAvailable:(NSArray *)versionInfo {
  if (versionInfo.count >= 2) {
    ParkData *parkData = [ParkData getParkData:CORE_DATA_ID];
    if (parkData != nil) {
      const double d0 = [[versionInfo objectAtIndex:0] doubleValue];
      const double d1 = [[versionInfo objectAtIndex:1] doubleValue];
      BOOL updateAvailable = (parkData.versionOfDataFile != d0 || parkData.versionOfIndexFile != d1);
      if (updateAvailable) {
        if (parkData.versionOfDataFile != d0) NSLog(@"update core data available (%f - %f)", parkData.versionOfDataFile, d0);
        else NSLog(@"update image index available (%f - %f)", parkData.versionOfIndexFile, d1);
        return YES;
      }
      return NO;
    }
  }
  return YES;
}

+(void)updateLastUpdateCheck:(NSArray *)availableUpdates versionInfo:(NSArray *)versionInfo {
  ParkData *parkData = [ParkData getParkData:CORE_DATA_ID];
  if (parkData != nil) {
    parkData.lastUpdateCheck = [[NSDate date] timeIntervalSince1970];
    parkData.numberOfAvailableUpdates = (availableUpdates != nil)? (int)[availableUpdates count] : 0;
    if (versionInfo != nil && [versionInfo count] >= 2) {
      parkData.versionOfDataFile = [[versionInfo objectAtIndex:0] doubleValue];
      parkData.versionOfIndexFile = [[versionInfo objectAtIndex:1] doubleValue];
    }
    [parkData save:YES];
  }
}

static BOOL availableUpdatesActive = NO;

+(BOOL)isAvailableUpdatesActive {
  @synchronized([ParkData class]) {
    return availableUpdatesActive;
  }  
}

+(int)availableUpdates:(BOOL)reload {
  @synchronized([ParkData class]) {
    availableUpdatesActive = YES;
    ParkData *parkData = [ParkData getParkData:CORE_DATA_ID];
    SettingsData *settings = [SettingsData getSettingsData];
    if ([settings isParkDataUpdateManually]) {
      availableUpdatesActive = NO;
      return (parkData != nil)? parkData.numberOfAvailableUpdates : 0;
    }
    int days = [settings getParkDataUpdateDays];
    if (parkData == nil) {
      [ParkData addParkData:CORE_DATA_ID versionOfData:0.0];
      parkData = [ParkData getParkData:CORE_DATA_ID];
    }
    double lastUpdateCheck = (parkData != nil)? parkData.lastUpdateCheck : 0.0;
    if (lastUpdateCheck+days*24*3600.0 <= [[NSDate date] timeIntervalSince1970]) {
      NSArray *availableUpdates = [Update availableUpdates:nil includingHD:YES checkVersionInfo:YES];
      if (availableUpdates != nil) {
        availableUpdatesActive = NO;
        return (int)[availableUpdates count];
      }
    }
    availableUpdatesActive = NO;
    return (parkData != nil)? parkData.numberOfAvailableUpdates : 0;
  }
}

#pragma mark -
#pragma mark Calendar data

-(BOOL)isCalendarDataInitialized {
  return (calendarData != nil);
}

-(CalendarData *)getCalendarData:(UIViewController<CalendarDataDelegate> *)viewController {
  if (calendarData != nil) {
    if (viewController != nil) [calendarData registerViewController:viewController];
    [calendarData updateIfNecessary];
    return calendarData;
  }
  if (![parkId isEqualToString:CORE_DATA_ID]) {
    if (viewController == nil) viewController = calendarData.registeredViewController;
    [calendarData release];
    calendarData = [[CalendarData alloc] initWithParkId:parkId registeredViewController:viewController];
    if (hasWinterData) winterDataEnabled = [calendarData hasWinterDataFor:[NSDate date]];
  }
  return calendarData;
}

-(CalendarData *)getCalendarData {
  return [self getCalendarData:nil];
}

#pragma mark -
#pragma mark News data

-(BOOL)isNewsDataInitialized {
  @synchronized([NewsData class]) {
    return (newsData != nil);
  }
}

-(NewsData *)getNewsData {
  @synchronized([NewsData class]) {
    if (newsData != nil) [newsData updateIfNecessary];
    else if (![parkId isEqualToString:CORE_DATA_ID]) newsData = [[NewsData alloc] initWithParkId:parkId];
    if (newsData != nil && newsData.numberOfNewEntries > 0) {
      numberOfNewNewsEntries += newsData.numberOfNewEntries;
      int n = [newsData.newsData.titles count];
      if (numberOfNewNewsEntries > n) numberOfNewNewsEntries = n;
      [newsData resetNumberOfNewEntries];
      [self save:YES];
    }
    return newsData;
  }
}

-(void)resetNumberOfNewNewsEntries {
  @synchronized([NewsData class]) {
    if (numberOfNewNewsEntries > 0) {
      numberOfNewNewsEntries = 0;
      [self save:YES];
    }
  }
}

#pragma mark -
#pragma mark News data

-(WaitingTimeData *)getWaitingTimeData:(UIViewController<WaitingTimeDataDelegate> *)viewController {
  if (waitingTimeData != nil) {
    if (viewController != nil) [waitingTimeData registerViewController:viewController];
    [waitingTimeData update:NO];
    return waitingTimeData;
  }
  if (![parkId isEqualToString:CORE_DATA_ID]) {
    if (viewController == nil) viewController = waitingTimeData.registeredViewController;
    [waitingTimeData release];
    waitingTimeData = [[WaitingTimeData alloc] initWithParkId:parkId registeredViewController:viewController];
  }
  return waitingTimeData;
}

-(WaitingTimeData *)getWaitingTimeData {
  return [self getWaitingTimeData:nil];
}

#pragma mark -
#pragma mark Attraction IDs

-(NSString *)getEntryOfPark:(TrackPoint *)trackPoint {
  @synchronized([ParkData class]) {
    if (trackPoint == nil && cachedMainEntryOfPark != nil) return cachedMainEntryOfPark;
    if (lastTrackPointForEntryOfPark != nil && [trackPoint isEqual:lastTrackPointForEntryOfPark]) return lastIdEntryOfPark;
    if (trackPoint != nil) {
      [lastTrackPointForEntryOfPark release];
      lastTrackPointForEntryOfPark = [trackPoint retain];
    }
    NSString *entryId = @"000";
    int entryIdx = [MenuData binarySearch:entryId inside:allAttractionIds];
    if (entryIdx >= 0) {
      if (trackPoint == nil) {
        [cachedMainEntryOfPark release];
        cachedMainEntryOfPark = [entryId retain];
      } else {
        [lastIdEntryOfPark release];
        lastIdEntryOfPark = [entryId retain];
      }
      return entryId;
    }
    NSArray *allEntries = [self allLocationIdxOf:entryId attractionIdx:entryIdx];
    entryIdx = [[allEntries objectAtIndex:0] intValue];
    if (entryIdx < 0) return nil;
    entryId = [allAttractionIds objectAtIndex:entryIdx];
    if (trackPoint == nil || allEntries.count == 1) {
      if (trackPoint == nil) {
        [cachedMainEntryOfPark release];
        cachedMainEntryOfPark = [entryId retain];
      } else {
        [lastIdEntryOfPark release];
        lastIdEntryOfPark = [entryId retain];
      }
      return entryId;
    }
    TrackPoint *t = [self getAttractionLocation:entryId];
    double lat = t.latitude-trackPoint.latitude;
    double lon = t.longitude-trackPoint.longitude;
    double m = lat*lat + lon*lon;
    for (NSNumber *aIdx in allEntries) {
      if (entryIdx != [aIdx intValue]) {
        NSString *aId = [allAttractionIds objectAtIndex:[aIdx intValue]];
        t = [self getAttractionLocation:aId];
        lat = t.latitude-trackPoint.latitude;
        lon = t.longitude-trackPoint.longitude;
        double d = lat*lat + lon*lon;
        if (d < m) {
          m = d;
          entryId = aId;
        }
      }
    }
    if (trackPoint == nil) {
      [cachedMainEntryOfPark release];
      cachedMainEntryOfPark = [entryId retain];
    } else {
      [lastIdEntryOfPark release];
      lastIdEntryOfPark = [entryId retain];
    }
    return entryId;
  }
}

-(NSString *)getExitOfPark:(TrackPoint *)trackPoint {
  @synchronized([ParkData class]) {
    if (trackPoint == nil && cachedMainExitOfPark != nil) return cachedMainExitOfPark;
    if (lastTrackPointForExitOfPark != nil && [trackPoint isEqual:lastTrackPointForExitOfPark]) return lastIdExitOfPark;
    if (trackPoint != nil) {
      [lastTrackPointForExitOfPark release];
      lastTrackPointForExitOfPark = [trackPoint retain];
    }
    NSString *exitId = @"000/e";
    int exitIdx = [MenuData binarySearch:exitId inside:allAttractionIds];
    if (exitIdx >= 0) {
      if (trackPoint == nil) {
        [cachedMainExitOfPark release];
        cachedMainExitOfPark = [exitId retain];
      } else {
        [lastIdExitOfPark release];
        lastIdExitOfPark = [exitId retain];
      }
      return exitId;
    }
    NSArray *allExits = [self allLocationIdxOf:exitId attractionIdx:exitIdx];
    exitIdx = [[allExits objectAtIndex:0] intValue];
    if (exitIdx < 0) return nil;
    exitId = [allAttractionIds objectAtIndex:exitIdx];
    if (trackPoint == nil || allExits.count == 1) {
      if (trackPoint == nil) {
        [cachedMainExitOfPark release];
        cachedMainExitOfPark = [exitId retain];
      } else {
        [lastIdExitOfPark release];
        lastIdExitOfPark = [exitId retain];
      }
      return exitId;
    }
    TrackPoint *t = [self getAttractionLocation:exitId];
    double lat = t.latitude-trackPoint.latitude;
    double lon = t.longitude-trackPoint.longitude;
    double m = lat*lat + lon*lon;
    for (NSNumber *aIdx in allExits) {
      if (exitIdx != [aIdx intValue]) {
        NSString *aId = [allAttractionIds objectAtIndex:[aIdx intValue]];
        t = [self getAttractionLocation:aId];
        lat = t.latitude-trackPoint.latitude;
        lon = t.longitude-trackPoint.longitude;
        double d = lat*lat + lon*lon;
        if (d < m) {
          m = d;
          exitId = aId;
        }
      }
    }
    if (trackPoint == nil) {
      [cachedMainExitOfPark release];
      cachedMainExitOfPark = [exitId retain];
    } else {
      [lastIdExitOfPark release];
      lastIdExitOfPark = [exitId retain];
    }
    return exitId;
  }
}

-(BOOL)isEntryOfPark:(NSString *)attractionId {
  if (([attractionId hasPrefix:@"000"] && ![attractionId hasSuffix:@"/e"]) || [cachedMainEntryOfPark isEqualToString:attractionId]) return YES;
  NSArray *a = [sameAttractionIds allKeysForObject:attractionId];
  if (a != nil && [a count] == 1) attractionId = [a objectAtIndex:0];
  attractionId = [self getRootAttractionId:attractionId];
  return ([attractionId hasPrefix:@"000"] && ![attractionId hasSuffix:@"/e"]);
}

-(BOOL)isExitOfPark:(NSString *)attractionId {
  if (([attractionId hasPrefix:@"000"] && [attractionId hasSuffix:@"/e"]) || [cachedMainExitOfPark isEqualToString:attractionId]) return YES;
  NSArray *a = [sameAttractionIds allKeysForObject:attractionId];
  if (a != nil && [a count] == 1) attractionId = [a objectAtIndex:0];
  attractionId = [self getRootAttractionId:attractionId];
  return ([attractionId hasPrefix:@"000"] && [attractionId hasSuffix:@"/e"]);
}

-(BOOL)isEntryOrExitOfPark:(NSString *)attractionId {
  if ([attractionId hasPrefix:@"000"] || [cachedMainEntryOfPark isEqualToString:attractionId] || [cachedMainExitOfPark isEqualToString:attractionId]) return YES;
  NSArray *a = [sameAttractionIds allKeysForObject:attractionId];
  if (a != nil && [a count] == 1) attractionId = [a objectAtIndex:0];
  attractionId = [self getRootAttractionId:attractionId];
  return [attractionId hasPrefix:@"000"];
}

-(BOOL)isEntryUnique:(NSString *)attractionId {
  // e.g. 495@0 is unique but not 495
  if ([self getAttractionLocation:attractionId] != nil) return YES;
  return ([self getAttractionLocation:[self getRootAttractionId:attractionId]] != nil);
}

-(NSString *)firstEntryAttractionIdOf:(NSString *)attractionId {
  if ([self getAttractionLocation:attractionId] != nil) return attractionId;
  NSString *aId = [Attraction getShortAttractionId:attractionId];
  NSString *eId = [aId stringByAppendingString:@"@0"];
  return ([self getAttractionLocation:eId] != nil)? eId : attractionId;
}

-(NSString *)exitAttractionIdOf:(NSString *)attractionId {
  //if ([self isEntryOfPark:attractionId]) return attractionId;  sonst wird beim neu Anlegen einer Tour zwei Mal der Haupteingang hinzugefügt
  NSString *aId = [Attraction getShortAttractionId:attractionId];
  NSString *eId = [aId stringByAppendingString:@"/e"];
  if ([self getAttractionLocation:eId] != nil) return eId;
  NSArray *a = [sameAttractionIds allKeysForObject:aId];
  if (a != nil && [a count] == 1) {
    aId = [a objectAtIndex:0];
    eId = [self getRootAttractionId:[aId stringByAppendingString:@"/e"]];
  }
  return ([self getAttractionLocation:eId] != nil)? eId : attractionId;
}

-(BOOL)isEntryExitSame:(NSString *)attractionId {
  NSString *aId = [Attraction getShortAttractionId:attractionId];
  NSString *eId = [aId stringByAppendingString:@"/e"];
  if ([self getAttractionLocation:eId] != nil) return NO;
  NSArray *a = [sameAttractionIds allKeysForObject:aId];
  if (a != nil && [a count] == 1) {
    aId = [a objectAtIndex:0];
    eId = [self getRootAttractionId:[aId stringByAppendingString:@"/e"]];
  }
  return ([self getAttractionLocation:eId] == nil);
}

-(NSArray *)allLocationIdxOf:(NSString *)attractionId attractionIdx:(int)attractionIdx {
  if (attractionIdx >= 0) return [NSArray arrayWithObject:[NSNumber numberWithInt:attractionIdx]];
  BOOL isExit = [attractionId hasSuffix:@"/e"];
  NSString *attractionId2 = (isExit)? [attractionId substringToIndex:[attractionId length]-2] : attractionId;
  NSString *aId = [self getRootAttractionId:[attractionId2 stringByAppendingString:(isExit)? @"@0/e" : @"@0"]];
  NSArray *array = [allRelatedAttractionIds objectForKey:attractionId];
  if (array == nil) {
    //attractionIdx = -attractionIdx - 1;
    //if (![aId isEqualToString:[allAttractionIds objectAtIndex:attractionIdx]]) {
    attractionIdx = [MenuData binarySearch:aId inside:allAttractionIds];
    if (attractionIdx < 0) return nil;
    //}
    NSMutableArray *m = [[[NSMutableArray alloc] initWithCapacity:4] autorelease];
    [m addObject:[NSNumber numberWithInt:attractionIdx]];
    for (int i = 1;; ++i) {
      aId = [self getRootAttractionId:[attractionId2 stringByAppendingFormat:((isExit)? @"@%d/e" : @"@%d"), i]];
      ++attractionIdx;
      if (![aId isEqualToString:[allAttractionIds objectAtIndex:attractionIdx]]) {
        attractionIdx = [MenuData binarySearch:aId inside:allAttractionIds];
        if (attractionIdx < 0) break;
      }
      [m addObject:[NSNumber numberWithInt:attractionIdx]];
    }
    array = m;
    [allRelatedAttractionIds setObject:array forKey:attractionId];
  }
  return array;
  /*
  if (attractionId == nil) return nil;
  NSString *aId = [self getRootAttractionId:[attractionId stringByAppendingString:@"@0"]];
  NSArray *array = [allRelatedAttractionIds objectForKey:aId];
  if (array == nil) {
    if ([parkAttractionLocations objectForKey:aId] == nil) array = [NSArray arrayWithObject:attractionId];
    else {
      NSMutableArray *m = [[[NSMutableArray alloc] initWithCapacity:4] autorelease];
      [m addObject:aId];
      NSLog(@"%@ (%d) - %@ (%d)", attractionId, [ParkData binarySearch:attractionId inside:allAttractionIds], aId, [ParkData binarySearch:aId inside:allAttractionIds]);
      for (int i = 1;; ++i) {
        aId = [self getRootAttractionId:[attractionId stringByAppendingFormat:@"@%d", i]];
        if ([parkAttractionLocations objectForKey:aId] == nil) break;
        NSLog(@"%@ - %@ (%d)", attractionId, aId, [ParkData binarySearch:aId inside:allAttractionIds]);
        [m addObject:aId];
      }
      array = m;
    }
    [allRelatedAttractionIds setObject:array forKey:aId];
  }
  return array;*/
}

-(NSArray *)allAttractionRelatedLocationIdsOf:(NSString *)attractionId { // incl. fast lane and exit
  if (attractionId == nil) return nil;
  NSMutableArray *m = [[[NSMutableArray alloc] initWithCapacity:10] autorelease];
  NSString *aId = [attractionId stringByAppendingString:@"@0"];
  NSString *rId = [self getRootAttractionId:aId];
  if ([parkAttractionLocations objectForKey:rId] == nil) {
    rId = [self getRootAttractionId:attractionId];
    if ([parkAttractionLocations objectForKey:rId] != nil) [m addObject:attractionId];
  } else {
    [m addObject:aId];
    for (int i = 1;; ++i) {
      aId = [attractionId stringByAppendingFormat:@"@%d", i];
      rId = [self getRootAttractionId:aId];
      if ([parkAttractionLocations objectForKey:rId] == nil) break;
      [m addObject:aId];
    }
  }
  aId = [attractionId stringByAppendingString:@"@0/e"];
  rId = [self getRootAttractionId:aId];
  if ([parkAttractionLocations objectForKey:rId] == nil) {
    aId = [attractionId stringByAppendingString:@"/e"];
    rId = [self getRootAttractionId:aId];
    if ([parkAttractionLocations objectForKey:rId] != nil) [m addObject:aId];
  } else {
    [m addObject:aId];
    for (int i = 1;; ++i) {
      aId = [attractionId stringByAppendingFormat:@"@%d/e", i];
      rId = [self getRootAttractionId:aId];
      if ([parkAttractionLocations objectForKey:rId] == nil) break;
      [m addObject:aId];
    }
  }
  aId = [attractionId stringByAppendingString:@"/f"];
  rId = [self getRootAttractionId:rId];
  if ([parkAttractionLocations objectForKey:rId] != nil) [m addObject:aId];
  return m;
}

-(NSString *)getRootAttractionId:(NSString *)attractionId {
  if ([attractionId hasPrefix:@"000"]) return attractionId;
  NSString *aId = [sameAttractionIds objectForKey:attractionId];
  return (aId != nil /*&& [sameAttractionIds objectForKey:aId] == nil*/)? aId : attractionId;
}

-(NSString *)getAttractionDataId:(NSString *)attractionId {
  return [attractionId hasPrefix:@"000"]? [sameAttractionIds objectForKey:attractionId] : attractionId;
}

-(BOOL)isExitAttractionId:(NSString *)attractionId {
  if ([attractionId hasSuffix:@"/e"]) return YES;
  NSString *aId = [sameAttractionIds objectForKey:attractionId];
  /*if (aId == nil) {
    NSArray *a = [sameAttractionIds allKeysForObject:attractionId];
    if (a != nil && [a count] == 1) aId = [a objectAtIndex:0];
  }*/
  return (aId != nil && [aId hasSuffix:@"/e"]);
}

-(NSString *)getEntryAttractionId:(NSString *)exitAttractionId {
  if ([exitAttractionId hasSuffix:@"/e"]) return [exitAttractionId substringToIndex:[exitAttractionId length]-2];
  NSString *eId = [self getRootAttractionId:exitAttractionId];
  return (eId != nil && [eId hasSuffix:@"/e"])? [eId substringToIndex:[eId length]-2] : exitAttractionId;
}

-(BOOL)isFastLaneEntryAttractionId:(NSString *)attractionId {
  if ([attractionId hasSuffix:@"/f"]) return YES;
  NSString *aId = [sameAttractionIds objectForKey:attractionId];
  return (aId != nil && [aId hasSuffix:@"/f"]);
}

-(NSString *)getFastLaneEntryAttractionIdOf:(NSString *)attractionId {
  NSString *aId = [Attraction getShortAttractionId:attractionId];
  NSString *fId = [aId stringByAppendingString:@"/f"];
  if ([self getAttractionLocation:fId] != nil) return fId;
  NSArray *a = [sameAttractionIds allKeysForObject:aId];
  if (a != nil && [a count] == 1) {
    aId = [a objectAtIndex:0];
    fId = [self getRootAttractionId:[aId stringByAppendingString:@"/f"]];
  }
  return ([self getAttractionLocation:fId] != nil)? fId : attractionId;
}

#pragma mark -
#pragma mark Tour data

-(NSArray *)getTourNames {
  return [toursData allKeys];
}

-(BOOL)setCurrentTourName:(NSString *)newTourName {
  if ([currentTourName isEqualToString:newTourName]) return YES;
  if ([toursData objectForKey:newTourName] == nil) return NO;
  [self completeCurrentTrack];
  [currentTourName release];
  currentTourName = [newTourName retain];
  [self save:YES];
  return YES;
}

-(void)addEntryExitToTourData:(TourData *)tourData {
  if (currentTourNotInitialized) {
    if (tourData != nil && [tourData count] == 0) {
      NSString *entryOfPark = [self getAttractionDataId:[self getEntryOfPark:nil]];
      if (entryOfPark != nil) {
        TourItem *tourItem = [[TourItem alloc] initWithAttractionId:entryOfPark entry:entryOfPark exit:entryOfPark];
        [tourData add:tourItem startTime:0.0];
        [tourItem release];
        currentTourNotInitialized = NO;
      } else {
        NSLog(@"Entry of park not defined for %@", parkId);
        currentTourNotInitialized = YES;
      }
      NSString *exitOfPark = [self getAttractionDataId:[self getExitOfPark:nil]];
      if (exitOfPark != nil) {
        TourItem *tourItem = [[TourItem alloc] initWithAttractionId:exitOfPark entry:exitOfPark exit:exitOfPark];
        [tourData add:tourItem startTime:[[NSDate date] timeIntervalSince1970]];
        [tourItem release];
        currentTourNotInitialized = NO;
      } else {
        NSLog(@"Exit of park not defined for %@", parkId);
        currentTourNotInitialized = YES;
      }
    } else {
      currentTourNotInitialized = NO;
    }
  }
}

-(BOOL)addNewTourName:(NSString *)newTourName {
  if (newTourName != nil && [toursData objectForKey:newTourName] == nil) {
    [self completeCurrentTrack];
    TourData *tourData = [[TourData alloc] initWithParkId:parkId tourName:newTourName];
    currentTourNotInitialized = YES;
    [self addEntryExitToTourData:tourData];
    [toursData setObject:tourData forKey:newTourName];
    [tourData release];
    [currentTourName release];
    currentTourName = [newTourName retain];
    [self save:YES];
    return YES;
  }
  return NO;
}

-(void)deleteTour:(NSString *)tourName {
  [self completeCurrentTrack];
  [toursData removeObjectForKey:tourName];
  if ([toursData count] == 0) {
    [self addNewTourName:[MenuData getParkName:parkId cache:YES]];
  } else if ([tourName isEqualToString:currentTourName]) {
    NSString *newTourName = [[toursData allKeys] objectAtIndex:0];
    [currentTourName release];
    currentTourName = [newTourName retain];
    [self save:YES];
  } else {
    [self save:YES];
  }
}

-(BOOL)renameTourNameFrom:(NSString *)fromTourName to:(NSString *)toTourName {
  BOOL isEqual = [fromTourName isEqualToString:toTourName];
  if (!isEqual && [toursData objectForKey:toTourName] == nil) {
    TourData * t = [toursData objectForKey:fromTourName];
    if (t == nil) return NO;
    t.tourName = toTourName;
    [toursData setObject:t forKey:toTourName];
    [toursData removeObjectForKey:fromTourName];
    [currentTourName release];
    currentTourName = [toTourName retain];
    [self save:YES];
    return YES;
  }
  return isEqual;
}

-(TourData *)getTourData:(NSString *)tourName {
  return [toursData objectForKey:tourName];
}

#pragma mark -
#pragma mark Track data

-(TrackData *)completeCurrentTrack {
  if (currentTrackData != nil) {
    TourData *tourData = [self getTourData:currentTourName];
    if (![currentTrackData complete:[tourData createTrackDescription]]) return nil;
    [tourData askNextTimeForTourOptimization];
    NSString *trackName = [currentTrackData.trackName retain];
    [completedTourData setObject:currentTrackData forKey:currentTrackData.trackName];
    [currentTrackData release];
    currentTrackData = nil;
    [self save:YES];
    TrackData *track = [completedTourData objectForKey:trackName];
    [trackName release];
    return track;
  }
  return nil;
}

-(NSArray *)getCompletedTracks {
  return [completedTourData allKeys];
}

-(TrackData *)getTrackData:(NSString *)trackName {
  return [completedTourData objectForKey:trackName];
}

-(void)removeTrackData:(NSString *)trackName {
  TrackData *trackData = [completedTourData objectForKey:trackName];
  if (trackData != nil) {
    [trackData deleteData];
    [completedTourData removeObjectForKey:trackName];
    [self save:YES];
  }
}

-(void)updateParkingTrack {
  if (currentTrackData.trackSegments != nil && [currentTrackData.trackSegments count] > 0) {
    TrackSegment *firstSegment = [currentTrackData.trackSegments objectAtIndex:0];
    if ([[firstSegment fromAttractionId] isEqualToString:PARKING_ATTRACTION_ID]) {
      dataChanges = YES;
      [lastTrackFromParking release];
      lastTrackFromParking = [firstSegment retain];
      [lastParkingNotes release];
      lastParkingNotes = [currentTrackData.parkingNotes retain];
    }
  }
}

#pragma mark -
#pragma mark Tour suggestion data

-(NSArray *)getTourSuggestions {
  NSMutableArray *m = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
  NSDictionary *d = [MenuData getParkDetails:parkId cache:YES];
  d = [d objectForKey:@"MENU_TOUR"];
  for (id tourName in d) {
    id o = [d objectForKey:tourName];
    if ([o isKindOfClass:[NSArray class]]) {
      [m addObject:tourName];
    }
  }
  return m;
}

-(NSArray *)getTourSuggestion:(NSString *)tourName {
  NSMutableArray *m = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
  NSDictionary *d = [MenuData getParkDetails:parkId cache:YES];
  d = [d objectForKey:@"MENU_TOUR"];
  NSArray *a = [d objectForKey:tourName];
  for (NSString *attractionId in a) {
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
    if (attraction == nil) NSLog(@"Unkown attraction %@ in tour suggestion %@", attractionId, tourName);
    else if (![attraction isClosed:parkId]) [m addObject:attractionId];
  }
  return m;
}

#pragma mark -
#pragma mark Tour comments and rating data

-(NSString *)getCommentsHistory:(NSString *)attractionId {
  NSMutableString *history = [[[NSMutableString alloc] initWithCapacity:500] autorelease];
  [history appendString:@"<table>"];
  NSArray *comments = [attractionComments objectForKey:attractionId];
  for (Comment *comment in comments) {
    [history appendFormat:@"<tr><td>%@&nbsp;</td><td>%@</td></tr>", [CalendarData stringFromDate:[NSDate dateWithTimeIntervalSince1970:comment.timeInterval] considerTimeZoneAbbreviation:timeZoneAbbreviation], comment.comment];
  }
  [history appendString:@"</table>"];
  return history;
}

-(NSArray *)getComments:(NSString *)attractionId {
  return [attractionComments objectForKey:attractionId];
}

-(void)addComment:(NSString *)comment attractionId:(NSString *)attractionId {
  dataChanges = YES;
  Comment *c = [[Comment alloc] initWithComment:comment];
  BOOL oneWay;
  NSArray *attractions = [self getTrainAttractionRoute:attractionId oneWay:&oneWay];
  if (attractions == nil) {
    NSArray *a = [attractionComments objectForKey:attractionId];
    if (a != nil) {
      NSMutableArray *m = [[NSMutableArray alloc] initWithCapacity:[a count]+1];
      [m addObject:c];
      [m addObjectsFromArray:a];
      [attractionComments setObject:m forKey:attractionId];
      [m release];
    } else {
      [attractionComments setObject:[NSArray arrayWithObject:c] forKey:attractionId];
    }
  } else {
    for (Attraction *attraction in attractions) {
      NSArray *a = [attractionComments objectForKey:attraction.attractionId];
      if (a != nil) {
        NSMutableArray *m = [[NSMutableArray alloc] initWithCapacity:[a count]+1];
        [m addObject:c];
        [m addObjectsFromArray:a];
        [attractionComments setObject:m forKey:attraction.attractionId];
        [m release];
      } else {
        [attractionComments setObject:[NSArray arrayWithObject:c] forKey:attraction.attractionId];
      }
    }
  }
  [c release];
}

-(int)getPersonalRating:(NSString *)attractionId {
  NSNumber *n = [personalAttractionRatings objectForKey:attractionId];
  return (n == nil)? 0 : [n intValue];
}

-(void)setPersonalRating:(int)rating attractionId:(NSString *)attractionId {
  BOOL oneWay;
  dataChanges = YES;
  NSArray *attractions = [self getTrainAttractionRoute:attractionId oneWay:&oneWay];
  if (attractions == nil) {
    if (rating == 0) [personalAttractionRatings removeObjectForKey:attractionId];
    else [personalAttractionRatings setObject:[NSNumber numberWithInt:rating] forKey:attractionId];
  } else if (rating == 0) {
    for (Attraction *attraction in attractions) [personalAttractionRatings removeObjectForKey:attraction.attractionId];
  } else {
    NSNumber *n = [NSNumber numberWithInt:rating];
    for (Attraction *attraction in attractions) [personalAttractionRatings setObject:n forKey:attraction.attractionId];
  }
}

-(NSString *)getPersonalRatingAsStars:(NSString *)attractionId {
  NSNumber *n = [personalAttractionRatings objectForKey:attractionId];
  if (n == nil) return nil;
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:5] autorelease];
  int i = -1;
  int j = [n intValue];
  while (++i < j) [s appendString:@"★"];
  while (++i < 6) [s appendString:@"☆"];
  return s;
}

-(BOOL)isFavorite:(NSString *)attractionId {
  return [attractionFavorites containsObject:attractionId];
}

-(void)addFavorite:(NSString *)attractionId {
  if (![attractionFavorites containsObject:attractionId]) {
    [attractionFavorites addObject:attractionId];
    [self save:YES];
  }
}

-(void)removeFavorite:(NSString *)attractionId {
  if ([attractionFavorites containsObject:attractionId]) {
    [attractionFavorites removeObject:attractionId];
    [self save:YES];
  }
}

-(NSMutableDictionary *)selectedCategoriesForCategoryNames:(NSArray *)categoryNames {
  NSMutableDictionary *selectedCategories = nil;
  NSString *path = [[NSString alloc] initWithFormat:@"%@/%@_types.dat", [MenuData documentPath], parkId];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:path]) {
    NSDictionary *data = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    Categories *categories = [Categories getCategories];
    if ([data objectForKey:@"SHOW"] != nil) {
      selectedCategories = [[[NSMutableDictionary alloc] initWithCapacity:data.count] autorelease];
      [data enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        NSString *categoryId = key;
        if ([categoryId isEqualToString:ALL_WITH_WAIT_TIME]) [selectedCategories setObject:object forKey:key];
        else {
          BOOL hasPrefix = [categoryId hasPrefix:PREFIX_FAVORITES];
          if (hasPrefix) categoryId = [categoryId substringFromIndex:[PREFIX_FAVORITES length]];
          NSString *categoryName = [categories getCategoryName:categoryId];
          if (categoryName != nil) {
            if (hasPrefix) categoryName = [PREFIX_FAVORITES stringByAppendingString:categoryName];
            [selectedCategories setObject:object forKey:categoryName];
          } else NSLog(@"unknown category ID %@", categoryId);
        }
      }];
    } else { // introduced in v1.7 but replaced by IDs in v1.7.1
      NSMutableArray *removeNames = [[NSMutableArray alloc] initWithCapacity:categoryNames.count];
      NSMutableArray *addNames = [[NSMutableArray alloc] initWithCapacity:categoryNames.count];
      selectedCategories = (data == nil)? [[[NSMutableDictionary alloc] initWithCapacity:categoryNames.count] autorelease] : [[[NSMutableDictionary alloc] initWithDictionary:data] autorelease];
      NSNumber *allFavorites = [selectedCategories objectForKey:ALL_FAVORITES];
      if (allFavorites == nil) allFavorites = [NSNumber numberWithBool:YES];
      [selectedCategories enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        NSString *c = key;
        if (![c isEqualToString:ALL_WITH_WAIT_TIME]) {
          if ([key hasPrefix:PREFIX_FAVORITES]) {
            if (![categoryNames containsObject:[key substringFromIndex:[PREFIX_FAVORITES length]]]) [removeNames addObject:key];
          } else {
            if (![categoryNames containsObject:key]) [removeNames addObject:key];
            NSString *favoriteKey = [PREFIX_FAVORITES stringByAppendingString:key];
            if ([selectedCategories objectForKey:favoriteKey] == nil) [addNames addObject:favoriteKey];
          }
        }
      }];
      if (removeNames.count > 0 || addNames.count > 0) {
        [selectedCategories removeObjectsForKeys:removeNames];
        for (NSString *name in addNames) {
          [selectedCategories setObject:allFavorites forKey:name];
        }
        [selectedCategories removeObjectForKey:ALL_FAVORITES];
        [self saveChangedCategories:selectedCategories];
      }
      [addNames release];
      [removeNames release];
    }
  } else {
    selectedCategories = [[[NSMutableDictionary alloc] initWithCapacity:categoryNames.count] autorelease];
    NSNumber *noValue = [NSNumber numberWithBool:NO];
    NSNumber *yesValue = [NSNumber numberWithBool:YES];
    [selectedCategories setObject:yesValue forKey:ALL_WITH_WAIT_TIME];
    for (NSString *categoryName in categoryNames) {
      [selectedCategories setObject:noValue forKey:categoryName];
      [selectedCategories setObject:yesValue forKey:[PREFIX_FAVORITES stringByAppendingString:categoryName]];
    }
    [self saveChangedCategories:selectedCategories];
  }
  [path release];
  return selectedCategories;
}

-(void)saveChangedCategories:(NSDictionary *)selectedCategories {
  // store IDs and not names to be language independant
  NSLog(@"save selected types for %@", parkId);
  NSString *path = [[NSString alloc] initWithFormat:@"%@/%@_types.dat", [MenuData documentPath], parkId];
  Categories *categories = [Categories getCategories];
  NSMutableDictionary *m = [[NSMutableDictionary alloc] initWithCapacity:selectedCategories.count];
  [selectedCategories enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSString *categoryName = key;
    if ([categoryName isEqualToString:ALL_WITH_WAIT_TIME]) [m setObject:object forKey:key];
    else {
      BOOL hasPrefix = [categoryName hasPrefix:PREFIX_FAVORITES];
      if (hasPrefix) categoryName = [categoryName substringFromIndex:[PREFIX_FAVORITES length]];
      NSString *categoryId = [categories getCategoryOrTypeId:categoryName];
      if (categoryId != nil) {
        if (hasPrefix) categoryId = [PREFIX_FAVORITES stringByAppendingString:categoryId];
        [m setObject:object forKey:categoryId];
      } else NSLog(@"unknown category name %@", categoryName);
    }
  }];
  [NSKeyedArchiver archiveRootObject:m toFile:path];
  [path release];
  [m release];
}

#pragma mark -
#pragma mark Track data

-(TrackPoint *)getAttractionLocation:(NSString *)attractionId {
  if (parkAttractionLocations != nil) {
    attractionId = [self getRootAttractionId:attractionId];
    return [parkAttractionLocations objectForKey:attractionId];
  }
  return nil;
}

-(void)addAttractionId:(NSString *)attractionId atLocation:(TrackPoint *)trackPoint {
  if (parkAttractionLocations != nil) {
    attractionId = [self getRootAttractionId:attractionId];
    [parkAttractionLocations setObject:trackPoint forKey:attractionId];
  }
}

-(void)renameAttractionId:(NSString *)attractionId to:(NSString *)newAttractionId {
  if (parkAttractionLocations != nil) {
    attractionId = [self getRootAttractionId:attractionId];
    TrackPoint *trackPoint = [[parkAttractionLocations objectForKey:attractionId] retain];
    if (trackPoint != nil) {
      [parkAttractionLocations removeObjectForKey:attractionId];
      [parkAttractionLocations setObject:trackPoint forKey:newAttractionId];
      [trackPoint release];
    }
    int attractionIdx = [MenuData binarySearch:attractionId inside:allAttractionIds];
    if (attractionIdx < 0) {
      NSLog(@"attractionId %@ not found and could not be renamed to %@", attractionId, newAttractionId);
      return;
    }
    int newAttractionIdx = [MenuData binarySearch:newAttractionId inside:allAttractionIds];
    if (newAttractionIdx < 0) {
      newAttractionIdx = (int)[allAttractionIds count];
      [allAttractionIds addObject:newAttractionId];
      NSLog(@"create new attractionId %@ to replace %@.\nRELOAD REQUIRED! (all attractions are not ordered anymore)", newAttractionId, attractionId);
    }
    NSMutableArray *keysToRename = [[NSMutableArray alloc] initWithCapacity:20];
    [trackSegments enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
      TrackSegment *segment = object;
      if ([segment.from isEqualToString:attractionId] || [segment.to isEqualToString:attractionId]) [keysToRename addObject:key];
    }];
    for (TrackSegmentIdOrdered *segmentId in keysToRename) {
      short fromAttractionIdx = segmentId.fromIndex;
      short toAttractionIdx = segmentId.toIndex;
      TrackSegment *trackSegment = [trackSegments objectForKey:segmentId];
      NSString *fromAttractionId = trackSegment.from;
      NSString *toAttractionId = trackSegment.to;
      if ([fromAttractionId isEqualToString:attractionId]) fromAttractionId = newAttractionId;
      if (fromAttractionIdx == attractionIdx) fromAttractionIdx = newAttractionIdx;
      if ([toAttractionId isEqualToString:attractionId]) toAttractionId = newAttractionId;
      if (toAttractionIdx == attractionIdx) toAttractionIdx = newAttractionIdx;
      TrackSegment *newTrackSegment = [[TrackSegment alloc] initWithFromAttractionId:fromAttractionId toAttractionId:toAttractionId trackPoints:trackSegment.trackPoints isTrackToTourItem:trackSegment.isTrackToTourItem];
      [trackSegments removeObjectForKey:segmentId];
      [trackSegments setObject:newTrackSegment forKey:[TrackSegment getTrackSegmentId:fromAttractionIdx toAttractionIdx:toAttractionIdx]];
      [newTrackSegment release];
    }
    [keysToRename release];
  }
}

-(void)setAttractionLocation:(NSString *)attractionId latitude:(double)latitude longitude:(double)longitude {
  if (parkAttractionLocations != nil) {
    attractionId = [self getRootAttractionId:attractionId];
    TrackPoint *p = [[TrackPoint alloc] initWithLatitude:latitude longitude:longitude];
    [parkAttractionLocations setObject:p forKey:attractionId];
    [p release];
  }
}

-(void)changeAttractionLocation:(NSString *)attractionId latitudeDelta:(double)latitudeDelta longitudeDelta:(double)longitudeDelta {
  if (parkAttractionLocations != nil) {
    attractionId = [self getRootAttractionId:attractionId];
    TrackPoint *p = [parkAttractionLocations objectForKey:attractionId];
    if (p != nil) {
      [p addLatitude:latitudeDelta];
      [p addLongitude:longitudeDelta];
    }
  }
  /* same TrackPoint objects as used in parkAttractionLocations
  NSEnumerator *i = [trackSegments objectEnumerator];
  while (TRUE) {
    TrackSegment *segment = [i nextObject];
    if (segment == nil) break;
    if ([[segment fromAttractionId] isEqualToString:attractionId]) {
      TrackPoint *p = [segment fromTrackPoint];
      if (p != nil) {
        [p addLatitude:latitudeDelta];
        [p addLongitude:longitudeDelta];
      }
    }
    if ([[segment toAttractionId] isEqualToString:attractionId]) {
      TrackPoint *p = [segment toTrackPoint];
      if (p != nil) {
        [p addLatitude:latitudeDelta];
        [p addLongitude:longitudeDelta];
      }
    }
  }*/
}

-(void)removeAttractionLocation:(NSString *)attractionId {
  if (parkAttractionLocations != nil) {
    NSMutableArray *m = [[NSMutableArray alloc] initWithCapacity:[trackSegments count]];
    [trackSegments enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
      TrackSegmentIdOrdered *segmentId = key;
      TrackSegment *segment = object;
      if ([[segment fromAttractionId] isEqualToString:attractionId] || [[segment toAttractionId] isEqualToString:attractionId]) {
        [m addObject:segmentId];
      }
    }];
    [trackSegments removeObjectsForKeys:m];
    [parkAttractionLocations removeObjectForKey:attractionId];
    [m release];
  }
}

-(NSArray *)getPath:(int)fromIdx toAttractionIdx:(int)toIdx {
  NSString *fromAttractionId = [allAttractionIds objectAtIndex:fromIdx];
  NSString *toAttractionId = [allAttractionIds objectAtIndex:toIdx];
  NSString *fromId = fromAttractionId;
  NSString *toId = toAttractionId;
  fromAttractionId = [self getRootAttractionId:fromAttractionId];
  if (![self isExitAttractionId:fromAttractionId]) fromAttractionId = [self firstEntryAttractionIdOf:fromAttractionId];
  toAttractionId = [self getRootAttractionId:toAttractionId];
  if (![self isExitAttractionId:toAttractionId]) toAttractionId = [self firstEntryAttractionIdOf:toAttractionId];
  if ([fromAttractionId isEqualToString:toAttractionId]) return [NSArray arrayWithObjects:nil];
  if (fromId != fromAttractionId) fromIdx = [MenuData binarySearch:fromAttractionId inside:allAttractionIds];
  if (toId != toAttractionId) toIdx = [MenuData binarySearch:toAttractionId inside:allAttractionIds];
  if (fromIdx < 0 || toIdx < 0) {
    NSLog(@"Internal error: attractions %@ (%d) - %@ (%d) unknown", fromAttractionId, fromIdx, toAttractionId, toIdx);
    return nil;
  }
  NSMutableArray *m1 = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
  NSMutableArray *m2 = [[NSMutableArray alloc] initWithCapacity:10];
  while (TRUE) {
    int s1 = getShortestPathPos(nShortestPath, fromIdx, toIdx);
    int s0 = shortestPath[s1];
    if (s0 < 0) break;
    fromAttractionId = [allAttractionIds objectAtIndex:s0];
    NSString *t = [self getRootAttractionId:fromAttractionId];
    if (fromAttractionId != t) {
      fromAttractionId = t;
      s0 = [MenuData binarySearch:fromAttractionId inside:allAttractionIds];
    }
    s1 = shortestPath[s1+1];
    if (s1 < 0) {
      [m1 addObject:[NSNumber numberWithInt:s0]];
      break;
    }
    toAttractionId = [allAttractionIds objectAtIndex:s1];
    t = [self getRootAttractionId:toAttractionId];
    if (toAttractionId != t) {
      toAttractionId = t;
      s1 = [MenuData binarySearch:toAttractionId inside:allAttractionIds];
    }
    if (fromIdx >= toIdx) {
      fromIdx = s1;
      toIdx = s0;
    } else {
      fromIdx = s0;
      toIdx = s1;
    }
    [m1 addObject:[NSNumber numberWithInt:fromIdx]];
    [m2 addObject:[NSNumber numberWithInt:toIdx]];
  }
  int l = m2.count;
  while (--l >= 0) [m1 addObject:[m2 objectAtIndex:l]];
  [m2 release];
  return m1;
}

-(BOOL)isPathInverse:(NSString *)fromAttractionId toAttractionId:(NSString *)toAttractionId {
  fromAttractionId = [self getRootAttractionId:fromAttractionId];
  toAttractionId = [self getRootAttractionId:toAttractionId];
  return ([fromAttractionId compare:toAttractionId] != NSOrderedAscending)? YES : NO;
}

/*-(BOOL)isSegementId:(TrackSegmentId *)segmentId startingWith:(NSString *)attractionId {
  attractionId = [self getRootAttractionId:attractionId];
  return [segmentId.from isEqualToString:attractionId];
  //return [segmentId hasPrefix:[attractionId stringByAppendingString:@" "]];
}*/

+(NSArray *)reversePath:(NSArray *)array {
  int l = array.count;
  if (l <= 1) return array;
  NSMutableArray *m = [[[NSMutableArray alloc] initWithCapacity:l] autorelease];
  while (--l >= 0) [m addObject:[array objectAtIndex:l]];
  return m;
}

-(NSArray *)getMinPathFrom:(NSString *)fromAttractionId fromAll:(BOOL)fromAll toAllAttractionId:(NSString *)toAttractionId {
  fromAttractionId = [self getRootAttractionId:fromAttractionId];
  toAttractionId = [self getRootAttractionId:toAttractionId];
  NSString *eId = [self exitAttractionIdOf:fromAttractionId];
  if ([eId isEqualToString:toAttractionId]) return [NSArray arrayWithObjects:fromAttractionId, toAttractionId, nil];
  if ([self isExitAttractionId:fromAttractionId] && [self isEntryExitSame:fromAttractionId]) fromAttractionId = [self getEntryAttractionId:fromAttractionId];
  NSArray *path = nil;
  [self distance:fromAttractionId fromAll:fromAll toAttractionId:toAttractionId toAll:YES path:&path];
  if (path != nil) {
    int l = path.count;
    if (l > 0) {
      NSMutableArray *pathIds = [[[NSMutableArray alloc] initWithCapacity:l] autorelease];
      if (l == 1) {
        [pathIds addObject:[allAttractionIds objectAtIndex:[[path objectAtIndex:0] intValue]]];
      } else {
        BOOL reverse = NO;
        NSString *fId = [Attraction getShortAttractionId:fromAttractionId];
        if (![fId isEqualToString:[Attraction getShortAttractionId:[allAttractionIds objectAtIndex:[[path objectAtIndex:0] intValue]]]]) reverse = YES;
        else {
          NSString *tId = [Attraction getShortAttractionId:toAttractionId];
          if ([fId isEqualToString:tId] && [tId isEqualToString:[Attraction getShortAttractionId:[allAttractionIds objectAtIndex:[[path lastObject] intValue]]]]) {
            if ([self isExitAttractionId:fromAttractionId] ^ [self isExitAttractionId:[allAttractionIds objectAtIndex:[[path objectAtIndex:0] intValue]]]) reverse = YES;
          }
        }
        if (reverse) while (--l >= 0) [pathIds addObject:[allAttractionIds objectAtIndex:[[path objectAtIndex:l] intValue]]];
        else for (NSNumber *idx in path) [pathIds addObject:[allAttractionIds objectAtIndex:[idx intValue]]];
      }
      path = pathIds;
    }
  }
  return path;
}

-(TrackSegment *)getTrackSegment:(NSString *)fromAttractionId toAttractionId:(NSString *)toAttractionId {
  fromAttractionId = [self getRootAttractionId:fromAttractionId];
  int fromAttractionIdx = [MenuData binarySearch:fromAttractionId inside:allAttractionIds];
  if (fromAttractionIdx < 0) {
    NSLog(@"Internal error: attraction %@ unknown", fromAttractionId);
    fromAttractionIdx = -1;
  }
  toAttractionId = [self getRootAttractionId:toAttractionId];
  int toAttractionIdx = [MenuData binarySearch:toAttractionId inside:allAttractionIds];
  if (toAttractionIdx < 0) {
    NSLog(@"Internal error: attraction %@ unknown", toAttractionId);
    toAttractionIdx = -1;
  }
  return [trackSegments objectForKey:[TrackSegment getTrackSegmentId:fromAttractionIdx toAttractionIdx:toAttractionIdx]];
}

-(double)currentDistanceToAll:(NSString *)toAttractionId tolerance:(double *)tolerance fromAttractionId:(NSString **)fromAttractionId {
  toAttractionId = [self getRootAttractionId:toAttractionId];
  NSString *fAttractionId = nil;
  TrackPoint *currentLocation = nil;
  if ([LocationData isLocationDataActive]) {
    LocationData *location = [LocationData getLocationData];
    CLLocation *loc = location.lastUpdatedLocation;
    currentLocation = (loc == nil)? nil : [[TrackPoint alloc] initWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude];
    if (![self isInsidePark:currentLocation]) {
      //NSLog(@"Current location is not inside the park");
      fAttractionId = [[self getEntryOfPark:currentLocation] retain];
      TrackPoint *t = [self getAttractionLocation:fAttractionId];
      [currentLocation release];
      currentLocation = [t retain];
    }
  } else {
    fAttractionId = [[self getEntryOfPark:nil] retain];
    currentLocation = [[self getAttractionLocation:fAttractionId] retain];
  }
  double w = -1.0;
  *tolerance = 0.0;
  /*if (ABS(currentLocation.latitude-48.2703972) < 0.0000002 && ABS(currentLocation.longitude-7.7270409) < 0.0000002) {
    TrackSegment *ts = [trackSegments objectForKey:[TrackSegment getTrackSegmentId:@"000" toAttractionId:@"001"]];
    TrackPoint *t = [[TrackPoint alloc] initWithLatitude:48.2703972 longitude:7.7270409];
    BOOL b = [ts closestDistanceForTrackPoint:t checkEvenIsNotInside:YES closestDistance:&w];
    NSLog(@"TRACK: %d  %f", b, w);
    w = -1.0;
    [ts closestDistanceForTrackPoint:t checkEvenIsNotInside:NO closestDistance:&w];
    [t release];
  }*/
  static double distanceToFromLocationId = 0.0;
  @synchronized([ParkData class]) {
    static TrackPoint *lastTrackPoint = nil;
    static NSString *lastFromLocationId = nil;
    static TrackSegment *lastClosestSegment = nil;
    // check if current loction is same as last location
    if (lastTrackPoint != nil && [lastTrackPoint isEqual:currentLocation]) {
      //closestSegement = lastClosestSegment;
      w = distanceToFromLocationId;
      fAttractionId = [lastFromLocationId retain];
    } else {
      [lastTrackPoint release];
      lastTrackPoint = [currentLocation retain];
      TrackSegment *closestSegement = nil;
      // check if current loction is inside last identified segment
      if (lastClosestSegment != nil) {
        if ([lastClosestSegment closestDistanceForTrackPoint:currentLocation checkEvenIsNotInside:NO closestDistance:&w] && w >= 0.0) closestSegement = lastClosestSegment;
      }
      // find track segment containing current location
      if (closestSegement == nil) closestSegement = [self closestTrackSegmentForTrackPoint:currentLocation];
      if (closestSegement != nil) {
        if (lastClosestSegment != closestSegement) {
          [lastClosestSegment release];
          lastClosestSegment = [closestSegement retain];
        }
        [fAttractionId release];
        if ([closestSegement fromAttractionIdEqualToTrackPoint:currentLocation]) {
          fAttractionId = [[closestSegement fromAttractionId] retain];
          w = 0.0;
        } else if ([closestSegement toAttractionIdEqualToTrackPoint:currentLocation]) {
          fAttractionId = [[closestSegement toAttractionId] retain];
          w = 0.0;
        } else {
          NSArray *path = [self getMinPathFrom:[closestSegement fromAttractionId] fromAll:YES toAllAttractionId:toAttractionId];
          if ([path containsObject:[closestSegement toAttractionId]]) {
            fAttractionId = [[closestSegement toAttractionId] retain];
            w = [closestSegement distanceFromTrackPoint:currentLocation toAttractionId:fAttractionId];
          } else {
            fAttractionId = [[closestSegement fromAttractionId] retain];
            w = [closestSegement distanceFromTrackPoint:currentLocation toAttractionId:fAttractionId];
          }
        }
      }
      // find closest attraction point (also internal)
      if (fAttractionId == nil) fAttractionId = [[self closestLocationIdEstimateForTrackPoint:currentLocation distance:&w] retain];
      [lastFromLocationId release];
      lastFromLocationId = [fAttractionId retain];
      distanceToFromLocationId = w;
    }
  }
  w += [self distance:fAttractionId fromAll:NO toAttractionId:toAttractionId toAll:YES path:nil];
  // deadlock might occur if getAttraction is inside synchronized block (e.g. getAttraction vs getParkData)
  if (fAttractionId != nil && (distanceToFromLocationId >= 10.0 || [Attraction isInternalId:fAttractionId] || [Attraction getAttraction:parkId attractionId:[Attraction getShortAttractionId:fAttractionId]] == nil)) {
    [fAttractionId release];
    fAttractionId = nil;
  }
  if (fAttractionId != nil) {
    *fromAttractionId = [NSString stringWithString:fAttractionId];
    [fAttractionId release];
  } else *fromAttractionId = nil;
  [currentLocation release];
  return w;
}

-(double)distance:(NSString *)fromAttractionId fromAll:(BOOL)fromAll toAttractionId:(NSString *)toAttractionId toAll:(BOOL)toAll path:(NSArray **)minPath {
  fromAttractionId = [self getRootAttractionId:fromAttractionId];
  toAttractionId = [self getRootAttractionId:toAttractionId];
  BOOL fromUnique = [self isEntryUnique:fromAttractionId];
  if (fromUnique && [self isExitAttractionId:fromAttractionId]) fromAll = NO;
  else if (!fromAll && !fromUnique) fromAll = YES;
  if (fromAll) fromAttractionId = [Attraction getShortAttractionId:fromAttractionId];
  BOOL toUnique = [self isEntryUnique:toAttractionId];
  if (!toAll && !toUnique) toAll = YES;
  if (toAll) toAttractionId = [Attraction getShortAttractionId:toAttractionId];
  if ([fromAttractionId isEqualToString:toAttractionId] || (!fromAll && toAll && [toAttractionId isEqualToString:[Attraction getShortAttractionId:fromAttractionId]])) return 0.0;
  // Attention on attractions with mutliple entrances!
  int fromAttractionIdx = [MenuData binarySearch:fromAttractionId inside:allAttractionIds];
  if (fromAttractionIdx < 0 && !fromAll) return 0.0;
  int toAttractionIdx = [MenuData binarySearch:toAttractionId inside:allAttractionIds];
  if (toAttractionIdx < 0 && !toAll) return 0.0;
  NSArray *fAttractionIds = (fromAll)? [self allLocationIdxOf:fromAttractionId attractionIdx:fromAttractionIdx] : [NSArray arrayWithObject:[NSNumber numberWithInt:fromAttractionIdx]];
  NSArray *tAttractionIds = (toAll)? [self allLocationIdxOf:toAttractionId attractionIdx:toAttractionIdx] : [NSArray arrayWithObject:[NSNumber numberWithInt:toAttractionIdx]];
  [fAttractionIds retain];
  [tAttractionIds retain];
  //TrackSegmentId *minSegmentId = nil;
  double minDistance = 0.0;
  NSMutableArray *mPath = [[[NSMutableArray alloc] initWithCapacity:10] autorelease];
  for (NSNumber *fAttractionIdx in fAttractionIds) {
    NSString *fAttractionId = [allAttractionIds objectAtIndex:[fAttractionIdx intValue]];
    for (NSNumber *tAttractionIdx in tAttractionIds) {
      NSString *tAttractionId = [allAttractionIds objectAtIndex:[tAttractionIdx intValue]];
      int aIdx = [fAttractionIdx intValue];
      NSArray *path = [self getPath:aIdx toAttractionIdx:[tAttractionIdx intValue]];
      if (path == nil) {
        [fAttractionIds release];
        [tAttractionIds release];
        NSLog(@"Error! Missing path between %@ and %@", fAttractionId, tAttractionId);
        return 0.0;
      }
      double d = 0.0;
      NSString *aId = fAttractionId;
      TrackPoint *lastTrackPoint = nil;
      for (NSNumber *nIdx in path) {
        int bIdx = [nIdx intValue];
        NSString *bId = [allAttractionIds objectAtIndex:bIdx];
        TrackSegment *t = [trackSegments objectForKey:[TrackSegment getTrackSegmentId:aIdx toAttractionIdx:bIdx]];
        if (t != nil) {
          d += t.distance;
          if (lastTrackPoint != nil && ![lastTrackPoint isEqual:[t trackPointOf:aId]]) {
            d += [TrackPoint distanceFrom:lastTrackPoint to:[t trackPointOf:aId]];
            NSLog(@"Warning! %@ has different track points", aId);
          }
          lastTrackPoint = [t trackPointOf:bId];
        } else if (aIdx != bIdx) {
          NSLog(@"Error! Missing track segment between %@ and %@ of path from %@ to %@ (path: %@)", aId, bId, fAttractionId, tAttractionId, path);
        }
        aId = bId;
        aIdx = bIdx;
      }
      TrackSegment *t = [trackSegments objectForKey:[TrackSegment getTrackSegmentId:aIdx toAttractionIdx:[tAttractionIdx intValue]]];
      if (t != nil) {
        d += t.distance;
        if (lastTrackPoint != nil && ![lastTrackPoint isEqual:[t trackPointOf:aId]]) {
          d += [TrackPoint distanceFrom:lastTrackPoint to:[t trackPointOf:aId]];
          NSLog(@"Warning! %@ has different track points", aId);
        }
      } else if (aIdx != [tAttractionIdx intValue]) {
        NSLog(@"Error! Missing track segment between %@ and %@ of path from %@ to %@ (path: %@)", aId, tAttractionId, fAttractionId, tAttractionId, path);
      }
      if (minDistance == 0.0 || minDistance > d) {
        minDistance = d;
        //minSegmentId = [TrackSegment getTrackSegmentId:[fAttractionIdx intValue] toAttractionIdx:[tAttractionIdx intValue]];
        if (minPath != nil) {
          [mPath removeAllObjects];
          [mPath addObject:fAttractionIdx];
          for (NSNumber *bIdx in path) [mPath addObject:bIdx];
          [mPath addObject:tAttractionIdx];
        }
      }
    }
  }
  [fAttractionIds release];
  [tAttractionIds release];
  if (minPath != nil) *minPath = mPath;
  return minDistance;
}

-(NSSet *)allConnectedAttractionIds:(NSString *)attractionId {
  NSMutableSet *connections = [[[NSMutableSet alloc] initWithCapacity:5] autorelease];
  NSEnumerator *i = [trackSegments objectEnumerator];
  while (TRUE) {
    TrackSegment *segment = [i nextObject];
    if (segment == nil) break;
    if ([segment.from isEqualToString:attractionId]) {
      if (![segment.to isEqualToString:attractionId]) [connections addObject:segment.to];
    } else if ([segment.to isEqualToString:attractionId]) {
      if (![segment.from isEqualToString:attractionId]) [connections addObject:segment.from];
    }
  }
  return connections;
}

-(NSSet *)connectedAttractionIds:(NSString *)attractionId {
  // no internal attraction ID will be returned
  NSMutableSet *allConnections = [[NSMutableSet alloc] initWithCapacity:20];
  NSMutableSet *connections = [[[NSMutableSet alloc] initWithCapacity:10] autorelease];
  NSMutableSet *internalConnections = [[NSMutableSet alloc] initWithCapacity:5];
  [internalConnections addObject:attractionId];
  [allConnections addObject:attractionId];
  do {
    attractionId = [internalConnections anyObject];
    NSMutableSet *directConnections = [[NSMutableSet alloc] initWithSet:[self allConnectedAttractionIds:attractionId]];
    [directConnections minusSet:allConnections];
    [allConnections unionSet:directConnections];
    for (NSString *aId in directConnections) {
      if ([Attraction getAttraction:parkId attractionId:[Attraction getShortAttractionId:aId]] == nil) [internalConnections addObject:aId];
      else [connections addObject:aId];
    }
    [internalConnections removeObject:attractionId];
    [directConnections release];
  } while ([internalConnections count] > 0);
  [internalConnections release];
  [allConnections release];
  return connections;
}

-(NSString *)closestAttractionId:(NSString *)attractionId distance:(double *)distance {
  // no internal attraction ID will be returned
  NSSet *connectedAttractionIds = [self connectedAttractionIds:attractionId];
  NSString *closestAttractionId = nil;
  double d = 0.0;
  for (NSString *aId in connectedAttractionIds) {
    double m = [self distance:attractionId fromAll:NO toAttractionId:aId toAll:NO path:nil];
    if (d == 0.0 || m < d) {
      d = m;
      closestAttractionId = aId;
    }
  }
  *distance = d;
  return closestAttractionId;
}

-(NSString *)closestLocationIdEstimateForTrackPoint:(TrackPoint *)trackPoint distance:(double *)distance {
  // checking only the the coordinates of the attractions
  __block NSString *closestAttractionId = nil;
  __block double d = 0.0;
  const double latitude = trackPoint.latitude;
  const double longitude = trackPoint.longitude;
  [parkAttractionLocations enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    TrackPoint *t = object;
    double lat = t.latitude-latitude;
    double lon = t.longitude-longitude;
    double m = lat*lat + lon*lon;
    if (d == 0.0 || m < d) {
      d = m;
      closestAttractionId = key;
    }
  }];
  if (closestAttractionId != nil) {
    *distance = [trackPoint distanceTo:[parkAttractionLocations objectForKey:closestAttractionId]];
  } else {
    *distance = 0.0;
  }
  return closestAttractionId;
}

-(NSString *)closestAttractionIdEstimateForTrackPoint:(TrackPoint *)trackPoint distance:(double *)distance {
  // checking only the the coordinates of the attractions
  __block NSString *closestAttractionId = nil;
  __block double d = 0.0;
  const double latitude = trackPoint.latitude;
  const double longitude = trackPoint.longitude;
  [parkAttractionLocations enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    if (![Attraction isInternalId:key]) {
      TrackPoint *t = object;
      double lat = t.latitude-latitude;
      double lon = t.longitude-longitude;
      double m = lat*lat + lon*lon;
      if ((d == 0.0 || m < d) && [Attraction getAttraction:parkId attractionId:[Attraction getShortAttractionId:key]] != nil) {
        d = m;
        closestAttractionId = key;
      }
    }
  }];
  if (closestAttractionId != nil) {
    *distance = [trackPoint distanceTo:[parkAttractionLocations objectForKey:closestAttractionId]];
  } else {
    *distance = 0.0;
  }
  return closestAttractionId;
}

-(TrackSegment *)closestTrackSegmentForTrackPoint:(TrackPoint *)trackPoint {
  if (![self isInsidePark:trackPoint]) return nil;
  double w = -1.0;
  TrackSegment *closestSegement = nil;
  NSEnumerator *i = [trackSegments objectEnumerator];
  while (TRUE) {
    TrackSegment *segment = [i nextObject];
    if (!segment) break;
    if ([segment closestDistanceForTrackPoint:trackPoint checkEvenIsNotInside:NO closestDistance:&w]) {
      closestSegement = segment;
      if (w == 0.0) break;
    }
  }
  return closestSegement;
}

/*-(NSString *)closestAttractionIdForTrackPoint:(TrackPoint *)trackPoint {
  // more accurate implementation: search all TrackSegments, but internal attractionsIds must be continued
  if (![self isInsidePark:trackPoint]) return [self getEntryOfPark:trackPoint];
  double w = -1.0;
  TrackSegment *closestSegement = nil;
  NSArray *allSegements = [trackSegments allValues];
  for (TrackSegment *segment in allSegements) {
    if ([segment closestDistanceForTrackPoint:trackPoint closestDistance:&w]) {
      closestSegement = segment;
      if (w == 0.0) break;
    }
  }
  if (closestSegement == nil) return [self closestAttractionIdEstimateForTrackPoint:trackPoint distance:&w];
  double distance,tolerance;
  NSString *attractionId = [closestSegement closestAttractionIdForTrackPoint:trackPoint distance:&distance tolerance:&tolerance];
  if ([Attraction getAttraction:parkId attractionId:[Attraction getShortAttractionId:attractionId]] != nil) return attractionId;
  return [self closestAttractionId:attractionId distance:&w]; // ToDo: might be not accurate enough, correct would be to call it for both ids of the segment
}*/

-(MKCoordinateRegion)getParkRegion {
  if (parkRegion.center.latitude != 0.0) return parkRegion;
  MKCoordinateRegion r;
  r.center.latitude = 0.0;
  r.center.longitude = 0.0;
  r.span.latitudeDelta = 0.0;
  r.span.longitudeDelta = 0.0;
  if (parkAttractionLocations != nil) {
    int minLat = 0;
    int maxLat = 0;
    int minLon = 0;
    int maxLon = 0;
    NSEnumerator *i = [parkAttractionLocations objectEnumerator];
    while (TRUE) {
      TrackPoint *p = [i nextObject];
      if (p == nil) break;
      int d = p.latitudeInt;
      if (minLat == 0) minLat = maxLat = d;
      else if (d < minLat) minLat = d;
      else if (d > maxLat) maxLat = d;
      d = p.longitudeInt;
      if (minLon == 0) minLon = maxLon = d;
      else if (d < minLon) minLon = d;
      else if (d > maxLon) maxLon = d;
    }
    minLat -= 1000; minLon -= 1000; // about 250m
    maxLat += 1000; maxLon += 1000; // about 250m
    r.center.latitude = (minLat+maxLat)/2000000.0;
    r.center.longitude = (minLon+maxLon)/2000000.0;
    r.span.latitudeDelta = (maxLat-minLat)/1000000.0;
    r.span.longitudeDelta = (maxLon-minLon)/1000000.0;
#if TARGET_IPHONE_SIMULATOR
#ifdef DEBUG_MAP
    NSLog(@"// %@\nscrollFromRegion.center.latitude = %.6f;\nscrollFromRegion.center.longitude = %.6f;\nscrollToRegion.center.latitude = %.6f;\nscrollToRegion.center.longitude = %.6f;", parkId, maxLat/1000000.0, minLon/1000000.0, minLat/1000000.0, maxLon/1000000.0);
#else
    NSLog(@"park region: lat (%.6f - %.6f), lon (%.6f - %.6f)", minLat/1000000.0, maxLat/1000000.0, minLon/1000000.0, maxLon/1000000.0);
#endif
#endif
  }
  parkRegion = r;
  return r;
}

-(BOOL)isInsidePark:(TrackPoint *)trackPoint {
  MKCoordinateRegion region = [self getParkRegion];
  return (trackPoint.latitude >= region.center.latitude-2*region.span.latitudeDelta && trackPoint.latitude <= region.center.latitude+2*region.span.latitudeDelta && trackPoint.longitude >= region.center.longitude-2*region.span.longitudeDelta && trackPoint.longitude <= region.center.longitude+2*region.span.longitudeDelta);
}

-(BOOL)isCurrentlyInsidePark {
  if (![LocationData isLocationDataActive]) return NO;
  LocationData *locData = [LocationData getLocationData];
  if (locData.lastUpdatedLocation == nil) return NO;
  CLLocationCoordinate2D loc = locData.lastUpdatedLocation.coordinate;
  TrackPoint *t = [[TrackPoint alloc] initWithLatitude:loc.latitude longitude:loc.longitude];
  ParkData *parkData = [ParkData getParkData:parkId];
  BOOL isInside = [parkData isInsidePark:t];
  [t release];
  return isInside;
}

-(NSArray *)getTrainAttractionRoute:(NSString *)attractionId oneWay:(BOOL *)oneWay {
  *oneWay = YES;
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  if (attraction == nil || attraction.nextStationId == nil) return nil;
  Attraction *beginning = attraction;
  __block NSString *aId = attractionId;
  NSMutableArray *route = [[[NSMutableArray alloc] initWithCapacity:7] autorelease];
  while (![attractionId isEqualToString:attraction.nextStationId]) {
    attraction = [Attraction getAttraction:parkId attractionId:attraction.nextStationId];
    if (attraction.nextStationId == nil) {
      NSLog(@"Train route of %@ is not closed!", attractionId);
      break;
    }
    if ([route count] == 0 && [attractionId isEqualToString:attraction.nextStationId]) {
      NSDictionary *allAttractions = [Attraction getAllAttractions:parkId reload:NO];
      [allAttractions enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        Attraction *a = object;
        if ([a isTrain] && ((![attraction.attractionId isEqualToString:a.attractionId] && [attractionId isEqualToString:a.nextStationId]) || (![attractionId isEqualToString:a.attractionId] && [attraction.attractionId isEqualToString:a.nextStationId]))) {
          [route addObject:attraction];
          aId = attraction.attractionId;
          *stop = YES;
        }
      }];
    }
    if ([route containsObject:attraction]) { // same stations back
      *oneWay = NO;
      __block Attraction *previousStation = nil;
      NSDictionary *allAttractions = [Attraction getAllAttractions:parkId reload:NO];
      if (![route containsObject:beginning]) [route addObject:beginning];
      int l = [route count];
      for (int i = 0; i < l; ++i) {
        attraction = [route objectAtIndex:i];
        aId = attraction.attractionId;
        do {
          previousStation = nil;
          [allAttractions enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
            Attraction *a = object;
            if ([a isTrain] && [aId isEqualToString:a.nextStationId] && ![route containsObject:a]) {
              [route addObject:a];
              previousStation = a;
              aId = key;
              *stop = YES;
            }
          }];
        } while (previousStation != nil);
      }
      return route;
    }
    [route addObject:attraction];
  }
  [route addObject:beginning];
  return route;
}

-(NSArray *)getNextTrainStationAttractions:(Attraction *)attraction {
  NSString *nextStationId = attraction.nextStationId;
  if (nextStationId == nil) return nil;
  BOOL oneWay;
  NSString *aId = attraction.attractionId;
  NSArray *route = [self getTrainAttractionRoute:aId oneWay:&oneWay];
  if (oneWay) return [NSArray arrayWithObject:[Attraction getAttraction:parkId attractionId:nextStationId]];
  NSMutableArray *nextStations = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];
  [nextStations addObject:[Attraction getAttraction:parkId attractionId:nextStationId]];
  for (Attraction *a in route) {
    if ([aId isEqualToString:a.nextStationId] && ![nextStationId isEqualToString:a.attractionId]) {
      [nextStations addObject:[Attraction getAttraction:parkId attractionId:a.attractionId]];
      break;
    }
  }
  return nextStations;
}

-(int)getTrainAttractionDurationFrom:(NSString *)fromAttractionId to:(NSString *)toAttractionId {
  // ToDo: is not always correct if not one way; then the shortest duration/path should be used
  BOOL oneWay;
  NSArray *route = [self getTrainAttractionRoute:fromAttractionId oneWay:&oneWay];
  if (route == nil) return 0;
  Attraction *attraction = [route lastObject];
  int duration = attraction.duration;
  int numberOfWaitingStations = 0;
  for (attraction in route) {
    if ([attraction.attractionId isEqualToString:toAttractionId]) break;
    duration += attraction.duration;
    ++numberOfWaitingStations;
  }
  return duration+numberOfWaitingStations;
}

-(NSString *)writeGPX:(NSString *)name {
  NSDateFormatter *gpxTimeFormat = [[NSDateFormatter alloc] init];
  [gpxTimeFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
  //static DateFormat gpxTimeFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
  NSMutableString *content = [[NSMutableString alloc] initWithCapacity:10000];
  [content appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"];
  [content appendString:@"<gpx xmlns=\"http://www.topografix.com/GPX/1/1\" creator=\"InPark\" version=\"1.1\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n"];
  [content appendFormat:@"<trk>\n  <name>%@</name>\n", name];
  NSEnumerator *i = [trackSegments objectEnumerator];
  while (TRUE) {
    TrackSegment *segment = [i nextObject];
    if (!segment) break;
    [content appendString:[segment toString:gpxTimeFormat comment:nil]];
    [content appendString:@"\n"];
  }
  [content appendString:@"</trk>\n"];
  // Way points
  [parkAttractionLocations enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSString *attractionId = key;
    TrackPoint *p = object;
    NSString *rootAttractionId = [self getRootAttractionId:attractionId];
    NSString *aIds = [rootAttractionId isEqualToString:attractionId]? attractionId : [NSString stringWithFormat:@"%@=%@", rootAttractionId, attractionId];
    [content appendFormat:@"  <wpt lat=\"%.6f\" lon=\"%.6f\">\n    <name>%@</name>\n    <ele>0.0</ele>\n    <time></time>\n    <sym>Dot</sym>\n  </wpt>\n", p.latitude, p.longitude, aIds];
  }];
  [content appendString:@"</gpx>"];
  NSString *fileName = [NSString stringWithFormat:@"%@/%@.gpx", [MenuData documentPath], name];
  [content writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
  [gpxTimeFormat release];
  [content release];
  return fileName;
}

static const char* stringValue(const char *source, char *target, int MAX_CSTRING) {
  int i = 0;
  do {
    char c = *source;
    if (!c) break;
    if (c == ';' || c == '[' || c == '{' || c == '}' || c == '=' || c == '\n') break;
    target[i] = c;
    ++source;
  } while (++i < MAX_CSTRING);
  target[i] = '\x0';
  return source;
}

static const char* longValue(const char *source, long *value) {
  long x = 0;
  BOOL neg = FALSE;
  if (*source == '-') {
    ++source;
    neg = TRUE;
  }
  while (TRUE) {
    char c = *source;
    if (c >= '0' && c <= '9') {
      x *= 10; x += (int)(c - '0');
    } else {
      *value = (neg)? -x : x;
      return source;
    }
    ++source;
  }
}

static const char* int4Values(const char *source, int radix, int *value) {
  int64_t x = 0;
  while (TRUE) {
    char c = *source;
    if (isdigit(c)) {
      x *= 10; x += (int)(c - '0');
    } else break;
    ++source;
  }
  value[3] = x%radix; x /= radix;
  value[2] = x%radix; x /= radix;
  value[1] = x%radix; x /= radix;
  value[0] = x%radix;
  return source;
}

static const char* doubleValue(const char *source, double *value) {
  double x = 0.0;
  double comma = 0.0;
  BOOL neg = FALSE;
  if (*source == '-') {
    ++source;
    neg = TRUE;
  }
  while (TRUE) {
    char c = *source;
    if (c >= '0' && c <= '9') {
      if (comma == 0.0) {
        x *= 10; x += (int)(c - '0');
      } else {
        comma /= 10;
        x += comma * (int)(c - '0');
      }
    } else if (c == '.' && comma == 0.0) {
      comma = 1.0;
    } else {
      *value = (neg)? -x : x;
      return source;
    }
    ++source;
  }
}

-(BOOL)readGPSData {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *filePath = [[MenuData parkDataPath:parkId] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", parkId]];
  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    FILE *pFile = fopen([filePath UTF8String], "r");
    if (pFile == NULL) {
      NSLog(@"File error %@", filePath);
      return NO;
    }
    // obtain file size:
    fseek(pFile, 0, SEEK_END);
    long lSize = ftell(pFile);
    rewind(pFile);
    char *data = malloc(sizeof(char)*(lSize+1));
    if (data == NULL) {
      NSLog(@"Memory error");
      fclose(pFile);
      [pool release];
      return NO;
    }
    // copy the file into the buffer:
    size_t result = fread(data, 1, lSize, pFile);
    fclose(pFile);
    if (result != lSize) {
      NSLog(@"Reading error");
      free(data);
      [pool release];
      return NO;
    }
    data[lSize] = '\x0';
    const char *s = data;
    const int MAX_CSTRING = 1500;
    char tmp[MAX_CSTRING+1];
    NSLog(@"Read GPS data %@", filePath);
    [allRelatedAttractionIds release];
    allRelatedAttractionIds = [[NSMutableDictionary alloc] initWithCapacity:400];
    [allAttractionIds release];
    allAttractionIds = [[NSMutableArray alloc] initWithCapacity:600];
    [parkAttractionLocations release];
    parkAttractionLocations = [[NSMutableDictionary alloc] initWithCapacity:400];
    [trackSegments release];
    trackSegments = [[NSMutableDictionary alloc] initWithCapacity:700];
    //[distances release];
    //distances = [[NSMutableDictionary alloc] initWithCapacity:100];
    [sameAttractionIds release];
    sameAttractionIds = [[NSMutableDictionary alloc] initWithCapacity:20];
    // ToDo: auslagern von Prefix of lon/lat, z.B. 48.28 - 7.72
        
    // Attraction locations
    while (*s != '\n') {
      double lat,lon;
      s = stringValue(s, tmp, MAX_CSTRING);
      if (*s != ';') NSLog(@"Separator character ';' missing!");
      [allAttractionIds addObject:[NSString stringWithUTF8String:tmp]];
      s = doubleValue(s+1, &lat);
      if (*s != ';') NSLog(@"Separator character ';' missing!");
      s = doubleValue(s+1, &lon);
      TrackPoint *t = [[TrackPoint alloc] initWithLatitude:lat longitude:lon];
      if (*s == ',') NSLog(@"ERROR: Multiple locations for attractions (%s) not supported anymore!", tmp);
      [parkAttractionLocations setObject:t forKey:[NSString stringWithUTF8String:tmp]];
      [t release];
      if (*s != ';') NSLog(@"End character ';' missing!");
      ++s;
    }
#ifdef DEBUG_MAP
    // check if all attractions IDs are ordered
    NSString *previousAttractionId = nil;
    for (NSString *attractionId in allAttractionIds) {
      if (previousAttractionId != nil && [previousAttractionId compare:attractionId] == NSOrderedDescending) {
        NSLog(@"ERROR: all attraction IDs are not in correct order: %@ - %@", previousAttractionId, attractionId);
      }
      previousAttractionId = attractionId;
    }
#endif
    // Segments
    int radix = (int)[allAttractionIds count];
    if (shortestPath != NULL) {
      free(shortestPath);
      shortestPath = NULL;
    }
    shortestPath = malloc(sizeof(short)*radix*(radix-1));
    if (shortestPath == NULL) {
      NSLog(@"Memory error");
      fclose(pFile);
      free(data);
      [pool release];
      return NO;
    }
    while (*++s != '\n') {
      long pathIdx;
      s = longValue(s, &pathIdx);
      NSString *fromId = [allAttractionIds objectAtIndex:pathIdx%radix];
      NSString *toId = [allAttractionIds objectAtIndex:pathIdx/radix];
      TrackPoint *p = [parkAttractionLocations objectForKey:fromId];
      NSMutableArray *trackPoints = [[NSMutableArray alloc] initWithCapacity:5];
      [trackPoints addObject:p];
      while (*s == ';') {
        double lat,lon;
        s = doubleValue(s+1, &lat);
        if (*s != ';') NSLog(@"Separator character ';' missing!");
        s = doubleValue(s+1, &lon);
        TrackPoint *t = [[TrackPoint alloc] initWithLatitude:lat longitude:lon];
        [trackPoints addObject:t];
        [t release];
      }
      p = [parkAttractionLocations objectForKey:toId];
      [trackPoints addObject:p];
      /*if (![fromId isEqualToString:[self getRootAttractionId:fromId]]) {
        NSLog(@"ERROR: Segment from %@ to %@  is using %@ and not root ID %@", fromId, toId, fromId, [self getRootAttractionId:fromId]);
      }
      if (![toId isEqualToString:[self getRootAttractionId:toId]]) {
        NSLog(@"ERROR: Segment from %@ to %@  is using %@ and not root ID %@", fromId, toId, toId, [self getRootAttractionId:toId]);
      }*/
      TrackSegment *segment = [[TrackSegment alloc] initWithFromAttractionId:fromId toAttractionId:toId trackPoints:trackPoints isTrackToTourItem:NO];
      TrackSegmentIdOrdered *segmentId = [[TrackSegmentIdOrdered alloc] initWithFromIndex:pathIdx%radix toIndex:pathIdx/radix];
      [trackSegments setObject:segment forKey:segmentId];
      [trackPoints release];
      [segment release];
      [segmentId release];
    }
    // Shortest path
    long pathIdx;
    //int i = 0;
    //int j = 0;
    int k = 0;
    do {
      s = longValue(s+1, &pathIdx);
      //if (++j == radix) j = (++i) + 1;
      if (pathIdx <= 0) {
        shortestPath[k] = -1;
        shortestPath[k+1] = -1;
      } else {
        int fromIdx = (pathIdx-1)%radix;
        if (pathIdx > radix) {
          int toIdx = (int)(pathIdx-1)/radix - 1;
          shortestPath[k] = fromIdx;
          shortestPath[k+1] = toIdx;
        } else {
          shortestPath[k] = fromIdx;
          shortestPath[k+1] = -1;
        }
      }
      k += 2;
    } while (s[1] != '\n');
    nShortestPath = radix;
    s += 2;
    if (*s != '\x0') {
      // Mapping same attraction locations
      s = stringValue(s, tmp, MAX_CSTRING);
      if (*s != '=') NSLog(@"Separator character '=' missing!");
      while (TRUE) {
        NSString *fromId = (*tmp == '\n')? [NSString stringWithUTF8String:tmp+1] : [NSString stringWithUTF8String:tmp];
        s = stringValue(s+1, tmp, MAX_CSTRING);
        NSString *toId = [NSString stringWithUTF8String:tmp];
        //if ([Attraction getAttraction:parkId attractionId:fromId] == nil) {
          [sameAttractionIds setObject:toId forKey:fromId];
          if ([self isEntryOrExitOfPark:fromId]) [sameAttractionIds setObject:fromId forKey:toId];
        /*} else {
          [sameAttractionIds setObject:fromId forKey:toId];
          if ([self isEntryOfPark:toId]) [sameAttractionIds setObject:toId forKey:fromId];
        }*/
        if (parkAttractionLocations != nil) {
          TrackPoint *p = [parkAttractionLocations objectForKey:fromId];
          if (p != nil) {
            [parkAttractionLocations setObject:p forKey:toId];
          } else {
            p = [parkAttractionLocations objectForKey:toId];
            if (p != nil) [parkAttractionLocations setObject:p forKey:fromId];
          }
        }
        if (*s != ';') break;
        s = stringValue(s+1, tmp, MAX_CSTRING);
        if (*s != '=') {
          NSLog(@"Unknown separator '%c'!", *s);
          break;
        }
      }
    }
    NSLog(@"Parsing completed %s", s);
    NSLog(@"parkAttractionLocations: %d  trackSegments: %d  shortestPath: %d  sameAttractionIds: %d", parkAttractionLocations.count, trackSegments.count, nShortestPath, sameAttractionIds.count);
    //[allAttractionIds release];
    free(data);
  }
  [pool release];
  return YES;
}
/*
-(void)load {
  NSString *docPath = [SettingsData documentPath];
  NSString *filename = [NSString stringWithFormat:@"%@.dataVersion", parkName];
  NSNumber *version = [NSKeyedUnarchiver unarchiveObjectWithFile:[docPath stringByAppendingPathComponent:filename]];
  NSLog(@"load version:%@", version);
  if (version != nil && [version doubleValue] == versionOfData) {
    NSLog(@"loading %@ data", parkName);
    filename = [NSString stringWithFormat:@"%@.segment", parkName];
    trackSegments = [[NSKeyedUnarchiver unarchiveObjectWithFile:[docPath stringByAppendingPathComponent:filename]] retain];
    attributeIndex = [[NSKeyedUnarchiver unarchiveObjectWithFile:[docPath stringByAppendingPathComponent:@"UsedCarIndex"]] retain];
    minValuesAttributes = [[NSKeyedUnarchiver unarchiveObjectWithFile:[docPath stringByAppendingPathComponent:@"UsedCarMinValues"]] retain];
    maxValuesAttributes = [[NSKeyedUnarchiver unarchiveObjectWithFile:[docPath stringByAppendingPathComponent:@"UsedCarMaxValues"]] retain];
  }
}

-(void)save:(NSString *)name ofType:(NSString *)ext {
  NSLog(@"save version:%f  (free memory %d bytes)", versionOfData, [self getFreeMemory]);
  NSString *docPath = [SettingsData documentPath];
  [NSKeyedArchiver archiveRootObject:[NSNumber numberWithDouble:versionOfData] toFile:[docPath stringByAppendingPathComponent:@"UsedCarVersion"]];
  [NSKeyedArchiver archiveRootObject:attributeIndex toFile:[docPath stringByAppendingPathComponent:@"UsedCarIndex"]];
  [NSKeyedArchiver archiveRootObject:minValuesAttributes toFile:[docPath stringByAppendingPathComponent:@"UsedCarMinValues"]];
  [NSKeyedArchiver archiveRootObject:maxValuesAttributes toFile:[docPath stringByAppendingPathComponent:@"UsedCarMaxValues"]];
  [NSKeyedArchiver archiveRootObject:usedCars toFile:[docPath stringByAppendingPathComponent:@"UsedCarData"]];
  NSLog(@"save completed");
}*/

@end
