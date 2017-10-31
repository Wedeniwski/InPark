//
//  Update.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 13.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "unzip.h"


#import "TrackPoint.h"
//#ifdef DEBUG_MAP
//#define UPDATE_INDEX @"inpark.private.info"
//#else
#define UPDATE_INDEX @"inpark.info"
//#endif

@protocol UpdateDelegate
-(void)status:(NSString *)status percentage:(double)percentage;
-(void)downloaded:(NSString *)number;
@end

@interface Update : NSObject {
@private
  id<UpdateDelegate> delegate;
  NSURLConnection *connection1;
  NSMutableData *data1;
  NSString *data1URL;
  int downloadedSize;
  int downloadedFileSize;
  BOOL hasProgress;
  int indexOfPathes;
  
@public
  NSArray *imagePathes;
  int numberOfFiles;
  NSString *parkId;
  NSString *parkGroupId;
  NSString *parkName;
  NSString *country;
  double version;  // number of seconds since January 1, 1970, 00:00:00 GMT
  NSString *path;
  int fileSize;
  BOOL isHD;
  NSString *hashCode;
}

-(id)init;
-(id)init:(NSString *)lineOfData owner:(id<UpdateDelegate>)owner;
-(id)initWithImageArray:(NSArray *)imageArray size:(int)size numberOfImages:(int)numberOfImages assoziation:(Update *)update;
-(id)initWithImageArray:(NSArray *)imageArray size:(int)size numberOfImages:(int)numberOfImages parkId:(NSString *)pId owner:(id<UpdateDelegate>)owner;

-(NSComparisonResult)compare:(Update *)otherUpdate;
-(BOOL)isMandetory:(NSArray *)mandetoryParkGroupIds;
-(void)updateImagePathes:(NSArray *)newImagePathes numberOfFiles:(int)newNumberOfFiles fileSize:(int)newFileSize;

+(NSString *)sourceDataPath;
+(NSString *)sizeToString:(unsigned long)size;
//+(NSData *)decompressGZip:(NSData *)data;
+(BOOL)decompressBZ2:(NSData *)data filePath:(NSString *)filePath;
+(NSArray *)availableUpdates:(id<UpdateDelegate>)owner includingHD:(BOOL)additionalImages checkVersionInfo:(BOOL)checkVersionInfo;
+(double)localTimeIntervalSinceNowOfData:(NSString *)localPath parkId:(NSString *)parkId;
+(NSString *)localDataPath:(NSString *)localPath parkId:(NSString *)parkId;
+(NSString *)onlineDataPath:(NSString *)dataPath hasPrefix:(NSString *)prefix useLocalDataIfNotOlder:(double)modificationTimeInHours parkId:(NSString *)parkId online:(BOOL *)online statusCode:(int *)statusCode;
+(BOOL)addSkipBackupAttributeToItemAtURL:(NSString *)path; // iOS >= 5.1 needed
-(void)replaceLocalData:(NSString *)sourcePath;
-(BOOL)unzipFile:(unzFile)file to:(NSString*)zipPath numberOfEntries:(int)numberOfEntries reportStatus:(BOOL)reportStatus;
-(void)update;
-(BOOL)hasProgress;
-(BOOL)isDownloading;
-(double)downloadedPercentage;

@property (readonly, nonatomic) id<UpdateDelegate> delegate;
@property (readonly, nonatomic) NSArray *imagePathes;
@property (readonly) int numberOfFiles;
@property (readonly, nonatomic) NSString *parkId;
@property (readonly, nonatomic) NSString *parkGroupId;
@property (readonly, nonatomic) NSString *parkName;
@property (readonly, nonatomic) NSString *country;
@property (readonly) double version;
@property (readonly, nonatomic) NSString *path;
@property (readonly) int fileSize;
@property (readonly) BOOL isHD;
@property (readonly, nonatomic) NSString *hashCode;

@end
