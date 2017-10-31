//
//  CalendarItem.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 26.03.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CalendarItem : NSObject {
	NSArray *attractionIds;
	NSDate *startDate;
	NSDate *endDate;
	NSDate *startTime;
	NSDate *endTime;
  BOOL needToAttendAtStartTime;
  BOOL extraHours;
  BOOL winterData;
}

-(id)initWithAttractionIds:(NSArray *)aIds parkId:(NSString *)parkId startDate:(NSDate *)sD endDate:(NSDate *)eD startTime:(NSDate *)sT endTime:(NSDate *)eT extraHours:(BOOL)eH winterData:(BOOL)wD;
-(BOOL)isEqual:(id)object;
-(NSComparisonResult)compare:(CalendarItem *)otherCalendarItem;

-(NSString *)getStartTime;
-(NSString *)getEndTime;
-(NSString *)getTimeFrame;

+(BOOL)isTimeIntervalSince1970:(double)time insideCalendarItems:(NSArray *)calendarItems;
+(double)nextOpeningTimeIntervalSince1970:(double)time insideCalendarItems:(NSArray *)calendarItems;

@property (readonly, nonatomic) NSArray *attractionIds;
@property (readonly, nonatomic) NSDate *startDate;
@property (readonly, nonatomic) NSDate *endDate;
@property (readonly, nonatomic) NSDate *startTime;
@property (readonly, nonatomic) NSDate *endTime;
@property (readonly) BOOL needToAttendAtStartTime;
@property (readonly) BOOL extraHours;
@property (readonly) BOOL winterData;

@end
