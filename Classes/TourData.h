//
//  TourData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 04.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TourItem.h"

//#if TARGET_IPHONE_SIMULATOR
#ifdef DEBUG_MAP
//#define DEBUG_TOUR_OPTIMIZE 1
#define DEBUG_TOUR 1
#endif

#ifdef DEBUG_TOUR
#define MAX_NUMBER_OF_ITEMS_IN_TOUR 1000
#else
#define MAX_NUMBER_OF_ITEMS_IN_TOUR 100
#endif

#define MAX_NUMBER_OF_ITEMS_IN_TOUR_OPTIMIZING 10

@interface TourData : NSObject <NSCoding> {
  NSString *parkId;
  NSString *tourName;
  NSMutableArray *tourItems;
  double lastOptimized;
  NSArray *tourItemsOfLastAskIfTourOptimizing;
  BOOL askTourOptimizationAfterNextSwitchDone;
}

-(id)initWithParkId:(NSString *)pId tourName:(NSString *)tName;
-(id)initWithTourData:(TourData *)tourData;
-(BOOL)canAddToTour:(NSString *)attractionId;
-(int)add:(TourItem *)attraction startTime:(double)startTime;  // before last exit
-(void)insertAfterFirstDone:(TourItem *)attraction startTime:(double)startTime;
-(void)clear;
-(double)lastOptimized;
-(void)askNextTimeForTourOptimization;
-(void)dontAskNextTimeForTourOptimization;
-(double)optimize;
-(NSString *)createTrackDescription;
-(NSArray *)createRouteDescriptionFrom:(NSString *)fromAttractionId currentPosition:(BOOL)currentPosition to:(NSString *)toAttractionId attractionIdsOfDescription:(NSMutableArray *)attractionIdsOfDescription;
//-(NSString *)createRouteDescription;
-(BOOL)isAllDone;
-(BOOL)isExitOfParkDone;
-(void)switchDoneAtIndex:(NSUInteger)index startTime:(double)startTime completed:(BOOL)completed closed:(BOOL)closed submitWaitTime:(BOOL)submitWaitTime toTourItem:(BOOL)toTourItem;
-(int)scrollToIndex;
-(int)count;
-(TourItem *)lastObject;
-(TourItem *)objectAtIndex:(NSUInteger)index;
-(void)removeObjectAtIndex:(NSUInteger)index startTime:(double)startTime;
-(void)moveFrom:(NSUInteger)fromIndex to:(NSUInteger)toIndex startTime:(double)startTime;
-(NSString *)getNextTourAttractionId;
-(void)updateTourData:(double)startTime;
//-(double)getOverallTourDistance; // including walk to exit
-(double)getRemainingTourDistance; // exclude attractions which are done
-(int)getWalkingTime:(double)distance;
-(NSString *)getFormat:(int)walkingTime;
-(int)getOverallTourTime;  // in min
-(int)getRemainingTourTime;
-(int)getAttractionCount:(NSString *)attractionId;

@property (readonly, nonatomic) NSString *parkId;
@property (retain, nonatomic) NSString *tourName;
@property (retain, nonatomic) NSMutableArray *tourItems;
@property BOOL askTourOptimizationAfterNextSwitchDone;

@end
