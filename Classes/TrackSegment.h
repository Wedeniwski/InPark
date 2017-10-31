//
//  TrackSegment.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 18.10.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrackPoint.h"

@interface TrackSegmentId : NSObject <NSCopying> {
  short fromIndex;
  short toIndex;
}

-(id)initWithFromIndex:(short)fIndex toIndex:(short)tIndex;
-(id)copyWithZone:(NSZone *)zone;
-(NSUInteger)hash;
-(NSComparisonResult)compare:(TrackSegmentId *)trackSegmentId;
-(BOOL)isEqual:(id)object;
-(NSString *)from:(NSArray *)allAttractionIds;
-(NSString *)to:(NSArray *)allAttractionIds;

@property (readonly) short fromIndex;
@property (readonly) short toIndex;

@end

@interface TrackSegmentIdOrdered : TrackSegmentId {
}

-(id)initWithFromIndex:(short)fIndex toIndex:(short)tIndex;
-(id)copyWithZone:(NSZone *)zone;
-(BOOL)isEqual:(id)object;

@end

@interface TrackSegment : NSObject <NSCoding> {
  BOOL idsSwapped;
  NSString *from;
  NSString *to;
  NSArray *trackPoints;
  double distance;
  BOOL isTrackToTourItem;
  int minLatitude, minLongitude, maxLatitude, maxLongitude;
  NSString *fromExitAttractionId;
}

-(id)initWithFromAttractionId:(NSString *)fromAttractionId toAttractionId:(NSString *)toAttractionId trackPoints:(NSArray *)tPoints isTrackToTourItem:(BOOL)trackToTourItem;

-(NSString *)fromAttractionId;
-(NSString *)toAttractionId;

+(NSArray *)findTrackSegmentIdFromAttractionIdx:(short)fromAttractionIdx toNotUnique:(NSArray *)toAttractionIds inside:(NSArray *)array allAttractionIds:(NSArray *)allAttractionIds;
+(NSArray *)findTrackSegmentIdFromNotUnique:(NSArray *)fromAttractionIds toAttractionIdx:(short)toAttractionIdx inside:(NSArray *)array allAttractionIds:(NSArray *)allAttractionIds;
+(NSArray *)findTrackSegmentIdFromNotUnique:(NSArray *)fromAttractionIds toNotUnique:(NSArray *)toAttractionIds inside:(NSArray *)array allAttractionIds:(NSArray *)allAttractionIds;
+(TrackSegmentIdOrdered *)getTrackSegmentId:(short)fromIdx toAttractionIdx:(short)toIdx;
-(BOOL)isEqual:(TrackSegment *)segment;
-(int)count;
-(void)deleteTrackPointAtIndex:(int)index;
-(void)insertCenterTrackPointAtIndex:(int)index;
-(TrackPoint *)trackPointOf:(NSString *)attractionId;
-(TrackPoint *)fromTrackPoint;
-(TrackPoint *)toTrackPoint;
-(BOOL)fromAttractionIdEqualToTrackPoint:(TrackPoint *)trackPoint;
-(BOOL)toAttractionIdEqualToTrackPoint:(TrackPoint *)trackPoint;
-(BOOL)isInsideRegion:(TrackPoint *)trackPoint;
-(BOOL)closestInsightDistanceForTrackPoint:(TrackPoint *)trackPoint closestDistance:(double *)closestDistance;
-(BOOL)closestDistanceForTrackPoint:(TrackPoint *)trackPoint checkEvenIsNotInside:(BOOL)checkEvenIsNotInside closestDistance:(double *)closestDistance;
-(double)distanceFromTrackPoint:(TrackPoint *)trackPoint toAttractionId:(NSString *)attractionId;
//-(NSString *)closestAttractionIdForTrackPoint:(TrackPoint *)trackPoint distance:(double *)closestDistance tolerance:(double *)tolerance;
-(NSString *)toString:(NSDateFormatter *)gpxTimeFormat comment:(NSString *)comment;

@property (readonly, nonatomic) NSString *from;
@property (readonly, nonatomic) NSString *to;
@property (readonly, nonatomic) NSArray *trackPoints;
@property (readonly) double distance;
@property (readonly) BOOL isTrackToTourItem;
@property (retain, nonatomic) NSString *fromExitAttractionId;

@end
