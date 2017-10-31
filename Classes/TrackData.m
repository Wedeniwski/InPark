//
//  TrackData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 06.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "TrackData.h"
#import "MenuData.h"
#import "ParkData.h"
#import "CalendarData.h"
#import "Attraction.h"
#import "Categories.h"
#import "LocationData.h"
#import "SettingsData.h"

@implementation TrackData

@synthesize trackName, parkId, parkingNotes, trackDescription, fromAttractionId;
@synthesize currentTrackPoints, trackSegments;


#pragma mark -
#pragma mark Memory management

-(id)initWithTrackName:(NSString *)tName parkId:(NSString *)pId fromAttractionId:(NSString *)fAttractionId {
  self = [super init];
  if (self != nil) {
    ParkData *parkData = [ParkData getParkData:pId];
    NSString *newTrackName = tName;
    NSArray *trackNames = [parkData getCompletedTracks];
    for (int i = 1; [trackNames indexOfObject:newTrackName] != NSNotFound; ++i) {
      newTrackName = [tName stringByAppendingFormat:@" - %d", i];
    }
    trackName = [newTrackName retain];
    parkId = [pId retain];
    parkingNotes = nil;
    trackDescription = @"";
    gpxFileName = [[NSString stringWithFormat:@"%ld_%@.gpx", (long)([[NSDate date] timeIntervalSince1970]), parkId] retain];
    currentTrackPoints = [[NSMutableArray alloc] initWithCapacity:50];
    //ParkData *parkData = [ParkData getParkData:parkId];
    //fromAttractionId = [[parkData getRootAttractionId:fAttractionId] retain];
    fromAttractionId = [fAttractionId retain];
    trackSegments = [[NSMutableArray alloc] initWithCapacity:25];
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [super init];
  if (self != nil) {
    trackName = [[coder decodeObjectForKey:@"TRACK_NAME"] retain];
    parkId = [[coder decodeObjectForKey:@"PARK_ID"] retain];
    parkingNotes = [[coder decodeObjectForKey:@"PARKING_NOTES"] retain];
    trackDescription = [[coder decodeObjectForKey:@"TRACK_DESCRIPTION"] retain];
    gpxFileName = [[coder decodeObjectForKey:@"GPX_FILENAME"] retain];
    currentTrackPoints = [[NSMutableArray alloc] initWithArray:[coder decodeObjectForKey:@"CURRENT_TRACK_POINTS"]];
    fromAttractionId = [[coder decodeObjectForKey:@"FROM_ATTRACTION_ID"] retain];
    trackSegments = [[NSMutableArray alloc] initWithArray:[coder decodeObjectForKey:@"TRACK_SEGMENTS"]];
  }
  return self;
}

-(void)dealloc {
  [trackName release];
  [parkId release];
  [parkingNotes release];
  [trackDescription release];
  [gpxFileName release];
  [currentTrackPoints release];
  [fromAttractionId release];
  [trackSegments release];
  [super dealloc];
}

-(void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:trackName forKey:@"TRACK_NAME"];
  [coder encodeObject:parkId forKey:@"PARK_ID"];
  [coder encodeObject:parkingNotes forKey:@"PARKING_NOTES"];
  [coder encodeObject:trackDescription forKey:@"TRACK_DESCRIPTION"];
  [coder encodeObject:gpxFileName forKey:@"GPX_FILENAME"];
  [coder encodeObject:currentTrackPoints forKey:@"CURRENT_TRACK_POINTS"];
  [coder encodeObject:fromAttractionId forKey:@"FROM_ATTRACTION_ID"];
  [coder encodeObject:trackSegments forKey:@"TRACK_SEGMENTS"];
}

-(BOOL)complete:(NSString *)completedTrackDescription {
  if ([self saveData]) {
    [trackDescription release];
    trackDescription = [completedTrackDescription retain];
    [currentTrackPoints removeAllObjects];
    [fromAttractionId release];
    fromAttractionId = @"";
    [trackSegments removeAllObjects];
    return YES;
  }
  return NO;
}

-(BOOL)isDoneAtTourIndex:(int)index {
  for (TrackSegment *s in trackSegments) {
    if (s.isTrackToTourItem) {
      if (index == 0) return YES;
      --index;
    }
  }
  return NO;
}

-(BOOL)isDoneAndActiveAtTourIndex:(int)index {
  for (TrackSegment *s in trackSegments) {
    if (s.isTrackToTourItem) {
      if (index == 0) return YES;
      --index;
    }
  }
  return (index == 0 && ![self walkToEntry]);
}

-(double)doneTimeIntervalAtEntryTourIndex:(int)index {
  TrackSegment *previous = nil;
  for (TrackSegment *s in trackSegments) {
    if (s.isTrackToTourItem) {
      if (index == 0) {
        if (previous == nil || previous.isTrackToTourItem) return 0.0;
        ExtendedTrackPoint *t = (ExtendedTrackPoint *)[previous toTrackPoint];
        return t.recordTime;
      }
      --index;
    }
    previous = s;
  }
  return 0.0;
}

-(double)doneTimeIntervalAtExitTourIndex:(int)index {
  for (TrackSegment *s in trackSegments) {
    if (s.isTrackToTourItem) {
      if (index == 0) {
        ExtendedTrackPoint *t = (ExtendedTrackPoint *)[s toTrackPoint];
        return t.recordTime;
      }
      --index;
    }
  }
  return 0.0;
}

-(int)numberOfTourItemsDone {
  int done = 0;
  for (TrackSegment *s in trackSegments) {
    if (s.isTrackToTourItem) ++done;
  }
  return done;
}

-(int)numberOfTourItemsDoneAndActive {
  return [self numberOfTourItemsDone] + ([self walkToEntry]? 0 : 1);
}

-(BOOL)walkToEntry {
  int n = (int)[trackSegments count];
  if (n == 0) return YES;
  TrackSegment *lastSegment = [trackSegments lastObject];
  if (!lastSegment.isTrackToTourItem) return NO;
  if ([lastSegment.fromAttractionId isEqualToString:lastSegment.toAttractionId]) return YES;
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:fromAttractionId];
  return (attraction == nil || ![attraction isRealAttraction]);
}

-(double)completedDistance {
  double d = 0.0;
  for (TrackSegment *s in trackSegments) {
    if (s.isTrackToTourItem) d += s.distance;
  }
  return d;
}

-(double)distanceOfCompletedSegmentAtTourIndex:(int)index {
  for (TrackSegment *s in trackSegments) {
    if (s.isTrackToTourItem) {
      if (index == 0) return s.distance;
      --index;
    }
  }
  return 0.0;
}

-(int)walkingTimeOfCompletedSegmentAtTourIndex:(int)index {
  for (TrackSegment *s in trackSegments) {
    if (s.isTrackToTourItem) {
      if (index == 0) {
        ExtendedTrackPoint *f = (ExtendedTrackPoint *)[s fromTrackPoint];
        ExtendedTrackPoint *t = (ExtendedTrackPoint *)[s toTrackPoint];
        return (int)((t.recordTime-f.recordTime)/60);
      }
      --index;
    }
  }
  return 0;
}

-(void)addAttractionId:(NSString *)newAttractionId toTourItem:(BOOL)toTourItem fromExitAttractionId:(NSString *)fromExitAttractionId {
  if ([currentTrackPoints count] == 0) return;
  ExtendedTrackPoint *lastTrackPoint = [currentTrackPoints lastObject];
  double now = [[NSDate date] timeIntervalSince1970];
  if (now-lastTrackPoint.recordTime >= 30.0) {
    if ([LocationData isLocationDataActive]) {
      LocationData *locData = [LocationData getLocationData];
      CLLocation *lastLocation = locData.lastUpdatedLocation;
      double lastTimestamp = [lastLocation.timestamp timeIntervalSince1970];
      if (now-lastTimestamp >= 30.0) lastTimestamp = now;
      lastTrackPoint = [[ExtendedTrackPoint alloc] initWithLatitude:lastLocation.coordinate.latitude
                                                          longitude:lastLocation.coordinate.longitude
                                                          elevation:(lastLocation.verticalAccuracy < 0.0)? 0.0 : lastLocation.altitude
                                                           accuracy:lastLocation.horizontalAccuracy
                                                         recordTime:lastTimestamp];
    } else {
      lastTrackPoint = [[ExtendedTrackPoint alloc] initWithLatitude:lastTrackPoint.latitude longitude:lastTrackPoint.longitude elevation:lastTrackPoint.elevation accuracy:lastTrackPoint.accuracy recordTime:now];
    }
    [currentTrackPoints addObject:lastTrackPoint];
  } else [lastTrackPoint retain];
  TrackSegment *segment = [[TrackSegment alloc] initWithFromAttractionId:fromAttractionId toAttractionId:newAttractionId trackPoints:currentTrackPoints isTrackToTourItem:toTourItem];
  ParkData *parkData = [ParkData getParkData:parkId];
  if (fromExitAttractionId != nil && ![fromAttractionId isEqualToString:[parkData getEntryAttractionId:fromExitAttractionId]]) {
    segment.fromExitAttractionId = fromExitAttractionId;
  }
  [trackSegments addObject:segment];
  [segment release];
  [currentTrackPoints release];
  currentTrackPoints = [[NSMutableArray alloc] initWithCapacity:50];
  [currentTrackPoints addObject:lastTrackPoint];
  [lastTrackPoint release];
  [fromAttractionId release];
  fromAttractionId = [newAttractionId retain];
}

-(void)addTrackPoint:(CLLocation *)newLocation {
  if (newLocation.horizontalAccuracy >= 0.0) {
    ExtendedTrackPoint *t = [[ExtendedTrackPoint alloc] initWithLatitude:newLocation.coordinate.latitude
                                                               longitude:newLocation.coordinate.longitude
                                                               elevation:(newLocation.verticalAccuracy < 0.0)? 0.0 : newLocation.altitude
                                                                accuracy:newLocation.horizontalAccuracy
                                                              recordTime:[newLocation.timestamp timeIntervalSince1970]];
    [currentTrackPoints addObject:t];
    [t release];
  }
}

-(double)timeOfLastTrackFromAttraction {
  if (currentTrackPoints != nil && [currentTrackPoints count] > 0) {
    ExtendedTrackPoint *t = [currentTrackPoints objectAtIndex:0];
    return t.recordTime;
  }
  return 0.0;
}

-(ExtendedTrackPoint *)deleteCurrentTrackExceptLastPoint {
  if (currentTrackPoints != nil) {
    int l = (int)[currentTrackPoints count];
    if (l > 1) {
      ExtendedTrackPoint *t = [[currentTrackPoints lastObject] retain];
      [currentTrackPoints removeAllObjects];
      [currentTrackPoints addObject:t];
      [t release];
      return [currentTrackPoints objectAtIndex:0];
    }
  }
  return nil;
}

-(TrackSegment *)getTrackSegmentFromParking {
  int l = (int)[trackSegments count];
  if (l > 0) {
    TrackSegment *s = [trackSegments objectAtIndex:0];
    if ([s.fromAttractionId isEqualToString:PARKING_ATTRACTION_ID]) return s;
  }
  return nil;
}

-(BOOL)containsTrackingFromParking {
  return ([trackSegments count] == 0 && [fromAttractionId isEqualToString:PARKING_ATTRACTION_ID]);
}

-(ExtendedTrackPoint *)latestTrackPoint {
  return (currentTrackPoints != nil)? [currentTrackPoints lastObject] : nil;
}

+(NSString *)defaultName:(NSString *)tourName {
  return [NSString stringWithFormat:@"%@  %@", tourName, [CalendarData stringFromDate:[NSDate date] considerTimeZoneAbbreviation:nil]];
}

-(NSString *)gpxFilePath {
  return [NSString stringWithFormat:@"%@/%@", [MenuData documentPath], gpxFileName];
}

-(void)timeframeAtAttraction:(Attraction *)attraction afterTime:(NSDate *)time fromGPXContentsOfFile:(NSString *)content start:(NSDate **)start end:(NSDate **)end {
  *start = nil; *end = nil;
  NSRange range = [content rangeOfString:@"<wpt "];
  if (range.length == 0) return;
  NSDateFormatter *gpxTimeFormat = [[NSDateFormatter alloc] init];
  [gpxTimeFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
  if (time != nil) {
    range.length = [content length]-range.location;
    range = [content rangeOfString:[NSString stringWithFormat:@"<time>%@Z</time>", [gpxTimeFormat stringFromDate:time]] options:NSLiteralSearch range:range];
    if (range.length == 0) {
      [gpxTimeFormat release];
      return;
    }
  }
  range.length = [content length]-range.location;
  // Depends on language! NSString *exitName = [NSString stringWithFormat:NSLocalizedString(@"tour.description.exit.of", nil), attraction.stringAttractionName];
  NSRange range2 = [content rangeOfString:[NSString stringWithFormat:@"<name>%@</name>", attraction.stringAttractionName] options:NSLiteralSearch range:range];
  if (range2.length > 0) {
    range.location = range2.location+13+strlen(attraction.attractionName);
    range.length = [content length]-range.location;
    NSRange range3 = [content rangeOfString:@"<name>" options:NSLiteralSearch range:range];
    if (range3.length > 0 && range3.location > range2.location) {
      range2.length = range3.location-range2.location;
      range2 = [content rangeOfString:@"<time>" options:NSLiteralSearch range:range2];
      if (range2.length > 0) {
        range2.location += 6; range2.length = 19;
        *start = [gpxTimeFormat dateFromString:[content substringWithRange:range2]];
      }
      range3.length = [content length]-range3.location;
      range3 = [content rangeOfString:@"<time>" options:NSLiteralSearch range:range3];
      if (range3.length > 0) {
        range3.location += 6; range3.length = 19;
        *end = [gpxTimeFormat dateFromString:[content substringWithRange:range3]];
      }
    } else {
      range3.location = range2.location;
      range3.length = [content length]-range2.location;
      range3 = [content rangeOfString:@"<time>" options:NSLiteralSearch range:range3];
      if (range3.length > 0) {
        range3.location += 6; range2.length = 19;
        *end = [gpxTimeFormat dateFromString:[content substringWithRange:range3]];
      }
      range2.length = range2.location;
      range2.location = 0;
      range2 = [content rangeOfString:@"<time>" options:NSBackwardsSearch range:range2];
      if (range2.length > 0) {
        range2.location += 6; range2.length = 19;
        *start = [gpxTimeFormat dateFromString:[content substringWithRange:range2]];
      }
      if (*start == nil) *start = *end;
      else if (*end != nil && [*start compare:*end] == NSOrderedDescending) *start = *end;
    }
  }
  [gpxTimeFormat release];
}

-(NSArray *)getAllAttractionsFromGPXFile:(double *)completedDistance start:(NSDate **)start end:(NSDate **)end {
  NSDateFormatter *gpxTimeFormat = [[NSDateFormatter alloc] init];
  [gpxTimeFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
  NSString *fileName = [self gpxFilePath];
  NSError *error = nil;
  NSString *content = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];
  if (error != nil) NSLog(@"Error to read file '%@' (%@)", fileName, [error localizedDescription]);
  NSUInteger l = [content length];
  NSRange range;
  *completedDistance = 0.0;
  range.location = 0; range.length = l;
  double prevLat = 0.0;
  double prevLon = 0.0;
  *start = nil; *end = nil;
  while (YES) {
    NSRange range2 = [content rangeOfString:@"<trkpt " options:NSLiteralSearch range:range];
    if (range2.length == 0) {
      range2 = [content rangeOfString:@"<time>" options:NSLiteralSearch range:range];
      if (range2.length > 0) {
        range2.location += 6; range2.length = 19;
        NSString *time = [content substringWithRange:range2];
        *end = [gpxTimeFormat dateFromString:time];
      }
      break;
    }
    range.location = range2.location+range2.length; range.length = l-range.location;
    range2 = [content rangeOfString:@"\" lon=\"" options:NSLiteralSearch range:range];
    range2.length = range2.location-range.location-5; range2.location = range.location+5;
    NSString *lat = [content substringWithRange:range2];
    range.location = range2.location+range2.length; range.length = l-range.location;
    range2 = [content rangeOfString:@"\">" options:NSLiteralSearch range:range];
    range2.length = range2.location-range.location-7; range2.location = range.location+7;
    NSString *lon = [content substringWithRange:range2];
    if (prevLat == 0.0 && prevLon == 0.0) {
      prevLat = [lat doubleValue]; prevLon = [lon doubleValue];
    } else {
      *completedDistance += distance(prevLat, prevLon, [lat doubleValue], [lon doubleValue]);
      prevLat = [lat doubleValue]; prevLon = [lon doubleValue];
    }
    if (*start == nil) {
      range2 = [content rangeOfString:@"<time>" options:NSLiteralSearch range:range];
      range2.location += 6; range2.length = 19;
      NSString *time = [content substringWithRange:range2];
      *start = [gpxTimeFormat dateFromString:time];
    }
    range.location = range2.location+range2.length; range.length = l-range.location;
  }
  [gpxTimeFormat release];
  range.location = 0; range.length = l;
  NSString *exitOfDescription = NSLocalizedString(@"tour.description.exit.of", nil);
  exitOfDescription = [exitOfDescription stringByReplacingOccurrencesOfString:@"%@" withString:@""];
  NSMutableArray *attractions = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
  while (YES) {
    NSRange range2 = [content rangeOfString:@"<wpt " options:NSLiteralSearch range:range];
    if (range2.length == 0) break;
    range.location = range2.location+range2.length; range.length = l-range.location;
    range2 = [content rangeOfString:@"<name>" options:NSLiteralSearch range:range];
    range.location = range2.location+range2.length; range.length = l-range.location;
    range2 = [content rangeOfString:@"</name>" options:NSLiteralSearch range:range];
    range2.length = range2.location-range.location; range2.location = range.location;
    NSString *attractionName = [content substringWithRange:range2];
    if ([attractionName hasPrefix:exitOfDescription]) attractionName = [attractionName substringFromIndex:exitOfDescription.length];
    Attraction *attraction = [Attraction getAttraction:parkId attractionName:[attractionName UTF8String]];
    if (attraction != nil && [attraction isRealAttraction] && ![attractions containsObject:attraction]) {
      [attractions addObject:attraction];
    }
  }
  [content release];
  return attractions;
}

-(BOOL)saveData {
  NSDateFormatter *gpxTimeFormat = [[NSDateFormatter alloc] init];
  [gpxTimeFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
  NSMutableString *content = [[NSMutableString alloc] initWithCapacity:10000];
  [content appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n"];
  [content appendString:@"<gpx xmlns=\"http://www.topografix.com/GPX/1/1\" creator=\"InPark.info\" version=\"1.1\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">\n"];
  [content appendFormat:@" <!-- InPark %@ - www.inpark.info -->\n<trk>\n  <name>%@ - %@</name>\n", [SettingsData getAppVersion], [MenuData getParkName:parkId cache:YES], trackName];
  for (TrackSegment *s in trackSegments) {
    [content appendFormat:@"%@\n", [s toString:gpxTimeFormat comment:nil]];
  }
  [content appendString:@"</trk>\n"];
  if ([trackSegments count] > 0) { // Way points
    TrackSegment *previousSegment = nil;
    TrackSegment *lastSegment = [trackSegments lastObject];
    ParkData *parkData = [ParkData getParkData:parkId];
    for (TrackSegment *s in trackSegments) {
      //NSLog(@"from %@ (%d) from exit %@", s.fromAttractionId, s.isTrackToTourItem, s.fromExitAttractionId);
      if (s == lastSegment) break;
      if (s.isTrackToTourItem && s.fromAttractionId != nil && ![s.fromAttractionId isEqualToString:UNKNOWN_ATTRACTION_ID]) {
        if (previousSegment != nil && !previousSegment.isTrackToTourItem && s.fromExitAttractionId != nil && ![parkData isEntryOrExitOfPark:s.fromExitAttractionId]) {
          Attraction *exit = [Attraction getAttraction:parkId attractionId:s.fromExitAttractionId];
          ExtendedTrackPoint *t = (ExtendedTrackPoint *)[previousSegment fromTrackPoint];
          if ([previousSegment.fromAttractionId isEqualToString:s.fromExitAttractionId] || [parkData isExitAttractionId:s.fromExitAttractionId]) {
            [content appendFormat:@"<wpt lat=\"%.6f\" lon=\"%.6f\">\n  <name>%@</name>\n  <ele>%f</ele>\n  <!-- accuracy %f -->\n  <time>", t.latitude, t.longitude, [NSString stringWithFormat:NSLocalizedString(@"tour.description.exit.of", nil), exit.stringAttractionName], t.elevation, t.accuracy];
          } else {
            [content appendFormat:@"<wpt lat=\"%.6f\" lon=\"%.6f\">\n  <name>%@</name>\n  <ele>%f</ele>\n  <!-- accuracy %f -->\n  <time>", t.latitude, t.longitude, exit.stringAttractionName, t.elevation, t.accuracy];
          }
          [content appendString:[gpxTimeFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:t.recordTime]]];
          [content appendString:@"Z</time>\n  <sym>Dot</sym>\n</wpt>\n"];
        }
        NSString *fId = s.fromAttractionId;
        Attraction *a = [Attraction getAttraction:parkId attractionId:fId];
        ExtendedTrackPoint *t = (ExtendedTrackPoint *)[s fromTrackPoint];
        if (![parkData isExitOfPark:fId]) {
          [content appendFormat:@"<wpt lat=\"%.6f\" lon=\"%.6f\">\n  <name>%@</name>\n  <ele>%f</ele>\n  <!-- accuracy %f -->\n  <time>", t.latitude, t.longitude, [NSString stringWithFormat:NSLocalizedString(@"tour.description.exit.of", nil), a.stringAttractionName], t.elevation, t.accuracy];
        } else if ([parkData isFastLaneEntryAttractionId:fId]) {
          [content appendFormat:@"<wpt lat=\"%.6f\" lon=\"%.6f\">\n  <name>%@</name>\n  <ele>%f</ele>\n  <!-- accuracy %f -->\n  <time>", t.latitude, t.longitude, [NSString stringWithFormat:NSLocalizedString(@"tour.description.fastpass.of", nil), parkData.fastLaneId, a.stringAttractionName], t.elevation, t.accuracy];
        } else {
          [content appendFormat:@"<wpt lat=\"%.6f\" lon=\"%.6f\">\n  <name>%@</name>\n  <ele>%f</ele>\n  <!-- accuracy %f -->\n  <time>", t.latitude, t.longitude, a.stringAttractionName, t.elevation, t.accuracy];
        }
        [content appendString:[gpxTimeFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:t.recordTime]]];
        [content appendString:@"Z</time>\n  <sym>Dot</sym>\n</wpt>\n"];
      }
      previousSegment = s;
    }
    if (lastSegment.fromExitAttractionId != nil && ![parkData isEntryOrExitOfPark:lastSegment.fromExitAttractionId]) {
      Attraction *exit = [Attraction getAttraction:parkId attractionId:lastSegment.fromExitAttractionId];
      ExtendedTrackPoint *t = (ExtendedTrackPoint *)[lastSegment fromTrackPoint];
      if ([parkData isExitAttractionId:lastSegment.fromExitAttractionId]) {
        [content appendFormat:@"<wpt lat=\"%.6f\" lon=\"%.6f\">\n  <name>%@</name>\n  <ele>%f</ele>\n  <!-- accuracy %f -->\n  <time>", t.latitude, t.longitude, [NSString stringWithFormat:NSLocalizedString(@"tour.description.exit.of", nil), exit.stringAttractionName], t.elevation, t.accuracy];
      } else {
        [content appendFormat:@"<wpt lat=\"%.6f\" lon=\"%.6f\">\n  <name>%@</name>\n  <ele>%f</ele>\n  <!-- accuracy %f -->\n  <time>", t.latitude, t.longitude, exit.stringAttractionName, t.elevation, t.accuracy];
      }
      [content appendString:[gpxTimeFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:t.recordTime]]];
      [content appendString:@"Z</time>\n  <sym>Dot</sym>\n</wpt>\n"];
    }
    Attraction *a = [Attraction getAttraction:parkId attractionId:lastSegment.toAttractionId];
    ExtendedTrackPoint *t = (ExtendedTrackPoint *)[lastSegment toTrackPoint];
    [content appendFormat:@"<wpt lat=\"%.6f\" lon=\"%.6f\">\n  <name>%@</name>\n  <ele>%f</ele>\n  <!-- accuracy %.6f -->\n  <time>", t.latitude, t.longitude, a.stringAttractionName, t.elevation, t.accuracy];
    [content appendString:[gpxTimeFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:t.recordTime]]];
    [content appendString:@"Z</time>\n  <sym>Dot</sym>\n</wpt>\n"];
  }
  [content appendString:@"</gpx>"];
  NSString *fileName = [self gpxFilePath];
  NSError *error = nil;
  [content writeToFile:fileName atomically:NO encoding:NSUTF8StringEncoding error:&error];
  if (error != nil) NSLog(@"Error (%@) to save GPX file %@ for %@", [error localizedDescription], fileName, trackName);
  else NSLog(@"GPX file %@ for %@ saved", fileName, trackName);
  [gpxTimeFormat release];
  [content release];
  return (error == nil);
}

-(void)deleteData {
  [currentTrackPoints removeAllObjects];
  [fromAttractionId release];
  fromAttractionId = @"";
  [trackSegments removeAllObjects];
  NSError *error = nil;
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager removeItemAtPath:[self gpxFilePath] error:&error];
  if (error != nil) {
    NSLog(@"Error removing path %@ - %@", [self gpxFilePath], [error localizedDescription]);
  } else {
    NSLog(@"Local file %@ deleted", [self gpxFilePath]);
  }

}

@end
