//
//  WaitingTimeItem.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.04.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WaitingTimeItem : NSObject {
  double totalWaitingTime;
  BOOL fastLaneInfoAvailable;
  short fastLaneAvailable; // >0 : Available, <0 : Limited Availability, 0 : Unavailable
  short fastLaneAvailableTimeFrom;
  short fastLaneAvailableTimeTo;
  NSMutableArray *waitingTimes;
  NSMutableArray *submittedTimestamps;
  NSMutableArray *userNames;
  NSMutableArray *comments;
  //NSMutableArray *startTimes; // format: HH:mm [(<language>)]
}

-(id)initWithWaitTimeLine:(NSString *)line baseTime:(NSDate *)baseTime;
-(id)initWithWaitTime:(short)waitingTime submittedTimestamp:(NSDate *)submittedTimestamp userName:(NSString *)userName comment:(NSString *)comment;

-(BOOL)isEqual:(id)object;
-(BOOL)isEqualToWaitingTimeItem:(WaitingTimeItem *)item;

-(int)count;
-(void)addWaitTimeLine:(NSString *)line baseTime:(NSDate *)baseTime;
-(void)insertWaitTime:(short)waitingTime submittedTimestamp:(NSDate *)submittedTimestamp userName:(NSString *)userName comment:(NSString *)comment atIndex:(int)index;
-(double)totalWaitingTime;
-(BOOL)isOld;
-(BOOL)isVeryOld;
-(BOOL)willWaitTimeBeRefused:(int)waitTime;
+(BOOL)willWaitTimeBeRefused:(int)waitTime;
-(short)latestWaitingTime;
-(NSDate *)latestSubmittedTimestamp;
-(short)updateTotalWaitTime;
-(BOOL)containsComment;
-(short)waitTimeAt:(int)index;
-(NSDate *)submittedTimestampAt:(int)index;
-(NSString *)userNameAt:(int)index;
-(NSString *)commentsAt:(int)index;
-(NSString *)toStringAt:(int)index;
-(BOOL)isFastLaneAvailable;
-(BOOL)isFastLaneLimitedAvailability;
-(BOOL)isFastLaneUnavailable;
//-(BOOL)hasStartTimes;
//-(NSArray *)startTimes;

+(NSString *)removeTokens:(NSString *)text maxLength:(int)maxLength;

@property (readonly) BOOL fastLaneInfoAvailable;
@property (readonly) short fastLaneAvailable;
@property (readonly) short fastLaneAvailableTimeFrom;
@property (readonly) short fastLaneAvailableTimeTo;

@end
