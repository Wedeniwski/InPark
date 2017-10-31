//
//  Update.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 13.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "Update.h"
#import "MenuData.h"
#import "HelpData.h"
#import "ParkData.h"
#import "ImageData.h"
#import "SettingsData.h"
#import "CalendarData.h"
#import "Categories.h"
#import "Attraction.h"
#import "md5.h"
#import "bzlib.h"

@implementation Update

@synthesize delegate;
@synthesize imagePathes;
@synthesize numberOfFiles;
@synthesize parkId, parkGroupId, parkName, country, path, hashCode;
@synthesize version;
@synthesize fileSize;
@synthesize isHD;

-(id)init {
  self = [super init];
  if (self != nil) {
    connection1 = nil;
    data1 = nil;
    data1URL = nil;
    downloadedSize = 0;
    downloadedFileSize = 0;
    hasProgress = NO;
    indexOfPathes = 0;
    delegate = nil;
    imagePathes = nil;
    numberOfFiles = 0;
    parkId = nil;
    parkGroupId = nil;
    parkName = nil;
    country = nil;
    version = 0.0;
    path = nil;
    fileSize = 25000;
    isHD = NO;
    hashCode = nil;
  }
  return self;
}

-(id)init:(NSString *)lineOfData owner:(id<UpdateDelegate>)owner {
  self = [super init];
  if (self != nil) {
    connection1 = nil;
    data1 = nil;
    data1URL = nil;
    downloadedSize = 0;
    downloadedFileSize = 0;
    hasProgress = NO;
    indexOfPathes = 0;
    delegate = owner;
    imagePathes = nil;
    numberOfFiles = 0;
    NSArray *values = [lineOfData componentsSeparatedByString:@","];
    if ([values count] == 8) {
      parkId = [[values objectAtIndex:0] retain];
      parkGroupId = [[values objectAtIndex:1] retain];
      parkName = ([parkId isEqualToString:CORE_DATA_ID])? NSLocalizedString(@"update.core.data", nil) : [[values objectAtIndex:2] retain];
      country = [[values objectAtIndex:3] retain];
      version = [[values objectAtIndex:4] doubleValue];
      path = [[values objectAtIndex:5] retain];
      fileSize = [[values objectAtIndex:6] intValue];
      hashCode = [[values objectAtIndex:7] retain];
    }
    isHD = NO;
  }
  return self;
}

-(id)initWithImageArray:(NSArray *)imageArray size:(int)size numberOfImages:(int)numberOfImages assoziation:(Update *)update {
  self = [super init];
  if (self != nil) {
    connection1 = nil;
    data1 = nil;
    data1URL = nil;
    downloadedSize = 0;
    downloadedFileSize = 0;
    hasProgress = NO;
    indexOfPathes = 0;
    delegate = update.delegate;
    imagePathes = [[NSArray alloc] initWithArray:imageArray];
    numberOfFiles = numberOfImages;
    parkId = [update.parkId retain];
    parkGroupId = [update.parkGroupId retain];
    parkName = ([parkId isEqualToString:CORE_DATA_ID])? @"" : [[NSString alloc] initWithFormat:@"%@ (HD)", update.parkName];
    country = [update.country retain];
    version = 0.0;
    path = nil;
    fileSize = size;
    isHD = YES;
    hashCode = nil;
  }
  return self;
}

-(id)initWithImageArray:(NSArray *)imageArray size:(int)size numberOfImages:(int)numberOfImages parkId:(NSString *)pId owner:(id<UpdateDelegate>)owner {
  self = [super init];
  if (self != nil) {
    connection1 = nil;
    data1 = nil;
    data1URL = nil;
    downloadedSize = 0;
    downloadedFileSize = 0;
    hasProgress = NO;
    indexOfPathes = 0;
    delegate = owner;
    imagePathes = [[NSArray alloc] initWithArray:imageArray];
    numberOfFiles = numberOfImages;
    parkId = [pId retain];
    parkGroupId = nil;
    parkName = nil;
    country = nil;
    version = 0.0;
    path = nil;
    fileSize = size;
    isHD = NO;
    hashCode = nil;
  }
  return self;
}

-(void)dealloc {
  if (![parkId isEqualToString:CORE_DATA_ID]) [parkName release];
  parkName = nil;
  [data1 release];
  data1 = nil;
  [data1URL release];
  data1URL = nil;
  [imagePathes release];
  imagePathes = nil;
  [parkId release];
  parkId = nil;
  [parkGroupId release];
  parkGroupId = nil;
  [country release];
  country = nil;
  [path release];
  path = nil;
  [hashCode release];
  hashCode = nil;
  [super dealloc];
}

-(NSComparisonResult)compare:(Update *)otherUpdate {
  return [NSLocalizedString(country, nil) caseInsensitiveCompare:NSLocalizedString(otherUpdate.country, nil)];
}

-(BOOL)isMandetory:(NSArray *)mandetoryParkGroupIds {
  if ([parkId isEqualToString:CORE_DATA_ID]) return YES;
  if (mandetoryParkGroupIds != nil && !isHD) {
    return ([mandetoryParkGroupIds containsObject:parkId] || [mandetoryParkGroupIds containsObject:parkGroupId]);
  }
  return NO;
}

-(void)updateImagePathes:(NSArray *)newImagePathes numberOfFiles:(int)newNumberOfFiles fileSize:(int)newFileSize {
  if (imagePathes != nil) {
    [imagePathes release];
    imagePathes = [newImagePathes retain];
    numberOfFiles = newNumberOfFiles;
    fileSize = newFileSize;
  }
}

+(NSString *)sourceDataPath {
  return @"http://www.inpark.info/data/"; //@"/Users/Wedeniwski/Documents/iPhone Projects/InPark/data";
}

+(NSString *)sizeToString:(unsigned long)size {
  if (size < 1023) return [NSString stringWithFormat:@"%d bytes", (int)size];
  float fSize = size/1024.0f;
  if (fSize < 1023) return [NSString stringWithFormat:@"%1.0f kB", fSize];
  fSize /= 1024;
  if (fSize < 1023) return [NSString stringWithFormat:@"%1.2f MB", fSize];
  fSize /= 1024;
  return [NSString stringWithFormat:@"%1.3f GB", fSize];
}

+(BOOL)writeData:(NSData *)data toFile:(NSString *)destinationPath {
  return ([data length] > 0 && [data writeToFile:destinationPath atomically:YES]);
}

/*+(NSData *)decompressGZip:(NSData *)data {
  NSUInteger l = [data length];
  if (l == 0 || l > UINT_MAX) return nil;
  z_stream stream;
  bzero(&stream, sizeof(z_stream));
  stream.avail_in = l;
  stream.next_in = (unsigned char*)[data bytes];
  stream.total_out = 0;
  stream.zalloc = Z_NULL;
  stream.zfree = Z_NULL;
  int r = inflateInit2(&stream, 47);
    //int retCode = inflateInit2(&stream, 31);
  if (r != Z_OK) {
    NSLog(@"failed to init for inflate, error %d", r);
    return nil;
  }
  NSMutableData *result = [NSMutableData dataWithCapacity:4*l];
  //unsigned char output[kMemoryChunkSize];
  do {
    NSLog(@"inflate: %ld", stream.total_out);
    if (stream.total_out >= result.length) [result increaseLengthBy:result.length];
    stream.avail_out = (uInt)result.length - (uInt)stream.total_out;
    stream.next_out = [result mutableBytes] + stream.total_out;
    r = inflate (&stream, Z_SYNC_FLUSH);
    //stream.avail_out = kMemoryChunkSize;
    //stream.next_out = output;
    //r = inflate(&stream, Z_NO_FLUSH);
    if (r != Z_OK && r != Z_STREAM_END) {
      NSLog(@"Error during inflate, error %d: %s", r, stream.msg);
      inflateEnd(&stream);
      return nil;
    }
    //unsigned n = kMemoryChunkSize-stream.avail_out;
    //if (n > 0) [result appendBytes:output length:n];
  } while (r == Z_OK);
  if (stream.avail_in != 0) {
    NSLog(@"%u bytes left?", stream.avail_in);
    result = nil;
  }
  inflateEnd(&stream);
  result.length = stream.total_out;
  NSLog(@"orig size %d - decompressed %d", l, [result length]);
  return (r == Z_STREAM_END)? result : nil;
}*/

+(BOOL)decompressBZ2:(NSData *)data filePath:(NSString *)filePath {
  BOOL successful = NO;
  NSString *destinationPath = [filePath stringByAppendingString:@".bz2"];
  if ([Update writeData:data toFile:destinationPath]) {
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BZFILE *bz2fp = BZ2_bzopen([destinationPath UTF8String], "rb");
    if (bz2fp == NULL) {
      NSLog(@"Can't open bzip2 stream (%@)", destinationPath);
    } else {
      NSString *sourcePath = filePath;
      NSString *tmpUnzipPath = [sourcePath stringByAppendingString:@"-tmp"];
      FILE *fp = fopen([tmpUnzipPath UTF8String], "wb");
      if (fp == NULL) {
        NSLog(@"Can't open file (%@)", tmpUnzipPath);
      } else {
        char buffer[0x10000];
        while (TRUE) {
          int n = BZ2_bzread(bz2fp, buffer, 0x10000);
          if (n <= 0) break;
          fwrite(buffer, 1, n, fp);
        }
        fclose(fp);
        [fileManager removeItemAtPath:sourcePath error:&error];
        if (error != nil) {
          NSLog(@"File %@ could not be deleted", sourcePath);
          error = nil;
        }
        [fileManager moveItemAtPath:tmpUnzipPath toPath:sourcePath error:&error];
        if (error != nil) {
          NSLog(@"Error move path %@ to %@ (%@)", tmpUnzipPath, sourcePath, [error localizedDescription]);
          error = nil;
        }
      }
      BZ2_bzclose(bz2fp);
      [fileManager removeItemAtPath:destinationPath error:&error];
      if (error != nil) {
        NSLog(@"Error deleting %@ (%@)", destinationPath, [error localizedDescription]);
        error = nil;
      } else {
        successful = YES;
      }
    }
  }
  return successful;
}

+(NSArray *)availableUpdates:(id<UpdateDelegate>)owner includingHD:(BOOL)additionalImages checkVersionInfo:(BOOL)checkVersionInfo {
  if (PARK_ID_EDITION != nil && additionalImages) additionalImages = NO;
  NSString *path = [[Update sourceDataPath] stringByAppendingString:@"version.info"];
  NSError *error = nil;
  BOOL updateAvailable = NO;
  NSArray *versionInfo = nil;
  NSURLResponse *response = nil;
  NSURLRequest *request = nil;
  NSData *rawData = nil;
  if (checkVersionInfo) {
    NSLog(@"Check for update changes at %@", path);
    updateAvailable = YES;
    request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:path] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0];
    rawData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error == nil && rawData != nil) {
      NSString *data = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
      versionInfo = [[data componentsSeparatedByString:@","] retain];
      updateAvailable = [ParkData isUpdateAvailable:versionInfo];
      [data release];
    } else {
      NSLog(@"Error during update: %@", [error localizedDescription]);
    }
  }
  if (error == nil) {
    NSString *rawDataPath = [[MenuData documentPath] stringByAppendingPathComponent:UPDATE_INDEX];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (updateAvailable || ![fileManager fileExistsAtPath:rawDataPath]) {
      Update *updateIndex = nil;
      if (PARK_ID_EDITION == nil) {
        updateIndex = [[Update alloc] init];
        [updateIndex performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
      }
      path = [[Update sourceDataPath] stringByAppendingString:UPDATE_INDEX];
      NSLog(@"Download available data updates at %@", path);
      [request release];
      request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:path] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5.0];
      rawData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
      if (error == nil && rawData != nil) [Update writeData:rawData toFile:rawDataPath];
      if (updateIndex != nil) {
        int i = 0;
        while ([updateIndex isDownloading] && ++i < 15) [NSThread sleepForTimeInterval:0.4];
        if (i >= 15) NSLog(@"Download of 'index.info' interrupted!");
      }
      [updateIndex release];
    } else {
      rawData = [NSData dataWithContentsOfFile:rawDataPath options:NSDataReadingUncached error:&error];
      if (error != nil) NSLog(@"Error reading data during update: %@", [error localizedDescription]);
    }
  }
  if (error == nil && rawData != nil) {
    NSLog(@"Check available data updates");
    NSString *data = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
    NSArray *installedParkIds = [MenuData getParkIds];
    NSMutableSet *parkCountryIds = [[NSMutableSet alloc] initWithCapacity:[installedParkIds count]];
    for (NSString *parkId in installedParkIds) {
      if (![parkId isEqualToString:CORE_DATA_ID]) {
        NSString *country = [MenuData objectForKey:@"Land" at:[MenuData getParkDetails:parkId cache:NO]];
        if (country != nil) [parkCountryIds addObject:country];
      }
    }
    NSArray *missingParkIds = [ParkData getMissingParkIds:installedParkIds];
    SettingsData *settings = [SettingsData getSettingsData];
    NSArray *parkData = [data componentsSeparatedByString:@"\n"];
    NSMutableArray *updates = [[[NSMutableArray alloc] initWithCapacity:[parkData count]] autorelease];
    NSDictionary *localData = (additionalImages)? [ImageData localData] : nil;
    NSDictionary *hdImageData = (additionalImages)? [ImageData availableDataForParkId:nil reload:NO] : nil;
    NSMutableArray *changes = [[NSMutableArray alloc] initWithCapacity:200];
    for (NSString *t in parkData) {
      if ([t length] > 0) {
        Update *u = [[Update alloc] init:t owner:owner];
        if (u.version == 0.0) {
          //NSLog(@"Error to parse info file: %@", data);
          NSLog(@"Error to parse info file");
          [data release];
          data = nil;
          [u release];
          break;
        } else if (PARK_ID_EDITION == nil || [u.parkId isEqualToString:PARK_ID_EDITION] || [u.parkGroupId isEqualToString:PARK_ID_EDITION] || [u.parkId isEqualToString:CORE_DATA_ID] || [missingParkIds containsObject:u.parkId]) {
          ParkData *parkData = [ParkData getParkData:u.parkId];
          if ([settings considerOnyInstalledParkDataUpdate]) {
            if (parkData != nil && [installedParkIds containsObject:u.parkId]) {
              if (parkData.versionOfData < u.version || [missingParkIds containsObject:u.parkId]) [updates addObject:u];
              if (additionalImages) {
                int numberOfChangingImages = 0;
                int s = [ImageData availableChangesOfParkId:u.parkId betweenLocalData:localData andAvailableData:hdImageData resultingChanges:changes numberOfChangingImages:&numberOfChangingImages];
                if (s > 0) {
                  Update *u2 = [[Update alloc] initWithImageArray:changes size:s numberOfImages:numberOfChangingImages assoziation:u];
                  [updates addObject:u2];
                  [u2 release];
                }
              }
            }
          } else if ([settings considerOnyInstalledCountriesParkDataUpdate]) {
            if (parkData != nil && [parkCountryIds containsObject:NSLocalizedString(u.country, nil)]) {
              if (parkData.versionOfData < u.version || [missingParkIds containsObject:u.parkId]) [updates addObject:u];
              if (additionalImages) {
                int numberOfChangingImages = 0;
                int s = [ImageData availableChangesOfParkId:u.parkId betweenLocalData:localData andAvailableData:hdImageData resultingChanges:changes numberOfChangingImages:&numberOfChangingImages];
                if (s > 0) {
                  Update *u2 = [[Update alloc] initWithImageArray:changes size:s numberOfImages:numberOfChangingImages assoziation:u];
                  [updates addObject:u2];
                  [u2 release];
                }
              }
            }
          } else {
            if (parkData == nil || parkData.versionOfData < u.version || [missingParkIds containsObject:u.parkId]) [updates addObject:u];
            if (additionalImages && ![u.parkId isEqualToString:CORE_DATA_ID]) {
              int numberOfChangingImages = 0;
              int s = [ImageData availableChangesOfParkId:u.parkId betweenLocalData:localData andAvailableData:hdImageData resultingChanges:changes numberOfChangingImages:&numberOfChangingImages];
              if (s > 0) {
                Update *u2 = [[Update alloc] initWithImageArray:changes size:s numberOfImages:numberOfChangingImages assoziation:u];
                [updates addObject:u2];
                [u2 release];
              }
            }
          }
        }
        [u release];
      }
    }
    [changes release];
    [ParkData updateLastUpdateCheck:updates versionInfo:versionInfo];
    [parkCountryIds release];
    [versionInfo release];
    [request release];
    if (data == nil && [updates count] == 0) return nil;
    [data release];
    [updates sortUsingSelector:@selector(compare:)];
    return updates;
  }
  [versionInfo release];
  [request release];
  return nil;
}

+(double)localTimeIntervalSinceNowOfData:(NSString *)localPath parkId:(NSString *)parkId {
  localPath = [[MenuData parkDataPath:parkId] stringByAppendingPathComponent:localPath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:localPath]) {
    NSError *error = nil;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:localPath error:&error];
    if (error == nil) {
      NSDate *creationDate = [attributes objectForKey:NSFileModificationDate];
      if (creationDate != nil) return [[NSDate date] timeIntervalSinceDate:creationDate];
    }
  }
  return -1.0;
}

+(NSString *)localDataPath:(NSString *)localPath parkId:(NSString *)parkId {
  NSError *error = nil;
  localPath = [[MenuData parkDataPath:parkId] stringByAppendingPathComponent:localPath];
  NSLog(@"retrieving local data at %@", localPath);
  NSString *data = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:&error];
  return (error == nil)? data : nil;
}

+(NSString *)onlineDataPath:(NSString *)dataPath hasPrefix:(NSString *)prefix useLocalDataIfNotOlder:(double)modificationTimeInHours parkId:(NSString *)parkId online:(BOOL *)online statusCode:(int *)statusCode {
  if (online != nil) *online = NO;
  NSError *error = nil;
  NSString *unzippedDataPath = dataPath;
  if ([dataPath hasSuffix:@".gz"]) unzippedDataPath = [dataPath substringToIndex:[dataPath length]-3];
  else if ([dataPath hasSuffix:@".bz2"]) unzippedDataPath = [dataPath substringToIndex:[dataPath length]-4];
  double modificationTimeOfLocalData = [Update localTimeIntervalSinceNowOfData:unzippedDataPath parkId:parkId];
  if (modificationTimeOfLocalData >= 0.0 && modificationTimeOfLocalData < modificationTimeInHours*3600.0) { // local data is not older than 16h
    NSString *data = [Update localDataPath:unzippedDataPath parkId:parkId];
    if (data != nil) return data;
  }
  NSString *path = (parkId == nil)? [[Update sourceDataPath] stringByAppendingPathComponent:dataPath] : [[[Update sourceDataPath] stringByAppendingPathComponent:parkId] stringByAppendingPathComponent:dataPath];
  NSURL *dataURL = [NSURL URLWithString:path];
  NSLog(@"retrieving data at %@", path);
  NSHTTPURLResponse *response = nil;
  NSURLRequest *request = [[NSURLRequest alloc] initWithURL:dataURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
  NSData *rawData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
  if (statusCode != nil) *statusCode = (int)response.statusCode;
  if (error == nil && rawData != nil && response.statusCode == 200) {
    if (online != nil) *online = YES;
    NSString *data = nil;
    if ([dataPath hasSuffix:@".bz2"]) {
      NSString *localPath = [[MenuData parkDataPath:parkId] stringByAppendingPathComponent:unzippedDataPath];
      if ([Update decompressBZ2:rawData filePath:localPath]) {
        NSError *error = nil;
        data = [NSString stringWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:&error];
        if (error != nil) NSLog(@"Error during decompress bz2: %@", [error localizedDescription]);
      }
    }
    if (data == nil) data = [[[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding] autorelease];
    if (prefix == nil || [data hasPrefix:prefix]) {
      NSString *localPath = [[MenuData parkDataPath:parkId] stringByAppendingPathComponent:unzippedDataPath];
      [data writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    } else NSLog(@"Downloaded data has not the expected prefix: %@", prefix);
    [request release];
    return data;
  } else {
    [request release];
    if (modificationTimeOfLocalData >= 0.0) {
      NSString *data = [self localDataPath:unzippedDataPath parkId:parkId];
      if (data != nil) return data;
    }
    NSLog(@"retrieving %@ for park %@ was unsuccessfull! (response code: %d)", dataPath, parkId, (int)response.statusCode);
  }
  return nil;
}

+(BOOL)addSkipBackupAttributeToItemAtURL:(NSString *)path { // iOS >= 5.1 needed
  // http://developer.apple.com/library/ios/#qa/qa1719/_index.html
  if (&NSURLIsExcludedFromBackupKey == nil) return NO;
  NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];
  NSError *error = nil;
  BOOL success = [url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error];
  if (url == nil || !success) NSLog(@"Error excluding %@ from backup %@", [url lastPathComponent], error);
  return success;
}

+(void)copyFrom:(NSString *)fromPath to:(NSString *)toPath {
  //NSLog(@"Copy data from %@ to %@", fromPath, toPath);
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSDictionary *attributes = [fileManager attributesOfItemAtPath:fromPath error:&error];
  if (error != nil) {
    NSLog(@"%@", [error localizedDescription]);
    error = nil;
  }
  if ([attributes objectForKey:NSFileType] == NSFileTypeDirectory && [fileManager createDirectoryAtPath:toPath withIntermediateDirectories:YES attributes:nil error:&error]) {
    NSArray *files = [fileManager contentsOfDirectoryAtPath:fromPath error:&error];
    if (error != nil) {
      NSLog(@"%@", [error localizedDescription]);
      error = nil;
    }
    for (NSString *path in files) {
      NSString *fullFromPath = [fromPath stringByAppendingPathComponent:path];
      attributes = [fileManager attributesOfItemAtPath:fullFromPath error:&error];
      if (error != nil) {
        NSLog(@"%@", [error localizedDescription]);
        error = nil;
      }
      NSString *fullToPath = [toPath stringByAppendingPathComponent:path];
      if ([attributes objectForKey:NSFileType] == NSFileTypeDirectory && [fileManager createDirectoryAtPath:fullToPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        [Update copyFrom:fullFromPath to:fullToPath];
      } else {
        NSLog(@"Copy file from %@ to %@", path, toPath);
        if ([fileManager fileExistsAtPath:fullToPath]) [fileManager removeItemAtPath:fullToPath error:NULL];
        [fileManager copyItemAtPath:fullFromPath toPath:fullToPath error:&error];
        if (error != nil) {
          NSLog(@"%@", [error localizedDescription]);
          error = nil;
        }
      }
    }
  } else {
    NSLog(@"Copy file from %@ to %@", fromPath, toPath);
    if ([fileManager fileExistsAtPath:toPath]) [fileManager removeItemAtPath:toPath error:NULL];
    [fileManager copyItemAtPath:fromPath toPath:toPath error:&error];
    if (error != nil) {
      NSLog(@"%@", [error localizedDescription]);
      error = nil;
    }
  }
}

-(void)replaceLocalData:(NSString *)sourcePath {
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *dataPath = [MenuData dataPath];
  NSString *destinationPath = [MenuData parkDataPath:parkId];
  if ([parkId isEqualToString:CORE_DATA_ID]) {
    NSArray *files = [fileManager contentsOfDirectoryAtPath:dataPath error:&error];
    if (error != nil) {
      NSLog(@"%@", [error localizedDescription]);
      error = nil;
      return;
    }
    for (NSString *p in files) {
      if ([p hasPrefix:@"."] || [p isEqualToString:sourcePath]) continue;
      NSString *fullPath = [dataPath stringByAppendingPathComponent:p];
      NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPath error:&error];
      if (error != nil) {
        NSLog(@"Error getting attributes of path %@ - %@", fullPath, [error localizedDescription]);
        error = nil;
      } else if ([attributes objectForKey:NSFileType] == NSFileTypeDirectory) {
        ParkData *parkData = [ParkData getParkData:p];
        if (parkData == nil) {
          [fileManager removeItemAtPath:fullPath error:&error];
          if (error != nil) {
            NSLog(@"Error removing path %@ - %@", fullPath, [error localizedDescription]);
            error = nil;
          } else {
            NSLog(@"Local data in directory %@ deleted", fullPath);
          }
        }
      } else {
        [fileManager removeItemAtPath:fullPath error:&error];
        if (error != nil) {
          NSLog(@"Error removing path %@ - %@", fullPath, [error localizedDescription]);
          error = nil;
        } else {
          NSLog(@"Local data in file %@ deleted", fullPath);
        }
      }
    }
    error = nil;
    files = [fileManager contentsOfDirectoryAtPath:sourcePath error:&error];
    if (error != nil) {
      NSLog(@"Error content of source path %@ - %@", sourcePath, [error localizedDescription]);
      error = nil;
      return;
    }
    for (NSString *p in files) {
      error = nil;
      [fileManager moveItemAtPath:[sourcePath stringByAppendingPathComponent:p] toPath:[destinationPath stringByAppendingPathComponent:p] error:&error];
      if (error != nil) NSLog(@"%@", [error localizedDescription]);
    }
    [HelpData getHelpData:YES];
    [Categories getCategories:YES];
    [Attraction getAllAttractions:nil reload:YES]; // reload Attraction data because categories might change
  } else {
    if ([fileManager fileExistsAtPath:destinationPath]) {
      [fileManager removeItemAtPath:destinationPath error:&error];
      if (error != nil) NSLog(@"Error removing destination path %@ - %@", destinationPath, [error localizedDescription]);
    }
    error = nil;
    [fileManager moveItemAtPath:sourcePath toPath:destinationPath error:&error];
    if (error != nil) NSLog(@"Error removing source path %@ - %@", sourcePath, [error localizedDescription]);
  }
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
  hasProgress = NO;
  if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
    NSLog(@"Error don't know what kind of request this is");
    return;
  }
  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
  if ([httpResponse.allHeaderFields count] == 0) {
    NSLog(@"response without any header fields");
    return;
  }
  switch (httpResponse.statusCode) {
    case 206: {
      NSString *range = [httpResponse.allHeaderFields valueForKey:@"Content-Range"];
      NSError *error = nil;
      // Check to see if the
      NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"bytes (\\d+)-\\d+/\\d+" options:NSRegularExpressionCaseInsensitive error:&error];
      if (error != nil) {
        NSLog(@"server returned not a valid byte-range - cannot resume download");
        downloadedSize = 0;
        downloadedFileSize = 0;
        [data1 release];
        data1 = nil;
        [data1URL release];
        data1URL = nil;
        break;
      }
      NSTextCheckingResult *match = [regex firstMatchInString:range options:NSMatchingAnchored range:NSMakeRange(0, range.length)];
      if (match.numberOfRanges < 2) {
        NSLog(@"no match the number of bytes, start the download from the beginning");
        downloadedSize = 0;
        downloadedFileSize = 0;
        [data1 release];
        data1 = nil;
        [data1URL release];
        data1URL = nil;
        break;
      }
      // Extract the byte offset the server reported to us, and truncate our
      // file if it is starting us at "0".  Otherwise, seek our file to the appropriate offset.
      NSString *byteStr = [range substringWithRange:[match rangeAtIndex:1]];
      NSInteger bytes = [byteStr integerValue];
      if (bytes <= 0 || bytes > data1.length) {
        downloadedSize = 0;
        downloadedFileSize = 0;
        [data1 release];
        data1 = nil;
        [data1URL release];
        data1URL = nil;
      } else {
        NSLog(@"resume download at %d (%d bytes already downloaded)", bytes, (int)data1.length);
        if (bytes < data1.length) {
          // ToDo: check if also [data1 setLength:bytes]; if possible
          NSMutableData *data = [[NSMutableData alloc] initWithCapacity:(imagePathes != nil)? (2*fileSize)/[imagePathes count] : fileSize];
          [data appendBytes:data1.mutableBytes length:bytes];
          [data1 release];
          data1 = data;
        }
      }
      break;
    }
    default:
      if (httpResponse.statusCode != 200) NSLog(@"http response code %d - cannot resume download for %@", (int)httpResponse.statusCode, connection.currentRequest.URL.absoluteString);
      if (imagePathes == nil) downloadedSize = 0;
      downloadedFileSize = 0;
      [data1 release];
      data1 = nil;
      [data1URL release];
      data1URL = nil;
      break;
  }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incrementalData {
  if (data1 == nil) data1 = [[NSMutableData alloc] initWithCapacity:(imagePathes != nil)? (2*fileSize)/[imagePathes count] : fileSize];
  [data1 appendData:incrementalData];
  NSUInteger n = incrementalData.length;
  if (n > 0) hasProgress = YES;
  downloadedSize += n;
  downloadedFileSize += n;
  [delegate status:[NSString stringWithFormat:NSLocalizedString(@"update.download.info", nil), parkName] percentage:[self downloadedPercentage]];
  [delegate downloaded:[Update sizeToString:downloadedSize]];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  [delegate status:[NSString stringWithFormat:NSLocalizedString(@"update.download.error", nil), [error localizedDescription]] percentage:-1.0];
  [delegate downloaded:@""];
  [connection1 release];
  connection1 = nil;
  //[data1 release];
  //data1 = nil;
  //downloadedSize = 0;
  //downloadedFileSize = 0;
}

-(BOOL)unzipFile:(unzFile)file to:(NSString*)zipPath numberOfEntries:(int)numberOfEntries reportStatus:(BOOL)reportStatus {
  BOOL success = YES;
  int ret = unzGoToFirstFile(file);
  if (ret != UNZ_OK) NSLog(@"unzGoToFirstFile failed");
  unsigned char buffer[0x10000];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSDateComponents *dc = [[NSDateComponents alloc] init];
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  int entry = 0;
  do {
    ret = unzOpenCurrentFile(file);
    if (ret != UNZ_OK) {
      NSLog(@"unzOpenCurrentFile error occurs");
      success = NO;
      break;
    }
    unz_file_info	fileInfo;
    ret = unzGetCurrentFileInfo(file, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
    if (ret != UNZ_OK) {
      NSLog(@"error occurs while getting file info");
      success = NO;
      unzCloseCurrentFile(file);
      break;
    }
    int n = fileInfo.size_filename+1;
    char *filename = (char *)malloc(n);
    unzGetCurrentFileInfo(file, &fileInfo, filename, n, NULL, 0, NULL, 0);
    filename[n-1] = '\0';
    for (int i = 0; i < n; ++i) {
      if (filename[i] == '\\') filename[i] = '/';
    }
    BOOL isDirectory = (filename[n-2] == '/');
		NSString* fullPath = [zipPath stringByAppendingPathComponent:[NSString stringWithUTF8String:filename]];
    free(filename);
    if (isDirectory) [fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
    else [fileManager createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    FILE* fp = fopen([fullPath UTF8String], "wb");
    if (fp) {
      while (TRUE) {
        int read = unzReadCurrentFile(file, buffer, 0x10000);
        if (read < 0) {
          NSLog(@"Failed to reading zip file");
          success = NO;
        }
        if (read <= 0) break;
        fwrite(buffer, read, 1, fp);
      }
      fclose(fp);
      ++entry;
      if (reportStatus) {
        [delegate status:NSLocalizedString(@"update.unzip.info", nil) percentage:(entry*1.0)/numberOfEntries];
        [delegate downloaded:[NSString stringWithFormat:@"%d/%d", entry, numberOfEntries]];
      }
      // set the orignal datetime property
      dc.second = fileInfo.tmu_date.tm_sec;
      dc.minute = fileInfo.tmu_date.tm_min;
      dc.hour = fileInfo.tmu_date.tm_hour;
      dc.day = fileInfo.tmu_date.tm_mday;
      dc.month = fileInfo.tmu_date.tm_mon+1;
      dc.year = fileInfo.tmu_date.tm_year;
      NSDate* orgDate = [gregorian dateFromComponents:dc] ;
      NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate];
      if (attr && ![fileManager setAttributes:attr ofItemAtPath:fullPath error:nil]) NSLog(@"Failed to set attributes");
    }
    unzCloseCurrentFile(file);
    ret = unzGoToNextFile(file);
  } while (ret == UNZ_OK && UNZ_OK != UNZ_END_OF_LIST_OF_FILE && success);
  [gregorian release];
  [dc release];
  return success;
}

-(void)importData:(NSData *)data {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  BOOL completeDataCopied = YES;
  BOOL failed = NO;
  if (data != nil) {
    [delegate status:[NSString stringWithFormat:NSLocalizedString(@"update.validate.download.info", nil), parkName] percentage:100.0/101.0];
    [delegate downloaded:[Update sizeToString:[data length]]];
    MD5_CTX mdContext;
    MD5Init(&mdContext);
    MD5Update(&mdContext, data.bytes, data.length);
    MD5Final(&mdContext);
    char md5ofData[33];
    md5ofData[32] = '\x0';
    //[NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7], result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
    for (int i = 0; i < 16; ++i) sprintf(md5ofData+2*i, "%02x", mdContext.digest[i]);
    if (![[NSString stringWithUTF8String:md5ofData] isEqualToString:hashCode]) {
      NSLog(@"Wrong hash MD5: %s != %@", md5ofData, hashCode);
      [data release];
      //data = nil;
      [delegate status:[NSString stringWithFormat:NSLocalizedString(@"update.download.error.hash", nil), parkName] percentage:-1.0];
      [delegate downloaded:@""];
      return;
    }
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *package = [path stringByAppendingString:@".zip"];
    [Update addSkipBackupAttributeToItemAtURL:[MenuData dataPath]];  // do not backup downloaded data
    NSString *destinationPath = [[MenuData dataPath] stringByAppendingPathComponent:package];
    if ([fileManager fileExistsAtPath:destinationPath]) {
      [fileManager removeItemAtPath:destinationPath error:&error];
      if (error != nil) {
        NSLog(@"Error removing already existing tmp %@ package: %@", parkId, [error localizedDescription]);
        failed = YES;
      }
    }
    if (!failed && [data length] > 0 && [data writeToFile:destinationPath atomically:YES]) {
      NSString *tmpUnzipPath = [[MenuData parkDataPath:parkId] stringByAppendingString:@"-tmp"];
      if ([fileManager fileExistsAtPath:tmpUnzipPath]) {
        [fileManager removeItemAtPath:tmpUnzipPath error:&error];
        if (error != nil) {
          NSLog(@"Error removing tmp %@ package: %@", parkId, [error localizedDescription]);
          failed = YES;
        }
      }
      if (!failed) {
        [fileManager createDirectoryAtPath:tmpUnzipPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil) {
          NSLog(@"Error creating directory for %@ - %@", parkId, [error localizedDescription]);
          failed = YES;
        } else {
          unzFile unzipFile = unzOpen([destinationPath UTF8String]);
          if (unzipFile) {
            unz_global_info globalInfo;
            if (unzGetGlobalInfo(unzipFile, &globalInfo) == UNZ_OK) {
              failed = ![self unzipFile:unzipFile to:tmpUnzipPath numberOfEntries:globalInfo.number_entry reportStatus:YES];
              unzClose(unzipFile);
            }
          }
          if (!failed) {
            [fileManager removeItemAtPath:destinationPath error:&error];
            if (error != nil) {
              NSLog(@"Error deleting %@ package: %@", parkId, [error localizedDescription]);
              error = nil;
            }
            [self replaceLocalData:tmpUnzipPath];
            [MenuData getParkDetails:nil cache:YES]; // clear cached plist data
            completeDataCopied = [ParkData addParkData:parkId versionOfData:version];
            if (![parkId isEqualToString:CORE_DATA_ID]) {
              //[Attraction getAllAttractions:parkId reload:YES]; already called in addParkData
              ParkData *parkData = [ParkData getParkData:parkId];
              BOOL isCalendarDataInit = [parkData isCalendarDataInitialized];
              BOOL isNewsDataInit = [parkData isNewsDataInitialized];
              CalendarData *calendarData = [parkData getCalendarData];
              if (isCalendarDataInit) [calendarData update:NO];
              NewsData *newsData = [parkData getNewsData];
              if (isNewsDataInit) [newsData update:NO];
              [Update addSkipBackupAttributeToItemAtURL:[MenuData parkDataPath:parkId]];  // do not backup downloaded data
            }
            if ([fileManager fileExistsAtPath:tmpUnzipPath]) {
              [fileManager removeItemAtPath:tmpUnzipPath error:&error];
              if (error != nil) {
                NSLog(@"Error removing tmp %@ package: %@", parkId, [error localizedDescription]);
                error = nil;
              }
            }
          }
        }
      }
    }
    [data release];
    //data = nil;
  }
  if (failed) {
    [delegate status:NSLocalizedString(@"update.download.imported.error", nil) percentage:-1.0];
    [delegate downloaded:@""];
  } else if (!completeDataCopied) {
    [delegate status:[NSString stringWithFormat:NSLocalizedString(@"update.park.data.import", nil), parkName] percentage:-2.0];
    [delegate downloaded:@""];
  } else {
    [delegate status:[NSString stringWithFormat:NSLocalizedString(@"update.download.imported", nil), parkName] percentage:1.0];
    [delegate downloaded:@""];
  }
  [pool release];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if (data1 == nil || downloadedSize == 0 || !hasProgress || (imagePathes == nil && data1.length < fileSize)) {
    [delegate status:NSLocalizedString(@"update.download.completion.error", nil) percentage:-1.0];
    [delegate downloaded:(downloadedSize == 0)? @"" : [Update sizeToString:downloadedSize]];
  } else if (parkId != nil) {
    if (imagePathes == nil) {
      [NSThread detachNewThreadSelector:@selector(importData:) toTarget:self withObject:data1];
      data1 = nil;
      [data1URL release];
      data1URL = nil;
    } else {
      static NSString *previousAttractionId = nil;
      NSString *currentAttractionId = nil;
      NSString *imagePath = [imagePathes objectAtIndex:indexOfPathes];
      NSMutableArray *pathComponents = [[NSMutableArray alloc] initWithArray:[imagePath componentsSeparatedByString:@"/"]];
      if (indexOfPathes == 0) previousAttractionId = ([pathComponents count] > 2)? [[pathComponents objectAtIndex:1] retain] : nil;
      BOOL valid = YES;
      BOOL zipFile = [imagePath hasSuffix:@".zip"];
      if ([pathComponents count] > 2) {
        NSString *attractionId = [pathComponents objectAtIndex:1];
        currentAttractionId = attractionId;
        if (!zipFile) {
          NSArray *imageProperties = [ImageData imageProperiesForParkId:parkId attractionId:attractionId data:[ImageData availableDataForParkId:parkId reload:NO]];
          NSString *s = [pathComponents lastObject];
          for (ImageProperty *imageProperty in imageProperties) {
            if ([imageProperty isEqualToString:s]) {
              valid = (imageProperty.size == [data1 length]);
              if (!valid) NSLog(@"downloaded file %s has size %d but not %d", imageProperty.imageName, [data1 length], imageProperty.size);
              break;
            }
          }
        }
        if (valid) {
          [pathComponents removeLastObject];
          [MenuData ensurePathStructure:pathComponents toBase:[ImageData additionalImagesDataPath]];
        }
      }
      [pathComponents release];
      if (zipFile) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *destinationPath = [MenuData parkDataPath:parkId];
        NSString *tmpFile = [destinationPath stringByAppendingPathComponent:@"tmp.zip"];
        NSString *tmpUnzipPath = [destinationPath stringByAppendingPathComponent:@"tmp"];
        valid = [data1 writeToFile:tmpFile atomically:YES];
        if (valid) {
          NSError *error = nil;
          if ([fileManager fileExistsAtPath:tmpUnzipPath]) {
            [fileManager removeItemAtPath:tmpUnzipPath error:&error];
            if (error != nil) {
              NSLog(@"Error removing already existing tmp unzip path %@: %@", tmpUnzipPath, [error localizedDescription]);
              valid = NO;
            }
          }
          if (valid) {
            valid = NO;
            [fileManager createDirectoryAtPath:tmpUnzipPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error != nil) {
              NSLog(@"Error creating tmp directory %@ - %@", tmpUnzipPath, [error localizedDescription]);
            } else {
              unzFile unzipFile = unzOpen([tmpFile UTF8String]);
              if (unzipFile) {
                unz_global_info globalInfo;
                if (unzGetGlobalInfo(unzipFile, &globalInfo) == UNZ_OK) {
                  valid = [self unzipFile:unzipFile to:tmpUnzipPath numberOfEntries:globalInfo.number_entry reportStatus:NO];
                  unzClose(unzipFile);
                }
              }
            }
            if (valid) {
              NSString *destinationImagePath = [ImageData additionalImagesDataPath];
              NSRange range = [imagePath rangeOfString:@"/" options:NSBackwardsSearch];
              if (range.length > 0) {
                destinationImagePath = [destinationImagePath stringByAppendingPathComponent:[imagePath substringToIndex:range.location]];
              }
              [fileManager removeItemAtPath:destinationImagePath error:&error];
              if (error != nil) {
                NSLog(@"Error deleting destination image path %@: %@", destinationImagePath, [error localizedDescription]);
                error = nil;
              }
              [fileManager moveItemAtPath:tmpUnzipPath toPath:destinationImagePath error:&error];
              if ([fileManager fileExistsAtPath:tmpUnzipPath]) {
                [fileManager removeItemAtPath:tmpUnzipPath error:&error];
                if (error != nil) {
                  NSLog(@"Error removing tmp path %@: %@", tmpUnzipPath, [error localizedDescription]);
                }
              }
            } else {
              NSLog(@"Error unzip for %@ was unsuccessful", parkId);
            }
          }
          [fileManager removeItemAtPath:tmpFile error:&error];
          if (error != nil) {
            NSLog(@"Error deleting tmp.zip (%@)", [error localizedDescription]);
            error = nil;
          }
        } else {
          NSLog(@"Error writing tmp.zip");
        }
      }
      [Update addSkipBackupAttributeToItemAtURL:[ImageData additionalImagesDataPath]];  // do not backup downloaded data
      if (valid && !zipFile) [Update writeData:data1 toFile:[[ImageData additionalImagesDataPath] stringByAppendingPathComponent:imagePath]];
      [data1 release];
      data1 = nil;
      [data1URL release];
      data1URL = nil;
      if (!valid) {
        [previousAttractionId release];
        previousAttractionId = nil;
        [delegate status:NSLocalizedString(@"update.download.imported.error", nil) percentage:-1.0];
        [delegate downloaded:@""];
      } else if (indexOfPathes+1 < imagePathes.count) {
        ++indexOfPathes;
        if (![previousAttractionId isEqualToString:currentAttractionId]) [ImageData updateLocalDataWithAvailableDataOfParkId:parkId attractionId:previousAttractionId];
        [previousAttractionId release];
        previousAttractionId = [currentAttractionId retain];
        downloadedFileSize = 0;
        [self update];
        return;
      } else {
        if (![previousAttractionId isEqualToString:currentAttractionId]) [ImageData updateLocalDataWithAvailableDataOfParkId:parkId attractionId:previousAttractionId];
        [ImageData updateLocalDataWithAvailableDataOfParkId:parkId attractionId:currentAttractionId];
        [previousAttractionId release];
        previousAttractionId = nil;
        [delegate status:[NSString stringWithFormat:NSLocalizedString(@"update.download.imported", nil), parkName] percentage:1.0];
        [delegate downloaded:@""];
      }
    }
    downloadedSize = 0;
    downloadedFileSize = 0;
    indexOfPathes = 0;
  } else {
    //if ([Update decompressBZ2:data1 filePath:[[MenuData documentPath] stringByAppendingPathComponent:@"index.info"]]) [ImageData availableDataForParkId:nil reload:YES];
    [Update decompressBZ2:data1 filePath:[[MenuData documentPath] stringByAppendingPathComponent:@"index.info"]];
    NSLog(@"file 'index.info' sucessfully decompressed");
    [ImageData clearCacheOfAvailableData];
    [data1 release];
    data1 = nil;
    [data1URL release];
    data1URL = nil;
    downloadedSize = 0;
    downloadedFileSize = 0;
    indexOfPathes = 0;
  }
  [connection1 release];
  connection1 = nil;
}

-(void)update {
  hasProgress = NO;
  NSString *package = nil;
  if (parkId != nil) {
    if (imagePathes != nil) {
      NSString *imagePath = [imagePathes objectAtIndex:indexOfPathes];
      package = [imagePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    } else {
      ParkData *parkData = [ParkData getParkData:parkId];
      if (parkData != nil && parkData.versionOfData == version) {  // check version
        NSLog(@"Park data for %@ version %f already available", parkId, version);
        return;
      }
      package = [path stringByAppendingString:@".zip"];
    }
  } else {
    package = @"index.info";
  }
  NSString *sourcePath = [[Update sourceDataPath] stringByAppendingPathComponent:package];
  NSURL *availableData = [NSURL URLWithString:sourcePath];
  if (data1URL != nil && ![data1URL isEqualToString:sourcePath]) {
    downloadedSize = 0;
    downloadedFileSize = 0;
    [data1 release];
    data1 = nil;
  }
  [data1URL release];
  data1URL = [sourcePath retain];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:availableData cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0];
  //if (![NSURLConnection canHandleRequest:request]) NSLog(@"Handle error");
  //NSURLRequest *request = [NSURLRequest requestWithURL:availableData cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15.0];
  // resuming download
  if (downloadedFileSize > 0) [request setValue:[NSString stringWithFormat:@"bytes=%d-", downloadedFileSize] forHTTPHeaderField:@"Range"];
  connection1 = [[NSURLConnection alloc] initWithRequest:request delegate:self];
  NSLog(@"Download file %@", sourcePath);
  [delegate status:[NSString stringWithFormat:NSLocalizedString(@"update.download.info", nil), parkName] percentage:[self downloadedPercentage]];
  [delegate downloaded:(downloadedSize == 0)? @"" : [Update sizeToString:downloadedSize]];
}

-(BOOL)hasProgress {
  return hasProgress;
}

-(BOOL)isDownloading {
  return (connection1 != nil);
}

-(double)downloadedPercentage {
  return downloadedSize/(1.01*fileSize);
}

@end
