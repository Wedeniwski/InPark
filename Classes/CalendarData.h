//
//  CalendarData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 26.03.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CalendarItem.h"

@protocol CalendarDataDelegate
-(void)calendarDataUpdated;
@end

@interface CalendarData : NSObject {
  UIViewController<CalendarDataDelegate> *registeredViewController;
  NSString *parkId;
  NSArray *openings;  // list of CalendarItem
  NSDate *cachedDate;
  NSCalendar *currentCalendar;
  NSMutableArray *cacheCalendarItems;
  double lastOnlineCheckTime;
  int numberOfFaildOnlineAccess;
  double modificationTimeOfLocalData;
  double timeOfOnlineData;
  BOOL newWaitingTimeData;
  BOOL updateIsActive;
}

-(id)initWithParkId:(NSString *)pId registeredViewController:(UIViewController<CalendarDataDelegate> *)viewController;
-(BOOL)isEmpty;
-(BOOL)isUpdateActive;
-(void)registerViewController:(UIViewController<CalendarDataDelegate> *)viewController;
-(void)unregisterViewController;

-(void)update:(BOOL)considerLocalData;
-(void)updateIfNecessary;
-(BOOL)hasWinterDataFor:(NSDate *)date;
-(NSArray *)getCalendarItemsFor:(NSDate *)date;
-(BOOL)hasCalendarItems:(NSString *)attractionId;
-(BOOL)hasCalendarItemsAfterToday:(NSString *)attractionId;
-(NSArray *)getCalendarItemsFor:(NSString *)attractionId forDate:(NSDate *)date;
-(NSDate *)getEarliestStartTimeFor:(NSString *)attractionId forDate:(NSDate *)date forItem:(CalendarItem *)item;
-(NSDate *)getLatestEndTimeFor:(NSString *)attractionId forDate:(NSDate *)date forItem:(CalendarItem *)item;
-(BOOL)getMinMax:(int *)minDefinedDay minDefinedMonth:(int *)minDefinedMonth minDefinedYear:(int *)minDefinedYear maxDefinedDay:(int *)maxDefinedDay maxDefinedMonth:(int *)maxDefinedMonth maxDefinedYear:(int *)maxDefinedYear;
+(BOOL)isBetween:(int)year month:(int)month day:(int)day minDay:(int)minDay minMonth:(int)minMonth minYear:(int)minYear maxDay:(int)maxDay maxMonth:(int)maxMonth maxYear:(int)maxYear;

+(BOOL)isToday:(NSDate *)date;
+(int)dayOfToday;
+(UIImage *)calendarIcon:(BOOL)large;

+(NSString *)stringFromTime:(NSDate *)time considerTimeZoneAbbreviation:(NSString *)abbreviation;
+(NSString *)stringFromTimeShort:(NSDate *)time considerTimeZoneAbbreviation:(NSString *)abbreviation;
+(NSString *)stringFromTimeLong:(NSDate *)time considerTimeZoneAbbreviation:(NSString *)abbreviation;
+(NSString *)stringFromDate:(NSDate *)date considerTimeZoneAbbreviation:(NSString *)abbreviation;
+(NSDate *)toLocalTime:(NSDate *)date considerTimeZoneAbbreviation:(NSString *)abbreviation;

@property BOOL newWaitingTimeData;
@property (readonly) UIViewController<CalendarDataDelegate> *registeredViewController;

@end
