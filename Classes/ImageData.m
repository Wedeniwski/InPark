//
//  ImageData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.10.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "ImageData.h"
#import "ParkData.h"
#import "MenuData.h"
#import "Attraction.h"
#import "Categories.h"
#import "Update.h"
#import "Colors.h"

@implementation ImageData

+(NSString *)oldestAdditionalImagesDataPath {
  return [[MenuData documentPath] stringByAppendingPathComponent:@"images"];
}

+(NSString *)oldAdditionalImagesDataPath {
  return [[MenuData libraryCachePath] stringByAppendingPathComponent:@"images"];
}

+(NSString *)newAdditionalImagesDataPath {
  return [[MenuData applicationSupportPath] stringByAppendingPathComponent:@"images"];
}

+(NSString *)additionalImagesDataPath {
  static NSString *dPath = nil;
  @synchronized([MenuData class]) {
    if (dPath == nil) {
      dPath = [MenuData applicationSupportPath];
      [MenuData ensurePathStructure:[NSArray arrayWithObject:@"images"] toBase:dPath];
      dPath = [[dPath stringByAppendingPathComponent:@"images"] retain];
    }
    return dPath;
  }
}

+(NSString *)userImagesDataPath {
  static NSString *dPath = nil;
  @synchronized([MenuData class]) {
    if (dPath == nil) {
      dPath = [MenuData documentPath];
      [MenuData ensurePathStructure:[NSArray arrayWithObject:@"user"] toBase:dPath];
      dPath = [[dPath stringByAppendingPathComponent:@"user"] retain];
    }
    return dPath;
  }
}

+(void)validateImageProperiesForParkId:(NSString *)parkId attractionIds:(NSArray *)attractionIds data:(NSDictionary *)data {
  NSMutableDictionary *aIds = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *basePath = [NSString stringWithFormat:@"%@/%@/", [ImageData additionalImagesDataPath], parkId];
  NSDictionary *imageAttractionIds = [data objectForKey:parkId];
  for (NSString *attractionId in attractionIds) {
    if ([imageAttractionIds objectForKey:attractionId] != nil) {
      NSString *path = [[NSString alloc] initWithFormat:@"%@%@", basePath, attractionId];
      if (![fileManager fileExistsAtPath:path]) {
        NSLog(@"remove image properties for attractionId %@ of parkId %@", attractionId, parkId);
        if (aIds == nil) aIds = [[NSMutableDictionary alloc] initWithDictionary:imageAttractionIds];
        [aIds removeObjectForKey:attractionId];
      }
      [path release];
    }
  }
  if (aIds != nil) {
    NSMutableDictionary *localData = [[NSMutableDictionary alloc] initWithDictionary:data];
    [localData setObject:aIds forKey:parkId];
    [aIds release];
    [ImageData save:localData];
    [localData release];
  }
}

+(void)deleteParkId:(NSString *)parkId {
  NSLog(@"delete additional images for parkId %@", parkId);
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = [[ImageData additionalImagesDataPath] stringByAppendingPathComponent:parkId];
  if ([fileManager fileExistsAtPath:path]) {
    [fileManager removeItemAtPath:path error:&error];
    if (error != nil) NSLog(@"Error deleting path %@ - %@", path, [error localizedDescription]);
  }
  NSMutableDictionary *localData = [[NSMutableDictionary alloc] initWithDictionary:[ImageData localData]];
  [localData removeObjectForKey:parkId];
  [ImageData save:localData];
  [localData release];
}

+(void)deleteParkId:(NSString *)parkId attractionId:(NSString *)attractionId localData:(NSDictionary *)localData {
  NSLog(@"delete additional images for attractionId %@ of parkId %@", attractionId, parkId);
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = [NSString stringWithFormat:@"%@/%@/%@", [ImageData additionalImagesDataPath], parkId, attractionId];
  if ([fileManager fileExistsAtPath:path]) {
    [fileManager removeItemAtPath:path error:&error];
    if (error != nil) NSLog(@"Error deleting path %@ - %@", path, [error localizedDescription]);
  }
  NSMutableDictionary *lData = [[NSMutableDictionary alloc] initWithDictionary:localData];
  NSMutableDictionary *aIds = [[NSMutableDictionary alloc] initWithDictionary:[lData objectForKey:parkId]];
  [aIds removeObjectForKey:attractionId];
  [lData setObject:aIds forKey:parkId];
  [aIds release];
  [ImageData save:lData];
  [lData release];
}

+(void)deleteParkId:(NSString *)parkId attractionId:(NSString *)attractionId fileName:(const char *)fileName localData:(NSDictionary *)localData {
  NSLog(@"delete additional image %s for attractionId %@ of parkId %@", fileName, attractionId, parkId);
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = [NSString stringWithFormat:@"%@/%@/%@/%s", [ImageData additionalImagesDataPath], parkId, attractionId, fileName];
  [fileManager removeItemAtPath:path error:&error];
  if (error != nil) NSLog(@"Error deleting file %@ - %@", path, [error localizedDescription]);
  NSMutableDictionary *lData = [[NSMutableDictionary alloc] initWithDictionary:localData];
  NSMutableDictionary *aIds = [[NSMutableDictionary alloc] initWithDictionary:[lData objectForKey:parkId]];
  NSMutableArray *images = [[NSMutableArray alloc] initWithArray:[aIds objectForKey:attractionId]];
  int i = 0;
  for (ImageProperty *image in images) {
    if ([image isEqualImageName:fileName]) break;
    ++i;
  }
  if (i < [images count]) [images removeObjectAtIndex:i];
  [aIds setObject:images forKey:attractionId];
  [images release];
  [lData setObject:aIds forKey:parkId];
  [aIds release];
  [ImageData save:lData];
  [lData release];
}

+(void)deleteUserImage:(NSString *)imagePath {
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager removeItemAtPath:imagePath error:&error];
  if (error != nil) NSLog(@"Error deleting file %@ - %@", imagePath, [error localizedDescription]);
  if ([imagePath hasSuffix:@".jpg"]) {
    imagePath = [[imagePath substringToIndex:[imagePath length]-4] stringByAppendingString:@"s.jpg"];
    [fileManager removeItemAtPath:imagePath error:&error];
    if (error != nil) NSLog(@"Error deleting file %@ - %@", imagePath, [error localizedDescription]);
  }
}

// parkId -> NSDictionary(attractionId -> NSArray(ImageProperty))
+(NSDictionary *)localData {
  NSError *error = nil;
  NSString *path = [[MenuData documentPath] stringByAppendingPathComponent:@"index.dat"];
  NSData *fileData = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingUncached error:&error];
  if (error != nil) NSLog(@"Error reading index.dat: %@", [error localizedDescription]);
  NSDictionary *localData = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
  NSMutableDictionary *localData2 = nil;
  NSEnumerator *i = [localData keyEnumerator];
  while (TRUE) {
    NSString *parkId = [i nextObject];
    if (!parkId) break;
    ParkData *parkData = [ParkData getParkData:parkId];
    if (parkData == nil) {
      if (localData2 == nil) localData2 = [[[NSMutableDictionary alloc] initWithDictionary:localData] autorelease];
      NSLog(@"remove parkId %@ from local image data", parkId);
      [localData2 removeObjectForKey:parkId];
    }
  }
  if (localData2 != nil) {
    [ImageData save:localData2];
    localData = localData2;
  }
  [fileData release];
  return localData;
}

+(BOOL)save:(NSDictionary *)data {
  //NSLog(@"save image local data index");
  NSString *path = [[MenuData documentPath] stringByAppendingPathComponent:@"index.dat"];
  return [[NSKeyedArchiver archivedDataWithRootObject:data] writeToFile:path atomically:YES];
}

static char* intValue(char *source, int *value) {
  int x = 0;
  BOOL neg = FALSE;
  if (*source == '-') {
    ++source;
    neg = TRUE;
  }
  while (TRUE) {
    char c = *source;
    if (c >= '0' && c <= '9') {
      x *= 10; x += (int)(c - '0');
    } else {
      *value = (neg)? -x : x;
      return source;
    }
    ++source;
  }
}

static char* doubleValue(char *source, double *value) {
  double x = 0.0;
  double comma = 0.0;
  BOOL neg = FALSE;
  if (*source == '-') {
    ++source;
    neg = TRUE;
  }
  while (TRUE) {
    char c = *source;
    if (c >= '0' && c <= '9') {
      if (comma == 0.0) {
        x *= 10; x += (int)(c - '0');
      } else {
        comma /= 10;
        x += comma * (int)(c - '0');
      }
    } else if (c == '.' && comma == 0.0) {
      comma = 1.0;
    } else {
      *value = (neg)? -x : x;
      return source;
    }
    ++source;
  }
}

static NSDictionary *availableData = nil;
static NSString *forParkId = nil;
+(NSDictionary *)availableDataForParkId:(NSString *)parkId reload:(BOOL)reload {
  @synchronized([ImageData class]) {
    if (availableData == nil || parkId == nil || reload || ![forParkId isEqualToString:parkId]) {
      if (parkId != nil) {
        [availableData release];
        availableData = nil;
        [forParkId release];
        forParkId = nil;
      }
      NSString *path = [[MenuData documentPath] stringByAppendingPathComponent:@"index.info"];
      if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"File 'index.info' does not exist in document path");
        return nil;
      }
      // Too slow: NSString *data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
      // return (error == nil && data != nil)? [ImageData parseData:data] : nil;
      // +(NSDictionary *)parseData:(NSString *)data; // parkId -> NSDictionary(attractionId -> NSArray(ImageProperty))
      FILE *pFile = fopen([path UTF8String], "r");
      if (pFile == NULL) {
        NSLog(@"File error %@", path);
        return nil;
      }
      // obtain file size:
      fseek(pFile, 0, SEEK_END);
      long lSize = ftell(pFile);
      rewind(pFile);
      char *data = malloc(sizeof(char)*(lSize+1));
      if (data == NULL) {
        NSLog(@"Memory error");
        fclose(pFile);
        return nil;
      }
      // copy the file into the buffer:
      size_t result = fread(data, 1, lSize, pFile);
      fclose(pFile);
      if (result != lSize) {
        NSLog(@"Reading error");
        free(data);
        return nil;
      }
      data[lSize] = '\x0';
      NSMutableDictionary *indexData = (parkId == nil)? [[[NSMutableDictionary alloc] initWithCapacity:10] autorelease] : [[NSMutableDictionary alloc] initWithCapacity:1];
      char *s = data;
      NSLog(@"parse available image index for park %@", parkId);
      while (*s != '\x0') {
        char *s2 = strchr(s, '\n');
        if (s2) *s2 = '\x0';
        else break;
        if (*s == '\x0') break;
        NSString *pId = [NSString stringWithFormat:@"%s", s];
        NSMutableDictionary *parkData = (parkId == nil || [parkId isEqualToString:pId])? [[NSMutableDictionary alloc] initWithCapacity:200] : nil;
        s = s2+1;
        while (*s != '\x0') {
          if (*s == '\n') {
            ++s;
            break;
          }
          char *s2 = strchr(s+1, '\n');
          if (s2) *s2 = '\x0';
          else break;
          NSString *attractionId = nil;
          NSMutableArray *images = nil;
          if (parkData != nil) {
            attractionId = [NSString stringWithFormat:@"%s", s];
            images = [[NSMutableArray alloc] initWithCapacity:3];
          }
          s = s2+1;
          while (*s != '\x0') {
            double timestamp = 0.0;
            s2 = doubleValue(s, &timestamp);
            if (*s2 != ',') break;
            int size = 0;
            s2 = intValue(s2+1, &size);
            if (*s2 == ',') {
              s = s2+1;
              char *s2 = strchr(s, '\n');
              if (s2) *s2 = '\x0';
              if (images != nil) {
                ImageProperty *property = [[ImageProperty alloc] initWithImageName:s size:size timestamp:timestamp];
                [images addObject:property];
                [property release];
              }
              s = s2+1;
            } else NSLog(@"Wrong size at image properties of attraction %@ park %@", attractionId, pId);
          }
          if (parkData != nil) {
            [parkData setObject:images forKey:attractionId];
            [images release];
          }
        }
        if (parkData != nil) {
          [indexData setObject:parkData forKey:pId];
          [parkData release];
          if (parkId != nil && [parkId isEqualToString:pId]) break;
        }
      }
      free(data);
      if (parkId != nil) {
        availableData = indexData;
        forParkId = [parkId retain];
      } else {
        return indexData;
      }
    }
    return availableData;
  }
}

+(void)clearCacheOfAvailableData {
  @synchronized([ImageData class]) {
    [availableData release];
    availableData = nil;
    [forParkId release];
    forParkId = nil;
  }
}

+(void)updateLocalDataWithAvailableDataOfParkId:(NSString *)parkId {
  NSDictionary *lData = [ImageData localData];
  NSMutableDictionary *localData = (lData != nil)? [[NSMutableDictionary alloc] initWithDictionary:lData] : [[NSMutableDictionary alloc] initWithCapacity:1];
  NSDictionary *availableData = [ImageData availableDataForParkId:parkId reload:NO];
  [localData setValue:[availableData objectForKey:parkId] forKey:parkId];
  [ImageData save:localData];
  [localData release];
}

+(void)updateLocalDataWithAvailableDataOfParkId:(NSString *)parkId attractionId:(NSString *)attractionId {
  NSDictionary *lData = [ImageData localData];
  NSMutableDictionary *localData = (lData != nil)? [[NSMutableDictionary alloc] initWithDictionary:lData] : [[NSMutableDictionary alloc] initWithCapacity:1];
  lData = [localData objectForKey:parkId];
  NSMutableDictionary *localData2 = (lData != nil)? [[NSMutableDictionary alloc] initWithDictionary:lData] : [[NSMutableDictionary alloc] initWithCapacity:1];
  NSDictionary *availableData = [ImageData availableDataForParkId:parkId reload:NO];
  availableData = [availableData objectForKey:parkId];
  [localData2 setValue:[availableData objectForKey:attractionId] forKey:attractionId];
  [localData setValue:localData2 forKey:parkId];
  [ImageData save:localData];
  [localData release];
  [localData2 release];
}

+(BOOL)isPathAvailableOfParkId:(NSString *)parkId {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = [[ImageData additionalImagesDataPath] stringByAppendingPathComponent:parkId];
  return [fileManager fileExistsAtPath:path];
}

+(NSSet *)allParkIdsWithAvailableChanges {
  NSArray *allParkIds = [MenuData getParkIds];
  NSMutableSet *allChanges = [[[NSMutableSet alloc] initWithCapacity:[allParkIds count]+1] autorelease];
  NSDictionary *localData = [ImageData localData];
  NSDictionary *availableData = [ImageData availableDataForParkId:nil reload:NO];
  for (NSString *parkId in allParkIds) {
    __block BOOL update = NO;
    NSDictionary *lData = [localData objectForKey:parkId];
    if (lData == nil) update = YES;
    else {
      NSDictionary *aData = [availableData objectForKey:parkId];
      [aData enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        NSString *attractionId = key;
        NSArray *images = object;
        NSArray *imageProperties = [lData objectForKey:attractionId];
        if (imageProperties == nil) update = YES;
        for (ImageProperty *imageProperty in images) {
          update = YES;
          NSUInteger idx = [imageProperties indexOfObject:imageProperty];
          if (idx != NSNotFound) {
            ImageProperty *i = [imageProperties objectAtIndex:idx];
            if (i.size == imageProperty.size && i.timestamp == imageProperty.timestamp) update = NO;
          }
        }
        if (update) *stop = YES;
      }];
    }
    if (update) [allChanges addObject:parkId];
  }
  return allChanges;
}

+(BOOL)changesAvailableForParkId:(NSString *)parkId {
  __block BOOL update = NO;
  NSDictionary *localData = [ImageData localData];
  localData = [localData objectForKey:parkId];
  if (localData == nil) update = YES;
  else {
    NSDictionary *availableData = [ImageData availableDataForParkId:parkId reload:NO];
    availableData = [availableData objectForKey:parkId];
    [availableData enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
      NSString *attractionId = key;
      NSArray *images = object;
      NSArray *imageProperties = [localData objectForKey:attractionId];
      if (imageProperties == nil) update = YES;
      for (ImageProperty *imageProperty in images) {
        update = YES;
        NSUInteger idx = [imageProperties indexOfObject:imageProperty];
        if (idx != NSNotFound) {
          ImageProperty *i = [imageProperties objectAtIndex:idx];
          if (i.size == imageProperty.size && i.timestamp == imageProperty.timestamp) update = NO;
        }
      }
      if (update) *stop = YES;
    }];
  }
  return update;
}

+(int)availableChangesOfParkId:(NSString *)parkId betweenLocalData:(NSDictionary *)localData andAvailableData:(NSDictionary *)availableData resultingChanges:(NSMutableArray *)changes numberOfChangingImages:(int *)numberOfChangingImages {
  __block int size = 0;
  __block NSMutableDictionary *localData2 = nil;
  *numberOfChangingImages = 0;
  [changes removeAllObjects];
  NSDictionary *localDataPark = [localData objectForKey:parkId];
  availableData = [availableData objectForKey:parkId];
  // check if local files need to be removed
  [localDataPark enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSString *attractionId = key;
    NSArray *images = object;
    NSArray *imageProperties = [availableData objectForKey:attractionId];
    if (imageProperties == nil) {
      if (localData2 == nil) localData2 = [[NSMutableDictionary alloc] initWithDictionary:localData];
      [ImageData deleteParkId:parkId attractionId:attractionId localData:localData2];
    } else {
      for (ImageProperty *imageProperty in images) {
        NSUInteger idx = [imageProperties indexOfObject:imageProperty];
        if (idx == NSNotFound) {
          if (localData2 == nil) localData2 = [[NSMutableDictionary alloc] initWithDictionary:localData];
          [ImageData deleteParkId:parkId attractionId:attractionId fileName:imageProperty.imageName localData:localData2];
        }
      }
    }
  }];
  if (localData2 != nil) {
    [localData2 release];
    localData2 = nil;
    localData = [ImageData localData];
    localDataPark = [localData objectForKey:parkId];
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  [availableData enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    int packageSize = 0;
    int numberOfImages = 0;
    int completePackageSize = 0;
    NSArray *images = object;
    NSString *attractionId = key;
    if (parkData == nil || [Attraction getAttraction:parkId attractionId:attractionId] != nil) {
      NSArray *imageProperties = [localDataPark objectForKey:attractionId];
      NSMutableArray *packageChanges = [[NSMutableArray alloc] initWithCapacity:20];
      for (ImageProperty *imageProperty in images) {
        BOOL update = YES;
        if (localDataPark != nil && imageProperties != nil) {
          NSUInteger idx = [imageProperties indexOfObject:imageProperty];
          if (idx != NSNotFound) {
            ImageProperty *i = [imageProperties objectAtIndex:idx];
            if (i.size == imageProperty.size && i.timestamp == imageProperty.timestamp) update = NO;
          }
        }
        if (update) {
          NSString *path = [[NSString alloc] initWithFormat:@"%@/%@/%s", parkId, attractionId, imageProperty.imageName];
          [packageChanges addObject:path];
          [path release];
          packageSize += imageProperty.size;
          ++numberOfImages;
        }
        completePackageSize += imageProperty.size;
      }
      if ([packageChanges count] > 1 && 2*completePackageSize < 3*packageSize) {
        [packageChanges removeAllObjects];
        NSString *path = [[NSString alloc] initWithFormat:@"%@/%@/%@.zip", parkId, attractionId, attractionId];
        [packageChanges addObject:path];
        [path release];
        packageSize = completePackageSize;
        numberOfImages = (int)[images count];
      }
      *numberOfChangingImages += numberOfImages;
      size += packageSize;
      [changes addObjectsFromArray:packageChanges];
      [packageChanges release];
    }
  }];
  return size;
}

+(int)availableChangesOfParkId:(NSString *)parkId attractionId:(NSString *)attractionId betweenLocalData:(NSDictionary *)localData andAvailableData:(NSDictionary *)availableData resultingChanges:(NSMutableArray *)changes numberOfChangingImages:(int *)numberOfChangingImages {
  int size = 0;
  int completeSize = 0;
  [changes removeAllObjects];
  *numberOfChangingImages = 0;
  localData = [localData objectForKey:parkId];
  NSArray *localImageProperties = [localData objectForKey:attractionId];
  availableData = [availableData objectForKey:parkId];
  NSArray *availableImageProperties = [availableData objectForKey:attractionId];
  for (ImageProperty *imageProperty in availableImageProperties) {
    BOOL update = YES;
    if (localData != nil && localImageProperties != nil) {
      NSUInteger idx = [localImageProperties indexOfObject:imageProperty];
      if (idx != NSNotFound) {
        ImageProperty *i = [localImageProperties objectAtIndex:idx];
        if (i.size == imageProperty.size && i.timestamp == imageProperty.timestamp) update = NO;
      }
    }
    if (update) {
      NSString *path = [[NSString alloc] initWithFormat:@"%@/%@/%s", parkId, attractionId, imageProperty.imageName];
      [changes addObject:path];
      [path release];
      size += imageProperty.size;
      ++(*numberOfChangingImages);
    }
    completeSize += imageProperty.size;
  }
  if ([changes count] > 1 && 2*completeSize < 3*size) {
    [changes removeAllObjects];
    NSString *path = [[NSString alloc] initWithFormat:@"%@/%@/%@.zip", parkId, attractionId, attractionId];
    [changes addObject:path];
    [path release];
    size = completeSize;
    *numberOfChangingImages = (int)availableImageProperties.count;
  }
  return size;
}

+(NSDictionary *)availableChangesSizeImagePathesByKindOfForParkId:(NSString *)parkId {
  Categories *categories = [Categories getCategories];
  NSDictionary *availableData = [ImageData availableDataForParkId:parkId reload:NO];
  NSDictionary *localData = [ImageData localData];
  NSDictionary *aData = [availableData objectForKey:parkId];
  NSMutableDictionary *sizeImagePathes = [[[NSMutableDictionary alloc] initWithCapacity:15] autorelease];
  NSMutableArray *imagePathes = [[NSMutableArray alloc] initWithCapacity:50];
  for (NSString *attractionId in aData) {
    int n = 0;
    int size = [ImageData availableChangesOfParkId:parkId attractionId:attractionId betweenLocalData:localData andAvailableData:availableData resultingChanges:imagePathes numberOfChangingImages:&n];
    if (n > 0 && size > 0) {
      Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
      if (attraction != nil) {
        NSArray *categoryNames = [categories getCategoryNames:attraction.typeId];
        if ([categoryNames count] > 0) {
          NSString *c = [categoryNames objectAtIndex:0];
          NSMutableArray *pathes = [sizeImagePathes objectForKey:c];
          if (pathes == nil) {
            pathes = [[NSMutableArray alloc] initWithCapacity:15];
            [pathes addObject:[NSNumber numberWithInt:0]];
            [pathes addObject:[NSNumber numberWithInt:0]];
            [sizeImagePathes setObject:pathes forKey:c];
          }
          [pathes replaceObjectAtIndex:0 withObject:[NSNumber numberWithInt:n+[[pathes objectAtIndex:0] intValue]]];
          [pathes replaceObjectAtIndex:1 withObject:[NSNumber numberWithInt:size+[[pathes objectAtIndex:1] intValue]]];
          [pathes addObjectsFromArray:imagePathes];
          [imagePathes release];
          imagePathes = [[NSMutableArray alloc] initWithCapacity:50];
        }
      }
    }
  }
  [imagePathes release];
  return sizeImagePathes;
}

+(NSArray *)allImagePathesForParkId:(NSString *)parkId attractionId:(NSString *)attractionId data:(NSDictionary *)data {
  NSMutableArray *result = nil;
  NSArray *images1 = [ImageData imageProperiesForParkId:parkId attractionId:attractionId data:data];
  NSArray *images2 = [ImageData userImagePathesForParkId:parkId attractionId:attractionId];
  if (images1 == nil || images1.count == 0) {
    result = [[[NSMutableArray alloc] initWithCapacity:images2.count+1] autorelease];
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
    [result addObject:[attraction imagePath:parkId]];
  } else {
    result = [[[NSMutableArray alloc] initWithCapacity:images1.count+images2.count] autorelease];
    for (ImageProperty *imageProperty in images1) {
      NSString *imagePath = [[NSString alloc] initWithFormat:@"%@/%@/%@/%s", [ImageData additionalImagesDataPath], parkId, attractionId, imageProperty.imageName];
      [result addObject:imagePath];
      [imagePath release];
    }
  }
  if (images2 != nil) [result addObjectsFromArray:images2];
  return result;
}

+(NSArray *)imageProperiesForParkId:(NSString *)parkId attractionId:(NSString *)attractionId data:(NSDictionary *)data {
  // wrong!! if data is not local data
  /*NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = [NSString stringWithFormat:@"%@/%@/%@", [ImageData additionalImagesDataPath], parkId, attractionId];
  if (![fileManager fileExistsAtPath:path]) {
    [ImageData deleteParkId:parkId attractionId:attractionId localData:data];
    return nil;
  }*/
  return [[data objectForKey:parkId] objectForKey:attractionId];
}

+(NSArray *)userImagePathesForParkId:(NSString *)parkId attractionId:(NSString *)attractionId {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = [NSString stringWithFormat:@"%@/%@/%@", [ImageData userImagesDataPath], parkId, attractionId];
  if (![fileManager fileExistsAtPath:path]) return nil;
  NSError *error = nil;
  NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:&error];
  if (error != nil) {
    NSLog(@"Error content of path %@ - %@", path, [error localizedDescription]);
    return nil;
  }
  int n = (int)files.count;
  if (n == 0) return nil;
  NSMutableArray *result = [[[NSMutableArray alloc] initWithCapacity:n] autorelease];
  for (NSString *filename in files) {
    if (![filename hasSuffix:@"s.jpg"]) [result addObject:[path stringByAppendingPathComponent:filename]];
  }
  return result;
}

+(NSArray *)getImagePropertiesForParkId:(NSString *)parkId attractionId:(NSString *)attractionId insideAvailableData:(NSDictionary *)availableData {
  return [[availableData objectForKey:parkId] objectForKey:attractionId];
}

+(NSString *)getAttractionIdForImage:(NSString *)imagePath atParkId:(NSString *)parkId insideAvailableData:(NSDictionary *)availableData {
  if ([imagePath hasSuffix:@".zip"]) {
    NSRange range = [imagePath rangeOfString:@"/" options:NSBackwardsSearch];
    if (range.length > 0 && range.location+6 < [imagePath length]) {
      ++range.location; range.length = [imagePath length]-range.location-4;
      return [imagePath substringWithRange:range];
    }
  }
  __block NSString *attractionId = nil;
  availableData = [availableData objectForKey:parkId];
  [availableData enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSArray *availableImageProperties = object;
    for (ImageProperty *imageProperty in availableImageProperties) {
      if ([imageProperty isSuffixOf:imagePath]) {
        attractionId = key;
        *stop = YES;
      }
    }
  }];
  return attractionId;
}

+(BOOL)isRetinaDisplay {
  UIScreen *s = [UIScreen mainScreen];
  return ([s respondsToSelector:@selector(displayLinkWithTarget:selector:)] && s.scale >= 2.0);
}

+(UIImage *)rescaleImage:(UIImage *)image toSize:(CGSize)size {
	CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
	UIGraphicsBeginImageContext(rect.size);
	[image drawInRect:rect];  // scales image to rect
	UIImage *resImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return resImage;
}

+(UIImage *)makeBackgroundImage:(UIImage*)myImage {
  CGImageRef originalImage = [myImage CGImage];
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef bitmapContext = CGBitmapContextCreate(NULL,CGImageGetWidth(originalImage),CGImageGetHeight(originalImage),8,CGImageGetWidth(originalImage)*4,colorSpace,kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(colorSpace);
  CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext)), originalImage);
  UInt8 *data = CGBitmapContextGetData(bitmapContext);
  int numComponents = 4;
  int bytesInContext = CGBitmapContextGetHeight(bitmapContext) * CGBitmapContextGetBytesPerRow(bitmapContext);
  double redIn, greenIn, blueIn;//,alphaIn;
  double hue,saturation,value;
  for (int i = 0; i < bytesInContext; i += numComponents) {
    redIn = (double)data[i]/255.0;
    greenIn = (double)data[i+1]/255.0;
    blueIn = (double)data[i+2]/255.0;
    //alphaIn = (double)data[i+3]/255.0;
    rgbToHsv(redIn, greenIn, blueIn, &hue, &saturation, &value);
    hue = 240;
    saturation *= 0.5;
    hsvToRgb(hue, saturation, value, &redIn, &greenIn, &blueIn);
    data[i] = redIn * 255.0;
    data[i+1] = greenIn * 255.0;
    data[i+2] = blueIn * 255.0;
  }
  CGImageRef outImage = CGBitmapContextCreateImage(bitmapContext);
  myImage = [UIImage imageWithCGImage:outImage];
  CGContextRelease(bitmapContext);
  CGImageRelease(outImage);
  return myImage;
}

@end
