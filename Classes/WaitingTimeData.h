//
//  WaitingTimeData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.06.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExtendedTrackPoint.h"
#import "WaitingTimeItem.h"
#import "TourItem.h"
#import "CustomBadge.h"

@protocol WaitingTimeDataDelegate
-(void)waitingTimeDataUpdated;
@optional
-(void)refreshView;
@end

@interface WaitingTimeData : NSObject {
  UIViewController<WaitingTimeDataDelegate> *registeredViewController;
  BOOL connection;
  int lastStatusCode;
  int numberOfFailedAccess;
  BOOL initialized;
  //BOOL containsStartTimes;
  short lowWaitingTimeBelowValue;
  short midWaitingTimeBelowValue;
  NSString *identifier;
  NSString *parkId;
  double lastUpdate;
  double lastSuccessfulUpdate;
  NSMutableDictionary *waitingTimes;
  NSString *lastParsedWaitingTimes;
  NSDate *baseTime;
}

-(id)initWithParkId:(NSString *)pId registeredViewController:(UIViewController<WaitingTimeDataDelegate> *)viewController;

+(NSString *)encodeToPercentEscapeString:(NSString *)text;

-(void)update:(BOOL)initData;
-(void)enforceUpdate:(id)sender;
-(BOOL)lastAccessFailed;
-(NSString *)lastAccessFailureText;
-(NSArray *)getAttractionIdsWithWaitingTime;
-(WaitingTimeItem *)getWaitingTimeFor:(NSString *)attractionId; // in minutes
-(void)submitTourItem:(TourItem *)tourItem closed:(BOOL)closed entryLocation:(ExtendedTrackPoint *)entryLocation exitLocation:(ExtendedTrackPoint *)exitLocation;
-(BOOL)submitTourItem:(TourItem *)tourItem waitingTime:(short)waitingTime comment:(NSString *)comment;
-(void)registerViewController:(UIViewController<WaitingTimeDataDelegate> *)viewController;
-(void)unregisterViewController;

+(NSArray *)waitingTimeData;
+(int)closestTimeDataIndexFor:(int)waitingTime;
+(int)selectedWaitingTimeAtIndex:(int)index;

//-(BOOL)hasStartTimes;
-(BOOL)isClosed:(NSString *)attractionId considerCalendar:(BOOL)considerCalendar;
-(NSString *)setBadge:(CustomBadge *)waitingTimeBadge forWaitingTimeItem:(WaitingTimeItem *)waitingTimeItem atIndex:(int)index showAlsoOldTimes:(BOOL)showAlsoOldTimes;
-(NSString *)setLabel:(UILabel *)waitingTimeLabel forTourItem:(TourItem *)tourItem color:(BOOL)color extendedFormat:(BOOL)extendedFormat;
-(NSString *)colorCodeForTourItem:(TourItem *)tourItem;

@property (readonly) BOOL initialized;
@property (readonly) NSDate *baseTime;
@property (readonly) double lastSuccessfulUpdate;
@property (readonly) UIViewController<WaitingTimeDataDelegate> *registeredViewController;

@end
