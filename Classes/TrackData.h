//
//  TrackData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 06.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "ExtendedTrackPoint.h"
#import "TrackSegment.h"
#import "Attraction.h"

// Possible tracks (first position is either PARKING_ATTRACTION_ID or UNKNOWN_ATTRACTION_ID):
// (Parking, 000, 400, 400/e, t01, 000/e)
// (, t00, 000, 400, 400/e, t01, 000/e)
// (, 000, t01, 000/e)
// (, t01)
// (, 000, 400, 400/e)
// (, 000, 500, 500)
// (, 400, 400/e)
// (, 400, 400/e, 000/e)


@interface TrackData : NSObject <NSCoding> {
  NSString *trackName;
  NSString *parkId;
  NSString *parkingNotes;
  NSString *trackDescription;
  NSString *gpxFileName;
  NSMutableArray *currentTrackPoints;
  NSString *fromAttractionId;
  NSMutableArray *trackSegments;
}

-(id)initWithTrackName:(NSString *)tName parkId:(NSString *)pId fromAttractionId:(NSString *)fAttractionId;
-(BOOL)complete:(NSString *)completedTrackDescription;
-(BOOL)isDoneAtTourIndex:(int)index;
-(BOOL)isDoneAndActiveAtTourIndex:(int)index;
-(double)doneTimeIntervalAtEntryTourIndex:(int)index;
-(double)doneTimeIntervalAtExitTourIndex:(int)index;
-(int)numberOfTourItemsDone;
-(int)numberOfTourItemsDoneAndActive;
-(BOOL)walkToEntry;
-(double)completedDistance;
-(double)distanceOfCompletedSegmentAtTourIndex:(int)index;
-(int)walkingTimeOfCompletedSegmentAtTourIndex:(int)index;
-(void)addAttractionId:(NSString *)newAttractionId toTourItem:(BOOL)toTourItem fromExitAttractionId:(NSString *)fromExitAttractionId;
-(void)addTrackPoint:(CLLocation *)newLocation;
-(double)timeOfLastTrackFromAttraction;
-(ExtendedTrackPoint *)deleteCurrentTrackExceptLastPoint;
-(TrackSegment *)getTrackSegmentFromParking;
-(BOOL)containsTrackingFromParking;
-(ExtendedTrackPoint *)latestTrackPoint;

+(NSString *)defaultName:(NSString *)tourName;

-(NSString *)gpxFilePath;
-(NSArray *)getAllAttractionsFromGPXFile:(double *)distance start:(NSDate **)start end:(NSDate **)end;
-(void)timeframeAtAttraction:(Attraction *)attraction afterTime:(NSDate *)time fromGPXContentsOfFile:(NSString *)content start:(NSDate **)start end:(NSDate **)end;
-(BOOL)saveData;
-(void)deleteData;

@property (readonly, nonatomic) NSString *trackName;
@property (readonly, nonatomic) NSString *parkId;
@property (retain, nonatomic) NSString *parkingNotes;
@property (retain, nonatomic) NSString *trackDescription;
@property (readonly, nonatomic) NSArray *currentTrackPoints;
@property (readonly, nonatomic) NSString *fromAttractionId;
@property (readonly, nonatomic) NSArray *trackSegments;

@end
