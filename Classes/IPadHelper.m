//
//  IPadHelper.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 12.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "IPadHelper.h"

@implementation IPadHelper

+(BOOL)isIPad {
  if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_3_2) {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) return YES;
  }
  return NO;
}

+(NSString *)addIPadSuffixWhenOnIPad:(NSString *)resourceName {
  return ([IPadHelper isIPad])? [resourceName stringByAppendingString:@"-iPad"] : resourceName;
}

@end
