//
//  ExtendedTrackPoint.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 17.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "ExtendedTrackPoint.h"

@implementation ExtendedTrackPoint

@synthesize recordTime;

-(id)initWithLatitude:(double)lat longitude:(double)lon elevation:(double)ele accuracy:(double)acc recordTime:(double)rTime {
  self = [super initWithLatitude:lat longitude:lon];
  if (self != nil) {
    elevation = (short)ele;
    accuracy = (short)acc;
    recordTime = rTime;
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self != nil) {
    if ([coder containsValueForKey:@"ELEVATION_INT"]) {
      elevation = (short)[coder decodeIntForKey:@"ELEVATION_INT"];
      accuracy = (short)[coder decodeIntForKey:@"ACCURACY_INT"];
    } else {
      elevation = (short)[coder decodeDoubleForKey:@"ELEVATION"];
      accuracy = (short)[coder decodeDoubleForKey:@"ACCURACY"];
    }
    recordTime = [coder decodeDoubleForKey:@"RECORD_TIME"];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder *)coder {
  [super encodeWithCoder:coder];
  [coder encodeInt:elevation forKey:@"ELEVATION_INT"];
  [coder encodeInt:accuracy forKey:@"ACCURACY_INT"];
  [coder encodeDouble:recordTime forKey:@"RECORD_TIME"];
}

-(NSString *)toString:(NSDateFormatter *)gpxTimeFormat {
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:100] autorelease];
  // ToDo: accuracy
  [s appendFormat:@"    <trkpt lat=\"%.6f\" lon=\"%.6f\">\n    <ele>%d</ele>\n    <!-- accuracy %d -->\n    <time>", latitude/1000000.0, longitude/1000000.0, elevation, accuracy];
  [s appendString:[gpxTimeFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:recordTime]]];
  [s appendString:@"Z</time>\n    </trkpt>"];
  return s;
}

-(double)elevation {
  return elevation;
}

-(double)accuracy {
  return accuracy;
}

@end
