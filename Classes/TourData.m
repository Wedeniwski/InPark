//
//  TourData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 04.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "TourData.h"
#import "ParkData.h"
#import "SettingsData.h"
#import "ProfileData.h"
#import "MenuData.h"
#import "CalendarData.h"
#import "CalendarItem.h"
#import "LocationData.h"
#import "WaitingTimeData.h"
#import "Comment.h"
#import "Categories.h"
#import "Conversions.h"

@implementation TourData

@synthesize parkId, tourName;
@synthesize tourItems;
@synthesize askTourOptimizationAfterNextSwitchDone;

-(id)init {
  self = [super init];
  if (self != nil) {
    lastOptimized = 0.0;
    tourItemsOfLastAskIfTourOptimizing = nil;
    askTourOptimizationAfterNextSwitchDone = NO;
  }
  return self;
}

-(id)initWithParkId:(NSString *)pId tourName:(NSString *)tName {
  self = [self init];
  if (self != nil) {
    parkId = [pId retain];
    tourName = [tName retain];
    tourItems = [[NSMutableArray alloc] initWithCapacity:40];
  }
  return self;
}

-(id)initWithTourData:(TourData *)tourData {
  self = [self init];
  if (self != nil) {
    parkId = [tourData.parkId retain];
    tourName = [tourData.tourName retain];
    tourItems = [[NSMutableArray alloc] initWithCapacity:[tourData.tourItems count]];
    for (TourItem *item in tourData.tourItems) {
      Attraction *attraction = [Attraction getAttraction:parkId attractionId:item.attractionId];
      if (attraction != nil) [tourItems addObject:item];  // attractions could not exist anymore after updates
      else NSLog(@"Attraction ID %@ cannot be migrate in tour %@", item.attractionId, tourName);
    }
  }
  return self;
}

-(id)initWithCoder:(NSCoder *)coder {
  self = [self init];
  if (self != nil) {
    parkId = [[coder decodeObjectForKey:@"PARK_ID"] retain];
    tourName = [[coder decodeObjectForKey:@"TOUR_NAME"] retain];
    tourItems = [[NSMutableArray alloc] initWithArray:[coder decodeObjectForKey:@"TOUR_ITEMS"]];
  }
  return self;
}

-(void)dealloc {
  [parkId release];
  parkId = nil;
  [tourName release];
  tourName = nil;
  [tourItems release];
  tourItems = nil;
  [tourItemsOfLastAskIfTourOptimizing release];
  tourItemsOfLastAskIfTourOptimizing = nil;
  [super dealloc];
}

-(void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:parkId forKey:@"PARK_ID"];
  [coder encodeObject:tourName forKey:@"TOUR_NAME"];
  [coder encodeObject:tourItems forKey:@"TOUR_ITEMS"];
}

-(BOOL)canAddToTour:(NSString *)attractionId {
  if ([tourItems count] >= MAX_NUMBER_OF_ITEMS_IN_TOUR) return NO;
  ParkData *parkData = [ParkData getParkData:parkId];
  if ([parkData isEntryOrExitOfPark:attractionId]) {
    return ([self getAttractionCount:attractionId] == 0);
  }
  return YES;
  // ToDo: maxTourDistance or maxParkVisitTime reached, ask to optimize
  /*Categories *categories = [Categories getCategories];
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  NSString *icon = [categories getAttractionCategoryIcon:attraction.categoryName];
  return ![icon isEqualToString:@"station.png"];  // ToDo: remove to enable adding trains*/
}

-(int)add:(TourItem *)tourItem startTime:(double)startTime {
  // insert after first done or active item in tour but after last park exit if added attraction is park entry
  // add at the end of the tour if added attraction is park exit
  // else add attraction at the end before last exit (if existing) but after last entry (if existing)
  // current restriction: just one park entry and exit can be added
  int tourCount = [self getAttractionCount:tourItem.attractionId];
  if ([self canAddToTour:tourItem.attractionId]) {
    SettingsData *settings = [SettingsData getSettingsData];
    if (tourCount < settings.maxNumberOfSameAttractionInTour) {
      ParkData *parkData = [ParkData getParkData:parkId];
      if ([parkData isExitOfPark:tourItem.attractionId]) {
        [tourItems addObject:tourItem];
      } else if ([parkData isEntryOfPark:tourItem.attractionId]) {
        int i = [tourItems count];
        int j = [parkData.currentTrackData numberOfTourItemsDoneAndActive];
        while (--i >= j) {
          TourItem *t = [tourItems objectAtIndex:i];
          if ([parkData isExitOfPark:t.attractionId]) break;
        }
        int k = i;
        while (--k >= 0) {
          TourItem *t = [tourItems objectAtIndex:k];
          if ([parkData isExitOfPark:t.attractionId]) {
            k = -1;
            break;
          } else if ([parkData isEntryOfPark:t.attractionId]) {
            break;
          }
        }
        if (k >= j) {
          if (++i == [tourItems count]) [tourItems addObject:tourItem];
          else [tourItems insertObject:tourItem atIndex:i];
        } else {
          if ([tourItems count] == j) [tourItems addObject:tourItem];
          else [tourItems insertObject:tourItem atIndex:j];
        }
      } else {
        // before last exit
        BOOL added = NO;
        int i = [tourItems count];
        int j = [parkData.currentTrackData numberOfTourItemsDoneAndActive];
        while (--i >= j) {
          TourItem *t = [tourItems objectAtIndex:i];
          if ([parkData isExitOfPark:t.attractionId]) {
            [tourItems insertObject:tourItem atIndex:i];
            added = YES;
            break;
          } else if ([parkData isEntryOfPark:t.attractionId]) {
            break;
          }
        }
        if (!added) [tourItems addObject:tourItem];
      }
      ++tourCount;
      lastOptimized = 0.0;
    }
  }
  if (startTime > 0.0) {
    [self updateTourData:startTime];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData save:YES];
  }
  return tourCount;
}

-(void)insertAfterFirstDone:(TourItem *)attraction startTime:(double)startTime {
  ParkData *parkData = [ParkData getParkData:parkId];
  if ([tourItems count] == 0) [tourItems addObject:attraction];
  else if ([parkData.currentTrackData walkToEntry]) [tourItems insertObject:attraction atIndex:[parkData.currentTrackData numberOfTourItemsDone]];
  else [tourItems insertObject:attraction atIndex:[parkData.currentTrackData numberOfTourItemsDone]+1];
  [self updateTourData:startTime];
  [parkData save:YES];
  lastOptimized = 0.0;
}

-(void)clear {
  [tourItemsOfLastAskIfTourOptimizing release];
  tourItemsOfLastAskIfTourOptimizing = nil;
  [tourItems removeAllObjects];
  ParkData *parkData = [ParkData getParkData:parkId];
  [parkData save:YES];
  lastOptimized = [[NSDate date] timeIntervalSince1970];
}

-(double)lastOptimized {
  if (tourItemsOfLastAskIfTourOptimizing != nil && [tourItemsOfLastAskIfTourOptimizing isEqualToArray:tourItems]) return -1.0;
  if (lastOptimized > 0.0) return lastOptimized;
  int n = [tourItems count];
  if (n <= 1) {
    lastOptimized = [[NSDate date] timeIntervalSince1970];
    return lastOptimized;
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  int done = [parkData.currentTrackData numberOfTourItemsDone];
  if (n-done <= 1) {
    lastOptimized = [[NSDate date] timeIntervalSince1970];
  } else {
    int m = 0;
    for (int k = done; m < 2 && k < n; ++k) {
      TourItem *item = [tourItems objectAtIndex:k];
      if (![parkData isEntryOrExitOfPark:item.attractionId]) ++m;
    }
    if (m <= 1) lastOptimized = [[NSDate date] timeIntervalSince1970];
  }
  return lastOptimized;
}

-(void)askNextTimeForTourOptimization {
  lastOptimized = 0.0;
  [tourItemsOfLastAskIfTourOptimizing release];
  tourItemsOfLastAskIfTourOptimizing = nil;
}

-(void)dontAskNextTimeForTourOptimization {
  [tourItemsOfLastAskIfTourOptimizing release];
  tourItemsOfLastAskIfTourOptimizing = [[NSArray alloc] initWithArray:tourItems];
}

+(NSString *)createLogEntry:(int)n array:(int *)a {
  if (n <= 0) return @"";
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:n*5] autorelease];
  [s appendFormat:@"%d", a[0]];
  for (int i = 1; i < n; ++i) [s appendFormat:@", %d", a[i]];
  return s;
}

+(NSString *)createLogEntry:(NSArray *)tourItems {
  int n = [tourItems count];
  if (n <= 0) return @"";
  NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:n*5] autorelease];
  id item = [tourItems objectAtIndex:0];
  NSString *tId = nil;
  if ([item isKindOfClass:[TourItem class]]) tId = ((TourItem *)item).attractionId;
  else if ([item isKindOfClass:[NSString class]]) tId = (NSString *)item;
  [s appendFormat:@"%@", tId];
  for (int i = 1; i < n; ++i) {
    item = [tourItems objectAtIndex:i];
    if ([item isKindOfClass:[TourItem class]]) tId = ((TourItem *)item).attractionId;
    else if ([item isKindOfClass:[NSString class]]) tId = (NSString *)item;
    else tId = nil;
    [s appendFormat:@", %@", tId];
  }
  return s;
}

-(void)insertAllItemsFrom:(NSMutableArray *)itemsToConsider startAtIndex:(int)startAtIndex whichAreOnThePathOfTour:(NSMutableArray *)optTour afterIndex:(int)afterIndex {
  // 6.1. einfügen alle ohne Zeitvorgabe, die auf dem Weg der Tour liegen (z.B. auch doppelte Einträge)
  // Eingang und Ausgang der doppelten Einträge muss auf dem Weg der Tour liegen (kann ggf. bei Zügen nicht zutreffen)
  // einfügen aller doppelten Einträge ohne Zeitvorgabe, zu beachten, dass doppelte Einträge auch nicht in der optimierten Tour enthalten sein können
  ParkData *parkData = [ParkData getParkData:parkId];
  for (int i = [itemsToConsider count]-1; i >= startAtIndex; --i) {
    TourItem *tourItem = [itemsToConsider objectAtIndex:i];
    if (tourItem.preferredTime == 0.0 && (itemsToConsider != optTour || ![parkData isEntryOrExitOfPark:tourItem.attractionId])) {
      Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
      for (int j = [optTour count]-1; j >= afterIndex+1; --j) {
        if (itemsToConsider == optTour && i == j) continue;
        TourItem *prevItem = [optTour objectAtIndex:j-1];
        TourItem *item = [optTour objectAtIndex:j];
        //NSLog(@"D: %@ - %@", prevItem.exitAttractionId, item.entryAttractionId);
        NSArray *path = [parkData getMinPathFrom:prevItem.exitAttractionId fromAll:YES toAllAttractionId:item.entryAttractionId];
        if ([path containsObject:tourItem.entryAttractionId] && [path containsObject:tourItem.exitAttractionId]) {
          //NSLog(@"D1: %@ - %@", prevItem.exitAttractionId, tourItem.attractionId);
          if ([attraction isTrain] && [parkData distance:prevItem.exitAttractionId fromAll:NO toAttractionId:tourItem.entryAttractionId toAll:NO path:nil] > [parkData distance:prevItem.exitAttractionId fromAll:NO toAttractionId:[parkData getEntryAttractionId:tourItem.exitAttractionId] toAll:NO path:nil]) {
            NSString *eId = [parkData getEntryAttractionId:tourItem.exitAttractionId];
            [tourItem set:[Attraction getShortAttractionId:eId] entry:eId exit:[parkData exitAttractionIdOf:tourItem.attractionId]];
          }
          path = [parkData getMinPathFrom:prevItem.exitAttractionId fromAll:YES toAllAttractionId:tourItem.attractionId];
          if (path == nil || [path count] < 2) NSLog(@"ERROR! min path from %@ to %@: %@", prevItem.exitAttractionId, tourItem.attractionId, path);
          else {
            prevItem.exitAttractionId = [path objectAtIndex:0];
            tourItem.entryAttractionId = [path lastObject];
          }
          //NSLog(@"D3: %@ - %@", tourItem.attractionId, item.attractionId);
          path = [parkData getMinPathFrom:[parkData exitAttractionIdOf:tourItem.attractionId] fromAll:YES toAllAttractionId:item.attractionId];
          if (path == nil || [path count] < 2) NSLog(@"ERROR! min path from %@ to %@: %@", tourItem.attractionId, item.attractionId, path);
          else {
            tourItem.exitAttractionId = [path objectAtIndex:0];
            item.entryAttractionId = [path lastObject];
          }
          if (i < j) {
            [optTour insertObject:tourItem atIndex:j];
            [itemsToConsider removeObjectAtIndex:i];
          } else {
            [tourItem retain];
            [itemsToConsider removeObjectAtIndex:i];
            [optTour insertObject:tourItem atIndex:j];
            [tourItem release];
          }
          //i = [itemsToConsider count];
          break;
        }
      }
    }
  }
}

-(BOOL)extendTour:(NSMutableArray *)optTour startAtIndex:(int)startAtIndex byBestItemFrom:(NSMutableArray *)itemsToConsider {
  // 6.2. sukzessives Hinzufügen der Anderen an best möglicher Stelle (d.h. kürzester Abstand von - neu - bis) einfügen
  // ToDo: Verbesserung durch auch zusätzlicher Betrachtung, dass nicht nur der mindestes Abstand sondern, ob auch andere Einträge auf Weg liegen und dadurch noch bessere Optimierung erreicht werden kann
#ifdef DEBUG_TOUR_OPTIMIZE
  NSLog(@"6. Extend by: %@", [TourData createLogEntry:itemsToConsider]);
#endif
  BOOL tourExtended = NO;
  ParkData *parkData = [ParkData getParkData:parkId];
  int sourcePos = 0;
  int targetPos = -1;
  BOOL swapEntryExit = NO;
  double minDistance = 0.0;
  int n = [optTour count]-1;
  int j = 0;
  for (TourItem *tourItem in itemsToConsider) {
    if (tourItem.preferredTime == 0.0) {
      Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
      for (int i = startAtIndex; i < n; ++i) {
        TourItem *item = [optTour objectAtIndex:i];
        TourItem *nextItem = [optTour objectAtIndex:i+1];
        double d0 = [parkData distance:item.exitAttractionId fromAll:NO toAttractionId:nextItem.entryAttractionId toAll:NO path:nil];
        double d1 = [parkData distance:item.exitAttractionId fromAll:NO toAttractionId:tourItem.attractionId toAll:YES path:nil] + [parkData distance:tourItem.exitAttractionId fromAll:NO toAttractionId:nextItem.entryAttractionId toAll:NO path:nil] - d0;
        if (targetPos < 0 || d1 < minDistance) {
          minDistance = d1;
          targetPos = i+1;
          sourcePos = j;
          swapEntryExit = NO;
        }
        if ([attraction isTrain] && ![tourItem.entryAttractionId isEqualToString:[parkData getEntryAttractionId:tourItem.exitAttractionId]]) {
          double d1 = [parkData distance:item.exitAttractionId fromAll:NO toAttractionId:[parkData getEntryAttractionId:tourItem.exitAttractionId] toAll:YES path:nil] + [parkData distance:[parkData exitAttractionIdOf:tourItem.attractionId] fromAll:YES toAttractionId:nextItem.entryAttractionId toAll:NO path:nil] - d0;
          if (targetPos < 0 || d1 < minDistance) {
            minDistance = d1;
            targetPos = i+1;
            sourcePos = j;
            swapEntryExit = YES;
          }
        }
      }
    }
    ++j;
  }
  if (targetPos >= 0) {
    TourItem *tourItem = [itemsToConsider objectAtIndex:sourcePos];
    if (swapEntryExit) {
      NSString *eId = [parkData getEntryAttractionId:tourItem.exitAttractionId];
      [tourItem set:[Attraction getShortAttractionId:eId] entry:eId exit:[parkData exitAttractionIdOf:tourItem.attractionId]];
    }
    TourItem *item = [optTour objectAtIndex:targetPos-1];
    TourItem *nextItem = [optTour objectAtIndex:targetPos];
    NSArray *path = [parkData getMinPathFrom:item.exitAttractionId fromAll:YES toAllAttractionId:tourItem.attractionId];
    if (path == nil || [path count] < 2) NSLog(@"ERROR! min path from %@ to %@: %@", item.exitAttractionId, tourItem.attractionId, path);
    else {
      item.exitAttractionId = [path objectAtIndex:0];
      tourItem.entryAttractionId = [path lastObject];
    }
    path = [parkData getMinPathFrom:[parkData exitAttractionIdOf:tourItem.attractionId] fromAll:YES toAllAttractionId:nextItem.attractionId];
    if (path == nil || [path count] < 2) NSLog(@"ERROR! min path from %@ to %@: %@", tourItem.attractionId, nextItem.attractionId, path);
    else {
      tourItem.exitAttractionId = [path objectAtIndex:0];
      nextItem.entryAttractionId = [path lastObject];
    }
    [optTour insertObject:tourItem atIndex:targetPos];
    [itemsToConsider removeObjectAtIndex:sourcePos];
    tourExtended = YES;
  }
  return tourExtended;
}

static double optimize(int n, double w, int *a, int *b, int *c, int *e, double *f, double *dist) {
#ifdef DEBUG_TOUR_OPTIMIZE
  const bool debug = true;
#else
  const bool debug = false;
#endif
  w -= 0.5;
  int n1 = n-2;
  int i = 0;
  int k = 0;
  double v = 0.0;
  while (TRUE) {
    while (++i <= n1) {
      int ai = a[i];
      double u = v + dist[a[k]*n+ai];
      if (u < w) {
        int k1 = k+1;
        if (k1 == n1) {
          u += dist[ai*n+n-1];
          //if (debug) NSLog(@"%f  for (%@)", u, [TourData createLogEntry:n array:a]);
          if (u < w) {
            w = u-0.5;
            memcpy(b, a, sizeof(int)*n);
            b[i] = a[k1]; b[k1] = ai;
            if (debug) NSLog(@"distance:%f  for (%@)", u, [TourData createLogEntry:n array:b]);
          }
        } else {
          a[i] = a[k1]; a[k1] = ai;
          e[k] = i; c[k] = ai; f[k] = v;
          v = u;
          i = k = k1;
        }
      }
    }
    if (k == 0) break;
    i = e[--k]; v = f[k];
    a[k+1] = a[i]; a[i] = c[k];
  }
  return w+0.5;
}

-(double)optimize {
  // There are 3 cases for optimization
  // 1) park entries at the edges of the tour and nothing done -> both edges are fix
  // 2) closest attraction to current location (always park entry if outside park) if exist -> start fix
  // 3) end is park exit -> fix otherwith open
  // ToDo: if (isOptimized) return;
  /*
   0) Einfache Vorabheuristik, starte mit dem ersten Eintrag und nehme dann immer den nächsten, der die kürzeste Entfernung hat
   1) alle gleichen aussortieren und die, die zwischen Ausgang und Eingang der gleichen Attraktionen liegen (und gleichen Aus-/Eingang haben)
   2) merken, ob Tourattraktionen auf den Weg zwischen zwei Attraktionen einer Tour liegen
   3) min sträckenlenge merken und eine Ebene früher aussteigen, wenn min distance im nächsten Schritt immer überschritten wird
   4) vorab Heuristik durch zusammenlegen aller Attraktionen nach Themenbereiche, darin lokal optimieren und dann die Themenbereichsmengen von Attraktionen sortieren   */
  int n = [tourItems count]-1;
  if (n <= 0) {
    lastOptimized = [[NSDate date] timeIntervalSince1970];
    return lastOptimized;
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  int itemsDone = (parkData.currentTrackData != nil)? [parkData.currentTrackData numberOfTourItemsDoneAndActive] : 0;
  if (itemsDone >= n) {
    lastOptimized = [[NSDate date] timeIntervalSince1970];
    return lastOptimized;
  }
  NSLog(@"Init optimization (done: %d)", itemsDone);
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"Input: %@", [TourData createLogEntry:tourItems]);
  // 1) Filterung von Park Ein- und Ausgänge und aller Tour-Einträge, die doppelt sind (gilt nicht für Züge mit unterschiedlichen Ein- und Ausgänge) oder Zeitvorgaben haben
  int indexOfParkEntryInTour = -1;
  int indexOfParkExitInTour = -1;
  NSMutableArray *itemsToConsiderLater = [[NSMutableArray alloc] initWithCapacity:n+1];
  NSMutableArray *itemsToConsiderNow = [[NSMutableArray alloc] initWithCapacity:n+1];
  for (int i = itemsDone; i <= n; ++i) {
    TourItem *tourItem = [tourItems objectAtIndex:i];
    if ([parkData isExitOfPark:tourItem.attractionId]) {
      if (indexOfParkExitInTour < 0) indexOfParkExitInTour = i;
    } else if ([parkData isEntryOfPark:tourItem.attractionId]) {
      if (indexOfParkEntryInTour < 0) indexOfParkEntryInTour = i;
    } else {
      Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
      if ([attraction isTrain] && ![tourItem.entryAttractionId isEqualToString:tourItem.exitAttractionId]) {
        [itemsToConsiderNow addObject:tourItem];
      } else {
        NSString *aId = [parkData getRootAttractionId:tourItem.attractionId];
        int j = i;
        while (--j >= itemsDone) {
          TourItem *item = [tourItems objectAtIndex:j];
          NSString *bId = [parkData getRootAttractionId:item.attractionId];
          if ([bId isEqualToString:aId]) {
            if (tourItem.preferredTime == 0.0) {
              break;
            } else if (item.preferredTime == 0.0) {
              [item retain];
              [tourItems removeObjectAtIndex:j];
              [tourItems insertObject:tourItem atIndex:j];
              [tourItems removeObjectAtIndex:i];
              if (i >= [tourItems count]) [tourItems addObject:item];
              else [tourItems insertObject:item atIndex:i];
              tourItem = item;
              [item release];
              break;
            }
          }
        }
        if (j >= itemsDone || tourItem.preferredTime > 0.0) [itemsToConsiderLater addObject:tourItem];
        else [itemsToConsiderNow addObject:tourItem];
      }
    }
  }
#ifdef DEBUG_TOUR_OPTIMIZE
  NSLog(@"1. Now: %@", [TourData createLogEntry:itemsToConsiderNow]);
  NSLog(@"1. Later: %@", [TourData createLogEntry:itemsToConsiderLater]);
#endif
  // 2) Filterung aller Tour-Einträge mit gleichen Ein- und Ausgang, die auf dem Weg zwischen dem Aus- und Eingang eines doppelten Eintrags enthalten sind
  for (int i = [itemsToConsiderLater count]-1; i >= 0; --i) {
    TourItem *tourItem = [itemsToConsiderLater objectAtIndex:i];
    NSArray *path = [parkData getMinPathFrom:tourItem.exitAttractionId fromAll:YES toAllAttractionId:tourItem.entryAttractionId];
    if ([path count] > 2) {
      for (int j = [itemsToConsiderNow count]-1; j >= 0; --j) {
        TourItem *item = [itemsToConsiderNow objectAtIndex:j];
        NSString *aId = [parkData getRootAttractionId:item.attractionId];
        if ([item.entryAttractionId isEqualToString:item.exitAttractionId] && [path containsObject:aId]) {
          [itemsToConsiderLater addObject:item];
          [itemsToConsiderNow removeObjectAtIndex:j];
        }
      }
    }
  }
#ifdef DEBUG_TOUR_OPTIMIZE
  NSLog(@"2. Now: %@", [TourData createLogEntry:itemsToConsiderNow]);
  NSLog(@"2. Later: %@", [TourData createLogEntry:itemsToConsiderLater]);
#endif
  // 3) bevorzuge Züge mit unterschiedlichen Ein- und Ausgang (Stationen) und Attraktionen aus unterschiedlichen Themenbereiche im ersten Run
  NSMutableSet *coveredThemeAreas = [[NSMutableSet alloc] initWithCapacity:[itemsToConsiderNow count]];
  NSMutableArray *tourToOptimizeFirst = [[NSMutableArray alloc] initWithCapacity:MAX_NUMBER_OF_ITEMS_IN_TOUR_OPTIMIZING+1];
  for (int i = [itemsToConsiderNow count]-1; i >= 0; --i) {
    TourItem *tourItem = [itemsToConsiderNow objectAtIndex:i];
    if (![parkData isEntryOrExitOfPark:tourItem.attractionId] && ![tourItem.entryAttractionId isEqualToString:tourItem.exitAttractionId]) {
      Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
      if ([attraction isTrain]) {
        NSDictionary *attractionDetails = [attraction getAttractionDetails:parkId cache:YES];
        [coveredThemeAreas addObject:[MenuData objectForKey:ATTRACTION_THEME_AREA at:attractionDetails]];
        [tourToOptimizeFirst addObject:tourItem];
        [itemsToConsiderNow removeObjectAtIndex:i];
        if ([tourToOptimizeFirst count] >= MAX_NUMBER_OF_ITEMS_IN_TOUR_OPTIMIZING) break;
      }
    }
  }
  if ([tourToOptimizeFirst count] < MAX_NUMBER_OF_ITEMS_IN_TOUR_OPTIMIZING) {
    for (int i = [itemsToConsiderNow count]-1; i >= 0; --i) {
      TourItem *tourItem = [itemsToConsiderNow objectAtIndex:i];
      if (![parkData isEntryOrExitOfPark:tourItem.attractionId]) {
        Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
        NSDictionary *attractionDetails = [attraction getAttractionDetails:parkId cache:YES];
        NSString *themeArea = [MenuData objectForKey:ATTRACTION_THEME_AREA at:attractionDetails];
        if (![coveredThemeAreas containsObject:themeArea]) {
          [coveredThemeAreas addObject:themeArea];
          [tourToOptimizeFirst addObject:tourItem];
          [itemsToConsiderNow removeObjectAtIndex:i];
          if ([tourToOptimizeFirst count] >= MAX_NUMBER_OF_ITEMS_IN_TOUR_OPTIMIZING) break;
        }
      }
    }
  }
  [coveredThemeAreas release];
#ifdef DEBUG_TOUR_OPTIMIZE
  NSLog(@"3. First: %@", [TourData createLogEntry:tourToOptimizeFirst]);
  NSLog(@"3. Now: %@", [TourData createLogEntry:itemsToConsiderNow]);
#endif
  // 4) einfaches Auffüllen, kann noch optimiert werden, vermutlich sind lange Entfernungen besser
  while ([itemsToConsiderNow count] > 0 && [tourToOptimizeFirst count] < MAX_NUMBER_OF_ITEMS_IN_TOUR_OPTIMIZING) {
    [tourToOptimizeFirst addObject:[itemsToConsiderNow lastObject]];
    [itemsToConsiderNow removeObjectAtIndex:[itemsToConsiderNow count]-1];
  }
  [itemsToConsiderLater addObjectsFromArray:itemsToConsiderNow];
  [itemsToConsiderNow release];
#ifdef DEBUG_TOUR_OPTIMIZE
  NSLog(@"4. First: %@", [TourData createLogEntry:tourToOptimizeFirst]);
  NSLog(@"4. Later: %@", [TourData createLogEntry:itemsToConsiderLater]);
#endif
  // 5) Touranfang und -ende bestimmen
  NSMutableArray *tour = [[NSMutableArray alloc] initWithCapacity:MAX_NUMBER_OF_ITEMS_IN_TOUR_OPTIMIZING+3];
  if (indexOfParkEntryInTour >= 0) {  // erster und letzer Eintrag Fix, wenn Entry und Exit!
    TourItem *tourItem = [tourItems objectAtIndex:indexOfParkEntryInTour];
    [tour addObject:tourItem.attractionId];
  } else {
    NSString *closestAttractionId = nil;
    NSString *alternativeStartAttractionId = nil;
    if ([LocationData isLocationDataActive]) {
      LocationData *locationData = [LocationData getLocationData];
      TrackPoint *t = [[TrackPoint alloc] initWithLatitude:locationData.lastUpdatedLocation.coordinate.latitude longitude:locationData.lastUpdatedLocation.coordinate.longitude];
      TrackSegment *closestTrackSegment = [parkData closestTrackSegmentForTrackPoint:t];
      closestAttractionId = closestTrackSegment.from;
      alternativeStartAttractionId = closestTrackSegment.to;
      [t release];
      NSLog(@"currently closest attraction IDs: %@ / %@)", closestAttractionId, alternativeStartAttractionId);
      // ToDo: second run with alternativeStartAttractionId as start!
    }
    if (closestAttractionId == nil) {
      if (itemsDone == 0) {
        [tour addObject:@""];
      } else {
        TourItem *tourItem = [tourItems objectAtIndex:itemsDone-1];
        [tour addObject:tourItem.exitAttractionId];
      }
    } else {
      [tour addObject:closestAttractionId];
    }
  }
  for (TourItem *tourItem in tourToOptimizeFirst) {
    if (![tourItem.entryAttractionId isEqualToString:tourItem.exitAttractionId]) {
      Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
      if ([attraction isTrain]) {
        [tour addObject:tourItem];
      } else {
        [tour addObject:[Attraction getShortAttractionId:tourItem.attractionId]];
      }
    } else {
      [tour addObject:[Attraction getShortAttractionId:tourItem.attractionId]];
    }
  }
  if (indexOfParkExitInTour >= 0) {
    TourItem *tourItem = [tourItems objectAtIndex:indexOfParkExitInTour];
    [tour addObject:tourItem.attractionId];
  } else {
    [tour addObject:@""];
  }
  n = [tour count];
  /* ToDo: simple sort always choose the closest
  [tourToOptimizeFirst removeAllObjects];
  if (n > 3) {
    NSString *aId = [tour objectAtIndex:0];
    [tourToOptimizeFirst addObject:aId];
    int start = 1;
    if ([aId length] == 0) {
      aId = [tour objectAtIndex:1];
      [tourToOptimizeFirst addObject:aId];
      aId = [parkData exitAttractionIdOf:aId];
      ++start;
    }
    for (int i = start; i < n-2; ++i) {
      NSString *bId = [tour objectAtIndex:i];
      double d = [parkData distance:aId fromAll:YES toAttractionId:bId toAll:YES];
      for (int j = i+1; j < n-1; ++j) {
        NSString *cId = [tour objectAtIndex:j];
        double d2 = [parkData distance:aId fromAll:YES toAttractionId:cId toAll:YES];
        if (d2 < d) {
          bId = cId;
          d = d2;
        }
      }
      [tourToOptimizeFirst addObject:bId];
      aId = [parkData exitAttractionIdOf:bId];
    }
    [tourToOptimizeFirst addObject:[tour objectAtIndex:n-2]];
    [tourToOptimizeFirst addObject:[tour objectAtIndex:n-1]];
  }*/
  [tourToOptimizeFirst release];
  NSLog(@"tour to optimize: %@", [TourData createLogEntry:tour]);
  int *a = malloc(sizeof(int)*n);
  int *b = malloc(sizeof(int)*n);
  int *c = malloc(sizeof(int)*n);
  int *e = malloc(sizeof(int)*n);
  double *f = malloc(sizeof(double)*n);
  double *dist = malloc(sizeof(double)*n*n);
  double w = 0.0;
  for (int i = 0; i < n; ++i) {
    b[i] = a[i] = i;
    id aId1 = [tour objectAtIndex:i];
    NSString *aId2 = nil;
    if ([aId1 isKindOfClass:[TourItem class]]) {
      TourItem *tourItem = (TourItem *)aId1;
      aId2 = tourItem.exitAttractionId;
      aId1 = tourItem.entryAttractionId;
    }
    for (int j = 0; j < n; ++j) {
      if (i == j) {
        dist[i*n+i] = 0.0;
      } else {
        id bId = [tour objectAtIndex:j];
        if ([bId isKindOfClass:[TourItem class]]) {
          TourItem *tourItem = (TourItem *)bId;
          bId = tourItem.entryAttractionId;
        }
        if ([aId1 length] == 0 || [bId length] == 0) dist[i*n+j] = 0.0;
        else if (i == 0) dist[j] = [parkData distance:(aId2 != nil)? aId2 : aId1 fromAll:NO toAttractionId:bId toAll:YES path:nil];
        else if (j == n-1) dist[i*n+j] = [parkData distance:(aId2 != nil)? aId2 : [parkData exitAttractionIdOf:aId1] fromAll:YES toAttractionId:bId toAll:NO path:nil];
        else dist[i*n+j] = [parkData distance:(aId2 != nil)? aId2 : [parkData exitAttractionIdOf:aId1] fromAll:YES toAttractionId:bId toAll:YES path:nil];
      }
    }
    if (i < n-1) w += dist[i*n+i+1];
  }
  // ToDo: Strecke in Zeit umrechnen und nach Zeit optimieren! Dabei Zeitvorgaben berücksichtigen
  // ToDo: Strecke mit Zug/Monorail/Schiff hat Gewicht 0, bei Einstellung nach Strecke optimieren
  NSLog(@"start tour items: %d with distance: %f", n, w);
  w = optimize(n, w, a, b, c, e, f, dist);
  NSLog(@"optimized distance: %f  (%@)", w, [TourData createLogEntry:n array:b]);
  free(a);
  free(c);
  free(e);
  free(f);
  free(dist);
  NSMutableArray *optTour = [[NSMutableArray alloc] initWithCapacity:[tourItems count]];
  for (int i = 0; i < itemsDone; ++i) [optTour addObject:[tourItems objectAtIndex:i]];
  id entryId = [tour objectAtIndex:(indexOfParkEntryInTour < 0)? b[1] : 0];
  id exitId = nil;
  if ([entryId isKindOfClass:[TourItem class]]) {
    TourItem *tourItem = (TourItem *)entryId;
    entryId = tourItem.entryAttractionId;
    exitId = tourItem.exitAttractionId;
  }
  NSLog(@"tour start at %@", entryId);
  for (int i = (indexOfParkEntryInTour < 0)? 1 : 0; i < n; ++i) {
    if (exitId == nil) exitId = ([parkData isEntryOrExitOfPark:entryId] || [parkData isEntryExitSame:entryId])? entryId : [parkData exitAttractionIdOf:entryId];
    id nextId1 = (i < n-1)? [tour objectAtIndex:b[i+1]] : nil;
    NSString *nextId2 = nil;
    if (nextId1 != nil && [nextId1 isKindOfClass:[TourItem class]] > 0) {
      TourItem *tourItem = (TourItem *)nextId1;
      nextId1 = tourItem.entryAttractionId;
      nextId2 = tourItem.exitAttractionId;
      double d1 = [parkData distance:exitId fromAll:YES toAttractionId:nextId1 toAll:NO path:nil];
      double d2 = [parkData distance:exitId fromAll:YES toAttractionId:nextId2 toAll:NO path:nil];
      if (i+1 >= n-1) {
        if (d2 < d1) {
          [tourItem setEntry:nextId2 exit:nextId1];
          nextId1 = tourItem.entryAttractionId;
          nextId2 = tourItem.exitAttractionId;
        }
      } else {
        id nextId3 = [tour objectAtIndex:b[i+2]];
        NSString *nextId4 = nil;
        if (nextId3 != nil && [nextId3 isKindOfClass:[TourItem class]] > 0) {
          TourItem *tourItem = (TourItem *)nextId3;
          nextId3 = tourItem.entryAttractionId;
          nextId4 = tourItem.exitAttractionId;
        }
        double d3 = [parkData distance:[parkData exitAttractionIdOf:nextId1] fromAll:YES toAttractionId:nextId3 toAll:NO path:nil];
        double d4 = [parkData distance:[parkData exitAttractionIdOf:nextId2] fromAll:YES toAttractionId:nextId3 toAll:NO path:nil];
        if (d2+d4 < d1+d3) {
          [tourItem setEntry:nextId2 exit:nextId1];
          nextId1 = tourItem.entryAttractionId;
          nextId2 = tourItem.exitAttractionId;
        } else if (nextId4 != nil) {
          d3 = [parkData distance:[parkData exitAttractionIdOf:nextId1] fromAll:YES toAttractionId:nextId4 toAll:NO path:nil];
          d4 = [parkData distance:[parkData exitAttractionIdOf:nextId2] fromAll:YES toAttractionId:nextId4 toAll:NO path:nil];
          if (d2+d4 < d1+d3) {
            [tourItem setEntry:nextId2 exit:nextId1];
            nextId1 = tourItem.entryAttractionId;
            nextId2 = tourItem.exitAttractionId;
            TourItem *item = [tour objectAtIndex:b[i+2]];
            [item setEntry:nextId4 exit:nextId3];
          }
        }
      }
    }
    if (nextId1 != nil && [nextId1 length] > 0) {
      NSArray *path = [parkData getMinPathFrom:exitId fromAll:YES toAllAttractionId:nextId1]; // shortest path because multiple entries possible
      if (path == nil || [path count] < 2) {
        NSLog(@"ERROR! min path from %@ to %@: %@", exitId, nextId1, path);
      } else {
        exitId = [path objectAtIndex:0];
        NSString *e = [path lastObject];
        if (!([parkData isExitOfPark:nextId1] && [parkData isEntryOfPark:e]) && !([parkData isExitOfPark:e] && [parkData isEntryOfPark:nextId1])) nextId1 = e;
      }
    }
    //NSLog(@"via %@ - %@ - %@", entryId, exitId, nextId1);
    TourItem *t = [[TourItem alloc] initWithAttractionId:[parkData isEntryOrExitOfPark:entryId]? [parkData getAttractionDataId:entryId] : [Attraction getShortAttractionId:entryId] entry:entryId exit:exitId];
    [optTour addObject:t];
    [t release];
    if (nextId1 == nil || [nextId1 length] == 0) break;
    entryId = nextId1;
    exitId = nextId2;
  }
  free(b);
  [tour release];
  // 6. Alle Einträge (doppelte, auf dem Weg liegende, mit Zeitvorgabe, überschüssige) nachträglich an der best möglichen Stelle einfügen
  while ([itemsToConsiderLater count] > 0) {
    [self insertAllItemsFrom:itemsToConsiderLater startAtIndex:0 whichAreOnThePathOfTour:optTour afterIndex:itemsDone];
    [self insertAllItemsFrom:optTour startAtIndex:itemsDone whichAreOnThePathOfTour:optTour afterIndex:itemsDone];
    if (![self extendTour:optTour startAtIndex:MAX(itemsDone-1, 0) byBestItemFrom:itemsToConsiderLater]) break;
  }
  [tourItems release];
  tourItems = optTour;
  lastOptimized = [[NSDate date] timeIntervalSince1970];
  //[self updateTourData:lastOptimized];
  // 6.3. Tour Zeitupdate und Zeitvorgaben einfügen, so dass viele Einträge möglichst zeitlich passen (nach jedem Einfügen wieder Zeitupdate)
  // ToDo: Zeitvorgaben werden zur Zeit nur für den Parkeingang unterstützt
  /*while ([itemsToConsiderLater count] > 0) {
    todo
  }*/

  //[tourItems setArray:optTour];
  //[optTour release];
  [itemsToConsiderLater release];
  [self updateTourData:lastOptimized];
  [parkData save:YES];
  NSLog(@"Output: %@", [TourData createLogEntry:tourItems]);
  [pool release];
  return lastOptimized;
}

-(NSString *)createTrackDescription {
  int l = [tourItems count];
  if (l > 0) {
    ParkData *parkData = [ParkData getParkData:parkId];
    SettingsData *settings = [SettingsData getSettingsData];
    NSMutableString *s = [[[NSMutableString alloc] initWithCapacity:(500*l)] autorelease];
    [s appendFormat:@"%@ %@\n", NSLocalizedString(@"tour.email.body.track", nil), parkData.currentTrackData.trackName];
    int i = 0;
    for (TourItem *a in tourItems) {
      double time1 = [parkData.currentTrackData doneTimeIntervalAtEntryTourIndex:i];
      double time2 = [parkData.currentTrackData doneTimeIntervalAtExitTourIndex:i];
      if (time2 > 0.0) {
        if (time1 > 0.0) {
          [s appendString:[CalendarData stringFromTime:[NSDate dateWithTimeIntervalSince1970:time1] considerTimeZoneAbbreviation:nil]];
          [s appendString:@" - "];
        }
        [s appendString:[CalendarData stringFromTime:[NSDate dateWithTimeIntervalSince1970:time2] considerTimeZoneAbbreviation:nil]];
        [s appendString:@" ("];
        [s appendString:NSLocalizedString(@"tour.cell.completed.distance.text", nil)];
        [s appendString:@" "];
        [s appendString:distanceToString([settings isMetricMeasure], [parkData.currentTrackData distanceOfCompletedSegmentAtTourIndex:i])];
        Attraction *attraction = [Attraction getAttraction:parkId attractionId:a.attractionId];
        [s appendFormat:@") %@\n", attraction.stringAttractionName];
        if ([attraction isTrain]) {
          Attraction *exitAttraction = [Attraction getAttraction:parkId attractionId:a.exitAttractionId];
          [s appendString:NSLocalizedString(@"tour.email.body.to", nil)];
          [s appendFormat:@" %@\n", exitAttraction.stringAttractionName];
        }
        int rating = [parkData getPersonalRating:a.attractionId];
        if (rating > 0) {
          [s appendString:NSLocalizedString(@"tour.email.body.rating", nil)];
          [s appendFormat:@" %d\n", rating];
        }
        if (!a.completed) {
          [s appendString:NSLocalizedString(@"tour.email.body.attraction.not.completed", nil)];
          [s appendString:@"\n"];
        }
        /*if (waitingTime > 0) {
          [s appendString:NSLocalizedString(@"tour.email.body.waiting", nil)];
          [s appendFormat:@" %d\n", waitingTime];
        }*/
        NSArray *comments = [parkData getComments:a.attractionId];
        if ([comments count] > 0) {
          Comment *c = [comments objectAtIndex:0];
          [s appendString:NSLocalizedString(@"tour.email.body.comments", nil)];
          [s appendFormat:@" %@\n", c.comment];
        }
        [s appendString:@"\n"];
      }
      ++i;
    }
    return s;
  }
  return @"";
}

-(NSString *)tourDescriptionVia:(NSArray *)path attractionId:(NSString *)attractionId atIndex:(int)i settings:(SettingsData *)settings {
  int l = [path count];
  int j = i+1;
  while (j+1 < l) {
    NSString *aId = [Attraction getShortAttractionId:[path objectAtIndex:j]];
    if (![aId isEqualToString:attractionId]) {
      while (++j < l) {
        aId = [Attraction getShortAttractionId:[path objectAtIndex:j]];
        if ([aId isEqualToString:attractionId]) {
          return [settings isMetricMeasure]? NSLocalizedString(@"tour.description.via.entry.of", nil) : NSLocalizedString(@"tour.description.via.entry.of.imperial", nil);
        }
      }
    }
    ++j;
  }
  j = i-1;
  while (j-1 >= 0) {
    NSString *aId = [Attraction getShortAttractionId:[path objectAtIndex:j]];
    if (![aId isEqualToString:attractionId]) {
      while (--j >= 0) {
        aId = [Attraction getShortAttractionId:[path objectAtIndex:j]];
        if ([aId isEqualToString:attractionId]) {
          return [settings isMetricMeasure]? NSLocalizedString(@"tour.description.via.exit.of", nil) : NSLocalizedString(@"tour.description.via.exit.of.imperial", nil);
        }
      }
    }
    --j;
  }
  return [settings isMetricMeasure]? NSLocalizedString(@"tour.description.via", nil) : NSLocalizedString(@"tour.description.via.imperial", nil);
}

-(NSArray *)createRouteDescriptionFrom:(NSString *)fromAttractionId currentPosition:(BOOL)currentPosition to:(NSString *)toAttractionId attractionIdsOfDescription:(NSMutableArray *)attractionIdsOfDescription {
  int l = [tourItems count];
  if (l == 0) return nil;
  //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  TourItem *tourItem = nil;
  TourItem *t = [tourItems objectAtIndex:0];
  NSString *aId = t.exitAttractionId;
  //NSString *aId = t.attractionId;
  //if (![parkData isEntryOfPark:aId]) aId = t.exitAttractionId;
  int tourItemIndex = 0;
  for (int i = 1; i < l; ++i) {
    TourItem *t2 = [tourItems objectAtIndex:i];
    if ([aId isEqualToString:fromAttractionId] && [t2.entryAttractionId isEqualToString:toAttractionId]) {
      tourItem = t;
      tourItemIndex = i-1;
      break;
    }
    t = t2;
    aId = t.exitAttractionId;
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  SettingsData *settings = [SettingsData getSettingsData];
  [attractionIdsOfDescription removeAllObjects];
  NSMutableArray *result = [[[NSMutableArray alloc] initWithCapacity:15] autorelease];
  NSArray *path = [[parkData getMinPathFrom:fromAttractionId fromAll:NO toAllAttractionId:toAttractionId] retain]; // may be overwrite through other functions like distance
  if (path == nil) {
    NSLog(@"Missing min path from %@ to %@", fromAttractionId, toAttractionId);
  } else {
    int l = [path count];
    if (l > 0) {
      NSString *bId = [path objectAtIndex:0];
      Attraction *bAtt = [Attraction getAttraction:parkId attractionId:bId]; // Remark: can be nil for internal points
      NSString *bName = nil;
      NSString *bThemeArea = nil;
      if (bAtt != nil) {
        if ([tourItems count] == 1 || [parkData isEntryExitSame:bId]) {
          bName = bAtt.stringAttractionName;
        } else {
          bName = [NSString stringWithFormat:NSLocalizedString(@"tour.description.exit.of", nil), bAtt.stringAttractionName];
          NSDictionary *attractionDetails = [bAtt getAttractionDetails:parkId cache:YES];
          NSString *themeArea = [MenuData objectForKey:ATTRACTION_THEME_AREA at:attractionDetails];
          if (themeArea != nil && [themeArea length] > 0) bThemeArea = themeArea;
        }
      }
      double d = 0.0;
      if (tourItem == nil) {
        double distance = [parkData distance:fromAttractionId fromAll:YES toAttractionId:toAttractionId toAll:YES path:nil];
        NSMutableString *s = [[NSMutableString alloc] initWithCapacity:60];
        [s appendString:distanceToString([settings isMetricMeasure], distance)];
        if (currentPosition) {
          [s appendString:@" "];
          [s appendString:NSLocalizedString(@"distance.position", nil)];
        }
        [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.cell.route.title", nil), s, [self getFormat:[self getWalkingTime:distance]]]];
        [s release];
      } else if (![parkData.currentTrackData isDoneAndActiveAtTourIndex:tourItemIndex+1]) {
        NSString *s = distanceToString([settings isMetricMeasure], tourItem.distanceToNextAttraction);
        [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.cell.route.title", nil), s, [self getFormat:[self getWalkingTime:tourItem.distanceToNextAttraction]]]];
      }
      BOOL first = YES;
      for (int i = 1; i < l; ++i) {
        NSString *cId = [path objectAtIndex:i];
        Attraction *cAtt = [Attraction getAttraction:parkId attractionId:cId];
        // ToDo: Detailierungsgrad anhand Distanz bestimmen!
        d = [parkData distance:bId fromAll:NO toAttractionId:cId toAll:NO path:nil];
        //NSLog(@"distance %f from %@ to %@", d, bId, cId);
        if (cAtt == nil || [cAtt isClosed:parkId] || (!cAtt.tourPoint && d < 50.0) || d < 10.0) continue;   // ab 50m werden auch die nicht tourPoints angezeigt
        NSString *cThemeArea = nil;
        NSString *cName = cAtt.stringAttractionName;
        NSDictionary *attractionDetails = [cAtt getAttractionDetails:parkId cache:YES];
        NSString *themeArea = [MenuData objectForKey:ATTRACTION_THEME_AREA at:attractionDetails];
        if (themeArea != nil && [themeArea length] > 0) cThemeArea = themeArea;
        if (bThemeArea == nil && cThemeArea != nil) bThemeArea = cThemeArea;
        if (first && i+1 < l) {
          first = NO;
          //[content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
          if (bName == nil) {
            if (bThemeArea != nil) {
              [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.start.theme.area", nil), bThemeArea]];
            }
          } else if (bThemeArea != nil) {
            [attractionIdsOfDescription addObject:bAtt.attractionId];
            [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.start", nil), bName, bThemeArea]];
          } else {
            [attractionIdsOfDescription addObject:bAtt.attractionId];
            [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.start.short", nil), bName]];
          }
          if (cName != nil && ![cName isEqualToString:bName] && ![parkData isExitAttractionId:cId]) {
            //[content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
            [attractionIdsOfDescription addObject:cAtt.attractionId];
            if ([settings isMetricMeasure]) {
              [result addObject:[NSString stringWithFormat:[self tourDescriptionVia:path attractionId:cAtt.attractionId atIndex:i settings:settings], (int)d, cName]];
            } else {
              [result addObject:[NSString stringWithFormat:[self tourDescriptionVia:path attractionId:cAtt.attractionId atIndex:i settings:settings], (int)convertMetersToFeet(d), cName]];
            }
          }
        } else if (bThemeArea != nil && cThemeArea != nil && ![bThemeArea isEqualToString:cThemeArea]) {
          if (i+1 < l) {
            //[content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
            [attractionIdsOfDescription addObject:cAtt.attractionId];
            if ([settings isMetricMeasure]) {
              [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.change.theme.area.via", nil), cThemeArea, (int)d, cName]];
            } else {
              [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.change.theme.area.via.imperial", nil), cThemeArea, (int)convertMetersToFeet(d), cName]];
            }
          } else {
            //[content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
            [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.change.theme.area", nil), cThemeArea]];
          }
        } else if (cName != nil && ![cName isEqualToString:bName] && ![parkData isExitAttractionId:cId] && i+1 < l) {
          //[content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
          [attractionIdsOfDescription addObject:cAtt.attractionId];
          if ([settings isMetricMeasure]) {
            [result addObject:[NSString stringWithFormat:[self tourDescriptionVia:path attractionId:cAtt.attractionId atIndex:i settings:settings], (int)d, cName]];
          } else {
            [result addObject:[NSString stringWithFormat:[self tourDescriptionVia:path attractionId:cAtt.attractionId atIndex:i settings:settings], (int)convertMetersToFeet(d), cName]];
          }
        }
        if (cName != nil && ![cName isEqualToString:bName] && (i == l-1 || ![parkData isExitAttractionId:cId])) {
          bId = cId;
          bName = cName;
          bThemeArea = cThemeArea;
        }
      }
      //[content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
      if (bAtt != nil) [attractionIdsOfDescription addObject:bAtt.attractionId];
      if ([settings isMetricMeasure]) {
        if ([parkData isExitAttractionId:bId]) [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.exit.arrived", nil), (int)d, bName]];
        else if ([parkData isFastLaneEntryAttractionId:bId]) [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.fastpass.arrived", nil), (int)d, bName]];
        else [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.arrived", nil), (int)d, bName]];
      } else {
        if ([parkData isExitAttractionId:bId]) [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.exit.arrived.imperial", nil), (int)convertMetersToFeet(d), bName]];
        else if ([parkData isFastLaneEntryAttractionId:bId]) [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.fastpass.arrived.imperial", nil), (int)convertMetersToFeet(d), bName]];
        else [result addObject:[NSString stringWithFormat:NSLocalizedString(@"tour.description.arrived.imperial", nil), (int)convertMetersToFeet(d), bName]];
      }
      //[content appendString:@"</th></tr>"];
      //if (++j < n) [content appendString:@"</table>&nbsp;<table>"];  // &nbsp; is separator for pages
      //step = 0;
    }
  }
  [path release];
  //[pool release];
  return result;
}

/*-(NSString *)createRouteDescription {
  // ToDo: use createRouteDescriptionFrom
  int n = [tourItems count];
  if (n > 0) {
    SettingsData *settings = [SettingsData getSettingsData];
    NSMutableString *content = [[[NSMutableString alloc] initWithCapacity:(500*n)] autorelease];
    [content appendString:@"<table>"];
    ParkData *parkData = [ParkData getParkData:parkId];
    TourItem *startTourItem = [tourItems objectAtIndex:0];
    NSString *aId = startTourItem.attractionId;
    int step = 0;
    int j = 0;
    for (int tourItemIndex = 0; tourItemIndex+1 < n; ++tourItemIndex) {
      TourItem *t = [tourItems objectAtIndex:tourItemIndex+1];
      NSArray *path = [parkData getMinPathForAll:aId toAllAttractionId:t.entryAttractionId];
      if (path == nil) {
        NSLog(@"Missing min path from %@ to %@", aId, t.entryAttractionId);
      } else {
        int l = [path count];
        if (l > 0) {
          NSString *bId = [path objectAtIndex:0];
          Attraction *bAtt = [Attraction getAttraction:parkId attractionId:bId];
          NSString *bName = nil;
          NSString *bThemeArea = nil;
          if ([parkData isEntryExitSame:bId]) {
            bName = bAtt.stringAttractionName;
          } else if (bAtt != nil) {
            bName = [NSString stringWithFormat:NSLocalizedString(@"tour.description.exit.of", nil), bAtt.stringAttractionName];
            if (bAtt.themeArea != nil && [bAtt.themeArea length] > 0) bThemeArea = bAtt.themeArea;
          }
          double d = 0.0;
          if (![parkData.currentTrackData isDoneAtTourIndex:tourItemIndex]) {
            [content appendString:@"<tr bgcolor=\"#CCCCCC\"><th align=\"left\">"];
            //Attraction *cAtt = [Attraction getAttraction:parkId attractionId:[path lastObject]];
            //NSString *s = NSLocalizedString(@"tour.description.title", nil);
            //[content appendFormat:s, (bAtt != nil)? bAtt.stringAttractionName : bName, (cAtt != nil)? cAtt.stringAttractionName : @""]; // ToDo
            //[content appendString:@"<br/>"];
            if ([settings isMetricMeasure]) {
              [content appendFormat:NSLocalizedString(@"tour.distance.value", nil), (int)t.distanceToNextAttraction];
            } else {
              [content appendFormat:NSLocalizedString(@"tour.distance.value.imperial", nil), convertMetersToMiles(t.distanceToNextAttraction)];
            }
            [content appendString:@" - "];
            [content appendString:[self getFormat:[self getWalkingTime:t.distanceToNextAttraction]]];
            [content appendString:@"</th></tr>"];
          }
          BOOL first = YES;
          for (int i = 1; i < l; ++i) {
            NSString *cId = [path objectAtIndex:i];
            Attraction *cAtt = [Attraction getAttraction:parkId attractionId:cId];
            if (cAtt == nil || !cAtt.tourPoint) continue;
            NSString *cThemeArea = nil;
            NSString *cName = cAtt.stringAttractionName;
            if (cAtt.themeArea != nil && [cAtt.themeArea length] > 0) cThemeArea = cAtt.themeArea;
            if (bThemeArea == nil && cThemeArea != nil) bThemeArea = cThemeArea;
            // ToDo: Detailierungsgrad anhand Distanz bestimmen!
            d = [parkData distance:bId fromAll:NO toAttractionId:cId toAll:NO];
            //NSLog(@"distance %f from %@ to %@", d, bId, cId);
            if (first) {
              first = NO;
              [content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
              if (bThemeArea != nil) {
                [content appendFormat:NSLocalizedString(@"tour.description.start", nil), bName, bThemeArea];
              } else {
                [content appendFormat:NSLocalizedString(@"tour.description.start.short", nil), bName];
              }
              [content appendString:@"</th></tr>"];
              if (cName != nil && ![cName isEqualToString:bName] && ![Attraction isExitAttractionId:cId]) {
                [content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
                if ([settings isMetricMeasure]) {
                  [content appendFormat:NSLocalizedString(@"tour.description.via", nil), (int)d, cName];
                } else {
                  [content appendFormat:NSLocalizedString(@"tour.description.via.imperial", nil), (int)convertMetersToFeet(d), cName];
                }
                [content appendString:@"</th></tr>"];
              }
            } else if (bThemeArea != nil && cThemeArea != nil && ![bThemeArea isEqualToString:cThemeArea]) {
              if (i+1 < l) {
                [content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
                if ([settings isMetricMeasure]) {
                  [content appendFormat:NSLocalizedString(@"tour.description.change.theme.area.via", nil), cThemeArea, (int)d, cName];
                } else {
                  [content appendFormat:NSLocalizedString(@"tour.description.change.theme.area.via.imperial", nil), cThemeArea, (int)convertMetersToFeet(d), cName];
                }
                [content appendString:@"</th></tr>"];
              } else {
                [content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
                [content appendFormat:NSLocalizedString(@"tour.description.change.theme.area", nil), cThemeArea];
                [content appendString:@"</th></tr>"];
              }
            } else if (cName != nil && ![cName isEqualToString:bName] && ![Attraction isExitAttractionId:cId] && i+1 < l) {
              [content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
              if ([settings isMetricMeasure]) {
                [content appendFormat:NSLocalizedString(@"tour.description.via", nil), (int)d, cName];
              } else {
                [content appendFormat:NSLocalizedString(@"tour.description.via.imperial", nil), (int)convertMetersToFeet(d), cName];
              }
              [content appendString:@"</th></tr>"];
            }
            if (cName != nil && ![cName isEqualToString:bName] && (i == l-1 || ![Attraction isExitAttractionId:cId])) {
              bId = cId;
              bName = cName;
              bThemeArea = cThemeArea;
            }
          }
          [content appendFormat:@"<tr><th align=\"left\">%d. ", ++step];
          if ([settings isMetricMeasure]) {
            [content appendFormat:([Attraction isExitAttractionId:bId])? NSLocalizedString(@"tour.description.exit.arrived", nil) : NSLocalizedString(@"tour.description.arrived", nil), (int)d, bName];
          } else {
            [content appendFormat:([Attraction isExitAttractionId:bId])? NSLocalizedString(@"tour.description.exit.arrived.imperial", nil): NSLocalizedString(@"tour.description.arrived.imperial", nil), (int)convertMetersToFeet(d), bName];
            
          }
          [content appendString:@"</th></tr>"];
          if (++j < n) [content appendString:@"</table>&nbsp;<table>"];  // &nbsp; is separator for pages
          step = 0;
        }
      }
      aId = t.exitAttractionId;
    }
    [content appendString:@"</table>"];
    return content;
  }
  return @"";
}*/

-(BOOL)isAllDone {
  int n = [tourItems count];
  if (n == 0) return NO;
  ParkData *parkData = [ParkData getParkData:parkId];
  return (n == [parkData.currentTrackData numberOfTourItemsDone]);
}

-(BOOL)isExitOfParkDone {
  ParkData *parkData = [ParkData getParkData:parkId];
  int n = [parkData.currentTrackData numberOfTourItemsDone];
  if (n == 0) return NO;
  TourItem *tourItem = [tourItems objectAtIndex:n-1];
  if ([parkData isExitOfPark:tourItem.attractionId]) {
    int l = [tourItems count];
    if (n == l) return YES;
    for (int i = n; i < l; ++i) {
      tourItem = [tourItems objectAtIndex:i];
      if ([parkData isEntryOrExitOfPark:tourItem.attractionId]) return NO;
    }
    tourItem = [tourItems objectAtIndex:n];
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
    if (attraction == nil || ![attraction isRealAttraction]) return YES;
    if ([parkData.currentTrackData walkToEntry]) return (attraction == nil || [attraction isRealAttraction]);
  }
  return NO;
}

-(void)switchDoneAtIndex:(NSUInteger)index startTime:(double)startTime completed:(BOOL)completed closed:(BOOL)closed submitWaitTime:(BOOL)submitWaitTime toTourItem:(BOOL)toTourItem {
  ParkData *parkData = [ParkData getParkData:parkId];
  if ([parkData.currentTrackData isDoneAtTourIndex:index]) {
    // ToDo: only last done
    //[t.done release];
    /*t.done = nil; // release included
     int i = index;
     int l = [data count];
     while (++i < l) { // move after last done position
     TourItem *s = [data objectAtIndex:i];
     if (s.done == nil) break;
     }
     if (--i > index) {
     [t retain];
     [data removeObjectAtIndex:index];
     [data insertObject:t atIndex:i];
     [t release];
     }*/
  } else {
    TourItem *tourItem = [tourItems objectAtIndex:index];
    if (tourItem != nil) {
      tourItem.closed = closed;
      tourItem.completed = completed;
      int i = [parkData.currentTrackData numberOfTourItemsDone];
      if (i < index) {
        [tourItem retain];
        [tourItems removeObjectAtIndex:index];
        [tourItems insertObject:tourItem atIndex:i];
        [tourItem release];
        [self askNextTimeForTourOptimization];
      }
      TourItem *previousItem = (i > 0)? [tourItems objectAtIndex:i-1] : nil;
      [parkData.currentTrackData addAttractionId:tourItem.attractionId toTourItem:toTourItem fromExitAttractionId:(previousItem != nil)? previousItem.exitAttractionId : nil];
      if (submitWaitTime && toTourItem && (completed || closed)) {
        Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
        if ([attraction isRealAttraction]) {
          WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
          NSArray *segments = parkData.currentTrackData.trackSegments;
          TrackSegment *track = [segments lastObject];
          [waitingTimeData submitTourItem:tourItem closed:closed entryLocation:(ExtendedTrackPoint *)[track fromTrackPoint] exitLocation:(ExtendedTrackPoint *)[track toTrackPoint]];
        }
      }
      if (askTourOptimizationAfterNextSwitchDone) [self askNextTimeForTourOptimization];
      if (index == 0) [parkData updateParkingTrack];
    }
    askTourOptimizationAfterNextSwitchDone = NO;
    [self updateTourData:startTime];
    [parkData save:YES];
  }
}

-(int)scrollToIndex {
  ParkData *parkData = [ParkData getParkData:parkId];
  int n = [parkData.currentTrackData numberOfTourItemsDone];
  //NSLog(@"done: %d   and active: %d", [parkData.currentTrackData numberOfTourItemsDone], n);
  return (n >= [tourItems count])? 0 : n;
}

-(int)count {
  return [tourItems count];
}

-(TourItem *)lastObject {
  int l = [tourItems count];
  ParkData *parkData = [ParkData getParkData:parkId];
  if (l > 0 && ![parkData.currentTrackData isDoneAndActiveAtTourIndex:l-1]) {
    return [tourItems lastObject];
  }
  return nil;
}

-(TourItem *)objectAtIndex:(NSUInteger)index {
  return [tourItems objectAtIndex:index];
}

-(void)removeObjectAtIndex:(NSUInteger)index startTime:(double)startTime {
  [tourItems removeObjectAtIndex:index];
  lastOptimized = 0.0;
  [self updateTourData:startTime];
  ParkData *parkData = [ParkData getParkData:parkId];
  [parkData save:YES];
}

-(void)moveFrom:(NSUInteger)fromIndex to:(NSUInteger)toIndex startTime:(double)startTime {
  if (fromIndex != toIndex) {
    id obj = [tourItems objectAtIndex:fromIndex];
    [obj retain];
    [tourItems removeObjectAtIndex:fromIndex];
    if (toIndex >= [tourItems count]) [tourItems addObject:obj];
    else [tourItems insertObject:obj atIndex:toIndex];
    [obj release];
    lastOptimized = 0.0;
    [self updateTourData:startTime];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData save:YES];
  }
}      

-(NSString *)getNextTourAttractionId {
  ParkData *parkData = [ParkData getParkData:parkId];
  int n = [parkData.currentTrackData numberOfTourItemsDone];
  if (n >= [tourItems count]) return nil;
  TourItem *t = [tourItems objectAtIndex:n];
  return t.attractionId;
}

-(void)updateTourData:(double)startTime { // ToDo: check if one entry has a negative calculatedTimeInterval, then optimization needs to be called or closing item / error message
  int l = [tourItems count];
  if (l == 0) return;
  int timeFromBeginning = 0;
  ParkData *parkData = [ParkData getParkData:parkId];
  CalendarData *calendarData = [parkData getCalendarData];
  ProfileData *profileData = [ProfileData getProfileData];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:startTime];
  int n = [parkData.currentTrackData numberOfTourItemsDone];
  int nActive = [parkData.currentTrackData numberOfTourItemsDoneAndActive];
  BOOL walkToEntry = [parkData.currentTrackData walkToEntry];
  double previousTime = 0.0;
  for (TourItem *tourItem in tourItems) {
    tourItem.currentWalkFromAttractionId = nil;
  }
  TourItem *previousTourItem = nil;
  for (int i = 0; i < l; ++i) {
    double nextTime = 0.0;
    TourItem *tourItem = [tourItems objectAtIndex:i];
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
    if ([attraction isTrain]) {
      tourItem.isWaitingTimeAvailable = YES;
      tourItem.isWaitingTimeUnknown = NO;
      tourItem.waitingTime = attraction.defaultWaiting;
    } else {
      WaitingTimeItem *waitingTimeItem = [waitingTimeData getWaitingTimeFor:tourItem.attractionId];
      tourItem.isWaitingTimeAvailable = (waitingTimeItem != nil);
      tourItem.isWaitingTimeUnknown = (waitingTimeItem == nil || [waitingTimeItem isOld]);
      tourItem.waitingTime = (waitingTimeItem == nil)? 0 : [waitingTimeItem totalWaitingTime];
    }
    if (i < n) {
      tourItem.calculatedTimeInterval = 0;
      tourItem.timeVisit = nil;
      tourItem.closed = (tourItem.waitingTime < 0);
      if (i+1 < n) {
        tourItem.distanceToNextAttraction = [parkData.currentTrackData distanceOfCompletedSegmentAtTourIndex:i+1];
        tourItem.walkingTime = [parkData.currentTrackData walkingTimeOfCompletedSegmentAtTourIndex:i+1];
      } else if (i+1 < [tourItems count]) {
        TourItem *nextTourItem = [tourItems objectAtIndex:i+1];
        NSString *fromAttractionId = tourItem.exitAttractionId;
        if (walkToEntry && [LocationData isLocationDataActive]) {
          TrackPoint *t = [parkData.currentTrackData latestTrackPoint];
          TrackSegment *closestTrackSegment = [parkData closestTrackSegmentForTrackPoint:t];
          if (closestTrackSegment != nil) {
            int fromIdx = [MenuData binarySearch:closestTrackSegment.from inside:parkData.allAttractionIds];
            if (fromIdx < 0) NSLog(@"Internal error: attraction %@ (%d) unknown", fromAttractionId, fromIdx);
            else {
              int toIdx = [MenuData binarySearch:nextTourItem.entryAttractionId inside:parkData.allAttractionIds];
              if (toIdx < 0) NSLog(@"Internal error: attraction %@ (%d) unknown", nextTourItem.entryAttractionId, toIdx);
              else {
                NSArray *path = [parkData getPath:fromIdx toAttractionIdx:toIdx];
                fromAttractionId = ([path containsObject:[NSNumber numberWithInt:fromIdx]])? closestTrackSegment.from : closestTrackSegment.to;
                nextTourItem.currentWalkFromAttractionId = fromAttractionId;
              }
            }
          }
        }
        double d = [parkData distance:fromAttractionId fromAll:YES toAttractionId:nextTourItem.entryAttractionId toAll:YES path:nil];
        tourItem.distanceToNextAttraction = d;
        tourItem.walkingTime = [self getWalkingTime:d];
      }
    } else {
      double d = 0.0;
      if (i < l-1) {
        TourItem *nextTourItem = [tourItems objectAtIndex:i+1];
        d = [parkData distance:tourItem.exitAttractionId fromAll:YES toAttractionId:nextTourItem.entryAttractionId toAll:YES path:nil];
      }
      tourItem.distanceToNextAttraction = d;
      tourItem.walkingTime = [self getWalkingTime:d];
      if (tourItem.preferredTime > 0.0) {
        timeFromBeginning = tourItem.preferredTime-startTime;
        tourItem.closed = (tourItem.waitingTime < 0);
        tourItem.timeVisit = nil;
      } else {
        NSArray *calendarItems = [[calendarData getCalendarItemsFor:tourItem.attractionId forDate:date] retain];
        if (calendarItems != nil && [calendarItems count] > 0) {
          if ([attraction needToAttendAtOpeningTime:parkId forDate:date]) {
            double t = 60*profileData.timeBeforeShow;
            //if (previousTourItem != nil) t += 60*previousTourItem.walkingTime;
            nextTime = [CalendarItem nextOpeningTimeIntervalSince1970:startTime+timeFromBeginning+t insideCalendarItems:calendarItems];
            if (nextTime < 0.0) {
              tourItem.timeVisit = nil;
              tourItem.closed = (i >= nActive || tourItem.waitingTime < 0);
            } else if (nextTime == 0.0) {
              tourItem.timeVisit = nil;
              tourItem.closed = (tourItem.waitingTime < 0);
            } else {
              tourItem.timeVisit = [CalendarData stringFromTime:[NSDate dateWithTimeIntervalSince1970:nextTime] considerTimeZoneAbbreviation:nil];
              tourItem.closed = (tourItem.waitingTime < 0);
              if (!tourItem.closed) timeFromBeginning = nextTime-startTime-t;
            }
          } else {
            tourItem.timeVisit = nil;
            if ([CalendarItem isTimeIntervalSince1970:startTime+timeFromBeginning insideCalendarItems:calendarItems]) {
              tourItem.closed = (tourItem.waitingTime < 0);
            } else if ([parkData isEntryOrExitOfPark:tourItem.attractionId] && (i == 0 || i < l-1)) { // ignore opening time if last entry is park exit
              NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
              const unsigned units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
              NSDateComponents *components = [calendar components:units fromDate:[NSDate dateWithTimeIntervalSince1970:startTime+timeFromBeginning]];
              int h = [components hour];
              int m = [components minute];
              CalendarItem *calendarItem = [calendarItems objectAtIndex:0];
              NSDateComponents *components2 = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:calendarItem.startTime];
              int h2 = [components2 hour];
              int m2 = [components2 minute];
              if (h > h2 || (h == h2 && m > m2)) {
                [components setDay:[components day]+1];  // ToDo: next day maybe not always valid; Verhalten bei Jahreswechsel unklar
                date = [calendar dateFromComponents:components];
                NSArray *cItems = [calendarData getCalendarItemsFor:tourItem.attractionId forDate:date];
                if (cItems != nil && [cItems count] > 0) {
                  [calendarItems release];
                  calendarItems = [cItems retain];
                  calendarItem = [calendarItems objectAtIndex:0];
                  components2 = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:calendarItem.startTime];
                  h2 = [components2 hour];
                  m2 = [components2 minute];
                }
              }
              [components setHour:h2];
              [components setMinute:m2];
              if (i == 0) { // total time are calculated from park opening and not from right now
                startTime = [[calendar dateFromComponents:components] timeIntervalSince1970];
                timeFromBeginning = 0;
              } else {
                timeFromBeginning = [[calendar dateFromComponents:components] timeIntervalSince1970]-startTime;
              }
              [calendar release];
              tourItem.closed = (tourItem.waitingTime < 0);//YES;
            } else {
              tourItem.closed = (i >= nActive || tourItem.waitingTime < 0);
            }
          }
        }
        [calendarItems release];
        if (i > 0 && previousTourItem != nil) {
          if (previousTime > 0.0) timeFromBeginning = previousTime-startTime;
          if (i > n || walkToEntry) {
            timeFromBeginning += 60*(previousTourItem.walkingTime + 0.5); // ToDo: t.minWalkingDuration
          }
          if (i > n || !walkToEntry) {
            if (i == n) {
              if (tourItem.waitingTime > 0) timeFromBeginning += 60*tourItem.waitingTime;
              if (!tourItem.closed) timeFromBeginning += 60*([attraction isTrain]? [parkData getTrainAttractionDurationFrom:tourItem.entryAttractionId to:tourItem.exitAttractionId] : attraction.duration);
            } else if (i > n+1 || walkToEntry) {
              if (previousTourItem.waitingTime > 0) timeFromBeginning += 60*previousTourItem.waitingTime;
              if (!previousTourItem.closed) {
                Attraction *previousAttraction = [Attraction getAttraction:parkId attractionId:previousTourItem.attractionId];
                timeFromBeginning += 60*([previousAttraction isTrain]? [parkData getTrainAttractionDurationFrom:previousTourItem.entryAttractionId to:previousTourItem.exitAttractionId] : previousAttraction.duration);
              }
            }
          }
        }
      }
      tourItem.calculatedTimeInterval = timeFromBeginning;
    }
    previousTourItem = tourItem;
    previousTime = nextTime;
  }
}

-(double)getOverallTourDistance {
  double d = 0.0;
  for (TourItem *a in tourItems) d += a.distanceToNextAttraction;
  return d;
}

-(double)getRemainingTourDistance {
  double d = 0.0;
  int l = [tourItems count];
  if (l > 0) {
    ParkData *parkData = [ParkData getParkData:parkId];
    int i = [parkData.currentTrackData numberOfTourItemsDoneAndActive];
    if (i > 0) --i;
    while (i < l) {
      TourItem *a = [tourItems objectAtIndex:i];
      d += a.distanceToNextAttraction;
      ++i;
    }
  }
  return d;
}

-(int)getWalkingTime:(double)distance {
  ProfileData *profileData = [ProfileData getProfileData];
  double t = distance / profileData.avgWalkingSpeed * 60.0 / 1000.0;
  return (int)(t+0.5);
}

-(NSString *)getFormat:(int)walkingTime {
  if (walkingTime >= 60) {
    if (walkingTime%60 == 0) {
      NSString *s = NSLocalizedString(@"tour.duration.value1", nil);
      return [NSString stringWithFormat:s, walkingTime/60];
    } else {
      NSString *s = NSLocalizedString(@"tour.duration.value2", nil);
      return [NSString stringWithFormat:s, walkingTime/60, walkingTime%60];
    }
  } else {
    NSString *s = NSLocalizedString(@"tour.duration.value3", nil);
    return [NSString stringWithFormat:s, walkingTime];
  }
}

-(int)getOverallTourTime {
  if ([tourItems count] <= 1) return 0.0;
  TourItem *first = [tourItems objectAtIndex:0];
  TourItem *last = [tourItems lastObject];
  return (last.calculatedTimeInterval - first.calculatedTimeInterval)/60;
}

-(int)getRemainingTourTime {
  if ([tourItems count] == 0) return 0;
  TourItem *last = [tourItems lastObject];
  ParkData *parkData = [ParkData getParkData:parkId];
  if (parkData.currentTrackData == nil) {
    TourItem *first = [tourItems objectAtIndex:0];
    int time = (last.calculatedTimeInterval - first.calculatedTimeInterval)/60;
    return (time < 0)? 0 : time;
  } else {
    int time = (last.calculatedTimeInterval - [[NSDate date] timeIntervalSinceNow])/60;
    return (time < 0)? 0 : time;
  }
}

-(int)getAttractionCount:(NSString *)attractionId {
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  BOOL isTrain = [attraction isTrain];
  int count = 0;
  for (TourItem *tourItem in tourItems) {
    //NSString *tId = [parkData getRootAttractionId:tourItem.attractionId]; // e.g. park entry
    Attraction *tourAttraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
    if ([attraction.attractionId isEqualToString:tourAttraction.attractionId]) ++count;
    if (isTrain) {
      Attraction *exitAttraction = [Attraction getAttraction:parkId attractionId:tourItem.exitAttractionId];
      if (![tourAttraction.attractionId isEqualToString:exitAttraction.attractionId] && [attraction.attractionId isEqualToString:exitAttraction.attractionId]) ++count;
    }
  }
  return count;
}

@end
