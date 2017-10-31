//
//  Attraction.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 27.08.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "TrackPoint.h"

#define ATTRACTION_DESCRIPTION @"Kurzbeschreibung"
#define ATTRACTION_THEME_AREA @"Themenbereich"

@interface AttractionAttributes : NSObject  {
  BOOL train;
  NSString *nextStationId; // only for trains
  BOOL fastLaneDefined;
  BOOL fastLane;
  short ageRestricted;
  short ageRestricted2;
  BOOL ageRestrictedBelow;
  short ageRestrictedBelowAdultAccompany;
  short ageRestrictedAboveChildAccompany;
  short heightRestricted;
  short heightRestricted2;
  BOOL heightRestrictedBelow;
  short heightRestrictedBelowAdultAccompany;
  short heightRestrictedAboveChildAccompany;
  short thrillFamilyWaterFactor;
  short duration; // in min
  short defaultWaiting; // in min
  BOOL waiting;
}

-(id)initWithAttractionId:(NSString *)aId parkId:parkId attractionDetails:(NSDictionary *)attractionDetails;
-(BOOL)isEmpty;
-(void)getThrillFactor:(int *)thrillFactor familyFactor:(int *)familyFactor waterFactor:(int *)waterFactor;

@property (readonly, nonatomic) NSString *nextStationId;
@property (readonly) BOOL fastLaneDefined;
@property (readonly) BOOL fastLane;
@property (readonly) short ageRestricted;
@property (readonly) short ageRestricted2;
@property (readonly) BOOL ageRestrictedBelow;
@property (readonly) short ageRestrictedBelowAdultAccompany;
@property (readonly) short ageRestrictedAboveChildAccompany;
@property (readonly) short heightRestricted;
@property (readonly) short heightRestricted2;
@property (readonly) BOOL heightRestrictedBelow;
@property (readonly) short heightRestrictedBelowAdultAccompany;
@property (readonly) short heightRestrictedAboveChildAccompany;
@property (readonly) short duration;
@property (readonly) short defaultWaiting;
@property (readonly) BOOL waiting;

@end


@interface Attraction : NSObject {
  NSString *attractionId;
  char *attractionName;
  char *imageName;
  BOOL imageExtensions;
  short typeIdx;
  BOOL tourPoint;
  BOOL sommer;
  BOOL winter;
  BOOL handicappedAccessible;
  AttractionAttributes *attributes;
}

-(id)initWithAttractionId:(NSString *)aId parkId:parkId attractionDetails:(NSDictionary *)attractionDetails;
-(NSComparisonResult)compare:(Attraction *)otherAttraction;

+(NSDictionary *)getAllAttractions:(NSString *)parkId reload:(BOOL)reload;
-(const char*)attractionName;
-(NSString *)stringAttractionName;
-(NSString *)imageName:(NSString *)parkId;
-(NSString *)imagePath:(NSString *)parkId;
-(NSString *)typeId;
-(NSString *)typeName;
-(BOOL)hasAttributes;
-(NSString *)nextStationId;
-(BOOL)fastLaneDefined;
-(BOOL)fastLane;
-(short)duration;
-(short)defaultWaiting;
-(BOOL)waiting;
-(BOOL)isTrain;
-(BOOL)isDining;
-(BOOL)isShow;
-(void)getThrillFactor:(int *)thrillFactor familyFactor:(int *)familyFactor waterFactor:(int *)waterFactor;
-(NSString *)ageRestriction;
-(NSString *)heightRestriction;
+(NSString *)getShortAttractionId:(NSString *)attractionId;
+(BOOL)isInternalId:(NSString *)attractionId;
//+(BOOL)isShortAttractionId:(NSString *)attractionId;
+(Attraction *)getAttraction:(NSString *)parkId attractionId:(NSString *)attractionId;
+(Attraction *)getAttraction:(NSString *)parkId attractionName:(const char *)attractionName;
+(NSArray *)getAttractions:(NSString *)parkId typeId:(NSString *)typeId;
-(NSDictionary *)getAttractionDetails:(NSString *)parkId cache:(BOOL)cache;
-(BOOL)needToAttendAtOpeningTime:(NSString *)parkId forDate:(NSDate *)date;
-(NSString *)startingTimes:(NSString *)parkId forDate:(NSDate *)date onlyNext4Times:(BOOL)onlyNext4Times hasMoreThanOneTime:(BOOL *)hasMoreThanOneTime;
-(NSString *)startingAndEndTimes:(NSString *)parkId forDate:(NSDate *)date maxTimes:(int)maxTimes;
-(NSString *)entranceStartingAndEndTimes:(NSString *)parkId forDate:(NSDate *)date;
-(NSString *)moreSpaceStartingAndEndTimes:(NSString *)startingAndEndTimes;
-(BOOL)isRealAttraction;
-(BOOL)isClosed:(NSString *)parkId;
+(NSArray *)getAllRecommendedAttractions:(NSString *)parkId;
+(Attraction *)getMostRecommendedAttraction:(NSString *)parkId;
+(NSDictionary *)categories:(NSString *)categoryName parkId:(NSString *)parkId checkThemeArea:(BOOL)checkThemeArea checkCategory:(BOOL)checkCategory checkAllCategories:(BOOL)checkAllCategories;
+(NSArray *)categoriesForParkId:(NSString *)parkId;
+(NSString *)createAllAttractionsDocument:(NSString *)parkId;

@property (readonly, nonatomic) NSString *attractionId;
@property (readonly) short typeIdx;
@property (readonly) BOOL tourPoint;
@property (readonly) BOOL sommer;
@property (readonly) BOOL winter;
@property (readonly) BOOL handicappedAccessible;
@property (readonly, nonatomic) AttractionAttributes *attributes;

@end
