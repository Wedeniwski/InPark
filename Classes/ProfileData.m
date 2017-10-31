//
//  ProfileData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 06.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "ProfileData.h"
#import "InAppSetting.h"
#import "ParkData.h"
#import "MenuData.h"

@implementation ProfileData

@synthesize avgWalkingSpeed;
@synthesize userName;
@synthesize age, height;
@synthesize sex;
@synthesize maxParkVisitTime, maxTourDistance, maxAcceptedWaitingTime, timeBeforeShow;
@synthesize thrillFactor, waterFactor, familyFactor;
@synthesize recommendationMatch;
@synthesize ratingWeight;
@synthesize considerOnlyHandicappedAccessible;
@synthesize optimization;
@synthesize considerAccompanist;
@synthesize ageAccompanist;
@synthesize heightAccompanist;

-(void)setSetting:(InAppSetting *)setting {
  NSString *key = [setting key];
  if (key != nil) {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    if ([key isEqualToString:@"AVG_WALKING_SPEED"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil) avgWalkingSpeed = [s doubleValue];
    } else if ([key isEqualToString:@"USER_NAME"]) {
      userName = [[d valueForKey:key] retain];
    } else if ([key isEqualToString:@"AGE"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) age = [n intValue];
    } else if ([key isEqualToString:@"HEIGHT"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil) height = [s intValue];
    } else if ([key isEqualToString:@"SEX"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil && [s length] > 0) sex = (char)[s characterAtIndex:0];
    } else if ([key isEqualToString:@"MAX_PARK_VISIT_TIME"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) maxParkVisitTime = [n intValue];
    } else if ([key isEqualToString:@"MAX_TOUR_DISTANCE"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) maxTourDistance = [n intValue];
    } else if ([key isEqualToString:@"MAX_ACCEPTED_WAITING_TIME"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) maxAcceptedWaitingTime = [n intValue];
    } else if ([key isEqualToString:@"TIME_BEFORE_SHOW"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) timeBeforeShow = [n intValue];
    } else if ([key isEqualToString:@"THRILL_FACTOR"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) thrillFactor = [n intValue];
    } else if ([key isEqualToString:@"WATER_FACTOR"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) waterFactor = [n intValue];
    } else if ([key isEqualToString:@"FAMILY_FACTOR"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) familyFactor = [n intValue];
    } else if ([key isEqualToString:@"RECOMMENDATION_MATCH"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) recommendationMatch = [n intValue]/100.0;
    } else if ([key isEqualToString:@"RATING_WEIGHT"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) ratingWeight = [n intValue];
    } else if ([key isEqualToString:@"CONSIDER_ONLY_HANDICAPPED_ACCESSIBLE"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil) considerOnlyHandicappedAccessible = [setting isTrueValue:s];
    } else if ([key isEqualToString:@"OPTIMIZATION"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil && [s length] > 0) optimization = (char)[s characterAtIndex:0];
    } else if ([key isEqualToString:@"CALL_OPTIMIZATION"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil && [s length] > 0) callOptimization = (char)[s characterAtIndex:0];
    } else if ([key isEqualToString:@"CONSIDER_ACCOMPANIST"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil) considerAccompanist = [setting isTrueValue:s];
    } else if ([key isEqualToString:@"AGE_ACCOMPANIST"]) {
      NSNumber *n = [d valueForKey:key];
      if (n == nil) n = [setting defaultValue];
      if (n != nil) ageAccompanist = [n intValue];
    } else if ([key isEqualToString:@"HEIGHT_ACCOMPANIST"]) {
      NSString *s = [d valueForKey:key];
      if (s == nil) s = [setting defaultValue];
      if (s != nil) heightAccompanist = [s intValue];
    }
  }
}

-(id)init {
  avgWalkingSpeed = 0.0;
  sex = 'M';
  maxParkVisitTime = maxTourDistance = -1;
  age = height = maxAcceptedWaitingTime = thrillFactor = waterFactor = familyFactor = 0;
  recommendationMatch = 0.0;
  considerOnlyHandicappedAccessible = NO;
  considerAccompanist = NO;
  ageAccompanist = heightAccompanist = 0;
  self = [super init];
  if (self != nil) {
    NSArray *a = [MenuData getRootKey:@"Profile"];
    NSUInteger l = [a count];
    for (NSUInteger i = 0; i < l; ++i) {
      InAppSetting *b = [[InAppSetting alloc] initWithDictionary:[a objectAtIndex:i]];
      [self setSetting:b];
      [b release];
    }
  }
  return self;
}

-(void)dealloc {
  [userName release];
  [super dealloc];
}

+(ProfileData *)getProfileData:(BOOL)reload {
  static ProfileData *profileData = nil;
  @synchronized([ProfileData class]) {
    if (profileData == nil || reload) {
      [profileData release];
      profileData = [[ProfileData alloc] init];
    }
  }
  return profileData;
}

+(ProfileData *)getProfileData {
  return [self getProfileData:NO];
}

-(void)setUserName:(NSString *)newUserName {
  [userName release];
  userName = [newUserName retain];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:userName forKey:@"USER_NAME"];
  [defaults synchronize];
}

-(double)percentageOfPreferenceFit:(Attraction *)attraction parkId:(NSString *)parkId personalAttractionRating:(int)personalAttractionRating adultAge:(int)adultAge {
  if ([attraction isClosed:parkId]) return 0.0;
  if (considerOnlyHandicappedAccessible && !attraction.handicappedAccessible) return 0.0;
  int minAge = age;
  int maxAge = age;
  int minHeight = height;
  int maxHeight = height;
  if (considerAccompanist) {
    if (ageAccompanist < age) minAge = ageAccompanist;
    else if (ageAccompanist > age) maxAge = ageAccompanist;
    if (heightAccompanist < age) minHeight = heightAccompanist;
    else if (heightAccompanist > age) maxHeight = heightAccompanist;
  }
  if ([attraction hasAttributes]) {
    AttractionAttributes *attributes = attraction.attributes;
    // e.g. @"ohne Beschränkung", @"keine", @"bis 6 Jahre", @"ab 4 Jahren", @"ab 6 Jahren", @"4 bis 11 Jahre"
    // e.g. "ab 8 Jahren, unter 10 Jahren nur in Begleitung eines Erwachsenen"
    if (attributes.ageRestricted2 > 0) {
      if (attributes.ageRestricted > minAge || attributes.ageRestricted2 < minAge) return 0.0;
    } else if (attributes.ageRestrictedBelowAdultAccompany > 0) {
      if (attributes.ageRestricted > minAge || (maxAge < adultAge && attributes.ageRestrictedBelowAdultAccompany > minAge)) return 0.0;
    } else if (attributes.ageRestricted > 0) {
      if (attributes.ageRestrictedBelow) {
        if (attributes.ageRestricted < minAge) return 0.0;
      } else {
        if (attributes.ageRestricted > maxAge) return 0.0;
      }
    }
    // e.g. @"ab 100 cm", @"bis 120 cm", @"ab 120 cm"
    // ab 90 cm, unter 120 cm nur in Begleitung eines Erwachsenen
    if (attributes.heightRestricted2 > 0) {
      if (attributes.heightRestricted > minHeight || attributes.heightRestricted2 < minHeight) return 0.0;
    } else if (attributes.heightRestrictedBelowAdultAccompany > 0) {
      if (attributes.heightRestricted > minHeight || (maxAge < adultAge && attributes.heightRestrictedBelowAdultAccompany > minHeight)) return 0.0;
    } else if (attributes.heightRestricted > 0) {
      if (attributes.heightRestrictedBelow) {
        if (attributes.heightRestricted < minHeight) return 0.0;
      } else {
        if (attributes.heightRestricted > maxHeight) return 0.0;
      }
    }
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  int personalRating = 3*(personalAttractionRating*personalAttractionRating*ratingWeight);
  if ([parkData isFavorite:attraction.attractionId]) personalRating += 225; // 3*3*5^2 = <number of factors>*<favorite weight>*<favorite factor>^2
  double factor = 5.0*(thrillFactor*thrillFactor+familyFactor*familyFactor+waterFactor*waterFactor) + personalRating;
  if (factor == 0.0) return 0.0;
  int fit = personalRating;
  int t, f, w;
  [attraction getThrillFactor:&t familyFactor:&f waterFactor:&w];
  if (t > 0) fit += thrillFactor*thrillFactor*t;
  if (f > 0) fit += familyFactor*familyFactor*f;
  if (w > 0) fit += waterFactor*waterFactor*w;
  // 5, 0, 3
  // 5*(5+0+3) 5*(5-3) + 0*(0-4) + 3*(3-4) = (40 - 13)/40 = 
  // fit is 0-15, 0 -> 100%, 15 -> 0%
  return fit/factor;
}

-(BOOL)askForOptimization {
  return (callOptimization == 'Q');
}

-(BOOL)automaticOptimization {
  return (callOptimization == 'A');
}

@end
