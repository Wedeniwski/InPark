//
//  WaitingTimeData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.06.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "WaitingTimeData.h"
#import "SettingsData.h"
#import "LocationData.h"
#import "ParkData.h"
#import "CalendarData.h"
#import "ProfileData.h"
#import "MenuData.h"
#import "Attraction.h"
#import "Update.h"
#import "Colors.h"
#import "md5.h"

@implementation WaitingTimeData

@synthesize initialized;
@synthesize baseTime;
@synthesize lastSuccessfulUpdate;
@synthesize registeredViewController;

+(NSString *)createNewUUID {
  CFUUIDRef theUUID = CFUUIDCreate(NULL);
  CFStringRef string = CFUUIDCreateString(NULL, theUUID);
  CFRelease(theUUID);
  return [(NSString *)string autorelease];
}

-(id)initWithParkId:(NSString *)pId registeredViewController:(UIViewController<WaitingTimeDataDelegate> *)viewController {
  self = [super init];
  if (self != nil) {
    initialized = NO;
    lastStatusCode = -1;
    numberOfFailedAccess = 0;
    //containsStartTimes = NO;
    baseTime = nil;
    registeredViewController = viewController;
    lastParsedWaitingTimes = nil;
    parkId = [pId retain];
    // identifier ist nur pro Tag, Park als auch Device eindeutig
    // deprecated [[UIDevice currentDevice] uniqueIdentifier]
    // alternative NSUUID *identifierForVendor NS_AVAILABLE_IOS(6_0)
    identifier = [[NSString alloc] initWithFormat:@"inpark%@%@%@", pId, [CalendarData stringFromDate:[NSDate date] considerTimeZoneAbbreviation:nil], [WaitingTimeData createNewUUID]];
    MD5_CTX mdContext;
    MD5Init(&mdContext);
    const char *s = [identifier UTF8String];
    MD5Update(&mdContext, s, strlen(s));
    MD5Final(&mdContext);
    char md5ofData[33];
    md5ofData[32] = '\x0';
    for (int i = 0; i < 16; ++i) sprintf(md5ofData+2*i, "%02x", mdContext.digest[i]);
    [identifier release];
    identifier = [[NSString alloc] initWithFormat:@"%s", md5ofData];
    lastSuccessfulUpdate = lastUpdate = 0.0;
    connection = NO;
    waitingTimes = [[NSMutableDictionary alloc] initWithCapacity:300];
    NSDictionary *details = [MenuData getParkDetails:parkId cache:NO];
    details = [details objectForKey:@"Wartezeiten"];
    if (details != nil) {
      lowWaitingTimeBelowValue = [[details objectForKey:@"2"] shortValue];
      midWaitingTimeBelowValue = [[details objectForKey:@"3"] shortValue];
    } else {
      lowWaitingTimeBelowValue = 20;
      midWaitingTimeBelowValue = 40;
    }
    [self update:NO];
  }
  return self;
}

-(void)dealloc {
  registeredViewController = nil;
  [parkId release];
  [identifier release];
  [waitingTimes release];
  [baseTime release];
  [lastParsedWaitingTimes release];
  [super dealloc];
}

-(NSMutableDictionary *)parseData:(NSString *)times {
  //NSLog(@"parse waiting time data %@", times);
  //containsStartTimes = NO;
  NSRange range = [times rangeOfString:@"\n" options:NSBackwardsSearch];
  if (range.length > 0 && range.location+1 < [times length]) {
    NSString *hashCode = [times substringFromIndex:range.location+1];
    times = [times substringToIndex:range.location+1];
    MD5_CTX mdContext;
    MD5Init(&mdContext);
    const char *s = [times UTF8String];
    MD5Update(&mdContext, s, strlen(s));
    MD5Final(&mdContext);
    char md5ofTimes[33];
    md5ofTimes[32] = '\x0';
    for (int i = 0; i < 16; ++i) sprintf(md5ofTimes+2*i, "%02x", mdContext.digest[i]);
    if (![[NSString stringWithUTF8String:md5ofTimes] isEqualToString:hashCode]) {
      NSLog(@"Wrong hash of waiting times table: %s != %@", md5ofTimes, hashCode);
      return nil;
    }
  } else {
    NSLog(@"Missing hash code in waiting times table!");
    return nil;
  }
  [lastParsedWaitingTimes release];
  lastParsedWaitingTimes = [times retain];
  NSMutableDictionary *newWaitingTimes = [[[NSMutableDictionary alloc] initWithCapacity:20] autorelease];
  NSArray *lines = [times componentsSeparatedByString:@"\n"];
  int i = 0;
  NSString *attractionId = nil;
  for (NSString *line in lines) {
    if (i > 1 && [line length] > 1) {
      if ([line hasPrefix:@","]) {
        [baseTime release];
        baseTime = [[NSDate dateWithTimeIntervalSince1970:[[line substringFromIndex:1] doubleValue]] retain];
      } else {
        NSRange range1 = [line rangeOfString:@":"];
        NSRange range2 = [line rangeOfString:@","];
        if (range1.length > 0 && range1.location+1 < [line length]) {
          attractionId = [line substringToIndex:range1.location];
          WaitingTimeItem *waitingTimeItem = [newWaitingTimes objectForKey:attractionId];
          if (waitingTimeItem == nil) {
            waitingTimeItem = [[WaitingTimeItem alloc] initWithWaitTimeLine:[line substringFromIndex:range1.location+1] baseTime:nil];
            [newWaitingTimes setObject:waitingTimeItem forKey:attractionId];
            [waitingTimeItem release];
          } else {
            [waitingTimeItem addWaitTimeLine:[line substringFromIndex:range1.location+1] baseTime:nil];
          }
          //if ([waitingTimeItem hasStartTimes]) containsStartTimes = YES;
        } else if (range2.length <= 0) {
          attractionId = line;
        } else if (attractionId != nil) {
          WaitingTimeItem *waitingTimeItem = [newWaitingTimes objectForKey:attractionId];
          if (waitingTimeItem == nil) {
            waitingTimeItem = [[WaitingTimeItem alloc] initWithWaitTimeLine:line baseTime:baseTime];
            [newWaitingTimes setObject:waitingTimeItem forKey:attractionId];
            [waitingTimeItem release];
          } else {
            [waitingTimeItem addWaitTimeLine:line baseTime:baseTime];
          }
          //if ([waitingTimeItem hasStartTimes]) containsStartTimes = YES;
        }
      }
    }
    ++i;
  }
#ifdef FAKE_CALENDAR
  NSDictionary *allAttractions = [Attraction getAllAttractions:parkId reload:NO];
  [allAttractions enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSString *attractionId = key;
    Attraction *attraction = object;
    if ([attraction isRealAttraction] && ![attractionId hasPrefix:@"ar"] && ![attractionId hasPrefix:@"g"] && ![attractionId hasPrefix:@"s"]) {
      int w = (rand()%((midWaitingTimeBelowValue/5)+1))*5;
      if ([attractionId hasPrefix:@"ch"]) w = (rand()%5)*5;
      NSString *line = [NSString stringWithFormat:@"%d", w];
      NSLog(@"fake waiting time %@ for %@", line, attractionId);
      WaitingTimeItem *waitingTimeItem = [newWaitingTimes objectForKey:attractionId];
      if (waitingTimeItem == nil) {
        waitingTimeItem = [[WaitingTimeItem alloc] initWithWaitTimeLine:line baseTime:nil];
        [newWaitingTimes setObject:waitingTimeItem forKey:attractionId];
        [waitingTimeItem release];
      } else {
        [waitingTimeItem addWaitTimeLine:line baseTime:nil];
      }
    }
  }];
#endif
  return newWaitingTimes;
}

+(NSString *)encodeToPercentEscapeString:(NSString *)text {
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)text, NULL, (CFStringRef)@"~!@#$%^*():{}\\€*’;&=+,/?[]", kCFStringEncodingUTF8);
  return [result autorelease];
}

-(BOOL)asychronousUpdate:(NSString *)path {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *times = nil;
  if (path == nil) {
    BOOL online = NO;
    int statusCode;
    times = [Update onlineDataPath:@"waiting.txt.gz" hasPrefix:[NSString stringWithFormat:@"- %@\n\n", parkId] useLocalDataIfNotOlder:-1.0 parkId:parkId online:&online statusCode:&statusCode];
    connection = (times != nil);
    lastStatusCode = (online)? statusCode : -1;
    numberOfFailedAccess = 0;
  } else {
    NSError *error = nil;
    //path = [path stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    //times = [NSString stringWithContentsOfURL:[NSURL URLWithString:path] encoding:NSUTF8StringEncoding error:&error];
    NSHTTPURLResponse *response = nil;
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:path] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    //[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    lastStatusCode = response.statusCode;
    if (error == nil && data != nil && response.statusCode == 200) {
      times = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
      connection = YES;
      numberOfFailedAccess = 0;
    } else {
      NSLog(@"wait times data could not be successfully downloaded or submitted! (%@)", [error localizedDescription]);
      connection = NO;
      ++numberOfFailedAccess;
    }
    [request release];
    [path release];
    if (error == nil && [times hasPrefix:[NSString stringWithFormat:@"- %@\n\n", parkId]]) {
      NSString *localPath = [[MenuData parkDataPath:parkId] stringByAppendingPathComponent:@"waiting.txt"];
      [times writeToFile:localPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
      if (error != nil) NSLog(@"downloaded waiting times table could not be successfully cached! (%@)", [error localizedDescription]);
    } else if (connection) {
      NSLog(@"wait time data wrong content: %@", times);
    }
  }
  BOOL newWaitingTimeData = NO;
  if (times != nil) {
    if (lastParsedWaitingTimes != nil && [lastParsedWaitingTimes isEqual:times]) {
      NSLog(@"no new wait times to parse for %@ updated", parkId);
    } else {
      NSMutableDictionary *newData = [self parseData:times];
      @synchronized([WaitingTimeData class]) {
        if (newData != nil && ![newData isEqual:waitingTimes]) {
          [waitingTimes setDictionary:newData];
          newWaitingTimeData = YES;
          ParkData *parkData = [ParkData getParkData:parkId];
          CalendarData *calendarData = [parkData getCalendarData];
          calendarData.newWaitingTimeData = YES;
          NSLog(@"wait times for %@ updated", parkId);
        } else {
          NSLog(@"no new wait times for %@ updated", parkId);
        }
      }
    }
  }
  lastUpdate = [[NSDate date] timeIntervalSince1970];
  if (![self lastAccessFailed]) lastSuccessfulUpdate = lastUpdate;
  initialized = YES;
  if (newWaitingTimeData && registeredViewController != nil) [registeredViewController waitingTimeDataUpdated];
  [pool release];
  return newWaitingTimeData;
}

-(void)update:(BOOL)initData {
  SettingsData *settings = [SettingsData getSettingsData];
  const int m = settings.waitingTimesUpdate;
  if (m <= 0) {
    if (m < 0) numberOfFailedAccess = 0;
    initialized = YES;
    return;
  }
  @synchronized([WaitingTimeData class]) {
    const double now = [[NSDate date] timeIntervalSince1970];
    const double d = now-lastUpdate;
    if (d > 60.0*m || (d > 15.0 && numberOfFailedAccess < 5 && [self lastAccessFailed])) {
      if (d > 60.0*m) numberOfFailedAccess = 0;
      lastUpdate = now;
      NSString *path = nil;
      if (initData) {
        path = [[NSString alloc] initWithFormat:@"%@waiting.php?pid=%@", [Update sourceDataPath], parkId];
        NSLog(@"init waiting times by %@", path);
      }
      [NSThread detachNewThreadSelector:@selector(asychronousUpdate:) toTarget:self withObject:path];
    }
  }
}

-(void)enforceUpdate:(id)sender {
  SettingsData *settings = [SettingsData getSettingsData];
  const int m = settings.waitingTimesUpdate;
  if (m < 0) {
    initialized = YES;
    numberOfFailedAccess = 0;
    return;
  }
  @synchronized([WaitingTimeData class]) {
    BOOL newWaitTime = NO;
    const double now = [[NSDate date] timeIntervalSince1970];
    const double d = now-lastUpdate;
    if (d > 60.0 || (d > 10.0 && [self lastAccessFailed])) {
      lastUpdate = now;
      newWaitTime = [self asychronousUpdate:nil];
    }
    if (sender != nil && [sender respondsToSelector:@selector(endRefreshing)]) [sender performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
    if (!newWaitTime && registeredViewController != nil && [registeredViewController respondsToSelector:@selector(refreshView)]) [registeredViewController refreshView];
  }
}

-(BOOL)lastAccessFailed {
  return (numberOfFailedAccess > 0 || !connection || lastStatusCode != 200);
}

-(NSString *)lastAccessFailureText {
  return [NSString stringWithFormat:NSLocalizedString(@"waiting.time.access.error", nil), lastStatusCode];
}

-(NSArray *)getAttractionIdsWithWaitingTime {
  @synchronized([WaitingTimeData class]) {
    return [waitingTimes allKeys];
  }
}

-(WaitingTimeItem *)getWaitingTimeFor:(NSString *)attractionId {
  SettingsData *settings = [SettingsData getSettingsData];
  if (settings.waitingTimesUpdate < 0) return nil;
  @synchronized([WaitingTimeData class]) {
    return [waitingTimes objectForKey:attractionId];
  }
}

-(void)submitTourItem:(TourItem *)tourItem closed:(BOOL)closed entryLocation:(ExtendedTrackPoint *)entryLocation exitLocation:(ExtendedTrackPoint *)exitLocation {
  // ToDo: maybe batch i.e. caching and submitting later
  // but always submiting asynchronous and caching up to 30 minutes if sending was not successful
  SettingsData *settings = [SettingsData getSettingsData];
  if (settings.waitingTimesUpdate < 0) return;
  ParkData *parkData = [ParkData getParkData:parkId];
  if (![parkData isCurrentlyInsidePark]) {
    NSLog(@"Waiting time can only submited inside park");
    return;
  }
  if (![LocationData isLocationDataActive]) return;
  LocationData *locData = [LocationData getLocationData];
  if (locData.lastUpdatedLocation == nil) return;
  NSString *attractionId = tourItem.attractionId;
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  if (attraction == nil) return;
  short waitingTime = (short)((exitLocation.recordTime-entryLocation.recordTime)/60.0);
  waitingTime -= attraction.duration;
  if (waitingTime > 180) {
    NSLog(@"Waiting times only less than 3 hours can be submitted");
    return;
  }
/*#ifndef TARGET_IPHONE_SIMULATOR
  CLLocationCoordinate2D loc = locData.lastUpdatedLocation.coordinate;
  TrackPoint *t = [[TrackPoint alloc] initWithLatitude:loc.latitude longitude:loc.longitude];
  double distanceToExit = [exitLocation distanceTo:[parkData getAttractionLocation:tourItem.exitAttractionId]];
  double distanceToEntry = [entryLocation distanceTo:[parkData getAttractionLocation:tourItem.entryAttractionId]];
  [t release];
  if (distanceToEntry > 500.0 || distanceToExit > 500.0) {
    NSLog(@"Entry (%.1f m) or exit (%.1f m) are too far from the real locations", distanceToEntry, distanceToExit);
    return;
  }
#endif*/
  NSDateFormatter *timestampFormat = [[NSDateFormatter alloc] init];
  [timestampFormat setDateFormat:@"yyyy-MM-dd+HH:mm:ss"];
  NSMutableString *path = [[NSMutableString alloc] initWithCapacity:300];
  NSMutableString *hash = [[NSMutableString alloc] initWithCapacity:200];
  [hash appendString:attractionId];
  [path appendString:[Update sourceDataPath]];
  [path appendFormat:@"waiting.php?pid=%@&aid=%@&eid=%@&xid=%@&e=", parkId, attractionId, tourItem.entryAttractionId, tourItem.exitAttractionId];
  NSDate *submittedTimestamp = [NSDate dateWithTimeIntervalSince1970:entryLocation.recordTime];
  NSString *timestamp = [timestampFormat stringFromDate:submittedTimestamp];
  [path appendString:timestamp];
  [hash appendString:[timestamp stringByReplacingOccurrencesOfString:@"+" withString:@" "]];
  [hash appendString:tourItem.entryAttractionId];
  [hash appendString:identifier];
  [hash appendString:tourItem.exitAttractionId];
  [hash appendString:[SettingsData getAppVersion]];
  [hash appendString:parkId];
  [hash appendFormat:@"%.5f", ((closed)? 1 : 0) + 3.0*attraction.duration - 3.1415927];
  [hash appendFormat:@"%.5f", ([[NSString stringWithFormat:@"%.6f", entryLocation.latitude] doubleValue] + 2*[[NSString stringWithFormat:@"%.6f", entryLocation.longitude] doubleValue] - 3*[[NSString stringWithFormat:@"%.0f", entryLocation.accuracy] doubleValue])];
  [path appendString:@"&x="];
  timestamp = [timestampFormat stringFromDate:[NSDate dateWithTimeIntervalSince1970:exitLocation.recordTime]];
  [path appendString:timestamp];
  [hash appendString:[timestamp stringByReplacingOccurrencesOfString:@"+" withString:@" "]];
  [hash appendFormat:@"%.5f", (2.7182818 + [[NSString stringWithFormat:@"%.6f", exitLocation.latitude] doubleValue] + 5*[[NSString stringWithFormat:@"%.6f", exitLocation.longitude] doubleValue] - 7*[[NSString stringWithFormat:@"%.0f", exitLocation.accuracy] doubleValue])];
  [path appendFormat:@"&c=%c&d=%d&v=%@&ela=%.6f&elo=%.6f&eac=%.0f", (closed)? '1' : '0', attraction.duration, [SettingsData getAppVersion], entryLocation.latitude, entryLocation.longitude, entryLocation.accuracy];
  [path appendFormat:@"&xla=%.6f&xlo=%.6f&xac=%.0f&uid=%@", exitLocation.latitude, exitLocation.longitude, exitLocation.accuracy, identifier];
  ProfileData *profileData = [ProfileData getProfileData];
  NSString *userName = profileData.userName;
  if (userName != nil && [userName length] > 0) {
    [path appendFormat:@"&un=%@", [WaitingTimeData encodeToPercentEscapeString:userName]];
    [hash appendString:userName];
  }
  [timestampFormat release];

  MD5_CTX mdContext;
  MD5Init(&mdContext);
  const char *s = [hash UTF8String];
  MD5Update(&mdContext, s, strlen(s));
  MD5Final(&mdContext);
  char md5ofPath[33];
  md5ofPath[32] = '\x0';
  for (int i = 0; i < 16; ++i) sprintf(md5ofPath+2*i, "%02x", mdContext.digest[i]);
  [path appendFormat:@"&h=%s", md5ofPath];
  [hash release];

  NSLog(@"submit data at %@", path);
  [NSThread detachNewThreadSelector:@selector(asychronousUpdate:) toTarget:self withObject:path];
  if (waitingTime < 0) waitingTime = 0;
  @synchronized([WaitingTimeData class]) {
    WaitingTimeItem *waitingTimeItem = [waitingTimes objectForKey:attractionId];
    if (waitingTimeItem == nil) {
      waitingTimeItem = [[WaitingTimeItem alloc] initWithWaitTime:waitingTime submittedTimestamp:submittedTimestamp userName:userName comment:nil];
      [waitingTimes setObject:waitingTimeItem forKey:attractionId];
      [waitingTimeItem release];
    } else {
      [waitingTimeItem insertWaitTime:waitingTime submittedTimestamp:submittedTimestamp userName:userName comment:nil atIndex:0];
    }
  }
}

-(BOOL)submitTourItem:(TourItem *)tourItem waitingTime:(short)waitingTime comment:(NSString *)comment {
  SettingsData *settings = [SettingsData getSettingsData];
  if (settings.waitingTimesUpdate < 0) return NO;
#ifndef TARGET_IPHONE_SIMULATOR
  ParkData *parkData = [ParkData getParkData:parkId];
  if (![parkData isCurrentlyInsidePark]) {
    NSLog(@"Waiting time can only submited inside park");
    return NO;
  }
#endif
  if (![LocationData isLocationDataActive]) return NO;
  LocationData *locData = [LocationData getLocationData];
  if (locData.lastUpdatedLocation == nil) return NO;
  NSString *attractionId = tourItem.attractionId;
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  if (attraction == nil) return NO;
  if (waitingTime > 180) {
    NSLog(@"Waiting times only less than 3 hours can be submitted");
    return NO;
  }
  BOOL closed = (waitingTime < 0);
  NSDateFormatter *timestampFormat = [[NSDateFormatter alloc] init];
  [timestampFormat setDateFormat:@"yyyy-MM-dd+HH:mm:ss"];
  NSMutableString *path = [[NSMutableString alloc] initWithCapacity:300];
  NSMutableString *hash = [[NSMutableString alloc] initWithCapacity:200];
  [hash appendString:attractionId];
  [path appendString:[Update sourceDataPath]];
  [path appendFormat:@"waiting.php?pid=%@&aid=%@&eid=%@&xid=%@&e=", parkId, attractionId, tourItem.entryAttractionId, tourItem.exitAttractionId];
  NSDate *submittedTimestamp = locData.lastUpdatedLocation.timestamp;
  NSString *timestamp = [timestampFormat stringFromDate:submittedTimestamp];
  [path appendString:timestamp];
  [hash appendString:[timestamp stringByReplacingOccurrencesOfString:@"+" withString:@" "]];
  [hash appendString:tourItem.entryAttractionId];
  [hash appendString:identifier];
  [hash appendString:tourItem.exitAttractionId];
  [hash appendString:[SettingsData getAppVersion]];
  [hash appendString:parkId];
  [hash appendFormat:@"%.5f", ((closed)? 1 : 0) + 3.0*waitingTime - 3.1415927];
  [hash appendFormat:@"%.5f", ([[NSString stringWithFormat:@"%.6f", locData.lastUpdatedLocation.coordinate.latitude] doubleValue] + 2*[[NSString stringWithFormat:@"%.6f", locData.lastUpdatedLocation.coordinate.longitude] doubleValue] - 3*[[NSString stringWithFormat:@"%.0f", locData.lastUpdatedLocation.horizontalAccuracy] doubleValue])];
  [path appendFormat:@"&c=%c&d=%d&v=%@&ela=%.6f&elo=%.6f&eac=%.0f", (closed)? '1' : '0', waitingTime, [SettingsData getAppVersion], locData.lastUpdatedLocation.coordinate.latitude, locData.lastUpdatedLocation.coordinate.longitude, locData.lastUpdatedLocation.horizontalAccuracy];
  ProfileData *profileData = [ProfileData getProfileData];
  NSString *userName = profileData.userName;
  if (userName != nil && [userName length] > 0) {
    [path appendFormat:@"&un=%@", [WaitingTimeData encodeToPercentEscapeString:userName]];
    [hash appendString:userName];
  }
  if (comment != nil && [comment length] > 0) {
    [path appendFormat:@"&cm=%@", [WaitingTimeData encodeToPercentEscapeString:comment]];
    MD5_CTX mdContext;
    MD5Init(&mdContext);
    const char *s = [comment UTF8String];
    MD5Update(&mdContext, s, strlen(s));
    MD5Final(&mdContext);
    char md5ofComment[33];
    md5ofComment[32] = '\x0';
    for (int i = 0; i < 16; ++i) sprintf(md5ofComment+2*i, "%02x", mdContext.digest[i]);
    [hash appendFormat:@"%s", md5ofComment];
  }
  [path appendFormat:@"&uid=%@", identifier];
  [timestampFormat release];

  //NSLog(@"hash=%@", hash);
  MD5_CTX mdContext;
  MD5Init(&mdContext);
  const char *s = [hash UTF8String];
  MD5Update(&mdContext, s, strlen(s));
  MD5Final(&mdContext);
  char md5ofPath[33];
  md5ofPath[32] = '\x0';
  for (int i = 0; i < 16; ++i) sprintf(md5ofPath+2*i, "%02x", mdContext.digest[i]);
  [path appendFormat:@"&h=%s", md5ofPath];
  [hash release];

  //NSLog(@"submit data at %@", path);
  BOOL successful = [self asychronousUpdate:path];
  /*[NSThread detachNewThreadSelector:@selector(asychronousUpdate:) toTarget:self withObject:path];
  if (successful) {
    if (waitingTime < 0) waitingTime = 0;
    @synchronized([WaitingTimeData class]) {
      WaitingTimeItem *waitingTimeItem = [waitingTimes objectForKey:attractionId];
      if (waitingTimeItem == nil) {
        waitingTimeItem = [[WaitingTimeItem alloc] initWithWaitTime:waitingTime submittedTimestamp:submittedTimestamp userName:userName comment:comment];
        [waitingTimes setObject:waitingTimeItem forKey:attractionId];
        [waitingTimeItem release];
      } else {
        [waitingTimeItem insertWaitTime:waitingTime submittedTimestamp:submittedTimestamp userName:userName comment:comment atIndex:0];
      }
    }
  }*/
  return successful;
}

-(void)registerViewController:(UIViewController<WaitingTimeDataDelegate> *)viewController {
  @synchronized([WaitingTimeData class]) {
    registeredViewController = viewController;
  }
}

-(void)unregisterViewController {
  @synchronized([WaitingTimeData class]) {
    registeredViewController = nil;
  }
}

static NSMutableArray *waitingTimeData = nil;

+(NSArray *)waitingTimeData {
  @synchronized([WaitingTimeData class]) {
    if (waitingTimeData == nil) {
      waitingTimeData = [[NSMutableArray alloc] initWithCapacity:23];
      [waitingTimeData addObject:NSLocalizedString(@"waiting.time.closed", nil)];
      [waitingTimeData addObject:NSLocalizedString(@"waiting.time.no", nil)];
      for (int i = 5; i <= 90; i += 5) {
        [waitingTimeData addObject:[NSString stringWithFormat:@"%d %@", i, NSLocalizedString(@"waiting.time.minutes.suffix", nil)]];
      }
      [waitingTimeData addObject:[NSString stringWithFormat:@"100 %@", NSLocalizedString(@"waiting.time.minutes.suffix", nil)]];
      [waitingTimeData addObject:[NSString stringWithFormat:@"110 %@", NSLocalizedString(@"waiting.time.minutes.suffix", nil)]];
      [waitingTimeData addObject:[NSString stringWithFormat:@"120+ %@", NSLocalizedString(@"waiting.time.minutes.suffix", nil)]];
    }
  }
  return waitingTimeData;
}

+(int)closestTimeDataIndexFor:(int)waitingTime {
  if (waitingTime < 0) return 0;
  if (waitingTime >= 120) return 22;
  if (waitingTime >= 115) return 21;
  if (waitingTime >= 95) return 20;
  return (waitingTime+7)/5;  
}

+(int)selectedWaitingTimeAtIndex:(int)index {
  if (index <= 0) return -1;
  return (index >= 20)? 10*(index-10) : 5*(index-1);
}

/*-(BOOL)hasStartTimes {
  return containsStartTimes;
}*/

-(BOOL)isClosed:(NSString *)attractionId considerCalendar:(BOOL)considerCalendar {
  SettingsData *settings = [SettingsData getSettingsData];
  if (settings.waitingTimesUpdate >= 0) {
    WaitingTimeItem *waitingTimeItem = nil;
    @synchronized([WaitingTimeData class]) {
      waitingTimeItem = [waitingTimes objectForKey:attractionId];
    }
    if (waitingTimeItem != nil) {
      if (waitingTimeItem.count < 3) return NO;
      int w = waitingTimeItem.totalWaitingTime;
      if (w == -1) return YES;
      if (w >= 0) return NO;
    }
  }
  if (!considerCalendar) return NO;
  ParkData *parkData = [ParkData getParkData:parkId];
  CalendarData *calendarData = [parkData getCalendarData];
  NSString *entryId = [parkData getEntryOfPark:nil];
  NSArray *calendarItems = [calendarData getCalendarItemsFor:entryId forDate:nil];
  if (calendarItems != nil && [calendarItems count] > 0) return NO;
  return [calendarData hasCalendarItemsAfterToday:entryId];
}

-(NSString *)setBadge:(CustomBadge *)waitingTimeBadge forWaitingTimeItem:(WaitingTimeItem *)waitingTimeItem atIndex:(int)index showAlsoOldTimes:(BOOL)showAlsoOldTimes {
  // should work also outside the park!
  NSString *result = nil;
  SettingsData *settings = [SettingsData getSettingsData];
  if (settings.waitingTimesUpdate < 0) {
    result = [NSString stringWithFormat:@"%@:\n%@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.disabled", nil)];
  } else {
    if (waitingTimeItem == nil) {
      if (connection) {
        waitingTimeBadge.badgeInsetColor = [Colors noWaitingTime];
        waitingTimeBadge.badgeText = NSLocalizedString(@"waiting.time.unknown", nil);
        [waitingTimeBadge setNeedsDisplay];
      } else if (settings.waitingTimesUpdate == 0 && ![self lastAccessFailed]) {
        result = [NSString stringWithFormat:@"%@:\n%@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.updated.needed", nil)];
      } else {
        result = [NSString stringWithFormat:@"%@:\n%@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.connection.needed", nil)];
      }
    } else {
      short m = (index < 0)? [waitingTimeItem totalWaitingTime] : [waitingTimeItem waitTimeAt:index];
      if (m < 0) {
        waitingTimeBadge.badgeInsetColor = [Colors noWaitingTime];
        m = [waitingTimeItem latestWaitingTime];
        if (m >= 0) {
          if ([waitingTimeItem totalWaitingTime] <= -2 || [waitingTimeItem count] == 0) waitingTimeBadge.badgeText = NSLocalizedString(@"waiting.time.unknown", nil);
          else {
            if (!showAlsoOldTimes && [waitingTimeItem isVeryOld]) waitingTimeBadge.badgeText = NSLocalizedString(@"waiting.time.unknown", nil);
            else waitingTimeBadge.badgeText = [NSString stringWithFormat:@"%d", m];
          }
        } else if ([waitingTimeItem count] > 0) waitingTimeBadge.badgeText = NSLocalizedString(@"waiting.time.maybe.closed", nil);
        else waitingTimeBadge.badgeText = NSLocalizedString(@"waiting.time.unknown", nil);
      } else {
        if (!showAlsoOldTimes && [waitingTimeItem isVeryOld]) {
          waitingTimeBadge.badgeInsetColor = [Colors noWaitingTime];
          waitingTimeBadge.badgeText = NSLocalizedString(@"waiting.time.unknown", nil);
        } else {
          if ([waitingTimeItem isOld]) waitingTimeBadge.badgeInsetColor = [Colors noWaitingTime];
          else if (m < lowWaitingTimeBelowValue) waitingTimeBadge.badgeInsetColor = [Colors lowWaitingTime];
          else if (m < midWaitingTimeBelowValue) waitingTimeBadge.badgeInsetColor = [Colors midWaitingTime];
          else waitingTimeBadge.badgeInsetColor = [Colors highWaitingTime];
          waitingTimeBadge.badgeText = [NSString stringWithFormat:@"%d", m];
        }
      }
      [waitingTimeBadge setNeedsDisplay];
    }
  }
  return result;
}

-(NSString *)setLabel:(UILabel *)waitingTimeLabel forTourItem:(TourItem *)tourItem color:(BOOL)color extendedFormat:(BOOL)extendedFormat {
  NSString *result = nil;
  int m = tourItem.waitingTime;
  if (m == 0 && tourItem.isWaitingTimeUnknown) {
    SettingsData *settings = [SettingsData getSettingsData];
    if (settings.waitingTimesUpdate < 0) {
      if (extendedFormat) result = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.disabled", nil)];
      else result = NSLocalizedString(@"waiting.time.disabled", nil);
    } else if (connection) {
      if (extendedFormat) result = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.unknown", nil)];
      else result = NSLocalizedString(@"waiting.time.unknown", nil);
    } else if (settings.waitingTimesUpdate == 0 && ![self lastAccessFailed]) {
      if (extendedFormat) result = @"";//[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.updated.needed", nil)];
      else result = NSLocalizedString(@"waiting.time.updated.needed", nil);
    } else {
      if (extendedFormat) result = @"";//[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.connection.needed", nil)];
      else result = NSLocalizedString(@"waiting.time.connection.needed", nil);
    }
    if (color && waitingTimeLabel != nil) waitingTimeLabel.textColor = [Colors darkBlue];
  } else if (m == 0 && !tourItem.isWaitingTimeAvailable) {
    if (connection) {
      if (extendedFormat) result = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.unavailable", nil)];
      else result = NSLocalizedString(@"waiting.time.unavailable", nil);
    } else {
      if (extendedFormat) result = @"";//[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.connection.needed", nil)];
      else result = NSLocalizedString(@"waiting.time.connection.needed", nil);
    }
    if (color && waitingTimeLabel != nil) waitingTimeLabel.textColor = [Colors darkBlue];
  } else {
    if (m < 0) {
      if (extendedFormat) result = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.unknown", nil)];
      else result = NSLocalizedString(@"waiting.time.unknown", nil);
      if (color && waitingTimeLabel != nil) waitingTimeLabel.textColor = [Colors darkBlue];
    } else {
      if (m <= 1) result = NSLocalizedString(@"waiting.time.no", nil);
      else {
        result = [NSString stringWithFormat:NSLocalizedString(@"waiting.time.minutes", nil), m];
        if (extendedFormat) result = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"waiting.time", nil), result];
      }
      if (color && waitingTimeLabel != nil) {
        if (m < lowWaitingTimeBelowValue) waitingTimeLabel.textColor = [Colors lowWaitingTime];
        else if (m < midWaitingTimeBelowValue) waitingTimeLabel.textColor = [Colors midWaitingTime];
        else waitingTimeLabel.textColor = [Colors highWaitingTime];
      }
    }
  }
  if (waitingTimeLabel != nil) waitingTimeLabel.text = result;
  return result;
}

#define OPAQUE_HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
green:((c>>8)&0xFF)/255.0 \
blue:(c&0xFF)/255.0 \
alpha:1.0];

+(NSString *)hexStringFromColor:(UIColor *)color {
  //NSAssert (self.canProvideRGBComponents, @"Must be a RGB color to use hexStringFromColor");  
  const CGFloat *c = CGColorGetComponents(color.CGColor);  
  CGFloat r = c[0];
  BOOL isMonochrome = (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome);
  CGFloat g = (isMonochrome)? c[0] : c[1];
  CGFloat b = (isMonochrome)? c[0] : c[2];  
  // Fix range if needed
  if (r < 0.0f) r = 0.0f;
  if (g < 0.0f) g = 0.0f;
  if (b < 0.0f) b = 0.0f;
  if (r > 1.0f) r = 1.0f;
  if (g > 1.0f) g = 1.0f;
  if (b > 1.0f) b = 1.0f;
  // Convert to hex string between 0x00 and 0xFF
  return [NSString stringWithFormat:@"%02X%02X%02X", (int)(r * 255), (int)(g * 255), (int)(b * 255)];
}

-(NSString *)colorCodeForTourItem:(TourItem *)tourItem {
  int m = tourItem.waitingTime;
  if (m >= 0 && !tourItem.isWaitingTimeUnknown && tourItem.isWaitingTimeAvailable) {
    if (m < lowWaitingTimeBelowValue) return [WaitingTimeData hexStringFromColor:[Colors lowWaitingTime]];
    else if (m < midWaitingTimeBelowValue) return [WaitingTimeData hexStringFromColor:[Colors midWaitingTime]];
    else return [WaitingTimeData hexStringFromColor:[Colors highWaitingTime]];
  }
  return nil;
}

@end
