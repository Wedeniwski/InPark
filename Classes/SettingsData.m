//
//  SettingsData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 06.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "SettingsData.h"
#import "InAppSetting.h"
#import "MenuData.h"

@implementation SettingsData

@synthesize shouldSkipVersion;
@synthesize skippedVersion, didDetectAppUpdate, releaseNotesKnown;
@synthesize profileKnown, visitNotesKnown, timeIs24HourFormat;
@synthesize maxNumberOfSameAttractionInTour;
@synthesize unitsOfMeasure;
@synthesize distanceThreshold, accuracyThreshold;
@synthesize compass;
@synthesize calendarDataUpdate, newsUpdate, waitingTimesUpdate;

-(InAppSetting *)getSettingForKey:(NSString *)key {
  NSArray *a = [MenuData getRootKey:@"PreferenceSpecifiers" languagePath:[self languagePath]];
  for (NSDictionary *d in a) {
    NSString *k = [d objectForKey:@"Key"];
    if (k != nil && [k isEqualToString:key]) {
      return [[[InAppSetting alloc] initWithDictionary:d] autorelease];
    }
  }
  return nil;
}

// ToDo: NOT fix
+(NSSet *)optionalSettings {
  static NSSet *settings = nil;
  if (settings == nil) {
    settings = [[NSSet alloc] initWithObjects:@"GPS_DISTANCE_THRESHOLD", @"PARK_DATA_SCOPE", nil];
  }
  return settings;
}

-(void)setSetting:(InAppSetting *)setting {
  NSString *key = [setting key];
  if (key != nil) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([key isEqualToString:@"MAX_NUMBER_OF_SAME_ATTRACTION_IN_TOUR"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) maxNumberOfSameAttractionInTour = [n shortValue];
    } else if ([key isEqualToString:@"SCREEN_DISPLAY"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil && [s length] > 0) screenDisplay = (char)[s characterAtIndex:0];
    } else if ([key isEqualToString:@"UNITS_OF_MEASURE"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil && [s length] > 0) unitsOfMeasure = (char)[s characterAtIndex:0];
    } else if ([key isEqualToString:@"MAP_TYPE"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil && [s length] > 0) mapType = (char)[s characterAtIndex:0];
    } else if ([key isEqualToString:@"GPS_DISTANCE_THRESHOLD"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) distanceThreshold = [n shortValue];
    } else if ([key isEqualToString:@"GPS_ACCURACY_THRESHOLD"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) accuracyThreshold = [n shortValue];
    } else if ([key isEqualToString:@"GPS_ENABLED"]) {
      NSNumber *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil) locationService = [s boolValue];
    } else if ([key isEqualToString:@"COMPASS_ENABLED"]) {
      NSNumber *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil) compass = [s boolValue];
    } else if ([key isEqualToString:@"PARK_DATA_UPDATE"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) parkDataUpdate = [n shortValue];
    } else if ([key isEqualToString:@"PARK_DATA_SCOPE"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil && [s length] > 0) parkDataUpdateScope = (char)[s characterAtIndex:0];
    } else if ([key isEqualToString:@"CALENDAR_DATA_UPDATE"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) calendarDataUpdate = [n shortValue];
    } else if ([key isEqualToString:@"NEWS_UPDATE"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) newsUpdate = [n shortValue];
    } else if ([key isEqualToString:@"WAITING_TIMES_UPDATE"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) waitingTimesUpdate = [n shortValue];
    }
  }
}

-(id)init {
  self = [super init];
  if (self != nil) {
    language = [[SettingsData currentLanguage] retain];
    didDetectAppUpdate = nil;
    compass = NO; // COMPASS_ENABLED
    calendarDataUpdate = 1; // CALENDAR_DATA_UPDATE
    newsUpdate = 1; // NEWS_UPDATE
    waitingTimesUpdate = 5; // WAITING_TIMES_UPDATE
    maxNumberOfSameAttractionInTour = 5; // MAX_NUMBER_OF_SAME_ATTRACTION_IN_TOUR
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    shouldSkipVersion = [defaults boolForKey:@"SKIP_VERSION"]; // default NO if undefined
    skippedVersion = [[defaults stringForKey:@"SKIPPED_VERSION"] retain];
    releaseNotesKnown = [[defaults stringForKey:@"RELEASE_NOTES_KNOWN"] retain];
    profileKnown = [defaults boolForKey:@"PROFILE_KNOWN"];
    visitNotesKnown = [defaults boolForKey:@"VISIT_NOTES_KNOWN"];
    NSArray *a = [MenuData getRootKey:@"PreferenceSpecifiers" languagePath:[self languagePath]];
    for (NSDictionary *d in a) {
      InAppSetting *b = [[InAppSetting alloc] initWithDictionary:d];
      [self setSetting:b];
      [b release];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    timeIs24HourFormat = (amRange.location == NSNotFound && pmRange.location == NSNotFound);
    [formatter release];
    NSLog(@"24-Hour Time: %d", timeIs24HourFormat);
  }
  return self;
}

-(void)dealloc {
  [language release];
  language = nil;
  [skippedVersion release];
  skippedVersion = nil;
  [releaseNotesKnown release];
  releaseNotesKnown = nil;
  [didDetectAppUpdate release];
  didDetectAppUpdate = nil;
  [super dealloc];
}

-(void)setShouldSkipVersion:(BOOL)shouldSkip {
  shouldSkipVersion = shouldSkip;
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:shouldSkipVersion forKey:@"SKIP_VERSION"];
  [defaults synchronize];
}

-(void)setSkippedVersion:(NSString *)version {
  [skippedVersion release];
  skippedVersion = [version retain];
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:skippedVersion forKey:@"SKIPPED_VERSION"];
  [defaults synchronize];
}

-(void)setReleaseNotesKnown:(NSString *)releaseVersion {
  [releaseNotesKnown release];
  releaseNotesKnown = [releaseVersion retain];
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:releaseNotesKnown forKey:@"RELEASE_NOTES_KNOWN"];
  [defaults synchronize];
}

-(void)setProfileKnown:(BOOL)isProfileKnown {
  profileKnown = isProfileKnown;
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:profileKnown forKey:@"PROFILE_KNOWN"];
  [defaults synchronize];
}

-(void)setVisitNotesKnown:(BOOL)isVisitNotesKnown {
  visitNotesKnown = isVisitNotesKnown;
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:visitNotesKnown forKey:@"VISIT_NOTES_KNOWN"];
  [defaults synchronize];
}

-(BOOL)isLocationServiceEnabled {
  return locationService;
}

-(void)setLocationService:(BOOL)enabled {
  locationService = enabled;
  NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool:locationService forKey:@"GPS_ENABLED"];  
  [defaults synchronize];
}

-(BOOL)isPortraitScreen {
  return (screenDisplay == 'P');
}

-(BOOL)isLeftHandedLandscapeScreen {
  return (screenDisplay == 'L');
}

-(BOOL)isRightHandedLandscapeScreen {
  return (screenDisplay == 'R');
}

-(BOOL)isMetricMeasure {
  return (unitsOfMeasure == 'M');
}

-(BOOL)setMapType:(char)mType {
  if (mapType != mType && (mapType == 'O' || mapType == 'T' || mapType == 'S' || mapType == 'H')) {
    mapType = mType;
    [self save];
    return true;
  }
  return false;
}

-(BOOL)isMapTypeOverlay {
  return (mapType == 'O');
}

-(BOOL)isMapTypeStandard {
  return (mapType == 'T');
}

-(BOOL)isMapTypeSatellite {
  return (mapType == 'S');
}

-(BOOL)isMapTypeHybrid {
  return (mapType == 'H');
}

-(BOOL)isParkDataUpdateManually {
  return (parkDataUpdate < 0);
}

-(int)getParkDataUpdateDays {
  return parkDataUpdate;
}

-(BOOL)considerAllParkDataUpdate {
  return (parkDataUpdateScope == 'A');
}

-(BOOL)considerOnyInstalledParkDataUpdate {
  return (parkDataUpdateScope == 'I');
}

-(BOOL)considerOnyInstalledCountriesParkDataUpdate {
  return (parkDataUpdateScope == 'C');
}

-(NSString *)shortLanguagePath {
  if ([language isEqualToString:@"de.lproj"]) return @"de";
  if ([language isEqualToString:@"en.lproj"]) return @"en";
  return @"en";
}

-(NSString *)longLanguagePath {
  if ([language isEqualToString:@"de.lproj"]) return @"German.lproj";
  if ([language isEqualToString:@"en.lproj"]) return @"English.lproj";
  return @"English.lproj";
}

-(NSString *)languagePath {
  return language;
  /*if (language == 'D') return @"German.lproj";
  if (language == 'E') return @"English.lproj";
  return @"German.lproj";*/
}

-(void)save {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"save settings");
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:[NSNumber numberWithInt:maxNumberOfSameAttractionInTour] forKey:@"MAX_NUMBER_OF_SAME_ATTRACTION_IN_TOUR"];
  //[defaults setObject:[NSString stringWithFormat:@"%c", language] forKey:@"LANGUAGE"];
  [defaults setObject:[NSString stringWithFormat:@"%c", screenDisplay] forKey:@"SCREEN_DISPLAY"];
  [defaults setObject:[NSString stringWithFormat:@"%c", unitsOfMeasure] forKey:@"UNITS_OF_MEASURE"];
  [defaults setObject:[NSString stringWithFormat:@"%c", mapType] forKey:@"MAP_TYPE"];
  [defaults setObject:[NSNumber numberWithInt:distanceThreshold] forKey:@"GPS_DISTANCE_THRESHOLD"];
  [defaults setObject:[NSNumber numberWithInt:accuracyThreshold] forKey:@"GPS_ACCURACY_THRESHOLD"];
  InAppSetting *setting = [self getSettingForKey:@"COMPASS_ENABLED"];
  [defaults setObject:((compass)? [setting trueValue] : [setting falseValue]) forKey:@"COMPASS_ENABLED"];
  [defaults setObject:[NSNumber numberWithInt:parkDataUpdate] forKey:@"PARK_DATA_UPDATE"];
  [defaults setObject:[NSString stringWithFormat:@"%c", parkDataUpdateScope] forKey:@"PARK_DATA_SCOPE"];
  [defaults setObject:[NSNumber numberWithInt:calendarDataUpdate] forKey:@"CALENDAR_DATA_UPDATE"];
  [defaults setObject:[NSNumber numberWithInt:newsUpdate] forKey:@"NEWS_UPDATE"];
  [defaults setObject:[NSNumber numberWithInt:waitingTimesUpdate] forKey:@"WAITING_TIMES_UPDATE"];
  //[defaults setObject:[NSNumber numberWithInt:googleMapUpdate] forKey:@"GOOGLE_MAP_UPDATE"];
  [defaults synchronize];
  [pool release];
}

-(void)setDefaultLanguageSettings {
  NSString *lang = [self shortLanguagePath];
  if ([lang isEqualToString:@"de"]) {
    unitsOfMeasure = 'M'; // M - Metric
    [self save];
  } else if ([lang isEqualToString:@"en"]) {
    unitsOfMeasure = 'I'; // I - Imperial
    [self save];
  }
}

+(SettingsData *)getSettingsData:(BOOL)reload {
  static SettingsData *settingsData = nil;
  @synchronized([SettingsData class]) {
    if (settingsData == nil || reload) {
      [settingsData release];
      settingsData = [[SettingsData alloc] init];
    }
    return settingsData;
  }
}

+(SettingsData *)getSettingsData {  // ToDo: change to getInstance
  return [self getSettingsData:NO];
}

+(NSString *)getAppVersion {
  return [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
}

+(NSString *)getAppVersionLong {
  NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
  return [NSString stringWithFormat:@"%@ (%@)", [info objectForKey:@"CFBundleVersion"], [info objectForKey:@"CFBundleName"]];
}

+(NSString *)currentLanguage {
  NSString *currentLanguage = @"en";
  //NSLog(@"using language: %@", [NSLocale preferredLanguages]);
  //ToDo: e.g. "de-US"
  for (NSString *language in [NSLocale preferredLanguages]) {
    if ([language hasPrefix:@"de"]) {
      currentLanguage = @"de";
      break;
    } else if ([language hasPrefix:@"en"]) {
      currentLanguage = @"en";
      break;
    }
  }
  NSLog(@"using language: %@", currentLanguage);
  return [currentLanguage stringByAppendingString:@".lproj"];
}

@end
