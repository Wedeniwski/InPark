//
//  LocationData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 06.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "TrackData.h"
#import "ParkData.h"

#ifdef FAKE_CORE_LOCATION
#import "FTLocationSimulator.h"
#endif

@protocol LocationDataDelegate <NSObject>
-(void)didUpdateLocationData;

@optional
-(void)didUpdateLocationError;
@end

@interface LocationData : NSObject <CLLocationManagerDelegate> {
  BOOL started;
  BOOL active;
  int distanceThreshold;
  int accuracyThreshold;
  int startAccuracy;
  CLLocation *lastRecordedLocation;
  CLLocation *lastUpdatedLocation;
#ifdef FAKE_CORE_LOCATION
  FTLocationSimulator *locationManager;
#else
  CLLocationManager *locationManager;
#endif
  NSString *parkId;
  TrackData *trackData;
  NSString *lastError;
  id<LocationDataDelegate> registeredViewController;
}

-(id)init;
+(void)releaseLocationData;
+(BOOL)isLocationDataInitialized;
+(BOOL)isLocationDataStarted;
+(BOOL)isLocationDataActive;
+(LocationData *)getLocationData;
-(BOOL)isDataPoolRegistered:(NSString *)parkId;
-(void)registerDataPool:(TrackData *)data parkId:(NSString *)parkId;
-(void)unregisterDataPool:(NSString *)parkId;
-(void)registerViewController:(id<LocationDataDelegate>)viewController;
-(void)unregisterViewController;
-(void)loadSettings;
+(void)settingsChanged;
-(void)start;
-(void)stop;

+(void)setAccuracyLabel:(UILabel *)accuracyLabel forParkData:(ParkData *)parkData addTime:(BOOL)addTime;

@property (readonly) BOOL started;
@property (readonly) BOOL active;
@property int distanceThreshold;
//@property (readonly, nonatomic) CLLocation *lastRecordedLocation;
@property (readonly, nonatomic) CLLocation *lastUpdatedLocation;
#ifdef FAKE_CORE_LOCATION
@property (readonly, nonatomic) FTLocationSimulator *locationManager;
#else
@property (readonly, nonatomic) CLLocationManager *locationManager;
#endif
@property (readonly, nonatomic) NSString *lastError;

@end
