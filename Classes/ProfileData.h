//
//  ProfileData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 06.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Attraction.h"

@interface ProfileData : NSObject {
  double avgWalkingSpeed; // in km/h
  NSString *userName;
  int age;
  int height; // negative value means actual height is lower than
  char sex; // M - male, F - female
  int maxParkVisitTime;  // in min
  int maxTourDistance;  // in m
  int maxAcceptedWaitingTime; // in min
  int timeBeforeShow; // in min
  int thrillFactor;
  int waterFactor;
  int familyFactor;
  int ratingWeigth;
  double recommendationMatch;
  BOOL considerOnlyHandicappedAccessible;
  char optimization;  // T - time, D - walking distance (include trains)
  char callOptimization;  // Q - ask, A - automatic, I - inactive
  BOOL considerAccompanist;
  int ageAccompanist;
  int heightAccompanist;
}

-(id)init;
+(ProfileData *)getProfileData:(BOOL)reload;
+(ProfileData *)getProfileData;

-(void)setUserName:(NSString *)newUserName;
-(double)percentageOfPreferenceFit:(Attraction *)attraction parkId:(NSString *)parkId personalAttractionRating:(int)personalAttractionRating adultAge:(int)adultAge;
-(BOOL)askForOptimization;
-(BOOL)automaticOptimization;

@property (readonly) double avgWalkingSpeed;
@property (readonly) NSString *userName;
@property (readonly) int age;
@property (readonly) int height;
@property (readonly) char sex;
@property (readonly) int maxParkVisitTime;
@property (readonly) int maxTourDistance;
@property (readonly) int maxAcceptedWaitingTime;
@property (readonly) int timeBeforeShow;
@property (readonly) int thrillFactor;
@property (readonly) int waterFactor;
@property (readonly) int familyFactor;
@property (readonly) double recommendationMatch;
@property (readonly) int ratingWeight;
@property (readonly) BOOL considerOnlyHandicappedAccessible;
@property (readonly) char optimization;
@property (readonly) BOOL considerAccompanist;
@property (readonly) int ageAccompanist;
@property (readonly) int heightAccompanist;

@end
