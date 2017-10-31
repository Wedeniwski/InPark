//
//  TourItem.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrackPoint.h"

@interface TourItem : NSObject <NSCoding> {
  NSString *attractionId;
  NSString *entryAttractionId;
  NSString *exitAttractionId;
  NSString *currentWalkFromAttractionId;

  BOOL isFastLane;
  BOOL isWaitingTimeAvailable;
  BOOL isWaitingTimeUnknown;
  int waitingTime; // in min  (-1 = closed, unknown)
  NSUInteger walkingTime; // in min
  double distanceToNextAttraction;
  double preferredTime;  // number of seconds since January 1, 1970, 00:00:00 GMT
  int calculatedTimeInterval;  // in seconds
  NSString *timeVisit; // HH:mm of opening if relevant
  BOOL closed;
  BOOL completed;
}

-(id)initWithAttractionId:(NSString *)aId entry:(NSString *)entryId exit:(NSString *)exitId;
-(BOOL)isEqual:(id)object;
-(void)setEntry:(NSString *)entryId exit:(NSString *)exitId;
-(void)set:(NSString *)aId entry:(NSString *)entryId exit:(NSString *)exitId;

@property (readonly, nonatomic) NSString *attractionId;
@property (retain, nonatomic) NSString *entryAttractionId;
@property (retain, nonatomic) NSString *exitAttractionId;
@property (retain, nonatomic) NSString *currentWalkFromAttractionId;
@property BOOL isFastLane;
@property BOOL isWaitingTimeAvailable;
@property BOOL isWaitingTimeUnknown;
@property int waitingTime;
@property NSUInteger walkingTime;
@property double distanceToNextAttraction;
@property double preferredTime;
@property int calculatedTimeInterval;
@property (retain, nonatomic) NSString *timeVisit;
@property BOOL closed;
@property BOOL completed;

@end
