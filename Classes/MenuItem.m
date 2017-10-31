//
//  MenuItem.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "MenuItem.h"

@implementation MenuItem

@synthesize menuId, name, imageName, fileName;
@synthesize order;
@synthesize distance, tolerance;
@synthesize closed, priorityDistance;
@synthesize badgeText;

-(id)initWithMenuId:(NSString *)mId order:(NSNumber *)o distance:(double)d tolerance:(double)t name:(NSString *)n imageName:(NSString *)i closed:(BOOL)c {
  self = [super init];
  if (self != nil) {
    menuId = (mId == nil)? @"" : [mId retain];
    order = (o == nil)? 0 : [o intValue];
    distance = d;
    tolerance = t;
    name = (n == nil)? @"" : [n retain];
    imageName = (i == nil)? @"" : [i retain];
    fileName = nil;
    closed = c;
    priorityDistance = NO;
    badgeText = nil;
  }
  return self;
}

-(void)dealloc {
  [menuId release];
  menuId = nil;
  [name release];
  name = nil;
  [imageName release];
  imageName = nil;
  [fileName release];
  fileName = nil;
  [badgeText release];
  badgeText = nil;
  [super dealloc];
}

-(NSComparisonResult)compare:(MenuItem *)otherMenuItem {
  if (closed && !otherMenuItem.closed) return 1;
  if (!closed && otherMenuItem.closed) return -1;
  if (priorityDistance) {
    if (distance < otherMenuItem.distance) return -1;
    if (distance > otherMenuItem.distance) return 1;
    if (tolerance < otherMenuItem.tolerance) return -1;
    if (tolerance > otherMenuItem.tolerance) return 1;
  }
  if (order < otherMenuItem.order) return -1;
  if (order > otherMenuItem.order) return 1;
  NSString *s = name;
  NSString *t = otherMenuItem.name;
  if ([s hasPrefix:@"\""] && [s length] > 1) s = [s substringFromIndex:1];
  if ([t hasPrefix:@"\""] && [t length] > 1) t = [t substringFromIndex:1];
  return [s caseInsensitiveCompare:t];
}

@end
