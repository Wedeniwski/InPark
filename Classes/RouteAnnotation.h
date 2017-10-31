//
//  RouteAnnotation.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 21.06.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "TrackSegment.h"

@interface RouteAnnotation : NSObject <MKAnnotation> {
  MKCoordinateRegion region;
  TrackSegment *trackSegment;
  CLLocationCoordinate2D coordinate;
}

-(id)initWithTrackSegment:(TrackSegment *)segment;

-(NSString *)title;
-(NSString *)subtitle;
-(void)addLatitude:(double)latitudeDelta atIndex:(int)index;
-(void)addLongitude:(double)longitudeDelta atIndex:(int)index;
-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate atIndex:(int)index;

-(void)resetRegion;
-(MKCoordinateRegion)getRegion;
-(void)deleteTrackPointAtIndex:(int)index;
-(void)insertCenterTrackPointAtIndex:(int)index;
-(NSString *)toString:(NSDateFormatter *)gpxTimeFormat;

@property (nonatomic, readonly) TrackSegment *trackSegment;

@end
