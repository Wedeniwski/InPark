//
//  Conversions.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 07.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
  double mile;
  double feet;
} MileFeet;

// 5,280 feet (ft) in a mile
// 1 mile (mi) = 1,609.344 meters
// 1 foot = 0.3048 meters
MileFeet convertMetricToImperial(double meters);
double convertMetersToMiles(double meters);
double convertMetersToFeet(double meters);
double convertMetersToInches(double meters);
double inchesToFeet(double inches);
double feetToInches(double feet);

NSString * distanceToString(BOOL metric, double value);

NSString * imperialSize(double metricSizeInMeter, BOOL roundBelow);
//+(NSString *)imperialSize:(int)metricSizeInMeter roundBelow:(BOOL)roundBelow;

NSString * getCurrentDistance(NSString *parkId, NSString *attractionId, double *distance);
