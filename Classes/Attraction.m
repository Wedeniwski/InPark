//
//  Attraction.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 27.08.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "Attraction.h"
#import "MenuData.h"
#import "ParkData.h"
#import "CalendarData.h"
#import "CalendarItem.h"
#import "WaitingTimeData.h"
#import "WaitingTimeItem.h"
#import "ProfileData.h"
#import "SettingsData.h"
#import "Conversions.h"
#import "Categories.h"

@implementation AttractionAttributes

@synthesize nextStationId;
@synthesize fastLaneDefined, fastLane;
@synthesize ageRestricted, ageRestricted2, heightRestricted, heightRestricted2;
@synthesize ageRestrictedBelow, heightRestrictedBelow;
@synthesize ageRestrictedBelowAdultAccompany, ageRestrictedAboveChildAccompany, heightRestrictedBelowAdultAccompany, heightRestrictedAboveChildAccompany;
@synthesize duration, defaultWaiting;
@synthesize waiting;

-(id)initWithAttractionId:(NSString *)aId parkId:parkId attractionDetails:(NSDictionary *)attractionDetails {
  self = [super init];
  if (self != nil) {
    nextStationId = [[attractionDetails objectForKey:@"nächste Station"] retain];
    NSNumber *n = [attractionDetails objectForKey:@"Attraktionsdauer"];
    duration = (n != nil)? [n intValue] : 0;
    n = [attractionDetails objectForKey:@"Wartezeit"];
    defaultWaiting = (n != nil)? [n intValue] : 0;
    n = [attractionDetails objectForKey:@"Warten"];
    waiting = (n != nil && [n boolValue] == YES);
    ParkData *parkData = [ParkData getParkData:parkId];
    if (parkData.fastLaneId != nil) {
      n = [attractionDetails objectForKey:@"Fast_lane"]; // introduced in 1.5.6 (Jan 4, 2013) - ToDo: Remove old access
      if (n == nil) n = [attractionDetails objectForKey:parkData.fastLaneId];
      fastLaneDefined = (n != nil);
      fastLane = (n != nil && [n boolValue] == YES);
    } else {
      fastLaneDefined = fastLane = NO;
    }
    n = [attractionDetails objectForKey:@"Thrill-Faktor"];
    int f = (n != nil)? [n intValue] : 7;
    if (f > 7) f = 7;
    else if (f < 0) f = 0;
    thrillFamilyWaterFactor = f;
    n = [attractionDetails objectForKey:@"Familien-Faktor"];
    f = (n != nil)? [n intValue] : 7;
    if (f > 7) f = 7;
    else if (f < 0) f = 0;
    thrillFamilyWaterFactor = (thrillFamilyWaterFactor << 3) | (f&7);
    n = [attractionDetails objectForKey:@"Wasser-Faktor"];
    f = (n != nil)? [n intValue] : 7;
    if (f > 7) f = 7;
    else if (f < 0) f = 0;
    thrillFamilyWaterFactor = (thrillFamilyWaterFactor << 3) | (f&7);
    ageRestricted = ageRestricted2 = 0;
    ageRestrictedBelow = NO;
    ageRestrictedBelowAdultAccompany = 0;
    ageRestrictedAboveChildAccompany = 0;
    NSString *t = [MenuData objectForKey:@"Altersbegrenzung" at:attractionDetails];
    if (t != nil && [t length] > 0) {
      t = [t stringByReplacingOccurrencesOfString:@"," withString:@";"];
      NSRange range = [t rangeOfString:@";"];
      NSArray *ageRestrictions = (range.length > 0)? [t componentsSeparatedByString:@"; "] : [NSArray arrayWithObject:t];
      for (t in ageRestrictions) {
        // "ohne Beschränkung; unter 8 Jahren nur in Begleitung eines Erwachsenen"
        // e.g. "ab 8 Jahren, unter 10 Jahren nur in Begleitung eines Erwachsenen", "4 bis 11 Jahre"
        if ([t hasSuffix:NSLocalizedString(@"profile.parse.adult.accompany", nil)]) ageRestrictedBelowAdultAccompany = 1;
        else if ([t hasSuffix:NSLocalizedString(@"profile.parse.child.accompany", nil)]) ageRestrictedAboveChildAccompany = 1;
        NSString *t2 = NSLocalizedString(@"profile.parse.from", nil);
        if ([t hasPrefix:t2]) {
          const char *s = [t UTF8String];
          s += [t2 length];
          if (ageRestrictedBelowAdultAccompany > 0) ageRestrictedBelowAdultAccompany = atoi(s);
          else if (ageRestrictedAboveChildAccompany > 0) ageRestrictedAboveChildAccompany = atoi(s);
          else ageRestricted = atoi(s);
        } else {
          t2 = NSLocalizedString(@"profile.parse.below", nil);
          if ([t hasPrefix:t2]) {
            const char *s = [t UTF8String];
            s += [t2 length];
            if (ageRestrictedBelowAdultAccompany > 0) ageRestrictedBelowAdultAccompany = atoi(s);
            else if (ageRestrictedAboveChildAccompany > 0) ageRestrictedAboveChildAccompany = atoi(s);
            else {
              ageRestricted = atoi(s);
              ageRestrictedBelow = YES;
            }
          } else {
            t2 = NSLocalizedString(@"profile.parse.until", nil);
            if ([t hasPrefix:t2]) {
              const char *s = [t UTF8String];
              s += [t2 length];
              if (ageRestrictedBelowAdultAccompany > 0) ageRestrictedBelowAdultAccompany = atoi(s);
              else if (ageRestrictedAboveChildAccompany > 0) ageRestrictedAboveChildAccompany = atoi(s);
              else {
                ageRestricted = atoi(s);
                ageRestrictedBelow = YES;
              }
            } else {
              t2 = NSLocalizedString(@"profile.parse.between", nil);
              NSRange range = [t rangeOfString:t2];
              if (range.length > 0) {
                const char *s = [t UTF8String];
                ageRestricted = atoi(s);
                s += range.location+range.length;
                ageRestricted2 = atoi(s);
                //ageRestrictedBelow = YES;
              } else {
                t2 = NSLocalizedString(@"profile.parse.no.restrictions", nil);
                if (![t hasPrefix:t2]) {
                  NSLog(@"ERROR: age restriction \"%@\" of %@ (%@) could not be parsed", t, aId, parkId);
                }
              }
            }
          }
        }
      }
    }
    heightRestricted = heightRestricted2 = 0;
    heightRestrictedBelow = NO;
    heightRestrictedBelowAdultAccompany = 0;
    heightRestrictedAboveChildAccompany = 0;
    t = [MenuData objectForKey:@"Größe" at:attractionDetails];
    if (t != nil && [t length] > 0) {
      t = [t stringByReplacingOccurrencesOfString:@"," withString:@";"];
      NSRange range = [t rangeOfString:@";"];
      NSArray *heightRestrictions = (range.length > 0)? [t componentsSeparatedByString:@"; "] : [NSArray arrayWithObject:t];
      for (t in heightRestrictions) {
        // e.g. @"nur Kleinkinder", @"ab 100 cm", @"bis 120 cm", @"ab 120 cm", @"130 cm bis 200 cm"
        // ab 90 cm, unter 120 cm nur in Begleitung eines Erwachsenen
        if ([t hasSuffix:NSLocalizedString(@"profile.parse.adult.accompany", nil)]) heightRestrictedBelowAdultAccompany = 1;
        else if ([t hasSuffix:NSLocalizedString(@"profile.parse.child.accompany", nil)]) {
          heightRestrictedAboveChildAccompany = 1;
        }
        NSString *t2 = NSLocalizedString(@"profile.parse.from", nil);
        if ([t hasPrefix:t2]) {
          const char *s = [t UTF8String];
          s += [t2 length];
          if (heightRestrictedBelowAdultAccompany > 0) heightRestrictedBelowAdultAccompany = atoi(s);
          else if (heightRestrictedAboveChildAccompany > 0) heightRestrictedAboveChildAccompany = atoi(s);
          else heightRestricted = atoi(s);
        } else {
          t2 = NSLocalizedString(@"profile.parse.below", nil);
          if ([t hasPrefix:t2]) {
            const char *s = [t UTF8String];
            s += [t2 length];
            if (heightRestrictedBelowAdultAccompany > 0) heightRestrictedBelowAdultAccompany = atoi(s);
            else if (heightRestrictedAboveChildAccompany > 0) heightRestrictedAboveChildAccompany = atoi(s);
            else {
              heightRestricted = atoi(s);
              heightRestrictedBelow = YES;
            }
          } else {
            t2 = NSLocalizedString(@"profile.parse.until", nil);
            if ([t hasPrefix:t2]) {
              const char *s = [t UTF8String];
              s += [t2 length];
              if (heightRestrictedBelowAdultAccompany > 0) heightRestrictedBelowAdultAccompany = atoi(s);
              else if (heightRestrictedAboveChildAccompany > 0) heightRestrictedAboveChildAccompany = atoi(s);
              else {
                heightRestricted = atoi(s);
                heightRestrictedBelow = YES;
              }
            } else {
              t2 = NSLocalizedString(@"profile.parse.between", nil);
              NSRange range = [t rangeOfString:t2];
              if (range.length > 0) {
                const char *s = [t UTF8String];
                heightRestricted = atoi(s);
                s += range.location+range.length;
                heightRestricted2 = atoi(s);
                //heightRestrictedBelow = YES;
              } else {
                t2 = NSLocalizedString(@"profile.parse.no.restrictions", nil);
                if (![t hasPrefix:t2]) {
                  NSLog(@"ERROR: height restriction \"%@\" of %@ (%@) could not be parsed", t, aId, parkId);
                }
              }
            }
          }
        }
      }
    }
  }
  return self;
}

-(void)dealloc {
  [nextStationId release];
  nextStationId = nil;
  [super dealloc];
}

-(BOOL)isEmpty {
  if (nextStationId == nil && duration == 0 && defaultWaiting == 0 && !waiting && !fastLaneDefined && !fastLane) {
    int f = thrillFamilyWaterFactor;
    if ((f&7) > 6 && ((f>>3)&7) > 6 && ((f>>6)&7) > 6) {
      if (ageRestricted == 0 && ageRestricted2 == 0 && !ageRestrictedBelow && ageRestrictedBelowAdultAccompany == 0 && ageRestrictedAboveChildAccompany == 0) {
        if (heightRestricted == 0 && heightRestricted2 == 0 && !heightRestrictedBelow && heightRestrictedBelowAdultAccompany == 0 && heightRestrictedAboveChildAccompany == 0) {
          return YES;
        }
      }
    }
  }
  return NO;
}

-(void)getThrillFactor:(int *)thrillFactor familyFactor:(int *)familyFactor waterFactor:(int *)waterFactor {
  int f = thrillFamilyWaterFactor;
  int i = f&7;
  *waterFactor = (i > 6)? -1 : i;
  i = (f>>3)&7;
  *familyFactor = (i > 6)? -1 : i;
  i = (f>>6)&7;
  *thrillFactor = (i > 6)? -1 : i;
}

@end

@implementation Attraction

@synthesize attractionId;
@synthesize typeIdx;
@synthesize tourPoint, sommer, winter, handicappedAccessible;
@synthesize attributes;

-(id)initWithAttractionId:(NSString *)aId parkId:parkId attractionDetails:(NSDictionary *)attractionDetails {
  self = [super init];
  if (self != nil) {
    Categories *categories = [Categories getCategories];
    attractionId = [aId retain];
    NSString *s = [MenuData objectForKey:@"Name" at:attractionDetails];
    if (s == nil) {
      attractionName = NULL;
      NSLog(@"missing name for attraction %@ at park %@", aId, parkId);
    } else {
      const char *c = [s UTF8String];
      int l = strlen(c);
      //if (l != s.length) NSLog(@"not equal length of '%@' as c string '%s'", s, c);
      attractionName = malloc(sizeof(char)*(l+1));
      strcpy(attractionName, c);
    }
    s = [attractionDetails objectForKey:@"Bild"];
    if (s == nil) {
      imageName = NULL;
      NSLog(@"missing image for attraction %@ at park %@", aId, parkId);
    } else {
      if (parkId != nil && ![parkId isEqualToString:CORE_DATA_ID] && [s hasSuffix:@".jpg"]) {
        NSString *prefix = [NSString stringWithFormat:@"%@ - %@ - ", parkId, attractionId];
        if ([s hasPrefix:prefix]) {
          imageExtensions = YES;
          NSRange r;
          r.location = prefix.length;
          r.length = s.length-prefix.length-4;
          s = [s substringWithRange:r];
        } else {
          imageExtensions = NO;
        }
        const char *c = [s UTF8String];
        imageName = malloc(sizeof(char)*(strlen(c)+1));
        strcpy(imageName, c);
      } else {
        NSLog(@"image '%@' can be optimized by using prefix '%@ - %@ - '", s, parkId, attractionId);
        imageExtensions = NO;
        const char *c = [s UTF8String];
        imageName = malloc(sizeof(char)*(strlen(c)+1));
        strcpy(imageName, c);
      }
    }
    typeIdx = [categories getTypeIdx:[attractionDetails objectForKey:@"Type"]];
    NSNumber *n = [attractionDetails objectForKey:@"Tourpoint"];
    tourPoint = (n == nil || [n boolValue] == YES);
    n = [attractionDetails objectForKey:@"Winter"];
    winter = (n == nil || [n boolValue] == YES);
    n = [attractionDetails objectForKey:@"Sommer"];
    sommer = (n == nil || [n boolValue] == YES);
    n = [attractionDetails objectForKey:@"Behindertengerecht"];
    handicappedAccessible = (n != nil && [n boolValue] == YES);
    AttractionAttributes *tmpAttributes = [[AttractionAttributes alloc] initWithAttractionId:aId parkId:parkId attractionDetails:attractionDetails];
    if ([tmpAttributes isEmpty]) {
      [tmpAttributes release];
      attributes = nil;
    } else attributes = tmpAttributes;
  }
  return self;
}

-(void)dealloc {
  [attractionId release];
  attractionId = nil;
  free(attractionName);
  free(imageName);
  [attributes release];
  attributes = nil;
  [super dealloc];
}

-(NSComparisonResult)compare:(Attraction *)otherAttraction {
  return strcasecmp(attractionName, otherAttraction.attractionName);
}

static NSMutableDictionary *allAttractions = nil;

+(NSDictionary *)getAllAttractions:(NSString *)parkId reload:(BOOL)reload {
  @synchronized([Attraction class]) {
    if (reload || allAttractions == nil) {
      if (allAttractions == nil) {
        [Attraction getAttraction:nil attractionId:nil];
      } else {
        if (parkId == nil) {
          [allAttractions release];
          allAttractions = nil;
          [Attraction getAttraction:nil attractionId:nil];
        } else {
          [allAttractions removeObjectForKey:parkId];
          [Attraction getAttraction:parkId attractionId:nil];
        }
      }
    }
    return [NSDictionary dictionaryWithDictionary:[allAttractions objectForKey:parkId]]; // might be changed during usage
  }
}

-(const char*)attractionName {
  return attractionName;
}

-(NSString *)stringAttractionName {
  return (attractionName == NULL)? @"" : [NSString stringWithUTF8String:attractionName];
}

-(NSString *)imageName:(NSString *)parkId {
  if (imageName == NULL) return nil;
  return (imageExtensions)? [NSString stringWithFormat:@"%@ - %@ - %s.jpg", parkId, attractionId, imageName] : [NSString stringWithUTF8String:imageName];
}

-(NSString *)imagePath:(NSString *)parkId {
  if (imageName == NULL) return nil;
  if (parkId == nil || [parkId isEqualToString:CORE_DATA_ID]) return [NSString stringWithFormat:@"%@/%s", [MenuData dataPath], imageName];
  return (imageExtensions)? [NSString stringWithFormat:@"%@/%@/%@ - %@ - %s.jpg", [MenuData dataPath], parkId, parkId, attractionId, imageName] : [NSString stringWithFormat:@"%@/%@/%s", [MenuData dataPath], parkId, imageName];
}

-(NSString *)typeId {
  Categories *categories = [Categories getCategories];
  return [categories getTypeId:typeIdx];
}

-(NSString *)typeName {
  Categories *categories = [Categories getCategories];
  return [categories getTypeNameForIdx:typeIdx];
}

-(BOOL)hasAttributes {
  return (attributes != nil);
}

-(NSString *)nextStationId {
  return (attributes == nil)? nil : attributes.nextStationId;
}

-(BOOL)fastLaneDefined {
  return (attributes == nil)? NO : attributes.fastLaneDefined;
}

-(BOOL)fastLane {
  return (attributes == nil)? NO : attributes.fastLane;
}

-(short)duration {
  return (attributes == nil)? 0 : attributes.duration;
}

-(short)defaultWaiting {
  return (attributes == nil)? 0 : attributes.defaultWaiting;
}

-(BOOL)waiting {
  return (attributes == nil)? NO : attributes.waiting;
}

-(BOOL)isTrain {
  return (attributes != nil && attributes.nextStationId != nil);
}

-(BOOL)isDining {
  Categories *categories = [Categories getCategories];
  return [categories isTypeId:[categories getTypeId:typeIdx] inCategoryId:@"DINING"];
  //return [attractionId hasPrefix:@"g"];
}

-(BOOL)isShow {
  Categories *categories = [Categories getCategories];
  return [categories isTypeId:[categories getTypeId:typeIdx] inCategoryId:@"SHOW"];
}

-(void)getThrillFactor:(int *)thrillFactor familyFactor:(int *)familyFactor waterFactor:(int *)waterFactor {
  if (attributes == nil) {
    *waterFactor = -1;
    *familyFactor = -1;
    *thrillFactor = -1;
  } else {
    [attributes getThrillFactor:thrillFactor familyFactor:familyFactor waterFactor:waterFactor];
  }
}

-(NSString *)ageRestriction {
  if (attributes == nil) return nil;
  short ageRestricted = attributes.ageRestricted;
  short ageRestrictedBelowAdultAccompany = attributes.ageRestrictedBelowAdultAccompany;
  short ageRestrictedAboveChildAccompany = attributes.ageRestrictedAboveChildAccompany;
  if (ageRestricted == 0 && ageRestrictedBelowAdultAccompany == 0 && ageRestrictedAboveChildAccompany == 0) return nil;
  NSString *s = @"";
  NSString *s2 = nil;
  short ageRestricted2 = attributes.ageRestricted2;
  if (ageRestricted2 > 0) {
    s = [NSString stringWithFormat:NSLocalizedString(@"profile.age.between", nil), ageRestricted, ageRestricted2];
  } else if (ageRestricted > 0) {
    NSString *t = (attributes.ageRestrictedBelow)? NSLocalizedString(@"profile.age.below", nil) : NSLocalizedString(@"profile.age.from", nil);
    s = [NSString stringWithFormat:t, ageRestricted];
  }
  if (ageRestrictedBelowAdultAccompany > 0) {
    s2 = [NSString stringWithFormat:NSLocalizedString(@"profile.age.until.and.adult.accompany", nil), ageRestrictedBelowAdultAccompany];
    if ([s length] == 0) s = NSLocalizedString(@"profile.parse.no.restrictions", nil);
  } else if (ageRestrictedAboveChildAccompany > 0) {
    s2 = [NSString stringWithFormat:NSLocalizedString(@"profile.age.above.and.child.accompany", nil), ageRestrictedAboveChildAccompany];
    if ([s length] == 0) s = NSLocalizedString(@"profile.parse.no.restrictions", nil);
  }
  return (s2 != nil)? [NSString stringWithFormat:@"%@; %@", s, s2] : s;
}

-(NSString *)heightRestriction {
  if (attributes == nil) return nil;
  short heightRestricted = attributes.heightRestricted;
  short heightRestrictedBelowAdultAccompany = attributes.heightRestrictedBelowAdultAccompany;
  short heightRestrictedAboveChildAccompany = attributes.heightRestrictedAboveChildAccompany;
  if (heightRestricted == 0 && heightRestrictedBelowAdultAccompany == 0 && heightRestrictedAboveChildAccompany == 0) return nil;
  short heightRestricted2 = attributes.heightRestricted2;
  SettingsData *settings = [SettingsData getSettingsData];
  NSString *s = @"";
  NSString *s2 = nil;
  if ([settings isMetricMeasure]) {
    if (heightRestricted2 > 0) {
      s = [NSString stringWithFormat:NSLocalizedString(@"profile.height.between", nil), heightRestricted, heightRestricted2];
    } else if (heightRestricted > 0) {
      NSString *t = (attributes.heightRestrictedBelow)? NSLocalizedString(@"profile.height.below", nil) : NSLocalizedString(@"profile.height.from", nil);
      s = [NSString stringWithFormat:t, heightRestricted];
    }
    if (heightRestrictedBelowAdultAccompany > 0) {
      s2 = [NSString stringWithFormat:NSLocalizedString(@"profile.height.until.and.adult.accompany", nil), heightRestrictedBelowAdultAccompany];
      if ([s length] == 0) s = NSLocalizedString(@"profile.parse.no.restrictions", nil);
    } else if (heightRestrictedAboveChildAccompany > 0) {
      s2 = [NSString stringWithFormat:NSLocalizedString(@"profile.height.above.and.child.accompany", nil), heightRestrictedAboveChildAccompany];
      if ([s length] == 0) s = NSLocalizedString(@"profile.parse.no.restrictions", nil);
    }
  } else {
    if (heightRestricted2 > 0) {
      s = [NSString stringWithFormat:NSLocalizedString(@"profile.height.imperial.between", nil), imperialSize(heightRestricted/100.0, NO), imperialSize(heightRestricted2/100.0, YES), heightRestricted, heightRestricted2];
    } else if (heightRestricted > 0) {
      NSString *t = (attributes.heightRestrictedBelow)? NSLocalizedString(@"profile.height.imperial.below", nil) : NSLocalizedString(@"profile.height.imperial.from", nil);
      s = [NSString stringWithFormat:t, imperialSize(heightRestricted/100.0, attributes.heightRestrictedBelow), heightRestricted];
    }
    if (heightRestrictedBelowAdultAccompany > 0) {
      s2 = [NSString stringWithFormat:NSLocalizedString(@"profile.height.imperial.until.and.adult.accompany", nil), imperialSize(heightRestrictedBelowAdultAccompany/100.0, YES), heightRestrictedBelowAdultAccompany];
      if ([s length] == 0) s = NSLocalizedString(@"profile.parse.no.restrictions", nil);
    } else if (heightRestrictedAboveChildAccompany > 0) {
      s2 = [NSString stringWithFormat:NSLocalizedString(@"profile.height.imperial.above.and.child.accompany", nil), imperialSize(heightRestrictedAboveChildAccompany/100.0, YES), heightRestrictedAboveChildAccompany];
      if ([s length] == 0) s = NSLocalizedString(@"profile.parse.no.restrictions", nil);
    }
  }
  return (s2 != nil)? [NSString stringWithFormat:@"%@; %@", s, s2] : s;
}

+(NSString *)getShortAttractionId:(NSString *)attractionId {
  if ([attractionId hasSuffix:@"/e"]) attractionId = [attractionId substringToIndex:[attractionId length]-2];
  if ([attractionId hasSuffix:@"/f"]) attractionId = [attractionId substringToIndex:[attractionId length]-2];
  NSRange found = [attractionId rangeOfString:@"@"];
  return (found.length == 0)? attractionId : [attractionId substringToIndex:found.location];
}

+(BOOL)isInternalId:(NSString *)attractionId {
  return [attractionId hasPrefix:@"i"];
}

+(Attraction *)getAttraction:(NSString *)parkId attractionId:(NSString *)attractionId {
  @synchronized([Attraction class]) {
    if (allAttractions == nil) {
      __block int numberOfAttractions = 0;
      __block int numberOfAttractionsWithAttrbibutes = 0;
      NSArray *parkIds = [MenuData getParkIds];
      NSMutableDictionary *md = [[NSMutableDictionary alloc] initWithCapacity:[parkIds count]];
      for (NSString *parkId in parkIds) {
        NSDictionary *attractionIds = [[[MenuData getParkDetails:parkId cache:YES] objectForKey:@"IDs"] retain];
        __block NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:[attractionIds count]];
        [attractionIds enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
          if ([object isKindOfClass:[NSDictionary class]]) {
            Attraction *attraction = [[Attraction alloc] initWithAttractionId:key parkId:parkId attractionDetails:object];
            [data setObject:attraction forKey:key];
            if ([attraction hasAttributes]) ++numberOfAttractionsWithAttrbibutes;
            [attraction release];
            ++numberOfAttractions;
          }
        }];
        [md setObject:data forKey:parkId];
        [data release];
        [attractionIds release];
      }
      allAttractions = md;
      if (numberOfAttractions > 0) NSLog(@"number of initialized attractions %d where %d have attributes", numberOfAttractions, numberOfAttractionsWithAttrbibutes);
    }
    if (parkId == nil) return nil;
    ParkData *parkData = [ParkData getParkData:parkId];
    if (parkData == nil) return nil;
    NSMutableDictionary *d = [allAttractions objectForKey:parkId];
    if (d == nil) {
      __block int numberOfAttractions = 0;
      __block int numberOfAttractionsWithAttrbibutes = 0;
      NSDictionary *attractionIds = [[[MenuData getParkDetails:parkId cache:YES] objectForKey:@"IDs"] retain];
      __block NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:[attractionIds count]];
      [attractionIds enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        if ([object isKindOfClass:[NSDictionary class]]) {
          Attraction *attraction = [[Attraction alloc] initWithAttractionId:key parkId:parkId attractionDetails:object];
          [data setObject:attraction forKey:key];
          if ([attraction hasAttributes]) ++numberOfAttractionsWithAttrbibutes;
          [attraction release];
          ++numberOfAttractions;
        }
      }];
      [allAttractions setObject:data forKey:parkId];
      [data release];
      [attractionIds release];
      NSLog(@"number of initialized attractions %d where %d have attributes for park %@", numberOfAttractions, numberOfAttractionsWithAttrbibutes, parkId);
    }
    if (attractionId == nil) return nil;
    Attraction *a = [d objectForKey:[parkData getAttractionDataId:attractionId]];
    if (a != nil) return a;
    return [d objectForKey:[parkData getAttractionDataId:[Attraction getShortAttractionId:attractionId]]];
  }
}

+(Attraction *)getAttraction:(NSString *)parkId attractionName:(const char *)attractionName {
  @synchronized([Attraction class]) {
    if (allAttractions == nil) [Attraction getAttraction:nil attractionId:nil];
    NSDictionary *attractions = [allAttractions objectForKey:parkId];
    NSEnumerator *i = [attractions objectEnumerator];
    while (TRUE) {
      Attraction *attraction = [i nextObject];
      if (!attraction) break;
      if (strcmp(attractionName, attraction.attractionName) == 0) return attraction;
    }
    return nil;
  }
}

+(NSArray *)getAttractions:(NSString *)parkId typeId:(NSString *)typeId {
  @synchronized([Attraction class]) {
    if (allAttractions == nil) [Attraction getAttraction:nil attractionId:nil];
    Categories *categories = [Categories getCategories];
    const short typeIdx = [categories getTypeIdx:typeId];
    NSMutableArray *result = [[[NSMutableArray alloc] initWithCapacity:5] autorelease];
    NSDictionary *attractions = [allAttractions objectForKey:parkId];
    NSEnumerator *i = [attractions objectEnumerator];
    while (TRUE) {
      Attraction *attraction = [i nextObject];
      if (!attraction) break;
      if (typeIdx == attraction.typeIdx) [result addObject:attraction];
    }
    return result;
  }
}

-(NSDictionary *)getAttractionDetails:(NSString *)parkId cache:(BOOL)cache {
  return [MenuData getAttractionDetails:parkId attractionId:attractionId cache:cache];
}

/*-(void)parseTimes:(NSString *)stringTimes {
  if (stringTimes != nil && [stringTimes length] > 0) {
    NSMutableArray *fTimes = [[NSMutableArray alloc] initWithCapacity:3];
    NSMutableArray *tTimes = [[NSMutableArray alloc] initWithCapacity:3];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    NSArray *a = [stringTimes componentsSeparatedByString:@", "];
    for (NSString *s in a) {
      NSArray *b = [s componentsSeparatedByString:NSLocalizedString(@"attraction.times.separator", nil)];
      if ([b count] >= 2) {
        NSDate *d = [timeFormat dateFromString:[b objectAtIndex:0]];
        [fTimes addObject:[NSNumber numberWithDouble:[d timeIntervalSince1970]]];
        d = [timeFormat dateFromString:[b objectAtIndex:1]];
        [tTimes addObject:[NSNumber numberWithDouble:[d timeIntervalSince1970]]];
      } else if ([b count] >= 1) {
        NSDate *d = [timeFormat dateFromString:[b objectAtIndex:0]];
        NSNumber *n = [NSNumber numberWithDouble:[d timeIntervalSince1970]];
        [fTimes addObject:n];
        [tTimes addObject:n];
      }
    }
    [timeFormat release];
    fromTimes = fTimes;
    toTimes = tTimes;
  }
}*/ 

-(BOOL)needToAttendAtOpeningTime:(NSString *)parkId forDate:(NSDate *)date {
  ParkData *parkData = [ParkData getParkData:parkId];
  /*if ([CalendarData isToday:date]) {
    WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
    if ([waitingTimeData hasStartTimes]) {
      WaitingTimeItem *waitingTimeItem = [waitingTimeData getWaitingTimeFor:attractionId];
      if (waitingTimeItem != nil && [waitingTimeItem hasStartTimes]) return YES;
    }
  }*/
  CalendarData *calendarData = [parkData getCalendarData];
  NSArray *calendarItems = [calendarData getCalendarItemsFor:attractionId forDate:date];
  if (calendarItems == nil || [calendarItems count] == 0) return NO;
  CalendarItem *item = [calendarItems objectAtIndex:0];
  return item.needToAttendAtStartTime;
}

-(NSString *)startingTimes:(NSString *)parkId forDate:(NSDate *)date onlyNext4Times:(BOOL)onlyNext4Times hasMoreThanOneTime:(BOOL *)hasMoreThanOneTime {
  if (hasMoreThanOneTime != nil) *hasMoreThanOneTime = NO;
  ParkData *parkData = [ParkData getParkData:parkId];
  /*WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  if ([waitingTimeData hasStartTimes]) {
    WaitingTimeItem *waitingTimeItem = [waitingTimeData getWaitingTimeFor:attractionId];
    if (waitingTimeItem != nil && [waitingTimeItem hasStartTimes]) {
      NSArray *startTimes = [waitingTimeItem startTimes];
      NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:100] autorelease];
      int i = 0;
      int n = [startTimes count];
      if (onlyNext4Times && n > 4) {
        NSString *currentTime = [CalendarData stringFromTime:[NSDate date] considerTimeZoneAbbreviation:nil];
        for (NSString* time in startTimes) {
          if ([time compare:currentTime] >= 0) {
            n = i+4;
            break;
          }
          ++i;
          if (n-i == 4) break;
        }
      }
      while (i < n) {
        NSString* time = [startTimes objectAtIndex:i];
        if ([s length] > 0) {
          [s appendString:@", "];
          if (hasMoreThanOneTime != nil) *hasMoreThanOneTime = YES;
        }
        [s appendString:time];
        ++i;
      }
      return s;
    }
  }*/
  CalendarData *calendarData = [parkData getCalendarData];
  if (date == nil) date = [NSDate date];
  NSArray *calendarItems = [calendarData getCalendarItemsFor:attractionId forDate:date];
  if (calendarItems == nil || [calendarItems count] == 0) {
    if ([calendarData hasCalendarItemsAfterToday:attractionId]) return NSLocalizedString(@"attraction.today.closed", nil);
    return ([self waiting] && [self isShow])? NSLocalizedString(@"wait.times.overview.unknown", nil) : nil;
  }
  [calendarItems retain];
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:100] autorelease];
  int i = 0;
  int n = [calendarItems count];
  if (onlyNext4Times && n > 4) {
    NSString *currentTime = [CalendarData stringFromTime:date considerTimeZoneAbbreviation:nil];
    for (CalendarItem* item in calendarItems) {
      NSString *time = [CalendarData stringFromTime:item.startTime considerTimeZoneAbbreviation:nil];
      if ([time compare:currentTime] >= 0) {
        n = i+4;
        break;
      }
      ++i;
      if (n-i == 4) break;
    }
  }
  while (i < n) {
    CalendarItem* item = [calendarItems objectAtIndex:i];
    if ([s length] > 0) {
      [s appendString:@", "];
      if (hasMoreThanOneTime != nil) *hasMoreThanOneTime = YES;
    }
    [s appendString:[CalendarData stringFromTime:item.startTime considerTimeZoneAbbreviation:nil]];
    ++i;
  }
  [calendarItems release];
  return s;
}

-(NSString *)startingAndEndTimes:(NSString *)parkId forDate:(NSDate *)date maxTimes:(int)maxTimes {
  ParkData *parkData = [ParkData getParkData:parkId];
  CalendarData *calendarData = [parkData getCalendarData];
  if (date == nil) date = [NSDate date];
  NSArray *calendarItems = [calendarData getCalendarItemsFor:attractionId forDate:date];
  if (calendarItems == nil || [calendarItems count] == 0) {
    if ([calendarData hasCalendarItemsAfterToday:attractionId]) return NSLocalizedString(@"attraction.today.closed", nil);
    return ([self waiting] && [self isShow])? NSLocalizedString(@"wait.times.overview.unknown", nil) : nil;
  }
  [calendarItems retain];
  if (maxTimes > 0 && [parkData isEntryOrExitOfPark:attractionId]) maxTimes = -1;
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:100] autorelease];
  int i = 0;
  int n = [calendarItems count];
  if (maxTimes > 0 && n > maxTimes) {
    NSString *currentTime = [CalendarData stringFromTime:date considerTimeZoneAbbreviation:nil];
    for (CalendarItem* item in calendarItems) {
      NSString *time = [CalendarData stringFromTime:item.startTime considerTimeZoneAbbreviation:nil];
      if ([time compare:currentTime] >= 0) {
        n = i+maxTimes;
        break;
      }
      ++i;
      if (n-i == maxTimes) break;
    }
  }
  while (i < n) {
    CalendarItem* item = [calendarItems objectAtIndex:i];
    if (!item.extraHours) {
      if ([s length] > 0) [s appendString:@", "];
      [s appendString:[CalendarData stringFromTime:item.startTime considerTimeZoneAbbreviation:nil]];
      if (![item.startTime isEqualToDate:item.endTime]) {
        [s appendString:NSLocalizedString(@"attraction.times.separator", nil)];
        /*BOOL endTimeSet = NO;
        if ([parkData isEntryOrExitOfPark:attractionId]) {
          WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
          WaitingTimeItem *waitingTimeItem = [waitingTimeData getWaitingTimeFor:@"000"];
          if (waitingTimeItem != nil) {
            int t = waitingTimeItem.totalWaitingTime;
            if (t > 0) {
              [s appendFormat:@"%02d:%02d", t/100, t%100];
              endTimeSet = YES;
            }
          }
        }
        if (!endTimeSet) {*/
          [s appendString:[CalendarData stringFromTime:item.endTime considerTimeZoneAbbreviation:nil]];
          BOOL first = YES;
          NSDate *earliestStartTime = [calendarData getEarliestStartTimeFor:attractionId forDate:date forItem:item];
          NSDate *latestEndTime = [calendarData getLatestEndTimeFor:attractionId forDate:date forItem:item];
          if (![item.startTime isEqualToDate:earliestStartTime]) {
            [s appendFormat:@" (%@ ", NSLocalizedString(@"attraction.extra.hours", nil)];
            [s appendString:[CalendarData stringFromTime:earliestStartTime considerTimeZoneAbbreviation:nil]];
            [s appendString:NSLocalizedString(@"attraction.times.separator", nil)];
            [s appendString:[CalendarData stringFromTime:item.startTime considerTimeZoneAbbreviation:nil]];
            first = NO;
          }
          if (![item.endTime isEqualToDate:latestEndTime]) {
            if (first) [s appendFormat:@" (%@ ", NSLocalizedString(@"attraction.extra.hours", nil)];
            else [s appendString:@", "];
            [s appendString:[CalendarData stringFromTime:item.endTime considerTimeZoneAbbreviation:nil]];
            [s appendString:NSLocalizedString(@"attraction.times.separator", nil)];
            [s appendString:[CalendarData stringFromTime:latestEndTime considerTimeZoneAbbreviation:nil]];
            [s appendString:@")"];
          } else if (!first) [s appendString:@")"];
        //}
      }
    }
    ++i;
  }
  [calendarItems release];
  return s;
}

-(NSString *)entranceStartingAndEndTimes:(NSString *)parkId forDate:(NSDate *)date {
  //ParkData *parkData = [ParkData getParkData:parkId];
  //if (![parkData isEntryOrExitOfPark:attractionId]) return nil;
  NSString *startingAndEndTimes = [self startingAndEndTimes:parkId forDate:date maxTimes:-1];
  if (startingAndEndTimes == nil) return nil;
  startingAndEndTimes = [startingAndEndTimes stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@" (%@", NSLocalizedString(@"attraction.extra.hours", nil)] withString:[NSString stringWithFormat:@"\n%@:", NSLocalizedString(@"attraction.extra.hours", nil)]];
  startingAndEndTimes = [startingAndEndTimes stringByReplacingOccurrencesOfString:@", " withString:[NSString stringWithFormat:@"\n%@: ", NSLocalizedString(@"attraction.extra.hours", nil)]];
  startingAndEndTimes = [startingAndEndTimes stringByReplacingOccurrencesOfString:@")" withString:@""];
  return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"attraction.park.hours", nil), startingAndEndTimes];
}

-(NSString *)moreSpaceStartingAndEndTimes:(NSString *)startingAndEndTimes {
  NSRange range = [startingAndEndTimes rangeOfString:NSLocalizedString(@"attraction.extra.hours", nil)];
  if (range.length > 0) return startingAndEndTimes;
  NSString *s = [NSString stringWithFormat:@" %@ ", NSLocalizedString(@"attraction.times.separator", nil)];
  return [startingAndEndTimes stringByReplacingOccurrencesOfString:NSLocalizedString(@"attraction.times.separator", nil) withString:s];
}

-(BOOL)isRealAttraction {
  Categories *categories = [Categories getCategories];
  NSArray *categoryIds = [categories getCategoryIdsForIdx:typeIdx];
  if (categoryIds != nil) {
    for (NSString *cId in categoryIds) {
      if ([categories isExcludingCategoryId:cId]) return NO;
    }
  }
  return YES;
}

-(BOOL)isClosed:(NSString *)parkId {
  ParkData *parkData = [ParkData getParkData:parkId];
  if (parkData.hasWinterData) {
    if (parkData.winterDataEnabled) {
      if (!winter) return YES;
    } else {
      if (!sommer) return YES;
    }
  }
  return NO;//[parkData isTodayClosed];
}

+(NSArray *)getAllRecommendedAttractions:(NSString *)parkId {
  NSDictionary *allAttractions = [Attraction getAllAttractions:parkId reload:NO];
  NSMutableArray *recommendation = [[[NSMutableArray alloc] initWithCapacity:[allAttractions count]] autorelease];
  ParkData *parkData = [ParkData getParkData:parkId];
  ProfileData *profileData = [ProfileData getProfileData];
  NSEnumerator *i = [allAttractions objectEnumerator];
  while (true) {
    Attraction *attraction = [i nextObject];
    if (!attraction) break;
    int rating = [parkData getPersonalRating:attraction.attractionId];
    double preferenceFit = [profileData percentageOfPreferenceFit:attraction parkId:parkId personalAttractionRating:rating adultAge:parkData.adultAge];
    if (preferenceFit >= profileData.recommendationMatch) [recommendation addObject:attraction];
  }
  return recommendation;
}

+(Attraction *)getMostRecommendedAttraction:(NSString *)parkId {
  NSDictionary *allAttractions = [Attraction getAllAttractions:parkId reload:NO];
  ParkData *parkData = [ParkData getParkData:parkId];
  ProfileData *profileData = [ProfileData getProfileData];
  double bestFit = 0.0;
  Attraction *mostRecommendedAttraction = nil;
  NSEnumerator *i = [allAttractions objectEnumerator];
  while (true) {
    Attraction *attraction = [i nextObject];
    if (!attraction) break;
    int rating = [parkData getPersonalRating:attraction.attractionId];
    double preferenceFit = [profileData percentageOfPreferenceFit:attraction parkId:parkId personalAttractionRating:rating adultAge:parkData.adultAge];
    if (preferenceFit > bestFit) {
      mostRecommendedAttraction = attraction;
      bestFit = preferenceFit;
    }
  }
  return mostRecommendedAttraction;
}

+(NSDictionary *)categories:(NSString *)categoryName parkId:(NSString *)parkId checkThemeArea:(BOOL)checkThemeArea checkCategory:(BOOL)checkCategory checkAllCategories:(BOOL)checkAllCategories {
  if (!checkThemeArea && !checkCategory && !checkAllCategories) return nil;
  Categories *categories = [Categories getCategories];
  NSString *categoryId = [categories getCategoryOrTypeId:categoryName];
  NSDictionary *allAttractions = [Attraction getAllAttractions:parkId reload:NO];
  NSMutableDictionary *frequency = [[[NSMutableDictionary alloc] initWithCapacity:[allAttractions count]] autorelease];
  NSMutableArray *insertArray = [[NSMutableArray alloc] initWithCapacity:5];
  NSEnumerator *i = [allAttractions objectEnumerator];
  while (TRUE) {
    Attraction *attraction = [i nextObject];
    if (!attraction) break;
    [insertArray removeAllObjects];
    if (checkAllCategories) {
      NSArray *categoriesIds = [categories getCategoryIds:attraction.typeId];
      if (categoriesIds == nil) {
        NSLog(@"ERROR: Type %@ of attraction %@ is not defined", attraction.typeId, attraction.attractionId);
      } else {
        for (NSString *cId in categoriesIds) {
          if (![categories isExcludingCategoryId:cId]) {
            [insertArray addObject:[categories getCategoryName:cId]];
            if ([insertArray count] == 1 && checkThemeArea) break;
          }
        }
      }
    } else if (checkCategory) {
      NSString *tId = attraction.typeId;
      if ([categories isTypeId:tId inCategoryId:categoryId]) [insertArray addObject:[categories getTypeName:tId]];
    }
    if (checkThemeArea) {
      NSDictionary *attractionDetails = [attraction getAttractionDetails:parkId cache:YES];
      NSString *themeArea = [MenuData objectForKey:ATTRACTION_THEME_AREA at:attractionDetails];
      if (themeArea != nil && [themeArea length] > 0) [insertArray addObject:themeArea];
    }
    if ([insertArray count] > 0) {
      for (NSString *key in insertArray) {
        NSMutableArray *a = [frequency objectForKey:key];
        if (a == nil) a = [[NSMutableArray alloc] initWithCapacity:20];
        else a = [a retain];
        [a addObject:attraction.attractionId];
        [frequency setObject:a forKey:key];
        [a release];
      }
    }
  }
  [insertArray release];
  return frequency;
}

+(NSArray *)categoriesForParkId:(NSString *)parkId {
  Categories *categories = [Categories getCategories];
  NSDictionary *allAttractions = [Attraction getAllAttractions:parkId reload:NO];
  NSMutableSet *set = [[NSMutableSet alloc] initWithCapacity:[categories numberOfCategories]];
  NSEnumerator *i = [allAttractions objectEnumerator];
  while (TRUE) {
    Attraction *attraction = [i nextObject];
    if (!attraction) break;
    NSArray *a = [categories getCategoryNames:attraction.typeId];
    if (a != nil) [set addObjectsFromArray:a];
  }
  NSArray *result = [[set allObjects] sortedArrayUsingSelector:@selector(compare:)];
  [set release];
  return result;
}

+(NSString *)createAllAttractionsDocument:(NSString *)parkId {
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:10000] autorelease];
  [s appendString:@"<html><body><h1><center>"];
  [s appendString:[MenuData getParkName:parkId cache:YES]];
  [s appendString:@"</center></h1><br/>"];
  NSArray *allAttractions = [[Attraction getAllAttractions:parkId reload:NO] allValues];
  allAttractions = [allAttractions sortedArrayUsingSelector:@selector(compare:)];
  for (Attraction *attraction in allAttractions) {
    [s appendFormat:@"<h2>%@</h2><p><b>%@:</b> ", attraction.stringAttractionName, NSLocalizedString(@"attraction.details.category", nil)];
    NSString *typeName = attraction.typeName;
    Categories *categories = [Categories getCategories];
    NSArray *categoriesNames = [categories getCategoryNames:attraction.typeId];
    if (categoriesNames != nil) {
      int l = [categoriesNames count];
      if (l == 1) {
        [s appendString:[categoriesNames objectAtIndex:0]];
        //NSString *c = [categoriesNames objectAtIndex:0];
        //if (![c isEqualToString:typeName]) [s appendString:c];
      } else if (l > 1) {
        [s appendString:[categoriesNames objectAtIndex:0]];
        for (int i = 1; i < l; ++i) {
          [s appendString:@" / "];
          [s appendString:[categoriesNames objectAtIndex:i]];
        }
      }
    }
    if ([typeName length] > 0) [s appendFormat:@"<br/><b>%@:</b> %@", NSLocalizedString(@"attraction.details.type", nil), typeName];
    NSDictionary *attractionDetails = [attraction getAttractionDetails:parkId cache:YES];
    NSString *themeArea = [MenuData objectForKey:ATTRACTION_THEME_AREA at:attractionDetails];
    if ([themeArea length] > 0) [s appendFormat:@"<br/><b>%@:</b> %@", NSLocalizedString(@"attraction.details.themeArea", nil), themeArea];
    [s appendFormat:@"</p><br/><p>%@</p><br/>", [MenuData objectForKey:ATTRACTION_DESCRIPTION at:attractionDetails]];
  }
  [s appendString:@"</body></html>"];
  return s;
}

@end
