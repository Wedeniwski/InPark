//
//  TrackSegment.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 18.10.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "TrackSegment.h"
#import "ExtendedTrackPoint.h"
#import "MenuData.h"

@implementation TrackSegmentId

@synthesize fromIndex, toIndex;

-(id)initWithFromIndex:(short)fIndex toIndex:(short)tIndex {
  self = [super init];
  if (self != nil) {
    fromIndex = fIndex;
    toIndex = tIndex;
  }
  return self;
}

-(id)copyWithZone:(NSZone *)zone {
  return [[TrackSegmentId allocWithZone:zone] initWithFromIndex:fromIndex toIndex:toIndex];
}

-(void)dealloc {
  [super dealloc];
}

-(NSUInteger)hash {
  NSUInteger hh = toIndex;
  NSUInteger hl = fromIndex;
  return ((hh << 8) | (hl & 255)) & 65535;
}

-(NSComparisonResult)compare:(TrackSegmentId *)trackSegmentId {
  short f1 = fromIndex;
  short f2 = trackSegmentId.fromIndex;
  if (f1 == f2) {
    f1 = toIndex;
    f2 = trackSegmentId.toIndex;
    if (f1 == f2) return NSOrderedSame;
  }
  return (f1 < f2)? NSOrderedAscending : NSOrderedDescending;
}

-(BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[TrackSegmentId class]]) return NO;
  TrackSegmentId *trackSegmentId = (TrackSegmentId *)object;
  return ((fromIndex == trackSegmentId.fromIndex && toIndex == trackSegmentId.toIndex) || (fromIndex == trackSegmentId.toIndex && toIndex == trackSegmentId.fromIndex));
}

-(NSString *)from:(NSArray *)allAttractionIds {
  return (fromIndex >= 0)? [allAttractionIds objectAtIndex:fromIndex] : nil;
}

-(NSString *)to:(NSArray *)allAttractionIds {
  return (toIndex >= 0)? [allAttractionIds objectAtIndex:toIndex] : nil;
}

@end

@implementation TrackSegmentIdOrdered

-(id)initWithFromIndex:(short)fIndex toIndex:(short)tIndex {
  self = [super initWithFromIndex:fIndex toIndex:tIndex];
  if (self != nil) {
    if (fIndex > tIndex) {
      fromIndex = tIndex;
      toIndex = fIndex;
    }
  }
  return self;
}

-(id)copyWithZone:(NSZone *)zone {
  return [[TrackSegmentIdOrdered allocWithZone:zone] initWithFromIndex:fromIndex toIndex:toIndex];
}

-(BOOL)isEqual:(id)object {
  if ([object isKindOfClass:[TrackSegmentIdOrdered class]]) {
    TrackSegmentIdOrdered *trackSegmentId = (TrackSegmentIdOrdered *)object;
    return (fromIndex == trackSegmentId.fromIndex && toIndex == trackSegmentId.toIndex);
  }
  return [super isEqual:object];
}

@end

@implementation TrackSegment

@synthesize from, to;
@synthesize trackPoints;
@synthesize distance;
@synthesize isTrackToTourItem;
@synthesize fromExitAttractionId;

#define TOLERANCE 0.00002  // about 5m
#define TOLERANCE_INT 20

-(void)updateDistanceAndRegion {
  distance = 0.0;
  int l = [trackPoints count];
  if (l > 0) {
    TrackPoint *t = [trackPoints objectAtIndex:0];
    /*TrackPoint *tt = [[TrackPoint alloc] initWithLatitude:t.latitude-TOLERANCE longitude:t.longitude-TOLERANCE];
    TrackPoint *ts = [[TrackPoint alloc] initWithLatitude:t.latitude+TOLERANCE longitude:t.longitude+TOLERANCE];
    NSLog(@"TOLERANCE distance: %f", [tt distanceTo:ts]);
    [tt release];
    [ts release];*/
    minLatitude = maxLatitude = t.latitudeInt;
    minLongitude = maxLongitude = t.longitudeInt;
    for (int i = 1; i < l; ++i) {
      TrackPoint *t2 = [trackPoints objectAtIndex:i];
      double d = t.latitudeInt;
      if (d > maxLatitude) maxLatitude = d;
      else if (d < minLatitude) minLatitude = d;
      d = t.longitudeInt;
      if (d > maxLongitude) maxLongitude = d;
      else if (d < minLongitude) minLongitude = d;
      distance += [t distanceTo:t2];
      t = t2;
    }
    minLatitude -= TOLERANCE_INT; minLongitude -= TOLERANCE_INT;
    maxLatitude += TOLERANCE_INT; maxLongitude += TOLERANCE_INT;
  } else {
    minLatitude = minLongitude = maxLatitude = maxLongitude = 0;
  }
}

-(id)initWithFromAttractionId:(NSString *)fromAttractionId toAttractionId:(NSString *)toAttractionId trackPoints:(NSArray *)tPoints isTrackToTourItem:(BOOL)trackToTourItem {
  self = [super init];
  if (self != nil) {
    if ([fromAttractionId compare:toAttractionId] == NSOrderedDescending) {
      idsSwapped = YES;
      from = [toAttractionId retain];
      to = [fromAttractionId retain];
    } else {
      idsSwapped = NO;
      from = [fromAttractionId retain];
      to = [toAttractionId retain];
    }
    trackPoints = [tPoints retain];
    isTrackToTourItem = trackToTourItem;
    fromExitAttractionId = nil;
    [self updateDistanceAndRegion];
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self != nil) {
    NSString *fromAttractionId = [coder decodeObjectForKey:@"FROM"];
    NSString *toAttractionId = [coder decodeObjectForKey:@"TO"];
    if ([fromAttractionId compare:toAttractionId] == NSOrderedDescending) {
      idsSwapped = YES;
      from = [toAttractionId retain];
      to = [fromAttractionId retain];
    } else {
      idsSwapped = NO;
      from = [fromAttractionId retain];
      to = [toAttractionId retain];
    }
    trackPoints = [[coder decodeObjectForKey:@"TRACK"] retain];
    isTrackToTourItem = [coder decodeBoolForKey:@"TO_TOUR_ITEM"];
    fromExitAttractionId = ([coder containsValueForKey:@"FROM_EXIT"])? [[coder decodeObjectForKey:@"FROM_EXIT"] retain] : nil;
    [self updateDistanceAndRegion];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
  if (idsSwapped) {
    [coder encodeObject:to forKey:@"FROM"];
    [coder encodeObject:from forKey:@"TO"];
  } else {
    [coder encodeObject:from forKey:@"FROM"];
    [coder encodeObject:to forKey:@"TO"];    
  }
  [coder encodeObject:trackPoints forKey:@"TRACK"];
  [coder encodeBool:isTrackToTourItem forKey:@"TO_TOUR_ITEM"];
  if (fromExitAttractionId != nil) [coder encodeObject:fromExitAttractionId forKey:@"FROM_EXIT"];
}

-(void)dealloc {
  [from release];
  from = nil;
  [to release];
  to = nil;
  [trackPoints release];
  trackPoints = nil;
  [fromExitAttractionId release];
  fromExitAttractionId = nil;
  [super dealloc];
}

-(NSString *)fromAttractionId {
  return (idsSwapped)? to : from;
}

-(NSString *)toAttractionId {
  return (idsSwapped)? from : to;
}

+(NSArray *)findTrackSegmentIdFromAttractionIdx:(short)fromAttractionIdx toNotUnique:(NSArray *)toAttractionIds inside:(NSArray *)array allAttractionIds:(NSArray *)allAttractionIds {
  NSMutableArray *result = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];
  for (NSString *tId in toAttractionIds) {
    int toAttractionIdx = [MenuData binarySearch:tId inside:allAttractionIds];
    if (toAttractionIdx < 0) NSLog(@"Internal error: attraction %@ (%d) unknown", tId, toAttractionIdx);
    else {
      TrackSegmentIdOrdered *segmentId = [TrackSegment getTrackSegmentId:fromAttractionIdx toAttractionIdx:toAttractionIdx];
      if ([array containsObject:segmentId]) [result addObject:segmentId];
    }
  }
  return result;
}

+(NSArray *)findTrackSegmentIdFromNotUnique:(NSArray *)fromAttractionIds toAttractionIdx:(short)toAttractionIdx inside:(NSArray *)array allAttractionIds:(NSArray *)allAttractionIds {
  NSMutableArray *result = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];
  for (NSString *fId in fromAttractionIds) {
    int fromAttractionIdx = [MenuData binarySearch:fId inside:allAttractionIds];
    if (fromAttractionIdx < 0) NSLog(@"Internal error: attraction %@ (%d) unknown", fId, fromAttractionIdx);
    else {
      TrackSegmentIdOrdered *segmentId = [TrackSegment getTrackSegmentId:fromAttractionIdx toAttractionIdx:toAttractionIdx];
      if ([array containsObject:segmentId]) [result addObject:segmentId];
    }
  }
  return result;
}

+(NSArray *)findTrackSegmentIdFromNotUnique:(NSArray *)fromAttractionIds toNotUnique:(NSArray *)toAttractionIds inside:(NSArray *)array allAttractionIds:(NSArray *)allAttractionIds {
  NSMutableArray *result = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];
  for (NSString *fId in fromAttractionIds) {
    int fromAttractionIdx = [MenuData binarySearch:fId inside:allAttractionIds];
    if (fromAttractionIdx < 0) NSLog(@"Internal error: attraction %@ (%d) unknown", fId, fromAttractionIdx);
    else {
      for (NSString *tId in toAttractionIds) {
        int toAttractionIdx = [MenuData binarySearch:tId inside:allAttractionIds];
        if (toAttractionIdx < 0) NSLog(@"Internal error: attraction %@ (%d) unknown", tId, toAttractionIdx);
        else {
          TrackSegmentIdOrdered *segmentId = [TrackSegment getTrackSegmentId:fromAttractionIdx toAttractionIdx:toAttractionIdx];
          if ([array containsObject:segmentId]) [result addObject:segmentId];
        }
      }
    }
  }
  return result;
}

/*+(NSArray *)findTrackSementId:(NSString *)fromAttractionId fromUnique:(BOOL)fromUnique toAttractionId:(NSString *)toAttractionId toUnique:(BOOL)toUnique inside:(NSArray *)array {
  NSString *fId = (fromUnique)? fromAttractionId : [fromAttractionId stringByAppendingString:@"@"];
  NSString *tId = (toUnique)? toAttractionId : [toAttractionId stringByAppendingString:@"@"];
  NSMutableArray *result = [[[NSMutableArray alloc] initWithCapacity:2] autorelease];
  for (NSString *segmentId in array) {
    NSRange range = [segmentId rangeOfString:fId];
    if (range.length > 0) {
      range = [segmentId rangeOfString:tId];
      if (range.length > 0) {
        [result addObject:segmentId];
      }
    }
  }
  return result;
}*/

+(TrackSegmentIdOrdered *)getTrackSegmentId:(short)fromIdx toAttractionIdx:(short)toIdx {
  // Notation should not be changed, because of methods isSegementId, getPath and isPathInverse at ParkData
  return [[[TrackSegmentIdOrdered alloc] initWithFromIndex:fromIdx toIndex:toIdx] autorelease];
}

-(BOOL)isEqual:(TrackSegment *)segment {
  if (distance != segment.distance) return NO;
  if (isTrackToTourItem != segment.isTrackToTourItem) return NO;
  if ([trackPoints count] != [segment.trackPoints count]) return NO;
  return ([from isEqual:segment.from] && [to isEqual:segment.to]);
}

-(int)count {
  return (int)[trackPoints count];
}

-(void)deleteTrackPointAtIndex:(int)index {
  int l = (int)[trackPoints count];
  if (index < l-1 && index > 0) {
    NSMutableArray *m = [[NSMutableArray alloc] initWithArray:trackPoints];
    [m removeObjectAtIndex:index];
    [trackPoints release];
    trackPoints = m;
    [self updateDistanceAndRegion];
  }
}

-(void)insertCenterTrackPointAtIndex:(int)index {
  int l = (int)[trackPoints count];
  if (index < l && index >= 0) {
    NSMutableArray *m = [[NSMutableArray alloc] initWithArray:trackPoints];
    TrackPoint *t = [trackPoints objectAtIndex:index];
    double lat = t.latitude;
    double lon = t.longitude;
    if (index-1 >= 0) t = [trackPoints objectAtIndex:index-1];
    else if (index+1 < l) t = [trackPoints objectAtIndex:index+1];
    t = [[TrackPoint alloc] initWithLatitude:(lat+t.latitude)/2 longitude:(lon+t.longitude)/2];
    [m insertObject:t atIndex:index];
    [t release];
    [trackPoints release];
    trackPoints = m;
    [self updateDistanceAndRegion];
  }
}

-(TrackPoint *)trackPointOf:(NSString *)attractionId {
  int l = [trackPoints count];
  if (l > 0) {
    if ([attractionId isEqualToString:from]) {
      return (idsSwapped)? [trackPoints objectAtIndex:l-1] : [trackPoints objectAtIndex:0];
    } else if ([attractionId isEqualToString:to]) {
      return (idsSwapped)? [trackPoints objectAtIndex:0] : [trackPoints objectAtIndex:l-1];
    }
  }
  return nil;
}

-(TrackPoint *)fromTrackPoint {
  return ([trackPoints count] > 0)? [trackPoints objectAtIndex:0] : nil;
}

-(TrackPoint *)toTrackPoint {
  int l = [trackPoints count];
  return (l > 0)? [trackPoints objectAtIndex:l-1] : nil;
}

-(BOOL)fromAttractionIdEqualToTrackPoint:(TrackPoint *)trackPoint {
  if ([trackPoints count] == 0) return NO;
  TrackPoint *t = [trackPoints objectAtIndex:0];
  return (ABS(trackPoint.latitudeInt - t.latitudeInt) < TOLERANCE_INT && ABS(trackPoint.longitudeInt - t.longitudeInt) < TOLERANCE_INT);
}

-(BOOL)toAttractionIdEqualToTrackPoint:(TrackPoint *)trackPoint {
  if ([trackPoints count] == 0) return NO;
  TrackPoint *t = [trackPoints lastObject];
  return (ABS(trackPoint.latitudeInt - t.latitudeInt) < TOLERANCE_INT && ABS(trackPoint.longitudeInt - t.longitudeInt) < TOLERANCE_INT);
}

-(BOOL)isInsideRegion:(TrackPoint *)trackPoint {
  int t = trackPoint.latitudeInt;
  if (t < minLatitude-TOLERANCE_INT || t > maxLatitude+TOLERANCE_INT) {
    if (t >= minLatitude-6*TOLERANCE_INT && t <= maxLatitude+6*TOLERANCE_INT) {
      t = trackPoint.longitudeInt;
      return (t >= minLongitude-TOLERANCE_INT && t <= maxLongitude+TOLERANCE_INT);
    }
    return NO;
  }
  t = trackPoint.longitudeInt;
  return (t >= minLongitude-6*TOLERANCE_INT && t <= maxLongitude+6*TOLERANCE_INT);
}

-(BOOL)closestInsightDistanceForTrackPoint:(TrackPoint *)trackPoint closestDistance:(double *)closestDistance {
  int n = [trackPoints count]-1;
  if (n < 2 || ![self isInsideRegion:trackPoint]) return NO;
  TrackPoint *t = [trackPoints objectAtIndex:0];
  if (ABS(trackPoint.latitudeInt - t.latitudeInt) < TOLERANCE_INT && ABS(trackPoint.longitudeInt - t.longitudeInt) < TOLERANCE_INT) return NO;
  t = [trackPoints lastObject];
  if (ABS(trackPoint.latitudeInt - t.latitudeInt) < TOLERANCE_INT && ABS(trackPoint.longitudeInt - t.longitudeInt) < TOLERANCE_INT) return NO;
  return [self closestDistanceForTrackPoint:trackPoint checkEvenIsNotInside:NO closestDistance:closestDistance];
}

-(BOOL)closestDistanceForTrackPoint:(TrackPoint *)trackPoint checkEvenIsNotInside:(BOOL)checkEvenIsNotInside closestDistance:(double *)closestDistance {
  int n = [trackPoints count];
  if (n < 2 || (!checkEvenIsNotInside && ![self isInsideRegion:trackPoint])) return NO;
  double d = *closestDistance;
  BOOL changed = NO;
  TrackPoint *t = [trackPoints objectAtIndex:0];
  double A = trackPoint.latitude - t.latitude;
  double AA = A*A;
  double B = trackPoint.longitude - t.longitude;
  double BB = B*B;
  for (int i = 1; i < n; ++i) { // ToDo: Abstand vom Punkt trackPoint zu den einzelnen Geraden
    TrackPoint *s = [trackPoints objectAtIndex:i];
    double C = s.latitude - t.latitude;
    double D = s.longitude - t.longitude;
    double E = trackPoint.latitude - s.latitude;
    double EE = E*E;
    double F = trackPoint.longitude - s.longitude;
    double FF = F*F;
    double CC = C*C;
    double DD = D*D;
    double dist = CC + DD + TOLERANCE;
    if (AA+BB <= dist && EE+FF <= dist) {
      double m = ABS(A*D - C*B) / sqrt(CC + DD);
      if (d < 0.0 || m < d) {
        d = m;
        changed = YES;
      }
    }
    A = E; B = F; AA = EE; BB = FF;
    t = s;
  }
  if (changed) *closestDistance = d;
  return changed;
}

-(double)distanceFromTrackPoint:(TrackPoint *)trackPoint toAttractionId:(NSString *)attractionId {
  double d = -1.0;
  int closestIdx = -1;
  int i = 0;
  for (TrackPoint *t in trackPoints) {
    double lat = t.latitude-trackPoint.latitude;
    double lon = t.longitude-trackPoint.longitude;
    double m = lat*lat + lon*lon;
    if (d == -1.0 || m < d) {
      closestIdx = i;
      d = m;
      if (d == 0.0) break;
    }
    ++i;
  }
  int l = [trackPoints count];
  if ([attractionId isEqualToString:[self fromAttractionId]]) {
    if (closestIdx == 0) return [trackPoint distanceTo:[trackPoints objectAtIndex:0]];
    d = 0.0;
    TrackPoint *t = [trackPoints objectAtIndex:0];
    for (int i = 1; i <= closestIdx; ++i) {
      TrackPoint *t2 = [trackPoints objectAtIndex:i];
      d += [t distanceTo:t2];
      t = t2;
    }
    return d + [trackPoint distanceTo:t];
  } else  if ([attractionId isEqualToString:[self toAttractionId]]) {
    if (closestIdx == l-1) return [trackPoint distanceTo:[trackPoints lastObject]];
    d = 0.0;
    TrackPoint *t = [trackPoints objectAtIndex:l-1];
    for (int i = l-2; i >= closestIdx; --i) {
      TrackPoint *t2 = [trackPoints objectAtIndex:i];
      d += [t distanceTo:t2];
      t = t2;
    }
    return d + [trackPoint distanceTo:t];
  } else return -1.0;
}

/*-(NSString *)closestAttractionIdForTrackPoint:(TrackPoint *)trackPoint distance:(double *)closestDistance tolerance:(double *)tolerance {
todo
  double d = -1.0;
  int closestIdx = -1;
  int i = 0;
  for (TrackPoint *t in trackPoints) {
    double lat = t.latitude-trackPoint.latitude;
    double lon = t.longitude-trackPoint.longitude;
    double m = lat*lat + lon*lon;
    if (d == -1.0 || m < d) {
      closestIdx = i;
      d = m;
      if (d == 0.0) break;
    }
    ++i;
  }
  if (closestIdx == 0) {
    *tolerance = *closestDistance = [trackPoint distanceTo:[trackPoints objectAtIndex:closestIdx]];
    return [self fromAttractionId];
  }
  int l = [trackPoints count];
  if (closestIdx == l-1) {
    *tolerance = *closestDistance = [trackPoint distanceTo:[trackPoints objectAtIndex:closestIdx]];
    return [self toAttractionId];
  }
  TrackPoint *t = [trackPoints objectAtIndex:closestIdx];
  *tolerance = [trackPoint distanceTo:t];
  if (closestIdx == 1 && l == 3) {
    TrackPoint *t1 = [trackPoints objectAtIndex:0];
    TrackPoint *t2 = [trackPoints objectAtIndex:1];
    TrackPoint *t3 = [trackPoints objectAtIndex:2];
    double lat1 = t1.latitude-t2.latitude;
    double lon1 = t1.longitude-t2.longitude;
    double lat2 = t3.latitude-t2.latitude;
    double lon2 = t3.longitude-t2.longitude;
    if (lat1*lat1 + lon1*lon1 <= lat2*lat2 + lon2*lon2) {
      *closestDistance = *tolerance + [t distanceTo:[trackPoints objectAtIndex:0]];
      return [self fromAttractionId];
    } else {
      *closestDistance = *tolerance + [t distanceTo:[trackPoints objectAtIndex:2]];
      return [self toAttractionId];
    }
  } else if (closestIdx > 0) {
    double dist1 = *tolerance;
    TrackPoint *t = [trackPoints objectAtIndex:0];
    for (int i = 1; i <= closestIdx; ++i) {
      TrackPoint *t2 = [trackPoints objectAtIndex:i];
      dist1 += [t distanceTo:t2];
      t = t2;
    }
    double dist2 = *tolerance;
    t = [trackPoints objectAtIndex:l-1];
    for (int i = l-2; i >= closestIdx; --i) {
      TrackPoint *t2 = [trackPoints objectAtIndex:i];
      dist2 += [t distanceTo:t2];
      t = t2;
    }
    if (dist1 <= dist2) {
      *closestDistance = dist1;
      return [self fromAttractionId];
    } else {
      *closestDistance = dist2;
      return [self toAttractionId];
    }
  }
  *closestDistance = 0.0;
  return nil;
}*/

-(NSString *)toString:(NSDateFormatter *)gpxTimeFormat comment:(NSString *)comment {
  int l = [trackPoints count];
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:l*100+10] autorelease];
  if (comment != nil) {
    [s appendString:@"  <trkseg> "];
    [s appendString:comment];
  } else {
    [s appendString:@"  <trkseg>"];
  }
#ifdef DEBUG_MAP
  [s appendString:@" <!-- "];
  [s appendString:[self fromAttractionId]];
  [s appendString:@" - "];
  [s appendString:[self toAttractionId]];
  [s appendString:@" -->"];
#endif
  [s appendString:@"\n"];
  for (TrackPoint *p in trackPoints) {
    if ([p isKindOfClass:[ExtendedTrackPoint class]]) {
      [s appendString:[(ExtendedTrackPoint *)p toString:gpxTimeFormat]];
    } else {
      [s appendString:[p toString]];
    }
    [s appendString:@"\n"];
  }
  [s appendString:@"  </trkseg>"];
  return s;
}

@end
