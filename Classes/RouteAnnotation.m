//
//  RouteAnnotation.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 21.06.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "RouteAnnotation.h"

@implementation RouteAnnotation

@synthesize trackSegment;
@synthesize coordinate;

-(id)initWithTrackSegment:(TrackSegment *)segment {
  self = [super init];
  if (self) {
    trackSegment = [segment retain];
    [self resetRegion];
    coordinate = region.center;
  }
  return self;
}

-(void)dealloc {
  [trackSegment release];
  [super dealloc];
}

-(NSString *)title {
  return nil;
}

-(NSString *)subtitle {
  return nil;
}

-(void)addLatitude:(double)latitudeDelta atIndex:(int)index {
  if ([trackSegment.trackPoints count] > index) {
    TrackPoint *t = [trackSegment.trackPoints objectAtIndex:index];
    coordinate = (CLLocationCoordinate2D){ t.latitude, t.longitude };
  }
  [self setCoordinate:CLLocationCoordinate2DMake(coordinate.latitude+latitudeDelta, coordinate.longitude) atIndex:index];
}

-(void)addLongitude:(double)longitudeDelta atIndex:(int)index {
  if ([trackSegment.trackPoints count] > index) {
    TrackPoint *t = [trackSegment.trackPoints objectAtIndex:index];
    coordinate = (CLLocationCoordinate2D){ t.latitude, t.longitude };
  }
  [self setCoordinate:CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude+longitudeDelta) atIndex:index];
}

-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate atIndex:(int)index {
  coordinate = newCoordinate;
  if ([trackSegment.trackPoints count] > index) {
    TrackPoint *t = [trackSegment.trackPoints objectAtIndex:index];
    double delta = newCoordinate.latitude-t.latitude;
    if (delta != 0.0) [t addLatitude:delta];
    delta = newCoordinate.longitude-t.longitude;
    if (delta != 0.0) [t addLongitude:delta];
  }
  [self resetRegion];
}

-(void)resetRegion {
  region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0.0, 0.0), MKCoordinateSpanMake(0.0, 0.0));
  [self getRegion];
}

-(MKCoordinateRegion)getRegion {
  if (region.center.latitude != 0.0) return region;
  double minLat = 0.0;
  double maxLat = 0.0;
  double minLon = 0.0;
  double maxLon = 0.0;
  for (TrackPoint *p in trackSegment.trackPoints) {
    double d = p.latitude;
    if (minLat == 0.0) minLat = maxLat = d;
    else if (d < minLat) minLat = d;
    else if (d > maxLat) maxLat = d;
    d = p.longitude;
    if (minLon == 0.0) minLon = maxLon = d;
    else if (d < minLon) minLon = d;
    else if (d > maxLon) maxLon = d;
  }
  MKCoordinateRegion r;
  r.center.latitude = (minLat+maxLat)/2;
  r.center.longitude = (minLon+maxLon)/2;
  r.span.latitudeDelta = maxLat-minLat;
  r.span.longitudeDelta = maxLon-minLon;
  region = r;
  return r;
}

-(void)deleteTrackPointAtIndex:(int)index {
  [trackSegment deleteTrackPointAtIndex:index];
}

-(void)insertCenterTrackPointAtIndex:(int)index {
  [trackSegment insertCenterTrackPointAtIndex:index];
}

-(NSString *)toString:(NSDateFormatter *)gpxTimeFormat {
  int l = (int)[trackSegment.trackPoints count];
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:l*100+10] autorelease];
  [s appendString:@"   <trkseg>\n"];
  for (TrackPoint *p in trackSegment.trackPoints) {
    [s appendFormat:@"%@\n", [p toString]];
  }
  [s appendString:@"   </trkseg>"];
/*#ifdef DEBUG_MAP
  s = [s stringByReplacingOccurrencesOfString:@"  " withString:@"    "];
#endif*/
  return s;
}

@end
