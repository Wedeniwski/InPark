//
//  SettingsData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 06.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SettingsData : NSObject {
  BOOL shouldSkipVersion;
  NSString *skippedVersion;
  NSString *didDetectAppUpdate;
  NSString *releaseNotesKnown;
  BOOL profileKnown;
  BOOL visitNotesKnown;
  BOOL timeIs24HourFormat;
  short maxNumberOfSameAttractionInTour;
  NSString *language;
  char screenDisplay;  // P - Portrait, L - Left-handed landscape, R - Right-handed landscape
  char unitsOfMeasure;  // M - Metric, I - Imperial
  char mapType; // O - Overlay, T - Standard, S - Satellite, H - Hybrid
  short distanceThreshold;  // Determines the minimum distance in meters to travel before a new track point is recorded.
  short accuracyThreshold;  // GPS_ACCURACY_THRESHOLD
  BOOL locationService;  // GPS_ENABLED
  BOOL compass; // COMPASS_ENABLED
  short parkDataUpdate; // PARK_DATA_UPDATE
  short calendarDataUpdate; // CALENDAR_DATA_UPDATE: -1 - manually, else number of days
  char parkDataUpdateScope; // PARK_DATA_SCOPE: A - all, I - installed, C - installed countries
  short newsUpdate; // NEWS_UPDATE: -1 - manually, else number of days
  short waitingTimesUpdate; // WAITING_TIMES_UPDATE
}

-(id)init;
+(NSSet *)optionalSettings;
-(void)setShouldSkipVersion:(BOOL)shouldSkip;
-(void)setSkippedVersion:(NSString *)version;
-(void)setReleaseNotesKnown:(NSString *)releaseVersion;
-(void)setProfileKnown:(BOOL)isProfileKnown;
-(void)setVisitNotesKnown:(BOOL)isVisitNotesKnown;
-(BOOL)isLocationServiceEnabled;
-(void)setLocationService:(BOOL)enabled;
-(BOOL)isPortraitScreen;
-(BOOL)isLeftHandedLandscapeScreen;
-(BOOL)isRightHandedLandscapeScreen;
-(BOOL)isMetricMeasure;
-(BOOL)setMapType:(char)mType;
-(BOOL)isMapTypeOverlay;
-(BOOL)isMapTypeStandard;
-(BOOL)isMapTypeSatellite;
-(BOOL)isMapTypeHybrid;
-(BOOL)isParkDataUpdateManually;
-(int)getParkDataUpdateDays;
-(BOOL)considerAllParkDataUpdate;
-(BOOL)considerOnyInstalledParkDataUpdate;
-(BOOL)considerOnyInstalledCountriesParkDataUpdate;
-(NSString *)shortLanguagePath;
-(NSString *)longLanguagePath;
-(NSString *)languagePath;
-(void)save;
-(void)setDefaultLanguageSettings;
+(SettingsData *)getSettingsData:(BOOL)reload;
+(SettingsData *)getSettingsData;
+(NSString *)getAppVersion;
+(NSString *)getAppVersionLong;
+(NSString *)currentLanguage;

@property (readonly) BOOL shouldSkipVersion;
@property (readonly, nonatomic) NSString *skippedVersion;
@property (retain, nonatomic) NSString *didDetectAppUpdate;
@property (readonly, nonatomic) NSString *releaseNotesKnown;
@property (readonly) BOOL profileKnown;
@property (readonly) BOOL visitNotesKnown;
@property (readonly) BOOL timeIs24HourFormat;
@property (readonly) short maxNumberOfSameAttractionInTour;
@property (readonly) char unitsOfMeasure;
@property (readonly) short distanceThreshold;
@property (readonly) short accuracyThreshold;
@property (readonly) BOOL compass;
@property (readonly) short calendarDataUpdate;
@property (readonly) short newsUpdate;
@property (readonly) short waitingTimesUpdate;

@end
