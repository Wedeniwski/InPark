//
//  MapPin.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TrackPoint.h"

@interface MapPin : NSObject <MKAnnotation> {
  NSString *attractionId;
  NSString *parkId;
  NSString *title;
  NSString *subtitle;
  CLLocationCoordinate2D coordinate;
  BOOL overlap;
}

-(id)initWithAttractionId:(NSString *)aId parkId:(NSString *)pId;
-(NSComparisonResult)compare:(MapPin *)otherMapPin;
//-(BOOL)isEqual:(id)object;

-(void)addLatitude:(double)latitudeDelta;
-(void)addLongitude:(double)longitudeDelta;
-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;
-(BOOL)hasImage;
-(UIImage *)getImage;

@property (readonly, nonatomic) NSString *attractionId;
@property (readonly, nonatomic) NSString *parkId;
@property (readonly, nonatomic, copy) NSString *title;
@property (readonly, nonatomic, copy) NSString *subtitle;
@property BOOL overlap;

@end