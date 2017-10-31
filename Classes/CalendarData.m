//
//  CalendarData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 26.03.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "CalendarData.h"
#import "MenuData.h"
#import "ParkData.h"
#import "SettingsData.h"
#import "Update.h"

@implementation CalendarData

@synthesize newWaitingTimeData;
@synthesize registeredViewController;

-(void)parseLine:(NSString *)line forAttractionIds:(NSArray *)attractionIds addTo:(NSMutableArray *)cData {
  // 09.04.2011-06.11.2011;13:00-13:35;15:45-16:20;17:30-18:05
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  NSArray *dates = [line componentsSeparatedByString:@";"];
  if (dates != nil && [dates count] > 0) {
    NSString *date = [dates objectAtIndex:0];
    NSArray *startEndDate = [date componentsSeparatedByString:@"-"];
    if (startEndDate != nil && [startEndDate count] >= 2) {
      [dateFormatter setDateFormat:@"dd.MM.yyyy"];
      NSDate *startDate = [dateFormatter dateFromString:[startEndDate objectAtIndex:0]];
      NSDate *endDate = [dateFormatter dateFromString:[startEndDate objectAtIndex:1]];
      if (startDate != nil && endDate != nil) {
        BOOL winterData = ([startEndDate count] >= 3)? [[startEndDate objectAtIndex:2] isEqualToString:@"w"] : NO;
        for (int i = 1; i < [dates count]; ++i) {
          NSArray *startEndTime = [[dates objectAtIndex:i] componentsSeparatedByString:@"-"];
          if (startEndTime != nil && [startEndTime count] == 2) {
            [dateFormatter setDateFormat:@"HH:mm"];
            NSString *endHour = [startEndTime objectAtIndex:1];
            BOOL extraHours = [endHour hasSuffix:@"+"];
            if (extraHours) endHour = [endHour substringToIndex:[endHour length]-1];
            NSDate *startTime = [dateFormatter dateFromString:[startEndTime objectAtIndex:0]];
            NSDate *endTime = [dateFormatter dateFromString:endHour];
            if (startTime != nil && endTime != nil) {
              CalendarItem *c = [[CalendarItem alloc] initWithAttractionIds:attractionIds parkId:parkId startDate:startDate endDate:endDate startTime:startTime endTime:endTime extraHours:extraHours winterData:winterData];
              [cData addObject:c];
              [c release];
            }
          }
        }
      }
    }
  }
  [dateFormatter release];
}

-(void)parseData:(NSString *)data {
  @synchronized([CalendarData class]) {
    [cachedDate release];
    cachedDate = nil;
    [cacheCalendarItems release];
    cacheCalendarItems = nil;
    NSArray *lines = [data componentsSeparatedByString:@"\n"];
    NSMutableArray *cData = [[NSMutableArray alloc] initWithCapacity:3*[lines count]+1];
    NSArray *attractionIds = nil;
    int i = 0;
    for (NSString *line in lines) {
      if (i > 1 && [line length] > 1) {
        if ([line hasSuffix:@":"]) {
          attractionIds = [[line substringToIndex:[line length]-1] componentsSeparatedByString:@","];
        } else if (attractionIds != nil) {
          [self parseLine:line forAttractionIds:attractionIds addTo:cData];
        }
      }
      ++i;
    }
    [openings release];
    [cData sortUsingSelector:@selector(compare:)];
    openings = cData;
    //openings = [[cData sortedArrayUsingSelector:@selector(compare:)] retain];
#ifdef FAKE_CALENDAR
    ParkData *parkData = [ParkData getParkData:parkId];
    NSString *entryId = [parkData getEntryOfPark:nil];
    NSArray *calendarItems = [self getCalendarItemsFor:entryId forDate:nil];
    if ((calendarItems == nil || [calendarItems count] == 0) && [self hasCalendarItems:entryId]) {
      NSString *aId = [parkData.sameAttractionIds objectForKey:entryId];
      for (CalendarItem *item in openings) {
        if ([item.attractionIds indexOfObject:entryId] != NSNotFound || (aId != nil && [item.attractionIds indexOfObject:aId] != NSNotFound)) {
          NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
          NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
          [dateFormatter setDateFormat:@"dd.MM.yyyy"];
          [dateFormatter2 setDateFormat:@"HH:mm"];
          NSString *line = [NSString stringWithFormat:@"%@-%@;%@-%@", [dateFormatter stringFromDate:[NSDate date]], [dateFormatter stringFromDate:[NSDate date]], [dateFormatter2 stringFromDate:item.startTime], [dateFormatter2 stringFromDate:item.endTime]];
          [dateFormatter2 release];
          [dateFormatter release];
          NSLog(@"fake calender by adding opening for %@: %@", item.attractionIds, line);
          [self parseLine:line forAttractionIds:item.attractionIds addTo:cData];
          //[openings release];
          //openings = [[cData sortedArrayUsingSelector:@selector(compare:)] retain];
          [cData sortUsingSelector:@selector(compare:)];
          openings = cData;
          [cachedDate release];
          cachedDate = nil;
          [cacheCalendarItems release];
          cacheCalendarItems = nil;
          break;
        }
      }
    }
#endif
  }
}

-(id)initWithParkId:(NSString *)pId registeredViewController:(UIViewController<CalendarDataDelegate> *)viewController {
  self = [super init];
  if (self != nil) {
    registeredViewController = viewController;
    parkId = [pId retain];
    openings = nil;
    currentCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    cachedDate = nil;
    cacheCalendarItems = nil;
    lastOnlineCheckTime = 0.0;
    numberOfFaildOnlineAccess = 0;
    modificationTimeOfLocalData = -1.0;
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    timeOfOnlineData = [defaults doubleForKey:[NSString stringWithFormat:@"%@.TIME_OF_ONINE_CALENDAR_DATA", parkId]];
    newWaitingTimeData = YES;
    updateIsActive = NO;
    [self updateIfNecessary]; // otheriwse another init might occur during data update
  }
  return self;
}

-(void)dealloc {
  registeredViewController = nil;
  [parkId release];
  parkId = nil;
  [openings release];
  openings = nil;
  [cacheCalendarItems release];
  cacheCalendarItems = nil;
  [cachedDate release];
  cachedDate = nil;
  [currentCalendar release];
  currentCalendar = nil;
  [super dealloc];
}

-(BOOL)isEmpty {
  return (openings == nil || openings.count == 0);
}

-(BOOL)isUpdateActive {
  return updateIsActive;
}

-(void)registerViewController:(UIViewController<CalendarDataDelegate> *)viewController {
  registeredViewController = viewController;
}

-(void)unregisterViewController {
  registeredViewController = nil;
}

-(void)asychronousUpdate:(NSArray *)args {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  double currentTime = [[args objectAtIndex:0] doubleValue];
  double timeToConsiderForLocalData = [[args objectAtIndex:1] doubleValue];
  BOOL online = NO;
  int statusCode = -1;
  NSString *data = [Update onlineDataPath:@"calendar.txt.bz2" hasPrefix:[NSString stringWithFormat:@"%@\n\n", parkId] useLocalDataIfNotOlder:timeToConsiderForLocalData parkId:parkId online:&online statusCode:&statusCode];
  if (statusCode >= 0) lastOnlineCheckTime = currentTime;
  if (online) {
    numberOfFaildOnlineAccess = 0;
  } else if (openings != nil) { // don't need to parse the same data again
    ++numberOfFaildOnlineAccess;
    [pool release];
    updateIsActive = NO;
    return;
  }
  if (data == nil) data = [Update localDataPath:@"calendar.txt" parkId:parkId];
  if (data == nil) {
    NSLog(@"no calendar data for %@ available", parkId);
    [openings release];
    openings = [[NSArray arrayWithObjects:nil] retain];
    ++numberOfFaildOnlineAccess;
    [pool release];
    updateIsActive = NO;
    if (registeredViewController != nil) [registeredViewController calendarDataUpdated];
    return;
  }
  [self parseData:data];
  [pool release];
  updateIsActive = NO;
  if (registeredViewController != nil) [registeredViewController calendarDataUpdated];
}

-(void)update:(BOOL)considerLocalData {
  updateIsActive = YES;
  if (newWaitingTimeData) {
    ParkData *parkData = [ParkData getParkData:parkId];
    WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
    if (waitingTimeData.initialized) {
      WaitingTimeItem *waitingTimeItem = [waitingTimeData getWaitingTimeFor:@"c"];
      //NSLog(@"lastOnlineCheckTime:%f - timeOfOnlineData:%f - waitingTimeItem.totalWaitingTime:%f", lastOnlineCheckTime, timeOfOnlineData, waitingTimeItem.totalWaitingTime);
      if (waitingTimeItem != nil && timeOfOnlineData != waitingTimeItem.totalWaitingTime) {
        considerLocalData = NO;
        timeOfOnlineData = waitingTimeItem.totalWaitingTime;
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setDouble:timeOfOnlineData forKey:[NSString stringWithFormat:@"%@.TIME_OF_ONINE_CALENDAR_DATA", parkId]];
        [defaults synchronize];
      }
      newWaitingTimeData = NO;
    }
  }
  double currentTime = [[NSDate date] timeIntervalSince1970];
  if (currentTime-lastOnlineCheckTime < 10.0 || (numberOfFaildOnlineAccess > 0 && currentTime-lastOnlineCheckTime < 300.0)) {
    updateIsActive = NO;
    return; // can happen if waiting time was not initialized or short time updated after calender update
  }
  double timeToConsiderForLocalData = -1.0;
  if (considerLocalData) {
    SettingsData *settings = [SettingsData getSettingsData];
    timeToConsiderForLocalData = 24.0*settings.calendarDataUpdate-8;
    if (modificationTimeOfLocalData >= 0.0 && modificationTimeOfLocalData < timeToConsiderForLocalData*3600.0) {
      updateIsActive = NO;
      return;
    }
    modificationTimeOfLocalData = [Update localTimeIntervalSinceNowOfData:@"calendar.txt" parkId:parkId];
    if (lastOnlineCheckTime > 0.0 && modificationTimeOfLocalData >= 0.0 && modificationTimeOfLocalData < timeToConsiderForLocalData*3600.0) {
      updateIsActive = NO;
      return;
    }
  }
  if (currentTime-lastOnlineCheckTime >= 10.0 && (numberOfFaildOnlineAccess == 0 || currentTime-lastOnlineCheckTime >= 300.0)) {
    [NSThread detachNewThreadSelector:@selector(asychronousUpdate:) toTarget:self withObject:[NSArray arrayWithObjects:[NSNumber numberWithDouble:currentTime], [NSNumber numberWithDouble:timeToConsiderForLocalData], nil]];
  } else updateIsActive = NO;
}

-(void)updateIfNecessary {
  SettingsData *settings = [SettingsData getSettingsData];
  if ((openings == nil || settings.calendarDataUpdate >= 0) && !updateIsActive) [self update:YES];
}

-(BOOL)hasWinterDataFor:(NSDate *)date {
  NSArray *calendarItems = [self getCalendarItemsFor:date];
  for (CalendarItem *item in calendarItems) {
    if (item.winterData) return YES;
  }
  return NO;
}

-(NSArray *)getCalendarItemsFor:(NSDate *)date {
  // is wrong if initialization of calendar items occur during park hours after midnight
  if (openings == nil || [openings count] == 0) return nil;
  if (date == nil) date = [NSDate date];
  @synchronized([CalendarData class]) {
    if (cachedDate != nil) {
      NSTimeInterval i = [date timeIntervalSinceDate:cachedDate];
      if (i >= 0.0 && i < 3600.0) return cacheCalendarItems;
    }
    //NSDateComponents* c = [currentCalendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit) fromDate:date];
    //[c setHour:0];
    //[c setMinute:0];
    //[c setSecond:0];
    [cachedDate release];
    //cachedDate = [[currentCalendar dateFromComponents:c] retain];
    cachedDate = [date retain];
    //int days = [date timeIntervalSince1970] / 86400;
    //if (days == cacheDays) return cacheCalendarItems; WRONG in other time zones!
    //ParkData *parkData = [ParkData getParkData:parkId];
    //NSLog(@"before: %@ - %@", [CalendarData stringFromDate:date considerTimeZoneAbbreviation:nil], [CalendarData stringFromTimeLong:date considerTimeZoneAbbreviation:nil]);
    //date = [NSDate dateWithTimeIntervalSince1970:days*86400.0];
    //NSLog(@"after: %@ - %@", [CalendarData stringFromDate:date considerTimeZoneAbbreviation:nil], [CalendarData stringFromTimeLong:date considerTimeZoneAbbreviation:parkData.timeZoneAbbreviation]);
    unsigned units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *components = [currentCalendar components:units fromDate:date];
    int day = (int)[components day];
    int month = (int)[components month];
    int year = (int)[components year];
    //NSLog(@"day: %d - %d - %d", day, month, year);
    [cacheCalendarItems release];
    cacheCalendarItems = [[NSMutableArray alloc] initWithCapacity:[openings count]];
    for (CalendarItem *item in openings) {
      components = [currentCalendar components:units fromDate:item.startDate];
      int day2 = (int)[components day];
      int month2 = (int)[components month];
      int year2 = (int)[components year];
      if (year > year2 || (year == year2 && (month > month2 || (month == month2 && day >= day2)))) {
        components = [currentCalendar components:units fromDate:item.endDate];
        day2 = (int)[components day];
        month2 = (int)[components month];
        year2 = (int)[components year];
        if (year < year2 || (year == year2 && (month < month2 || (month == month2 && day <= day2)))) {
          [cacheCalendarItems addObject:item];
        }
      }
    }
    return cacheCalendarItems;
  }
}

-(BOOL)hasCalendarItems:(NSString *)attractionId {
  if (openings == nil || [openings count] == 0) return NO;
  ParkData *parkData = [ParkData getParkData:parkId];
  NSString *aId = [parkData.sameAttractionIds objectForKey:attractionId];
  for (CalendarItem *item in openings) {
    if ([item.attractionIds indexOfObject:attractionId] != NSNotFound || (aId != nil && [item.attractionIds indexOfObject:aId] != NSNotFound)) return YES;
  }
  return NO;
}

-(BOOL)hasCalendarItemsAfterToday:(NSString *)attractionId {
  if (openings == nil || [openings count] == 0) return NO;
  ParkData *parkData = [ParkData getParkData:parkId];
  NSString *aId = [parkData.sameAttractionIds objectForKey:attractionId];
  unsigned units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
  NSDateComponents *components = [currentCalendar components:units fromDate:[NSDate date]];
  int day = (int)[components day];
  int month = (int)[components month];
  int year = (int)[components year];
  for (CalendarItem *item in openings) {
    if ([item.attractionIds indexOfObject:attractionId] != NSNotFound || (aId != nil && [item.attractionIds indexOfObject:aId] != NSNotFound)) {
      components = [currentCalendar components:units fromDate:item.startDate];
      int day2 = (int)[components day];
      int month2 = (int)[components month];
      int year2 = (int)[components year];
      if (year < year2 || (year == year2 && (month < month2 || (month == month2 && day < day2)))) return YES;
      components = [currentCalendar components:units fromDate:item.endDate];
      day2 = (int)[components day];
      month2 = (int)[components month];
      year2 = (int)[components year];
      if (year < year2 || (year == year2 && (month < month2 || (month == month2 && day < day2)))) return YES;
    }
  }
  return NO;
}

-(NSArray *)getCalendarItemsFor:(NSString *)attractionId forDate:(NSDate *)date {
  NSArray *allItems = [self getCalendarItemsFor:date];
  if (allItems == nil || [allItems count] == 0) return nil;
  ParkData *parkData = [ParkData getParkData:parkId];
  NSString *aId = [parkData.sameAttractionIds objectForKey:attractionId];
  NSMutableArray *array = [[[NSMutableArray alloc] initWithCapacity:[allItems count]] autorelease];
  for (CalendarItem *item in allItems) {
    if ([item.attractionIds indexOfObject:attractionId] != NSNotFound || (aId != nil && [item.attractionIds indexOfObject:aId] != NSNotFound)) {
      [array addObject:item];
    }
  }
  return array;
}

-(NSDate *)getEarliestStartTimeFor:(NSString *)attractionId forDate:(NSDate *)date forItem:(CalendarItem *)regular {
  NSArray *allItems = [self getCalendarItemsFor:date];
  if (allItems == nil || [allItems count] == 0) return nil;
  ParkData *parkData = [ParkData getParkData:parkId];
  NSString *aId = [parkData.sameAttractionIds objectForKey:attractionId];
  for (CalendarItem *item in allItems) {
    if (item != regular && item.extraHours && ([item.attractionIds indexOfObject:attractionId] != NSNotFound || (aId != nil && [item.attractionIds indexOfObject:aId] != NSNotFound))) {
      if ([item.endTime isEqualToDate:regular.startTime]) return item.startTime;
    }
  }
  return regular.startTime;
}

-(NSDate *)getLatestEndTimeFor:(NSString *)attractionId forDate:(NSDate *)date forItem:(CalendarItem *)regular {
  NSArray *allItems = [self getCalendarItemsFor:date];
  if (allItems == nil || [allItems count] == 0) return nil;
  ParkData *parkData = [ParkData getParkData:parkId];
  NSString *aId = [parkData.sameAttractionIds objectForKey:attractionId];
  for (CalendarItem *item in allItems) {
    if (item != regular && item.extraHours && ([item.attractionIds indexOfObject:attractionId] != NSNotFound || (aId != nil && [item.attractionIds indexOfObject:aId] != NSNotFound))) {
      if ([item.startTime isEqualToDate:regular.endTime]) return item.endTime;
    }
  }
  return regular.endTime;
}

-(BOOL)getMinMax:(int *)minDefinedDay minDefinedMonth:(int *)minDefinedMonth minDefinedYear:(int *)minDefinedYear maxDefinedDay:(int *)maxDefinedDay maxDefinedMonth:(int *)maxDefinedMonth maxDefinedYear:(int *)maxDefinedYear {
  NSDate *minDate = nil;
  NSDate *maxDate = nil;
  for (CalendarItem *item in openings) {
    if (minDate == nil || [item.startDate compare:minDate] < 0) minDate = item.startDate;
    if (maxDate == nil || [item.endDate compare:maxDate] > 0) maxDate = item.endDate;
  }
  if (minDate == nil || maxDate == nil) return NO;
  unsigned units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
  NSDateComponents *components = [currentCalendar components:units fromDate:minDate];
  *minDefinedDay = (int)[components day];
  *minDefinedMonth = (int)[components month];
  *minDefinedYear = (int)[components year];
  components = [currentCalendar components:units fromDate:maxDate];
  *maxDefinedDay = (int)[components day];
  *maxDefinedMonth = (int)[components month];
  *maxDefinedYear = (int)[components year];
  return YES;
}

+(BOOL)isBetween:(int)year month:(int)month day:(int)day minDay:(int)minDay minMonth:(int)minMonth minYear:(int)minYear maxDay:(int)maxDay maxMonth:(int)maxMonth maxYear:(int)maxYear {
  if (year < maxYear && year > minYear) return YES;
  if (minYear < maxYear) {
    if (year == minYear) return (month > minMonth || (month == minMonth && day >= minDay));
    if (year == maxYear) return (month < maxMonth || (month == maxMonth && day <= maxDay));
  } else if (minYear == maxYear && year == maxYear) {
    if (minMonth < maxMonth) return ((month < maxMonth && month > minMonth) || (month == minMonth && day >= minDay) || (month == maxMonth && day <= maxDay));
    else if (minMonth == maxMonth && month == maxMonth) return (day >= minDay && day <= maxDay);
  }
  return NO;
}

+(BOOL)isToday:(NSDate *)date {
  if (date == nil) return YES;
  // much faster but not correct depending on time zone!
  //const unsigned long d1 = [[NSDate date] timeIntervalSince1970]/86400; //(60*60*24);
  //const unsigned long d2 = [date timeIntervalSince1970]/86400;//(60*60*24);
  //return (d1 == d2);
  NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  //NSDateComponents *c1 = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
	//NSDateComponents *c2 = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
  //[calendar release];
	//return (c1.day == c2.day && c1.month == c2.month && c1.year == c2.year);
  NSDateComponents* c = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit) fromDate:[NSDate date]];
  [c setHour:0];
  [c setMinute:0];
  [c setSecond:0];
  NSTimeInterval i = [date timeIntervalSinceDate:[calendar dateFromComponents:c]];
  [calendar release];
  return (i >= 0.0 && i < 86400.0);
  /*NSCalendar* calendar = [NSCalendar currentCalendar];
  NSDateComponents* c = [calendar components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
  NSTimeInterval i = [date timeIntervalSinceDate:[calendar dateFromComponents:c]];
  return (i >= 0 && i < 60*60*24);*/
}

+(int)dayOfToday {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"d"];
  NSString *text = [dateFormatter stringFromDate:[NSDate date]];
  [dateFormatter release];
  return [text intValue];
}

+(UIImage *)calendarIcon:(BOOL)large {
  UIImage *image = [UIImage imageNamed:(large)? @"calendar.png" : @"small_calendar.png"];
  NSDate *date = [NSDate date];
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"cccc"];
  NSString *text = [dateFormatter stringFromDate:date];
  UIFont *font = [UIFont systemFontOfSize:(large)? 52 : 10];
  UIGraphicsBeginImageContext(image.size);
  [image drawAtPoint:CGPointZero];
  CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor whiteColor].CGColor);
  [text drawAtPoint:CGPointMake((image.size.width-[text sizeWithFont:font].width)/2, (large)? 12 : 2) withFont:font];
  [dateFormatter setDateFormat:@"d"];
  text = [dateFormatter stringFromDate:date];
  font = [UIFont boldSystemFontOfSize:(large)? 200 : 32];
  CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [UIColor blackColor].CGColor);
  [text drawAtPoint:CGPointMake((image.size.width-[text sizeWithFont:font].width)/2, (large)? 80 : 19) withFont:font];
  UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  [dateFormatter release];
  return resultImage;
}

+(NSString *)stringFromTime:(NSDate *)time considerTimeZoneAbbreviation:(NSString *)abbreviation {
  static NSString *timeZoneAbbreviation = nil;
  static NSDateFormatter *timeFormat = nil;
  @synchronized([CalendarData class]) {
    if (timeFormat == nil || (abbreviation == nil && timeZoneAbbreviation != nil) || (abbreviation != nil && timeZoneAbbreviation == nil)  || (abbreviation != nil && ![abbreviation isEqualToString:timeZoneAbbreviation])) {
      [timeFormat release];
      timeFormat = [[NSDateFormatter alloc] init];
      if (abbreviation != nil) [timeFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:abbreviation]];
      [timeFormat setDateFormat:NSLocalizedString(@"time.format", nil)];
    }
  }
  if (time == nil) return nil;
  NSString *t = [timeFormat stringFromDate:time];
  SettingsData *settings = [SettingsData getSettingsData];
  if (!settings.timeIs24HourFormat && t.length == 5) {
    const char *s = [t UTF8String];
    int h = atoi(s);
    int m = atoi(s+3);
    if (h >= 0 && h < 12) {
      if (h == 0) h = 12;
      t = (m == 0)? [NSString stringWithFormat:@"%dam", h] : [NSString stringWithFormat:@"%d:%02dam", h, m];
    } else {
      h -= 12;
      if (h == 0) h = 12;
      t = (m == 0)? [NSString stringWithFormat:@"%dpm", h] : [NSString stringWithFormat:@"%d:%02dpm", h, m];
    }
  }
  return t;
}

+(NSString *)stringFromTimeShort:(NSDate *)time considerTimeZoneAbbreviation:(NSString *)abbreviation {
  NSString *t = [CalendarData stringFromTime:time considerTimeZoneAbbreviation:abbreviation];
  if ([t hasSuffix:@"m"]) t = [t substringToIndex:t.length-1];
  return t;
}

+(NSString *)stringFromTimeLong:(NSDate *)time considerTimeZoneAbbreviation:(NSString *)abbreviation {
  static NSString *timeZoneAbbreviation = nil;
  static NSDateFormatter *timeFormat = nil;
  @synchronized([CalendarData class]) {
    if (timeFormat == nil || (abbreviation == nil && timeZoneAbbreviation != nil) || (abbreviation != nil && timeZoneAbbreviation == nil) || (abbreviation != nil && ![abbreviation isEqualToString:timeZoneAbbreviation])) {
      [timeFormat release];
      timeFormat = [[NSDateFormatter alloc] init];
      if (abbreviation != nil) [timeFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:abbreviation]];
      [timeFormat setDateFormat:NSLocalizedString(@"time.format.long", nil)];
    }
  }
  if (time == nil) return nil;
  NSString *t = [timeFormat stringFromDate:time];
  SettingsData *settings = [SettingsData getSettingsData];
  if (!settings.timeIs24HourFormat && t.length >= 5) {
    const char *s = [t UTF8String];
    int h = atoi(s);
    int m = atoi(s+3);
    if (h >= 0 && h < 12) {
      if (h == 0) h = 12;
      t = (m == 0)? [NSString stringWithFormat:@"%d am", h] : [NSString stringWithFormat:@"%d:%02d am", h, m];
    } else {
      h -= 12;
      if (h == 0) h = 12;
      t = (m == 0)? [NSString stringWithFormat:@"%d pm", h] : [NSString stringWithFormat:@"%d:%02d pm", h, m];
    }
  }
  return t;
}

+(NSString *)stringFromDate:(NSDate *)date considerTimeZoneAbbreviation:(NSString *)abbreviation {
  static NSString *timeZoneAbbreviation = nil;
  static NSDateFormatter *dateFormat = nil;
  @synchronized([CalendarData class]) {
    if (dateFormat == nil || (abbreviation == nil && timeZoneAbbreviation != nil) || (abbreviation != nil && timeZoneAbbreviation == nil) || (abbreviation != nil && ![abbreviation isEqualToString:timeZoneAbbreviation])) {
      [dateFormat release];
      dateFormat = [[NSDateFormatter alloc] init];
      if (abbreviation != nil) [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:abbreviation]];
      [dateFormat setDateFormat:NSLocalizedString(@"date.format", nil)];
    }
  }
  return (date == nil)? nil : [dateFormat stringFromDate:date];
}

+(NSDate *)toLocalTime:(NSDate *)date considerTimeZoneAbbreviation:(NSString *)abbreviation {
  static NSString *timeZoneAbbreviation = nil;
  static NSTimeZone *timeZone = nil;
  @synchronized([CalendarData class]) {
    if (timeZone == nil || (abbreviation == nil && timeZoneAbbreviation != nil) || (abbreviation != nil && timeZoneAbbreviation == nil) || (abbreviation != nil && ![abbreviation isEqualToString:timeZoneAbbreviation])) {
      [timeZone release];
      timeZone = (abbreviation != nil)? [[NSTimeZone timeZoneWithAbbreviation:abbreviation] retain] : nil;
    }
  }
  if (timeZone == nil) return date;
  return [NSDate dateWithTimeInterval:[timeZone secondsFromGMTForDate:date] sinceDate:date];
}

@end
