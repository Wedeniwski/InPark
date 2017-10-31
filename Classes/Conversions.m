//
//  Conversions.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 07.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "Conversions.h"
#import "Attraction.h"
#import "ParkData.h"
#import "SettingsData.h"

// 5,280 feet (ft) in a mile
// 1 mile (mi) = 1,609.344 meters
// 1 foot = 0.3048 meters
MileFeet convertMetricToImperial(double meters) {
  MileFeet mf;
  double ft = meters/0.3048;
  int mi = ft/528;
  ft -= mi*528.0;
  mf.feet = ft; mf.mile = mi*0.1;
  return mf;
}

double convertMetersToMiles(double meters) {
  return meters/1609.344;
}

double convertMetersToFeet(double meters) {
  return meters/0.3048;
}

double convertMetersToInches(double meters) {
  return meters*39.370078740157477;
}

double inchesToFeet(double inches) {
  return inches/12;
}

double feetToInches(double feet) {
  return feet*12;
}

NSString * distanceToString(BOOL metric, double value) {
  if (metric) {
    if (value >= 1000.0) return [NSString stringWithFormat:NSLocalizedString(@"tour.distance.value.km", nil), value/1000.0];
    else return [NSString stringWithFormat:NSLocalizedString(@"tour.distance.value", nil), (int)value];
  }
  double miles = convertMetersToMiles(value);
  return (miles < 0.1)? [NSString stringWithFormat:NSLocalizedString(@"tour.distance.value.imperial.feet", nil), convertMetersToFeet(value)] : [NSString stringWithFormat:NSLocalizedString(@"tour.distance.value.imperial", nil), miles];
}

NSString * imperialSize(double metricSizeInMeter, BOOL roundBelow) {
  double inches = convertMetersToInches(metricSizeInMeter);
  double ft = 0.0;//floor(inchesToFeet(inches));
  //inches -= feetToInches(ft);
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:20] autorelease];
  //NSLog(@"metricSizeInMeter: %f - inches: %f - roundBelow: %d", metricSizeInMeter, inches, roundBelow);
  if (roundBelow) {
    if (ft > 0.0) [s appendFormat:@"%d ft", (int)ft];
    int f = floor(inches);
    inches -= f;
    if (f <= 0) {
      if (inches > 0.8) [s appendString:@" 1\""];
      else if (inches > 0.55) [s appendString:@" &#190;\""];
      else if (inches > 0.35) [s appendString:@" &#189;\""];
      else if (inches >= 0.2) [s appendString:@" &#188;\""];
      else [s appendString:@" 0\""];
    } else {
      if (inches > 0.8) [s appendFormat:@" %d", (f+1)];
      else if (inches > 0.55) [s appendFormat:@" %d&#190;", f];
      else if (inches > 0.35) [s appendFormat:@" %d&#189;", f];
      else if (inches >= 0.2) [s appendFormat:@" %d&#188;", f];
      else [s appendFormat:@" %d", f];
      [s appendString:@"\""];
    }
  } else {
    if (ft > 0.0) [s appendFormat:@"%d ft", (int)ft];
    int f = floor(inches);
    inches -= f;
    if (f <= 0) {
      if (inches >= 0.2) {
        if (inches <= 0.35) [s appendString:@" &#188;\""];
        else if (inches <= 0.55) [s appendString:@" %d&#189;\""];
        else if (inches <= 0.8) [s appendString:@" %d&#190;\""];
        else [s appendString:@" 1\""];
      } else [s appendString:@" 0\""];
    } else {
      if (inches >= 0.2) {
        if (inches <= 0.35) [s appendFormat:@" %d&#188;", f];
        else if (inches <= 0.55) [s appendFormat:@" %d&#189;", f];
        else if (inches <= 0.8) [s appendFormat:@" %d&#190;", f];
        else [s appendFormat:@" %d", (f+1)];
      } else [s appendFormat:@" %d", f];
      [s appendString:@"\""];
    }
  }
  return s;
}

NSString * getCurrentDistance(NSString *parkId, NSString *attractionId, double *distance) {
  ParkData *parkData = [ParkData getParkData:parkId];
  if (parkData.currentTrackData == nil || [parkData.currentTrackData walkToEntry]) {
    double tolerance = 0.0;
    NSString *distanceFromAttractionId = nil;
    *distance = [parkData currentDistanceToAll:attractionId tolerance:&tolerance fromAttractionId:&distanceFromAttractionId];
    if (*distance >= 1.0 && (distanceFromAttractionId == nil || ![distanceFromAttractionId isEqualToString:attractionId])) {
      SettingsData *settings = [SettingsData getSettingsData];
      NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:60] autorelease];
      //[s appendString:NSLocalizedString(@"distance", nil)];
      //[s appendString:@" "];
      [s appendString:distanceToString([settings isMetricMeasure], *distance)];
      [s appendString:@" "];
      NSString *distanceSuffix = nil;
      if (distanceFromAttractionId == nil) {
        distanceSuffix = NSLocalizedString(@"distance.position", nil);
      } else {
        Attraction *distanceAttraction = [Attraction getAttraction:parkId attractionId:distanceFromAttractionId];
        if (distanceAttraction != nil) {
          distanceSuffix = [NSString stringWithFormat:NSLocalizedString(@"distance.position.from", nil), distanceAttraction.stringAttractionName];
        }
      }
      [s appendString:distanceSuffix];
      return s;
    }
  }
  *distance = -1.0;
  return @"";
}

