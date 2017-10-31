//
//  LocationData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 06.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "LocationData.h"
#import "TrackPoint.h"
#import "SettingsData.h"
#import "CalendarData.h"
#import "Conversions.h"
#import "Colors.h"

@implementation LocationData

@synthesize started, active;
@synthesize distanceThreshold;
//@synthesize lastRecordedLocation; 
@synthesize lastUpdatedLocation;
@synthesize locationManager;
@synthesize lastError;

#pragma mark -
#pragma mark Memory management

-(id)init {
  self = [super init];
  if (self != nil) {
    started = NO;
    active = NO;
    startAccuracy = 600;
#ifdef FAKE_CORE_LOCATION
    locationManager = [[FTLocationSimulator alloc] init];
#else
    locationManager = [[CLLocationManager alloc] init];
#endif
    NSLog(@"Init Location Data");
    locationManager.delegate = self;
    lastRecordedLocation = nil;
    lastUpdatedLocation = nil;
    parkId = nil;
    trackData = nil;
    lastError = nil;
    registeredViewController = nil;
    [self loadSettings];
  }
  return self;
}

-(void)dealloc {
  NSLog(@"Dealloc Location Data");
  [self stop];
  [lastRecordedLocation release];
  lastRecordedLocation = nil;
  [lastUpdatedLocation release];
  lastUpdatedLocation = nil;
  [parkId release];
  parkId = nil;
  [trackData release];
  trackData = nil;
  [lastError release];
  lastError = nil;
  registeredViewController = nil;
  [locationManager release];
  locationManager = nil;
  [super dealloc];
}

static LocationData *locationData = nil;

+(void)releaseLocationData {
  @synchronized([LocationData class]) {
    if (locationData != nil) {
      if (locationData.active || CLLocationManager.locationServicesEnabled) [locationData stop];
      [locationData release];
      locationData = nil;
    }
  }
}

+(BOOL)isLocationDataInitialized {
  @synchronized([LocationData class]) {
    return (locationData != nil);
  }
}

+(BOOL)isLocationDataStarted {
  @synchronized([LocationData class]) {
    return (locationData != nil && CLLocationManager.locationServicesEnabled && locationData.started);
  }
}

+(BOOL)isLocationDataActive {
  @synchronized([LocationData class]) {
    return (locationData != nil && locationData.active);
  }
}

+(LocationData *)getLocationData {
  @synchronized([LocationData class]) {
    if (locationData == nil) {
      locationData = [[LocationData alloc] init];
    }
  }
  return locationData;
}

#pragma mark -
#pragma mark Location manager

-(BOOL)isDataPoolRegistered:(NSString *)pId {
  @synchronized([LocationData class]) {
    return (trackData != nil && parkId != nil && [parkId isEqualToString:pId]);
  }
}

-(void)registerDataPool:(TrackData *)data parkId:(NSString *)pId {
  @synchronized([LocationData class]) {
    [trackData release];
    trackData = [data retain];
    [parkId release];
    parkId = [pId retain];
  }
}

-(void)unregisterDataPool:(NSString *)pId {
  @synchronized([LocationData class]) {
    if (pId == nil || (parkId != nil && ![parkId isEqualToString:pId])) {
      NSLog(@"unregister recorded locations for parkId %@", parkId);
      [trackData release];
      trackData = nil;
      [lastRecordedLocation release];
      lastRecordedLocation = nil;
      [parkId release];
      parkId = nil;
    }
  }
}

-(void)registerViewController:(id<LocationDataDelegate>)viewController {
  @synchronized([LocationData class]) {
    registeredViewController = viewController;
  }
}

-(void)unregisterViewController {
  @synchronized([LocationData class]) {
    registeredViewController = nil;
  }
}

-(void)loadSettings {
  @synchronized([LocationData class]) {
    if (locationData != nil) {
      SettingsData *settings = [SettingsData getSettingsData];
      locationData.distanceThreshold = settings.distanceThreshold;
      int accuracy = accuracyThreshold = settings.accuracyThreshold;
      if (accuracy <= 10) locationData.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
      else if (accuracy <= 20) locationData.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
      else if (accuracy < 100) locationData.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
      else locationData.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
      locationData.locationManager.distanceFilter = kCLDistanceFilterNone;
    }
  }
}

+(void)settingsChanged {
  LocationData *locData = [LocationData getLocationData];
  [locData loadSettings];
}

#ifdef DEBUG_LOCATION
-(void)startUpdatingLocation {
  CLLocation *newLocation = [[[CLLocation alloc] initWithLatitude:48.2683 longitude:7.72354] autorelease];
  [self locationManager:locationManager didUpdateToLocation:newLocation fromLocation:newLocation];    
}
#endif

-(void)start {
  @synchronized([LocationData class]) {
    if (!started) {
      started = YES;
      startAccuracy = 600;
      [self loadSettings];
      NSLog(@"Start Location Data with accuracy threashold %d", accuracyThreshold);
      [locationManager startUpdatingLocation];
      SettingsData *settings = [SettingsData getSettingsData];
      [settings setLocationService:YES];
    }
  }
}

-(void)stop {
  @synchronized([LocationData class]) {
    if (active) {
      [locationManager stopUpdatingLocation];
      NSLog(@"Stop Location Data: %d", CLLocationManager.locationServicesEnabled);
      active = NO;
      started = NO;
      SettingsData *settings = [SettingsData getSettingsData];
      [settings setLocationService:NO];
    }
  }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
  [lastError release];
  lastError = nil;
  CLLocationAccuracy acc = newLocation.horizontalAccuracy;
  if (acc >= 0 && (acc < startAccuracy || acc <= 2*accuracyThreshold+20) && CLLocationCoordinate2DIsValid(newLocation.coordinate)) {
    if (acc < startAccuracy) startAccuracy = acc;
    locationManager.distanceFilter = (acc <= accuracyThreshold)? distanceThreshold : kCLDistanceFilterNone;
    active = YES;
    if (lastUpdatedLocation == nil || lastUpdatedLocation.coordinate.latitude != newLocation.coordinate.latitude || lastUpdatedLocation.coordinate.longitude != newLocation.coordinate.longitude || acc < lastUpdatedLocation.horizontalAccuracy) {
      [lastUpdatedLocation release];
      lastUpdatedLocation = [newLocation retain];
      @synchronized([LocationData class]) {
        if (trackData != nil) {
          [trackData addTrackPoint:newLocation];
          [lastRecordedLocation release];
          lastRecordedLocation = [newLocation retain];
        } else if (lastRecordedLocation != nil) {
          [lastRecordedLocation release];
          lastRecordedLocation = nil;
        }
        if (registeredViewController != nil) [registeredViewController didUpdateLocationData];
      }
    }
  }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
  NSString *newError = nil;
  switch ([error code]) {
    case kCLErrorNetwork:
      newError = NSLocalizedString(@"location.error.network", nil);
      break;
    case kCLErrorDenied:
      newError = NSLocalizedString(@"location.error.denied", nil);
      break;
    /*case kCLErrorHeadingFailure:
      newError = NSLocalizedString(@"location.error.heading", nil);
      break;*/
    default:
      newError = NSLocalizedString(@"location.error.general", nil);
      break;
  }
  NSLog(@"Location manager error %@ (%@)", newError, [error localizedDescription]);
  if (lastError == nil || ![newError isEqualToString:lastError]) {
    [lastError release];
    lastError = [newError retain];
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"location.error", nil)
                           message:lastError
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  }
  if (registeredViewController != nil && [registeredViewController respondsToSelector:@selector(didUpdateLocationError)]) {
    [registeredViewController didUpdateLocationError];
  }
}

#pragma mark -
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
}

+(void)setAccuracyLabel:(UILabel *)accuracyLabel forParkData:(ParkData *)parkData addTime:(BOOL)addTime {
  if ([LocationData isLocationDataActive]) {
    LocationData *locData = [LocationData getLocationData];
    accuracyLabel.hidden = NO;
    accuracyLabel.tag = 0;
    if (locData.lastUpdatedLocation != nil) {
      double accuracy = locData.lastUpdatedLocation.horizontalAccuracy;
      if (accuracy < 0.0) {
        accuracyLabel.text = NSLocalizedString(@"tour.accuracy.invalid", nil);
        accuracyLabel.textColor = [Colors lightText];
      } else if (![parkData isCurrentlyInsidePark]) {
        accuracyLabel.text = NSLocalizedString(@"tour.accuracy.not.inside.park", nil);
        accuracyLabel.textColor = [Colors lightText];
        accuracyLabel.tag = 1;
      } else {
        SettingsData *settings = [SettingsData getSettingsData];
        NSString *s = nil;
        if ([settings isMetricMeasure]) {
          s = [NSString stringWithFormat:NSLocalizedString(@"tour.accuracy", nil), (int)accuracy];
        } else {
          s = [NSString stringWithFormat:NSLocalizedString(@"tour.accuracy.imperial", nil), (int)convertMetersToFeet(accuracy)];
        }
        accuracyLabel.text = (addTime)? [NSString stringWithFormat:@"%@ (%@)", s, [CalendarData stringFromTimeLong:[NSDate date] considerTimeZoneAbbreviation:nil]] : s;
        accuracyLabel.textColor = [Colors hilightText];
      }
    }
  } else {
    accuracyLabel.hidden = YES;
  }
}

@end
