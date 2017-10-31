//
//  ExtendedTrackPoint.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 17.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrackPoint.h"

@interface ExtendedTrackPoint : TrackPoint <NSCoding> {
  short elevation;
  short accuracy;
  double recordTime;  // number of seconds since January 1, 1970, 00:00:00 GMT
}

-(id)initWithLatitude:(double)lat longitude:(double)lon elevation:(double)ele accuracy:(double)acc recordTime:(double)rTime;
-(NSString *)toString:(NSDateFormatter *)gpxTimeFormat;
-(double)elevation;
-(double)accuracy;

@property (readonly) double recordTime;

@end
