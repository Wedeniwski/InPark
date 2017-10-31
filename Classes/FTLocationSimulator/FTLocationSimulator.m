//
//  FTLocationSimulator.m
//
//  Created by Ortwin Gentz on 23.09.2010.
//  Copyright 2010 FutureTap http://www.futuretap.com
//  All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.

#import "FTLocationSimulator.h"
#import "FTSynthesizeSingleton.h"
//#import "RegexKitLite.h"

@implementation FTLocationSimulator

SYNTHESIZE_SINGLETON_FOR_CLASS(FTLocationSimulator)

@synthesize location;
@synthesize oldLocation;
@synthesize delegate;
@synthesize distanceFilter;
@synthesize purpose;
@synthesize mapView;

-(void)dealloc {
	[mapView release];
	mapView = nil;
	[location release];
	location = nil;

	[purpose release];
	purpose = nil;
	[fakeLocations release];
  fakeLocations = nil;
	[super dealloc];
}

- (void)fakeNewLocation {
	if (!updatingLocation) return;
	// read and parse the KML file
	if (!fakeLocations) {
    NSMutableArray *coordinates = [[NSMutableArray alloc] initWithCapacity:600];
#ifdef FAKE_LOCATION_LAT
    [coordinates addObject:[NSString stringWithFormat:@"%f %f", FAKE_LOCATION_LAT, FAKE_LOCATION_LON]];
#else
    NSString *fakeLocationsPath = FAKE_LOCATION_PATH;//[[NSBundle mainBundle] pathForResource:@"fakeLocations" ofType:@"kml"];
    NSError *error = nil;
		NSString *fakeLocationsFile = [[NSString alloc] initWithContentsOfFile:fakeLocationsPath encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) NSLog(@"Fake location path %@ could not be read (%@)", fakeLocationsPath, [error localizedDescription]);
    NSRange range1 = [fakeLocationsFile rangeOfString:@"<trkpt lat=\""];
    while (range1.length > 0) {
      NSRange range2;
      range2.location = range1.location+range1.length;
      range2.length = [fakeLocationsFile length] - range2.location;
      range2 = [fakeLocationsFile rangeOfString:@"\">" options:NSCaseInsensitiveSearch range:range2];
      range1.location += range1.length;
      range1.length = range2.location-range1.location;
      NSString *coordinate = [fakeLocationsFile substringWithRange:range1];
      coordinate = [coordinate stringByReplacingOccurrencesOfString:@"\" lon=\"" withString:@" "];
      [coordinates addObject:coordinate];
      range2.location += range2.length;
      range2.length = [fakeLocationsFile length] - range2.location;
      range1 = [fakeLocationsFile rangeOfString:@"<trkpt lat=\"" options:NSCaseInsensitiveSearch range:range2];
    }
		/*NSString *coordinatesString = [fakeLocationsFile stringByMatching:@"<coordinates>[^-0-9]*(.+?)[^-0-9]*</coordinates>"
     options:RKLMultiline|RKLDotAll
     inRange:NSMakeRange(0, fakeLocationsFile.length)
     capture:1
     error:NULL];*/
		[fakeLocationsFile release];
#endif
		fakeLocations = coordinates;//[[coordinatesString componentsSeparatedByString:@" "] retain];
		updateInterval = FAKE_CORE_LOCATION_UPDATE_INTERVAL;
	}
	
	// select a new fake location
	NSArray *latLong = [[fakeLocations objectAtIndex:index] componentsSeparatedByString:@" "];
	CLLocationDegrees lat = [[latLong objectAtIndex:0] doubleValue];
	CLLocationDegrees lon = [[latLong objectAtIndex:1] doubleValue];

#ifdef FAKE_LOCATION_UP_TO_LAT
  static BOOL fakeLocationFound = NO;
  while (!fakeLocationFound && (fabs(FAKE_LOCATION_UP_TO_LAT-lat) > 0.000001 || fabs(FAKE_LOCATION_UP_TO_LON-lon) > 0.000001)) {
    if (++index >= fakeLocations.count) {
      index = 0;
      fakeLocationFound = YES;
    }
    latLong = [[fakeLocations objectAtIndex:index] componentsSeparatedByString:@" "];
    lat = [[latLong objectAtIndex:0] doubleValue];
    lon = [[latLong objectAtIndex:1] doubleValue];
  }
  fakeLocationFound = YES;
#endif
  NSLog(@"New location lat=%.6f lon=%.6f", lat, lon);
  self.location = [[[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon)
												   altitude:0
										 horizontalAccuracy:0
										   verticalAccuracy:0
												  timestamp:[NSDate date]] autorelease];
	
	// update the userlocation view
	if (self.mapView) {
		MKAnnotationView *userLocationView = [self.mapView viewForAnnotation:self.mapView.userLocation];
		[userLocationView.superview sendSubviewToBack:userLocationView];
		
 		CGRect frame = userLocationView.frame;
		frame.origin = [self.mapView convertCoordinate:self.location.coordinate toPointToView:userLocationView.superview];
		frame.origin.x -= 10;
		frame.origin.y -= 10;
		[UIView beginAnimations:@"fakeUserLocation" context:nil];
		[UIView setAnimationDuration:updateInterval];
		[UIView setAnimationCurve:UIViewAnimationCurveLinear];
		userLocationView.frame = frame;
		[UIView commitAnimations];

		[self.mapView.userLocation setCoordinate:self.location.coordinate];
	}

	// inform the locationManager delegate
	if((!self.oldLocation || [self.location distanceFromLocation:oldLocation] > distanceFilter) &&
	   [self.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
		[self.delegate locationManager:nil
				   didUpdateToLocation:self.location
						  fromLocation:oldLocation];
		self.oldLocation = self.location;
	}
	
	// iterate to the next fake location
	if (updatingLocation) {
		index++;
		if (index == fakeLocations.count) {
			index = 0;
		}
		[self performSelector:@selector(fakeNewLocation) withObject:nil afterDelay:updateInterval];
	}
}

- (void)startUpdatingLocation {
  NSLog(@"startUpdatingLocation");
	updatingLocation = YES;
	[self fakeNewLocation];
}

- (void)stopUpdatingLocation {
  NSLog(@"stopUpdatingLocation");
	updatingLocation = NO;
}

- (MKAnnotationView*)fakeUserLocationView {
	if (!self.mapView) {
		return nil;
	}

	[self.mapView.userLocation setCoordinate:self.location.coordinate];
	MKAnnotationView *userLocationView = [[[MKAnnotationView alloc] initWithAnnotation:self.mapView.userLocation reuseIdentifier:nil] autorelease];
	[userLocationView addSubview:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TrackingDot.png"]] autorelease]];
	userLocationView.centerOffset = CGPointMake(-10, -10);
	return userLocationView;
}


// dummy methods to keep the CLLocationManager interface
+ (BOOL)locationServicesEnabled {
	return [FTLocationSimulator sharedInstance].locationServicesEnabled;
}
+ (BOOL)headingAvailable {
	return NO;
}
+ (BOOL)significantLocationChangeMonitoringAvailable {
	return NO;
}
+ (BOOL)regionMonitoringAvailable {
	return NO;
}
+ (BOOL)regionMonitoringEnabled {
	return NO;
}
+ (CLAuthorizationStatus)authorizationStatus {
	return kCLAuthorizationStatusAuthorized;
}
- (BOOL)locationServicesEnabled {
	return updatingLocation;
}
- (CLLocationAccuracy) desiredAccuracy {
	return kCLLocationAccuracyBest;
}
- (void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
}
- (BOOL)headingAvailable {
	return NO;
}
- (CLLocationDegrees) headingFilter {
	return kCLHeadingFilterNone;
}
- (void)setHeadingFilter:(CLLocationDegrees)headingFilter {
}
- (CLDeviceOrientation) headingOrientation {
	return CLDeviceOrientationPortrait;
}
- (void)setHeadingOrientation:(CLDeviceOrientation)headingOrientation {
}
- (CLHeading*) heading {
	return nil;
}
- (CLLocationDistance) maximumRegionMonitoringDistance {
	return kCLErrorRegionMonitoringFailure;
}
- (NSSet*)monitoredRegions {
	return nil;
}
- (void)startUpdatingHeading {
}
- (void)stopUpdatingHeading {
}
- (void)dismissHeadingCalibrationDisplay {
}
- (void)startMonitoringSignificantLocationChanges {
}
- (void)stopMonitoringSignificantLocationChanges {
}
- (void)startMonitoringForRegion:(CLRegion*)region desiredAccuracy:(CLLocationAccuracy)accuracy {
}
- (void)stopMonitoringForRegion:(CLRegion*)region {
}
@end
