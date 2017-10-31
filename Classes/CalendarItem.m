//
//  CalendarItem.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 26.03.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "CalendarItem.h"
#import "CalendarData.h"
#import "Attraction.h"

@implementation CalendarItem

@synthesize attractionIds;
@synthesize startDate, endDate, startTime, endTime;
@synthesize needToAttendAtStartTime, extraHours, winterData;

-(id)initWithAttractionIds:(NSArray *)aIds parkId:(NSString *)parkId startDate:(NSDate *)sD endDate:(NSDate *)eD startTime:(NSDate *)sT endTime:(NSDate *)eT extraHours:(BOOL)eH winterData:(BOOL)wD {
  self = [super init];
  if (self != nil) {
    attractionIds = [aIds retain];
    startDate = [sD retain];
    endDate = [eD retain];
    startTime = [sT retain];
    endTime = [eT retain];
    needToAttendAtStartTime = NO;
    extraHours = eH;
    winterData = wD;
    if ([aIds count] > 0) {
      Attraction *attraction = [Attraction getAttraction:parkId attractionId:[aIds objectAtIndex:0]];
      if (attraction != nil) {
        needToAttendAtStartTime = (attraction.duration == (int)(([endTime timeIntervalSince1970]-[startTime timeIntervalSince1970])/60));
      }
    }
  }
  return self;
}

-(void)dealloc {
  [attractionIds release];
  [startDate release];
  [endDate release];
  [startTime release];
  [endTime release];
  [super dealloc];
}

-(BOOL)isEqual:(id)object {
  if ([object isKindOfClass:[CalendarItem class]]) {
    CalendarItem *item = (CalendarItem *)object;
    return ([startDate isEqualToDate:item.startDate] && [endDate isEqualToDate:item.endDate] && [startTime isEqualToDate:item.startTime] && [endTime isEqualToDate:item.endTime]);
  }
  return NO;
}

-(NSComparisonResult)compare:(CalendarItem *)otherCalendarItem {
  NSComparisonResult cmp = [startTime compare:otherCalendarItem.startTime];
  if (cmp != NSOrderedSame) return cmp;
  return [endTime compare:otherCalendarItem.endTime];
}

-(NSString *)getStartTime {
  return [CalendarData stringFromTime:startTime considerTimeZoneAbbreviation:nil];
}

-(NSString *)getEndTime {
  return [CalendarData stringFromTime:endTime considerTimeZoneAbbreviation:nil];
}

-(NSString *)getTimeFrame {
  return [NSString stringWithFormat:@"%@-%@", [CalendarData stringFromTime:startTime considerTimeZoneAbbreviation:nil], [CalendarData stringFromTime:endTime considerTimeZoneAbbreviation:nil]];
}

+(BOOL)isTimeIntervalSince1970:(double)time insideCalendarItems:(NSArray *)calendarItems {
  if (calendarItems == nil || [calendarItems count] == 0) return YES;
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  const unsigned units = NSHourCalendarUnit | NSMinuteCalendarUnit;
  NSDateComponents *components = [calendar components:units fromDate:[NSDate dateWithTimeIntervalSince1970:time]];
  int h = (int)[components hour];
  int m = (int)[components minute];
  BOOL isInside = NO;
  for (CalendarItem *item in calendarItems) {
    components = [calendar components:units fromDate:item.startTime];
    int h2 = (int)[components hour];
    if (h < h2 || (h == h2 && m < [components minute])) break;
    components = [calendar components:units fromDate:item.endTime];
    h2 = (int)[components hour];
    if (h < h2 || (h == h2 && m <= [components minute])) {
      isInside = YES;
      break;
    }
  }
  [calendar release];
  return isInside;
}

+(double)nextOpeningTimeIntervalSince1970:(double)time insideCalendarItems:(NSArray *)calendarItems {
  if (calendarItems == nil || [calendarItems count] == 0) return 0.0;
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  const unsigned units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
  NSDateComponents *components = [calendar components:units fromDate:[NSDate dateWithTimeIntervalSince1970:time]];
  int h = (int)[components hour];
  int m = (int)[components minute];
  for (CalendarItem *item in calendarItems) {
    NSDateComponents *components2 = [calendar components:units fromDate:item.startTime];
    int h2 = (int)[components2 hour];
    int m2 = (int)[components2 minute];
    if (h < h2 || (h == h2 && m <= m2)) {
      [components setHour:h2];
      [components setMinute:m2];
      NSDate *t = [calendar dateFromComponents:components];
      [calendar release];
      return [t timeIntervalSince1970];
    }
  }
  [calendar release];
  return -1.0;
}

@end
