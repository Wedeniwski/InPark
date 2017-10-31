//
//  WaitingTimeItem.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.04.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import "WaitingTimeItem.h"

@interface WaitingTimeItem (PrivateMethods)
@property (readonly) NSArray *waitingTimes;
@property (readonly) NSArray *submittedTimestamps;
@property (readonly) NSArray *userNames;
@property (readonly) NSArray *comments;
@end

@implementation WaitingTimeItem

@synthesize fastLaneInfoAvailable;
@synthesize fastLaneAvailable;
@synthesize fastLaneAvailableTimeFrom, fastLaneAvailableTimeTo;
//@synthesize waitingTimes, submittedTimestamps, userNames, comments;

-(id)initWithWaitTimeLine:(NSString *)line baseTime:(NSDate *)baseTime {
  self = [super init];
  if (self != nil) {
    totalWaitingTime = -100;
    fastLaneInfoAvailable = NO;
    fastLaneAvailable = 0;
    fastLaneAvailableTimeFrom = fastLaneAvailableTimeTo = 0;
    waitingTimes = [[NSMutableArray alloc] initWithCapacity:5];
    submittedTimestamps = [[NSMutableArray alloc] initWithCapacity:5];
    userNames = [[NSMutableArray alloc] initWithCapacity:5];
    comments = [[NSMutableArray alloc] initWithCapacity:5];
    //startTimes = nil;
    [self addWaitTimeLine:line baseTime:baseTime];
  }
  return self;
}

-(id)initWithWaitTime:(short)waitingTime submittedTimestamp:(NSDate *)submittedTimestamp userName:(NSString *)userName comment:(NSString *)comment {
  self = [super init];
  if (self != nil) {
    totalWaitingTime = -100;
    fastLaneInfoAvailable = NO;
    fastLaneAvailable = 0;
    fastLaneAvailableTimeFrom = fastLaneAvailableTimeTo = 0;
    waitingTimes = [[NSMutableArray alloc] initWithCapacity:5];
    submittedTimestamps = [[NSMutableArray alloc] initWithCapacity:5];
    userNames = [[NSMutableArray alloc] initWithCapacity:5];
    comments = [[NSMutableArray alloc] initWithCapacity:5];
    //startTimes = nil;
    [self insertWaitTime:waitingTime submittedTimestamp:submittedTimestamp userName:userName comment:comment atIndex:0];
  }
  return self;
}

-(void)dealloc {
  [waitingTimes release];
  [submittedTimestamps release];
  [userNames release];
  [comments release];
  //[startTimes release];
  [super dealloc];
}

-(NSArray *)waitingTimes {
  return waitingTimes;
}

-(NSArray *)submittedTimestamps {
  return submittedTimestamps;
}

-(NSArray *)userNames {
  return userNames;
}

-(NSArray *)comments {
  return comments;
}

-(BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[WaitingTimeItem class]]) return NO;
  WaitingTimeItem *item = (WaitingTimeItem *)object;
  return [self isEqualToWaitingTimeItem:item];
}

-(BOOL)isEqualToWaitingTimeItem:(WaitingTimeItem *)item {
  if (totalWaitingTime != item.totalWaitingTime) return NO;
  if (fastLaneInfoAvailable != item.fastLaneInfoAvailable) return NO;
  if (fastLaneAvailable != item.fastLaneAvailable) return NO;
  if (fastLaneAvailableTimeFrom != item.fastLaneAvailableTimeFrom) return NO;
  if (fastLaneAvailableTimeTo != item.fastLaneAvailableTimeTo) return NO;
  if (![waitingTimes isEqualToArray:item.waitingTimes]) return NO;
  if (![submittedTimestamps isEqualToArray:item.submittedTimestamps]) return NO;
  if (![userNames isEqualToArray:item.userNames]) return NO;
  if (![comments isEqualToArray:item.comments]) return NO;
  //if (![startTimes isEqualToArray:item.startTimes]) return NO;
  return YES;
}

-(int)count {
  return [waitingTimes count];
}

-(void)addWaitTimeLine:(NSString *)line baseTime:(NSDate *)baseTime {
  NSDate *submittedTimestamp = nil;
  NSRange range = [line rangeOfString:@","];
  if (range.length > 0) {
    NSString *s = [line substringToIndex:range.location];
    if (totalWaitingTime == -100) totalWaitingTime = -2;
    [waitingTimes addObject:s];
    line = [line substringFromIndex:range.location+1];
    range = [line rangeOfString:@","];
  } else {
    totalWaitingTime = [line doubleValue];
    range = [line rangeOfString:@"F"];
    if (range.length > 0) {  // <total wait time>[F(+-0)<from>[-<to>]]
      fastLaneInfoAvailable = YES;
      line = [line substringFromIndex:range.location+1];
      if ([line hasPrefix:@"+"]) fastLaneAvailable = 1;
      else if ([line hasPrefix:@"-"]) fastLaneAvailable = -1;
      if ([line length] > 1) {
        line = [line substringFromIndex:1];
        fastLaneAvailableTimeFrom = (short)[line intValue];
        range = [line rangeOfString:@":"];
        if (range.length > 0) {
          line = [line substringFromIndex:range.location+1];
          fastLaneAvailableTimeTo = (short)[line intValue];
        }
      }
    }
    /*range = [line rangeOfString:@"T"];
    if (range.length > 0) {
      NSArray *t = [[line substringFromIndex:range.location+1] componentsSeparatedByString:@":"];
      [startTimes release];
      startTimes = [[NSMutableArray alloc] initWithCapacity:[t count]+1];
      for (NSString *s in t)
        if ([s length] == 4) [startTimes addObject:[NSString stringWithFormat:@"%@:%@", [s substringToIndex:2], [s substringFromIndex:2]]];
    }*/
    return;
  }
  NSRange range2 = [line rangeOfString:@";"];
  if (range2.length > 0 && range2.location < [line length]) {
    if (range.length > 0 && range.location+1 < range2.location) {
      submittedTimestamp = [NSDate dateWithTimeInterval:[[line substringToIndex:range.location] intValue]*-60 sinceDate:baseTime];
      ++range.location;
      range.length = range2.location-range.location;
      [userNames addObject:[line substringWithRange:range]];
    } else {
      submittedTimestamp = [NSDate dateWithTimeInterval:[[line substringToIndex:range2.location] intValue]*-60 sinceDate:baseTime];
      [userNames addObject:[NSNull null]];
    }
    if (range2.location+1 < [line length]) [comments addObject:[line substringFromIndex:range2.location+1]];
    else [comments addObject:[NSNull null]];
  } else {
    if ([line length] == 0) {
      [userNames addObject:[NSNull null]];
    } else if (range.length > 0 && range.location+1 < [line length]) {
      submittedTimestamp = [NSDate dateWithTimeInterval:[[line substringToIndex:range.location] intValue]*-60 sinceDate:baseTime];
      [userNames addObject:[line substringFromIndex:range.location+1]];
    } else {
      submittedTimestamp = [NSDate dateWithTimeInterval:[line intValue]*-60 sinceDate:baseTime];
      [userNames addObject:[NSNull null]];
    }
    [comments addObject:[NSNull null]];
  }
  [submittedTimestamps addObject:(submittedTimestamp == nil)? [NSNull null] : submittedTimestamp];
  [self updateTotalWaitTime]; // needed if all times are old
}

-(void)insertWaitTime:(short)waitingTime submittedTimestamp:(NSDate *)submittedTimestamp userName:(NSString *)userName comment:(NSString *)comment atIndex:(int)index {
  int n = (int)[waitingTimes count];
  if (n == 0) totalWaitingTime = waitingTime;
  if ([userName length] == 0) userName = nil;
  if ([comment length] == 0) comment = nil;
  [waitingTimes insertObject:[NSString stringWithFormat:@"%d", waitingTime] atIndex:index];
  [submittedTimestamps insertObject:(submittedTimestamp == nil)? [NSNull null] : submittedTimestamp atIndex:index];
  [userNames insertObject:(userName == nil)? [NSNull null] : [WaitingTimeItem removeTokens:userName maxLength:20] atIndex:index];
  [comments insertObject:(comment == nil)? [NSNull null] : [WaitingTimeItem removeTokens:comment maxLength:100] atIndex:index];
  [self updateTotalWaitTime];
  if (n >= 3) {
    [waitingTimes removeLastObject];
    [submittedTimestamps removeLastObject];
    [userNames removeLastObject];
    [comments removeLastObject];
  }
}

-(double)totalWaitingTime {
  return totalWaitingTime;
}

-(BOOL)isOld {
  if ([submittedTimestamps count] == 0) return NO;
  double currentTime = [[NSDate date] timeIntervalSince1970];
  double submittedTimestamp = [[submittedTimestamps objectAtIndex:0] timeIntervalSince1970];
  return ((currentTime-submittedTimestamp)/1800 >= 1);
}

-(BOOL)isVeryOld {
  if ([submittedTimestamps count] == 0) return NO;
  double currentTime = [[NSDate date] timeIntervalSince1970];
  double submittedTimestamp = [[submittedTimestamps objectAtIndex:0] timeIntervalSince1970];
  return ((currentTime-submittedTimestamp)/1800 >= 2);
}

-(BOOL)willWaitTimeBeRefused:(int)waitTime {
  int n = [waitingTimes count];
  if (n == 0 && waitTime >= 100) return YES;  // ignore if only one manually submitted entry >= 100 minutes exist
  else if (n >= 2) {
    double currentTime = [[NSDate date] timeIntervalSince1970];
    double submittedTimestamp0 = [[submittedTimestamps objectAtIndex:0] timeIntervalSince1970];
    double submittedTimestamp1 = [[submittedTimestamps objectAtIndex:1] timeIntervalSince1970];
    if (currentTime-submittedTimestamp1 <= 15*60 && currentTime-submittedTimestamp0 <= 15*60) {
      int w0 = [[waitingTimes objectAtIndex:0] intValue]-waitTime;
      int w1 = [[waitingTimes objectAtIndex:1] intValue]-waitTime;
      if (ABS(w0) >= 60 && ABS(w1) >= 60) return YES;
    }
  }
  return NO;
}

+(BOOL)willWaitTimeBeRefused:(int)waitTime {
  return (waitTime >= 100);  // ignore if only one manually submitted entry >= 100 minutes exist
}

-(short)latestWaitingTime {
  return ([waitingTimes count] > 0)? [[waitingTimes objectAtIndex:0] intValue] : totalWaitingTime;
}

-(NSDate *)latestSubmittedTimestamp {
  return ([submittedTimestamps count] > 0)? [submittedTimestamps objectAtIndex:0] : nil;
}

-(short)updateTotalWaitTime {
  if (totalWaitingTime != -3 && [waitingTimes count] > 0 && ([[NSDate date] timeIntervalSince1970]-[[submittedTimestamps objectAtIndex:0] timeIntervalSince1970])/3600 > 2.0) totalWaitingTime = -3;
  /*int n = [waitingTimes count];
  if (n > 0) {
    if (([[NSDate date] timeIntervalSince1970]-[[submittedTimestamps objectAtIndex:0] timeIntervalSince1970])/3600 <= 2.0) {
      int closed = 0;
      int lastWaitTime = 0;
      double baseSeconds = 3640.0+[[submittedTimestamps lastObject] timeIntervalSince1970];
      double minutes = 0.0;
      double totalWeight = 0.0;
      for (int i = 0; i < n; ++i) {
        int m = [[waitingTimes objectAtIndex:i] intValue];
        lastWaitTime = m;
        if (m < 0) {
          ++closed;
        } else {
          double weight = [[submittedTimestamps objectAtIndex:i] timeIntervalSince1970];
          if (weight < baseSeconds) {
            weight = 3650.0/(baseSeconds-weight);
            minutes += m*weight;
            totalWeight += weight;
          }
          closed = 0;
        }
      }
      if (n > 0 && lastWaitTime < 0) totalWaitingTime = -2;
      else totalWaitingTime = (closed >= 3)? -1 : (short)(minutes/totalWeight);
    } else totalWaitingTime = -3;
  }*/
  return totalWaitingTime;
}

-(BOOL)containsComment {
  for (id comment in waitingTimes) {
    if (comment != [NSNull null]) return YES;
  }
  return NO;
}

-(short)waitTimeAt:(int)index {
  return (short)[[waitingTimes objectAtIndex:index] intValue];
}

-(NSDate *)submittedTimestampAt:(int)index {
  id n = [submittedTimestamps objectAtIndex:index];
  return (n == [NSNull null])? nil : n;
}

-(NSString *)userNameAt:(int)index {
  id n = [userNames objectAtIndex:index];
  return (n == [NSNull null])? nil : n;
}

-(NSString *)commentsAt:(int)index {
  id n = [comments objectAtIndex:index];
  return (n == [NSNull null])? nil : n;
}

-(NSString *)toStringAt:(int)index {
  NSString *s = [NSString stringWithFormat:@"%@,%@", [waitingTimes objectAtIndex:index], [submittedTimestamps objectAtIndex:index]];
  id userName = [self userNameAt:index];
  id comment = [self commentsAt:index];
  if (userName == [NSNull null] || [userName length] == 0) {
    if (comment == [NSNull null] || [comment length] == 0) return s;
    return [NSString stringWithFormat:@"%@;%@", s, comment];
  }
  if (comment == [NSNull null] || [comment length] == 0) return [NSString stringWithFormat:@"%@,%@", s, userName];
  return [NSString stringWithFormat:@"%@,%@;%@", s, userName, comment];
}

-(BOOL)isFastLaneAvailable {
  return (fastLaneInfoAvailable && fastLaneAvailable > 0);
}

-(BOOL)isFastLaneLimitedAvailability {
  return (fastLaneInfoAvailable && fastLaneAvailable < 0);
}

-(BOOL)isFastLaneUnavailable {
  return (fastLaneInfoAvailable && fastLaneAvailable == 0);
}

/*-(BOOL)hasStartTimes {
  return (startTimes != nil && [startTimes count] > 0);
}

-(NSArray *)startTimes {
  return startTimes;
}*/

+(NSString *)removeTokens:(NSString *)text maxLength:(int)maxLength {
  text = [text stringByReplacingOccurrencesOfString:@":" withString:@""];
  text = [text stringByReplacingOccurrencesOfString:@";" withString:@""];
  text = [text stringByReplacingOccurrencesOfString:@"," withString:@""];
  if ([text length] > maxLength) text = [text substringToIndex:maxLength];
  return text;
}

@end
