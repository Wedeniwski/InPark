//
//  MenuData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 17.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "MenuData.h"
#import "ParkData.h"
#import "SettingsData.h"

@implementation MenuData

+(int)binarySearch:(NSString *)key inside:(NSArray *)array {
	int low = 0;
	int high = (int)array.count-1;
	while (low <= high) {
    int mid = (low+high) >> 1;
    NSString* v = [array objectAtIndex:mid];
    NSInteger c = [v compare:key];
    if (c == NSOrderedAscending) low = mid+1;
    else if (c == NSOrderedDescending) high = mid-1;
    else return mid; // key found
	}
	return -(low+1);  // key not found.
}

+(void)ensurePathStructure:(NSArray *)path toBase:(NSString *)basePath {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:basePath]) {
    NSError *error = nil;
    [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error != nil) {
      NSLog(@"Error creating directory %@ - %@", basePath, [error localizedDescription]);
      return;
    }
  }
  for (NSString *p in path) {
    basePath = [basePath stringByAppendingPathComponent:p];
    if (![fileManager fileExistsAtPath:basePath]) {
      NSError *error = nil;
      [fileManager createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error];
      if (error != nil) NSLog(@"Error creating directory %@ - %@", basePath, [error localizedDescription]);
    }
  }
}

+(NSString *)libraryCachePath {
  static NSString *dPath = nil;
  @synchronized([MenuData class]) {
    if (dPath == nil) {
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
      dPath = [[paths objectAtIndex:0] retain];
    }
    return dPath;
  }
}

+(NSString *)applicationSupportPath {
  static NSString *dPath = nil;
  @synchronized([MenuData class]) {
    if (dPath == nil) {
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
      dPath = [[paths objectAtIndex:0] retain];
      [MenuData ensurePathStructure:nil toBase:dPath];
    }
    return dPath;
  }
}

+(NSString *)documentPath {
  static NSString *dPath = nil;
  @synchronized([MenuData class]) {
    if (dPath == nil) {
      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
      dPath = [[paths objectAtIndex:0] retain];
    }
    return dPath;
  }
}

+(NSString *)oldestDataPath {
  return [[MenuData documentPath] stringByAppendingPathComponent:@"data"];
}

+(NSString *)oldDataPath {
  return [[MenuData libraryCachePath] stringByAppendingPathComponent:@"data"];
}

+(NSString *)newDataPath {
  return [[MenuData applicationSupportPath] stringByAppendingPathComponent:@"data"];
}

+(NSString *)dataPath {
  static NSString *dPath = nil;
  @synchronized([MenuData class]) {
    if (dPath == nil) {
      dPath = [MenuData applicationSupportPath];
      [MenuData ensurePathStructure:[NSArray arrayWithObject:@"data"] toBase:dPath];
      dPath = [[dPath stringByAppendingPathComponent:@"data"] retain];
    }
    return dPath;
  }
}

+(NSString *)parkDataPath:(NSString *)parkId {
  return (parkId == nil || [parkId isEqualToString:CORE_DATA_ID])? [MenuData dataPath] : [[MenuData dataPath] stringByAppendingPathComponent:parkId];
}

+(NSString *)relativeParkDataPath:(NSString *)parkId toBase:(NSString *)basePath {
  NSString *dataPath = [MenuData parkDataPath:parkId];
  if ([dataPath isEqualToString:basePath]) return @"";
  const char* dPath = [dataPath UTF8String];
  const char* bPath = [basePath UTF8String];
  while (*dPath == *bPath) {
    ++dPath; ++bPath;
  }
  int i = 1;
  while (TRUE) {
    char c = *bPath;
    if (!c) break;
    if (c == '/') ++i;
    ++bPath;
  }
  NSString *t = [NSString stringWithUTF8String:dPath];
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:3*i+1+[t length]] autorelease];
  while (--i >= 0) [s appendString:@"../"];
  [s appendString:t];
  return s;
}

+(NSDictionary *)getRootOfFile:(NSString *)filename languagePath:(NSString *)languagePath {
  NSString *path = [[NSBundle mainBundle] bundlePath];
  NSString *listFile = [[path stringByAppendingPathComponent:languagePath] stringByAppendingPathComponent:filename];
  return [NSDictionary dictionaryWithContentsOfFile:listFile];
}
                        
+(NSDictionary *)getRootOfFile:(NSString *)filename {
  return [MenuData getRootOfFile:filename languagePath:[[SettingsData getSettingsData] languagePath]];
}

+(NSDictionary *)getRootOfData:(NSString *)filename languagePath:(NSString *)languagePath {
  NSString *path = [MenuData dataPath];
  NSString *listFile = [[path stringByAppendingPathComponent:languagePath] stringByAppendingPathComponent:filename];
  return [NSDictionary dictionaryWithContentsOfFile:listFile];
}

+(NSDictionary *)getRootOfData:(NSString *)filename {
  return [MenuData getRootOfData:filename languagePath:[[SettingsData getSettingsData] languagePath]];
}

+(NSArray *)getRootKey:(NSString *)key languagePath:(NSString *)languagePath {
  NSDictionary *settingsDictionary = [MenuData getRootOfFile:@"Root.plist" languagePath:languagePath];
  return [settingsDictionary objectForKey:key];
}

+(NSArray *)getRootKey:(NSString *)key {
  NSDictionary *settingsDictionary = [MenuData getRootOfFile:@"Root.plist"];
  return [settingsDictionary objectForKey:key];
}

+(NSString *)objectForKey:(NSString *)key at:(NSDictionary *)d {
  id value = [d objectForKey:key];
  if (value == nil) return nil;
  if ([value isKindOfClass:[NSString class]]) return value;
  else if ([value isKindOfClass:[NSDictionary class]]) {
    NSDictionary *d2 = value;
    SettingsData *settingsData = [SettingsData getSettingsData];
    //return [d2 objectForKey:[settingsData shortLanguagePath]];
    NSString *t = [d2 objectForKey:[settingsData shortLanguagePath]]; // shortLanguagePath introduced with v1.5.5 (Dec 10, 2012)
    return (t != nil)? t : [d2 objectForKey:[settingsData longLanguagePath]]; // ToDo: remove longLanguagePath
  }
  return nil;
}

+(NSArray *)getParkIds {
  NSMutableArray *parksIds = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *dataPath = [MenuData dataPath];
  NSArray *files = [fileManager contentsOfDirectoryAtPath:dataPath error:&error];
  if (error != nil) {
    NSLog(@"Error get content of data path %@  (%@)", dataPath, [error localizedDescription]);
    error = nil;
  } else {
    for (NSString *path in files) {
      NSString *fullPath = [dataPath stringByAppendingPathComponent:path];
      NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPath error:&error];
      if (error != nil) {
        NSLog(@"Error attributes of path %@ - %@", path, [error localizedDescription]);
        error = nil;
      }
      if ([attributes objectForKey:NSFileType] == NSFileTypeDirectory) {
        NSString *parkId = [[path lastPathComponent] stringByDeletingPathExtension];
        NSString *parkData = [[NSString alloc] initWithFormat:@"%@/%@.plist", fullPath, parkId];
        if ([fileManager fileExistsAtPath:parkData]) {
          if (PARK_ID_EDITION == nil || [parkId isEqualToString:PARK_ID_EDITION]) {
            //NSLog(@"Find park %@ in data path", parkId);
            [parksIds addObject:parkId];
          } else {
            NSDictionary *details = [MenuData getParkDetails:parkId cache:NO];
            NSString *parkGroup = [details objectForKey:@"Parkgruppe"];
            if (parkGroup != nil && [parkGroup isEqualToString:PARK_ID_EDITION]) {
              [parksIds addObject:parkId];
            }
          }
        }
        [parkData release];
      }
    }
  }
  return parksIds;
}

+(NSDictionary *)getParkNames {
  NSMutableDictionary *parkNames = [[[NSMutableDictionary alloc] initWithCapacity:20] autorelease];
  [parkNames setValue:CORE_DATA_NAME forKey:CORE_DATA_ID];
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *dataPath = [MenuData dataPath];
  NSArray *files = [fileManager contentsOfDirectoryAtPath:dataPath error:&error];
  if (error != nil) {
    NSLog(@"Error get content of data path %@  (%@)", dataPath, [error localizedDescription]);
    error = nil;
  }
  for (NSString *path in files) {
    NSString *fullPath = [dataPath stringByAppendingPathComponent:path];
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPath error:&error];
    if (error != nil) {
      NSLog(@"Error attributes of path %@ - %@", path, [error localizedDescription]);
      error = nil;
    }
    if ([attributes objectForKey:NSFileType] == NSFileTypeDirectory) {
      NSString *parkId = [[path lastPathComponent] stringByDeletingPathExtension];
      NSString *parkData = [[NSString alloc] initWithFormat:@"%@/%@.plist", fullPath, parkId];
      if ([fileManager fileExistsAtPath:parkData]) {
        NSDictionary *details = [MenuData getParkDetails:parkId cache:NO];
        NSString *parkName = [MenuData objectForKey:@"Parkname" at:details];
        if (PARK_ID_EDITION == nil || [parkId isEqualToString:PARK_ID_EDITION]) {
          [parkNames setValue:parkName forKey:parkId];
        } else {
          NSString *parkGroup = [details objectForKey:@"Parkgruppe"];
          if (parkGroup != nil && [parkGroup isEqualToString:PARK_ID_EDITION]) {
            [parkNames setValue:parkName forKey:parkId];
          }
        }
      }
      [parkData release];
    }
  }
  return parkNames;
}

+(NSDictionary *)getParkDetails:(NSString *)parkId cache:(BOOL)cache {
  if (cache) {
    static NSDictionary *lastParkDetails = nil;
    static NSString *lastParkId = nil;
    @synchronized([MenuData class]) {
      if (lastParkId != nil && parkId != nil && [lastParkId isEqualToString:parkId]) return lastParkDetails;
      [lastParkId release];
      [lastParkDetails release];
      if (parkId != nil) {
        lastParkId = [parkId retain];
        NSString *path = [[NSString alloc] initWithFormat:@"%@/%@/%@.plist", [MenuData dataPath], parkId, parkId];
        lastParkDetails = [[NSDictionary alloc] initWithContentsOfFile:path];
        if (lastParkDetails == nil) NSLog(@"Error get park details at %@", path);
        [path release];
      } else {
        lastParkId = nil;
        lastParkDetails = nil;
      }
      return lastParkDetails;
    }
  } else {
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@/%@.plist", [MenuData dataPath], parkId, parkId];
    NSDictionary *parkDetails = [NSDictionary dictionaryWithContentsOfFile:path];
    [path release];
    return parkDetails;
  }
}

+(NSString *)getParkName:(NSString *)parkId cache:(BOOL)cache {
  if ([parkId isEqualToString:CORE_DATA_ID]) return CORE_DATA_NAME;
  NSDictionary *details = [MenuData getParkDetails:parkId cache:cache];
  return (details != nil)? [MenuData objectForKey:@"Parkname" at:details] : nil;
}

+(NSDictionary *)getAllAttractionDetails:(NSString *)parkId cache:(BOOL)cache {
  if ([parkId isEqualToString:CORE_DATA_ID]) return nil;
  NSDictionary *details = [MenuData getParkDetails:parkId cache:cache];
  return (details != nil)? [details objectForKey:@"IDs"] : nil;
}

+(NSDictionary *)getAttractionDetails:(NSString *)parkId attractionId:(NSString *)attractionId cache:(BOOL)cache {
  if ([parkId isEqualToString:CORE_DATA_ID]) return nil;
  NSDictionary *details = [MenuData getParkDetails:parkId cache:cache];
  return (details != nil)? [[details objectForKey:@"IDs"] objectForKey:attractionId] : nil;
}

+(NSString*)stringByHyphenating:(NSString *)string {
  NSRange range = [string rangeOfString:@"Haupteingang"];
  if (range.length > 0) {
    return [NSString stringWithFormat:@"%@Haupt-eingang%@", [string substringToIndex:range.location], [string substringFromIndex:range.location+range.length]];
  }
  //NSMutableString* result = [NSMutableString stringWithCapacity:[string length] * 1.2];
  //[result appendString:@"­"]; // NOTE: UTF-8 soft hyphen!
  return string;
}

@end
