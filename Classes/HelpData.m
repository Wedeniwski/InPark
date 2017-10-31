//
//  HelpData.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 11.12.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "HelpData.h"
#import "MenuData.h"
#import "SettingsData.h"

@implementation HelpData

@synthesize languagePath;
@synthesize keys;
@synthesize pages, titles;

-(void)parseData:(NSString *)data {
  NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:20];
  NSMutableDictionary *p = [[NSMutableDictionary alloc] initWithCapacity:20];
  NSMutableDictionary *ttls = [[NSMutableDictionary alloc] initWithCapacity:20];
  if (data != nil) {
    NSArray *sections = [data componentsSeparatedByString:@"<h1><a name=\""];
    for (NSString *pgs in sections) {
      NSArray *a = [pgs componentsSeparatedByString:@"</a></h1>"];
      if ([a count] == 2) {
        NSArray *b = [[a objectAtIndex:0] componentsSeparatedByString:@"\">"];
        if ([b count] == 2) {
          NSString *key = [b objectAtIndex:0];
          [array addObject:key];
          [ttls setObject:[b objectAtIndex:1] forKey:key];
          [p setObject:[a objectAtIndex:1] forKey:key];
        }
      }
    }
  }
  keys = array;
  pages = p;
  titles = ttls;
}

-(id)init {
  self = [super init];
  if (self != nil) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *bPath = [MenuData dataPath];
    SettingsData *settings = [SettingsData getSettingsData];
    languagePath = [[settings languagePath] retain];
    NSString *filePath = [[bPath stringByAppendingPathComponent:languagePath] stringByAppendingPathComponent:@"tutorial.txt"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
      filePath = [[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:languagePath] stringByAppendingPathComponent:@"tutorial.txt"];
      if ([fileManager fileExistsAtPath:filePath]) {
        NSLog(@"Tutorial found in main bundle");
      }
    }
    NSError *error = nil;
    NSString *data = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error != nil) NSLog(@"Tutorial path %@ could not be read (%@)", filePath, [error localizedDescription]);
    [self parseData:data];
    [data release];
    [pool release];
  }
  return self;
}

-(id)initWithContent:(NSString *)data {
  self = [super init];
  if (self != nil) {
    SettingsData *settings = [SettingsData getSettingsData];
    languagePath = [[settings languagePath] retain];
    [self parseData:data];
  }
  return self;
}

-(void)dealloc {
  [languagePath release];
  languagePath = nil;
  [keys release];
  keys = nil;
  [pages release];
  pages = nil;
  [titles release];
  titles = nil;
  [super dealloc];
}

static HelpData *helpData = nil;
+(HelpData *)getHelpData:(BOOL)reload {
  @synchronized([HelpData class]) {
    if (helpData == nil || reload) {
      [helpData release];
      helpData = [[HelpData alloc] init];
    } else {
      SettingsData *settings = [SettingsData getSettingsData];
      if (![helpData.languagePath isEqualToString:[settings languagePath]]) {
        [helpData release];
        helpData = [[HelpData alloc] init];
      }
    }
  }
  return helpData;
}

+(HelpData *)getHelpData {
  return [HelpData getHelpData:NO];
}

@end
