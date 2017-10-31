//
//  TrackPoint.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 18.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "CompileSettings.h"
#import <Foundation/Foundation.h>

double distance(double lat1, double lon1, double lat2, double lon2);

@interface TrackPoint : NSObject <NSCoding> {
  int latitude;
  int longitude;
}

-(id)initWithLatitude:(double)lat longitude:(double)lon;
-(BOOL)isEqual:(id)object;
+(double)distanceFrom:(TrackPoint *)fromTrackPoint to:(TrackPoint *)toTrackPoint;
-(double)distanceTo:(TrackPoint *)trackPoint;
-(void)addLatitude:(double)latitudeDelta;
-(void)addLongitude:(double)longitudeDelta;
-(NSString *)toString;
-(double)latitude;
-(double)longitude;
-(int)latitudeInt;
-(int)longitudeInt;

@end
