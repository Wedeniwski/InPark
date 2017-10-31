//
//  MapPin.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "MapPin.h"
#import "Attraction.h"
#import "MenuData.h"
#import "ParkData.h"

@implementation MapPin

@synthesize attractionId, parkId, title, subtitle;
@synthesize coordinate;
@synthesize overlap;

-(id)initWithAttractionId:(NSString *)aId parkId:(NSString *)pId {
  self = [super init];
  if (self != nil) {
    attractionId = [aId retain];
    parkId = [pId retain];
    ParkData *parkData = [ParkData getParkData:parkId];
    TrackPoint *t = [parkData getAttractionLocation:[parkData firstEntryAttractionIdOf:attractionId]];
    if (t == nil) coordinate = (CLLocationCoordinate2D){0, 0};
    else coordinate = (CLLocationCoordinate2D){ t.latitude, t.longitude };
    Attraction *a = [Attraction getAttraction:parkId attractionId:attractionId];
    if (a != nil) {
#ifdef DEBUG_MAP
      if (a.attractionName == NULL) {
        NSLog(@"missing attraction name for %@", attractionId);
        title = nil;
      } else title = (strlen(a.attractionName) > 0)? [[NSString alloc] initWithFormat:@"%@ - %@", attractionId, a.stringAttractionName] : nil;
#else
      if ([parkData isExitAttractionId:attractionId] && ![parkData isEntryOrExitOfPark:attractionId]) title = [[NSString alloc] initWithFormat:NSLocalizedString(@"tour.description.exit.of", nil), a.stringAttractionName];
      else if ([parkData isFastLaneEntryAttractionId:attractionId]) title = [[NSString alloc] initWithFormat:NSLocalizedString(@"tour.description.fastpass.of", nil), parkData.fastLaneId, a.stringAttractionName];
      else title = [a.stringAttractionName copy];
#endif
      subtitle = [a.typeName retain];
    } else {
      subtitle = nil;
#ifdef DEBUG_MAP
      title = [attractionId retain];
#else
      title = @"";
#endif
    }
    overlap = NO;
  }
  return self;
}

-(void)dealloc {
  [attractionId release];
  attractionId = nil;
  [parkId release];
  parkId = nil;
  [title release];
  title = nil;
  [subtitle release];
  subtitle = nil;
  [super dealloc];
}

-(NSUInteger)hash {
  return [attractionId hash];
}

-(NSComparisonResult)compare:(MapPin *)otherMapPin {
  if (coordinate.latitude < otherMapPin.coordinate.latitude) return -1;
  if (coordinate.latitude > otherMapPin.coordinate.latitude) return 1;
  if (coordinate.longitude < otherMapPin.coordinate.longitude) return -1;
  if (coordinate.longitude > otherMapPin.coordinate.longitude) return 1;
  return 0;
}

-(BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[MapPin class]]) return NO;
  MapPin *mapPin = (MapPin *)object;
  return ([attractionId isEqualToString:mapPin.attractionId]);
}

-(void)addLatitude:(double)latitudeDelta {
  [self setCoordinate:CLLocationCoordinate2DMake(coordinate.latitude+latitudeDelta, coordinate.longitude)];
}

-(void)addLongitude:(double)longitudeDelta {
  [self setCoordinate:CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude+longitudeDelta)];
}

-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
  coordinate = newCoordinate;
}

-(BOOL)hasImage {
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  return (attraction != nil && [attraction imageName:parkId] != nil);
}

-(UIImage *)getImage {
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  return (attraction != nil)? [UIImage imageWithContentsOfFile:[attraction imagePath:parkId]] : nil;
}

@end
