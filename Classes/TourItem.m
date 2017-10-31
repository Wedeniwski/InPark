//
//  TourItem.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "TourItem.h"
#import "Attraction.h"

@implementation TourItem

@synthesize attractionId, entryAttractionId, exitAttractionId, currentWalkFromAttractionId;
@synthesize isFastLane, isWaitingTimeAvailable, isWaitingTimeUnknown;
@synthesize waitingTime;
@synthesize walkingTime;
@synthesize distanceToNextAttraction;
@synthesize preferredTime;
@synthesize calculatedTimeInterval;
@synthesize timeVisit;
@synthesize closed, completed;

-(id)initWithAttractionId:(NSString *)aId entry:(NSString *)entryId exit:(NSString *)exitId {
  self = [super init];
  if (self != nil) {
    attractionId = [aId retain];
    entryAttractionId = [entryId retain];
    exitAttractionId = [exitId retain];
    currentWalkFromAttractionId = nil;
    isFastLane = NO;
    isWaitingTimeAvailable = NO;
    isWaitingTimeUnknown = YES;
    waitingTime = 0;
    walkingTime = 0;
    distanceToNextAttraction = 0.0;
    preferredTime = 0.0;
    calculatedTimeInterval = 0;
    timeVisit = nil;
    closed = NO;
    completed = NO;
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self != nil) {
    attractionId = [[coder decodeObjectForKey:@"ATTRACTION_ID"] retain];
    entryAttractionId = [[coder decodeObjectForKey:@"ENTRY_ATTRACTION_ID"] retain];
    exitAttractionId = [[coder decodeObjectForKey:@"EXIT_ATTRACTION_ID"] retain];
    currentWalkFromAttractionId = nil;
    isFastLane = NO;
    isWaitingTimeAvailable = NO;
    isWaitingTimeUnknown = YES;
    waitingTime = [coder decodeIntForKey:@"WAITING_TIME"];
    walkingTime = 0.0;//[coder decodeIntForKey:@"WALKING_TIME"];
    distanceToNextAttraction = 0.0;//[coder decodeDoubleForKey:@"DISTANCE"];
    preferredTime = [coder decodeDoubleForKey:@"PREFERRED_TIME"];
    calculatedTimeInterval = 0;//[coder decodeIntForKey:@"CALCULATED_TIME_INTERVAL"];
    timeVisit = nil;
    closed = NO;
    // added with v 1.1
    completed = [coder containsValueForKey:@"COMPLETED"]? [coder decodeBoolForKey:@"COMPLETED"] : NO;
  }
  return self;
}

-(void)dealloc {
  [attractionId release];
  attractionId = nil;
  [entryAttractionId release];
  entryAttractionId = nil;
  [exitAttractionId release];
  exitAttractionId = nil;
  [currentWalkFromAttractionId release];
  currentWalkFromAttractionId = nil;
  [timeVisit release];
  timeVisit = nil;
  [super dealloc];
}

-(void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:attractionId forKey:@"ATTRACTION_ID"];
  [coder encodeObject:entryAttractionId forKey:@"ENTRY_ATTRACTION_ID"];
  [coder encodeObject:exitAttractionId forKey:@"EXIT_ATTRACTION_ID"];
  [coder encodeInt:waitingTime forKey:@"WAITING_TIME"];
  //[coder encodeInt:walkingTime forKey:@"WALKING_TIME"];
  //[coder encodeDouble:distanceToNextAttraction forKey:@"DISTANCE"];
  [coder encodeDouble:preferredTime forKey:@"PREFERRED_TIME"];
  //[coder encodeInt:calculatedTimeInterval forKey:@"CALCULATED_TIME_INTERVAL"];
  [coder encodeBool:completed forKey:@"COMPLETED"];
}

-(BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[TourItem class]]) return NO;
  TourItem *tourItem = (TourItem *)object;
  return ([attractionId isEqualToString:tourItem.attractionId] && [entryAttractionId isEqualToString:tourItem.entryAttractionId] && [exitAttractionId isEqualToString:tourItem.exitAttractionId]);
}

-(void)setEntry:(NSString *)entryId exit:(NSString *)exitId {
  [entryId retain];
  [exitId retain];
  [entryAttractionId release];
  entryAttractionId = entryId;
  [exitAttractionId release];
  exitAttractionId = exitId;
}

-(void)set:(NSString *)aId entry:(NSString *)entryId exit:(NSString *)exitId {
  [aId retain];
  [entryId retain];
  [exitId retain];
  [attractionId release];
  attractionId = aId;
  [entryAttractionId release];
  entryAttractionId = entryId;
  [exitAttractionId release];
  exitAttractionId = exitId;
}

@end
