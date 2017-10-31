//
//  ParkData.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "CompileSettings.h"
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "TrackPoint.h"
#import "TrackSegment.h"
#import "TrackData.h"
#import "TourData.h"
#import "CalendarData.h"
#import "NewsData.h"
#import "WaitingTimeData.h"

#define CORE_DATA_ID @"core"
#define CORE_DATA_NAME @"Core Data"

#define UNKNOWN_ATTRACTION_ID @""
#define PARKING_ATTRACTION_ID @"Parking"

#define ALL_WITH_WAIT_TIME @"allWithWaitTime"
#define ALL_FAVORITES @"allFavorites"
#define PREFIX_FAVORITES @"favorites_"

@interface ParkData : NSObject <NSCoding> {
@private
  BOOL dataChanges;
  BOOL isInitialized;
  BOOL rulesForCommentsAccepted;
  BOOL tutorialWaitTimeViewed;
  double versionOfDataFile;
  double versionOfIndexFile;
  double versionOfData;
  double lastUpdateCheck;
  int numberOfAvailableUpdates;
  int numberOfNewNewsEntries;
  BOOL currentTourNotInitialized;
  NSString *timeZoneAbbreviation;
  MKCoordinateRegion parkRegion;
  NSMutableDictionary *attractionComments;
  NSMutableDictionary *personalAttractionRatings;
  NSMutableSet *attractionFavorites;
  NSMutableDictionary *completedTourData;
  NSMutableDictionary *toursData;
  TrackData *currentTrackData;
  TrackSegment *lastTrackFromParking;
  NSString *lastParkingNotes;
  // internal attributes for caching
  NSString *cachedMainEntryOfPark;
  TrackPoint *lastTrackPointForEntryOfPark;
  NSString *lastIdEntryOfPark;
  NSString *cachedMainExitOfPark;
  TrackPoint *lastTrackPointForExitOfPark;
  NSString *lastIdExitOfPark;

  NSMutableDictionary *trackSegments;
  short *shortestPath;
  int nShortestPath;
  //NSMutableDictionary *distances;  // ToDo: check if really needed
  NSMutableArray *allAttractionIds;  // To reduce memory usage
  NSMutableDictionary *allRelatedAttractionIds; // cache to reduce numerous NSString object creations

  CalendarData *calendarData;
  NewsData *newsData;
  WaitingTimeData *waitingTimeData;
  NSDate *cachedParkClosedDate;
  BOOL parkIsTodayClosed;

@public
  int adultAge;
  BOOL hasWinterData;
  NSString *parkId;
  NSString *parkGroupId;
  NSString *fastLaneId;
  NSString *mapCopyright;
  NSString *currentTourName;
  NSMutableDictionary *parkAttractionLocations; // sorted by locationId
  NSMutableDictionary *sameAttractionIds;
}

+(ParkData *)getParkData:(NSString *)parkId reload:(BOOL)reload;
+(ParkData *)getParkData:(NSString *)parkId;
+(NSArray *)getInstalledParkIds; // incl. CORE_DATA_ID
+(NSArray *)getMissingParkIds:(NSArray *)parkIds; // could happen if iOS is deleting files outside Document folder
+(BOOL)hasParkDataFor:(NSString *)parkGroupId;
+(NSArray *)getParkDataListFor:(NSString *)parkGroupId;

-(id)initWithParkId:(NSString *)pId versionOfData:(double)version;
-(NSComparisonResult)compare:(ParkData *)otherParkData;
-(BOOL)isInitialized;
-(BOOL)isTodayClosed;
-(void)clearCachedData;
-(void)resetVersionOfData;
-(void)setupData;
-(void)setDataChanges;
-(void)setVersionOfIndexFile:(double)d;
-(void)setVersionOfDataFile:(double)d;
-(void)setRulesForCommentsAccepted:(BOOL)b;
-(void)setTutorialWaitTimeViewed:(BOOL)b;
-(void)setLastUpdateCheck:(double)d;
-(void)setNumberOfAvailableUpdates:(int)i;
-(void)setCurrentTrackData:(TrackData *)trackData;
-(void)save:(BOOL)save;
+(void)save;
+(BOOL)addParkData:(NSString *)parkId versionOfData:(double)version;
+(void)removeParkData:(NSString *)parkId;

+(NSString *)getParkDataVersions;
+(BOOL)checkIfUpdateIsNeeded:(NSString*)parkId;
+(BOOL)isUpdateAvailable:(NSArray *)versionInfo;
+(void)updateLastUpdateCheck:(NSArray *)availableUpdates versionInfo:(NSArray *)versionInfo;
+(BOOL)isAvailableUpdatesActive;
+(int)availableUpdates:(BOOL)reload;

-(BOOL)isCalendarDataInitialized;
-(CalendarData *)getCalendarData:(UIViewController<CalendarDataDelegate> *)viewController;
-(CalendarData *)getCalendarData;
-(BOOL)isNewsDataInitialized;
-(NewsData *)getNewsData;
-(void)resetNumberOfNewNewsEntries;
-(WaitingTimeData *)getWaitingTimeData:(UIViewController<WaitingTimeDataDelegate> *)viewController;
-(WaitingTimeData *)getWaitingTimeData;

-(NSString *)getEntryOfPark:(TrackPoint *)trackPoint; // closest entry to trackpoint if not nil
-(NSString *)getExitOfPark:(TrackPoint *)trackPoint; // closest exit to trackpoint if not nil
-(BOOL)isEntryOfPark:(NSString *)attractionId;
-(BOOL)isExitOfPark:(NSString *)attractionId;
-(BOOL)isEntryOrExitOfPark:(NSString *)attractionId;
-(BOOL)isEntryUnique:(NSString *)attractionId;
-(NSString *)firstEntryAttractionIdOf:(NSString *)attractionId;
-(NSString *)exitAttractionIdOf:(NSString *)attractionId;
-(BOOL)isEntryExitSame:(NSString *)attractionId;
-(NSArray *)allLocationIdxOf:(NSString *)attractionId attractionIdx:(int)attractionIdx;
-(NSArray *)allAttractionRelatedLocationIdsOf:(NSString *)attractionId; // incl. fast lane and exit
-(NSString *)getRootAttractionId:(NSString *)attractionId;
-(NSString *)getAttractionDataId:(NSString *)attractionId;
-(BOOL)isExitAttractionId:(NSString *)attractionId;
-(NSString *)getEntryAttractionId:(NSString *)exitAttractionId;
-(BOOL)isFastLaneEntryAttractionId:(NSString *)attractionId;
-(NSString *)getFastLaneEntryAttractionIdOf:(NSString *)attractionId;

-(NSArray *)getTourNames;
-(BOOL)setCurrentTourName:(NSString *)newTourName;
-(void)addEntryExitToTourData:(TourData *)tourData;
-(BOOL)addNewTourName:(NSString *)newTourName;
-(void)deleteTour:(NSString *)tourName;
-(BOOL)renameTourNameFrom:(NSString *)fromTourName to:(NSString *)toTourName;
-(TourData *)getTourData:(NSString *)tourName;
-(TrackData *)completeCurrentTrack;
-(NSArray *)getCompletedTracks;
-(TrackData *)getTrackData:(NSString *)trackName;
-(void)removeTrackData:(NSString *)trackName;

-(void)updateParkingTrack;

-(NSArray *)getTourSuggestions;
-(NSArray *)getTourSuggestion:(NSString *)tourName;

-(NSString *)getCommentsHistory:(NSString *)attractionId;
-(NSArray *)getComments:(NSString *)attractionId;
-(void)addComment:(NSString *)comment attractionId:(NSString *)attractionId;

-(int)getPersonalRating:(NSString *)attractionId;
-(void)setPersonalRating:(int)rating attractionId:(NSString *)attractionId;
-(NSString *)getPersonalRatingAsStars:(NSString *)attractionId;

-(BOOL)isFavorite:(NSString *)attractionId;
-(void)addFavorite:(NSString *)attractionId;
-(void)removeFavorite:(NSString *)attractionId;

-(NSMutableDictionary *)selectedCategoriesForCategoryNames:(NSArray *)categoryNames;
-(void)saveChangedCategories:(NSDictionary *)selectedCategories;

-(TrackPoint *)getAttractionLocation:(NSString *)attractionId;
-(void)addAttractionId:(NSString *)attractionId atLocation:(TrackPoint *)trackPoint;
-(void)renameAttractionId:(NSString *)attractionId to:(NSString *)newAttractionId;
-(void)setAttractionLocation:(NSString *)attractionId latitude:(double)latitude longitude:(double)longitude;
-(void)changeAttractionLocation:(NSString *)attractionId latitudeDelta:(double)latitudeDelta longitudeDelta:(double)longitudeDelta;
-(void)removeAttractionLocation:(NSString *)attractionId;
// array of attraction IDs where from and to is excluded
-(NSArray *)getPath:(int)fromAttractionIdx toAttractionIdx:(int)toAttractionIdx; // shortest path: list of track segments 
-(BOOL)isPathInverse:(NSString *)fromAttractionId toAttractionId:(NSString *)toAttractionId;
//-(BOOL)isSegementId:(TrackSegmentId *)segmentId startingWith:(NSString *)attractionId;
+(NSArray *)reversePath:(NSArray *)array;
-(NSArray *)getMinPathFrom:(NSString *)fromAttractionId fromAll:(BOOL)fromAll toAllAttractionId:(NSString *)toAttractionId;
-(TrackSegment *)getTrackSegment:(NSString *)fromAttractionId toAttractionId:(NSString *)toAttractionId;
-(double)currentDistanceToAll:(NSString *)toAttractionId tolerance:(double *)tolerance fromAttractionId:(NSString **)fromAttractionId;
-(double)distance:(NSString *)fromAttractionId fromAll:(BOOL)fromAll toAttractionId:(NSString *)toAttractionId toAll:(BOOL)toAll path:(NSArray **)path;
-(NSSet *)allConnectedAttractionIds:(NSString *)attractionId;
-(NSSet *)connectedAttractionIds:(NSString *)attractionId;
-(NSString *)closestAttractionId:(NSString *)attractionId distance:(double *)distance;
-(NSString *)closestLocationIdEstimateForTrackPoint:(TrackPoint *)trackPoint distance:(double *)distance;
-(NSString *)closestAttractionIdEstimateForTrackPoint:(TrackPoint *)trackPoint distance:(double *)distance;
-(TrackSegment *)closestTrackSegmentForTrackPoint:(TrackPoint *)trackPoint;
//-(NSString *)closestAttractionIdForTrackPoint:(TrackPoint *)trackPoint;
-(MKCoordinateRegion)getParkRegion;
-(BOOL)isInsidePark:(TrackPoint *)trackPoint;
-(BOOL)isCurrentlyInsidePark;

-(NSArray *)getTrainAttractionRoute:(NSString *)attractionId oneWay:(BOOL *)oneWay;
-(NSArray *)getNextTrainStationAttractions:(Attraction *)attraction;
-(int)getTrainAttractionDurationFrom:(NSString *)fromAttractionId to:(NSString *)toAttractionId; // in min

-(NSString *)writeGPX:(NSString *)name;
-(BOOL)readGPSData;

@property (readonly) BOOL rulesForCommentsAccepted;
@property (readonly) BOOL tutorialWaitTimeViewed;
@property (readonly) double versionOfDataFile;
@property (readonly) double versionOfIndexFile;
@property (readonly) double versionOfData;
@property (readonly) double lastUpdateCheck;
@property (readonly) int numberOfAvailableUpdates;
@property (readonly) int numberOfNewNewsEntries;
@property (readonly) NSString *timeZoneAbbreviation;
@property (readonly, nonatomic) NSDictionary *attractionComments;
@property (readonly, nonatomic) NSDictionary *personalAttractionRatings;
@property (readonly, nonatomic) NSSet *attractionFavorites;
@property (readonly, nonatomic) NSDictionary *completedTourData;
@property (readonly, nonatomic) NSDictionary *toursData;
@property (readonly, nonatomic) TrackData *currentTrackData;
@property (readonly, nonatomic) TrackSegment *lastTrackFromParking;
@property (readonly, nonatomic) NSString *lastParkingNotes;
@property (readonly, nonatomic) NSMutableDictionary *trackSegments;
@property (readonly, nonatomic) NSArray *allAttractionIds;
@property (readonly) int adultAge;
@property (readonly) BOOL hasWinterData;
@property BOOL winterDataEnabled;
@property (readonly, nonatomic) NSString *parkId;
@property (readonly, nonatomic) NSString *parkGroupId;
@property (readonly, nonatomic) NSString *fastLaneId;
@property (readonly, nonatomic) NSString *mapCopyright;
@property (readonly, nonatomic) NSString *currentTourName;
@property (readonly, nonatomic) NSDictionary *parkAttractionLocations;
@property (readonly, nonatomic) NSDictionary *sameAttractionIds;

@end
