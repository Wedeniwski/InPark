//
//  InParkAppDelegate.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 26.11.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "InParkAppDelegate.h"
#import "InParkViewController.h"
#import "ParkSelectionViewController.h"
#import "PathesViewController.h"
#import "GeneralInfoViewController.h"
#import "SettingsData.h"
#import "LocationData.h"
#import "MenuData.h"
#import "ParkData.h"
//#import "WaitingTimeData.h"
#import "ImageData.h"
#import "Update.h"

@implementation InParkAppDelegate

@synthesize viewController;
@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

+(void)initialize {
  iRate *rate = [iRate sharedInstance];
  //rate.appStoreID = 428834617;
  rate.promptAtLaunch = YES;
  rate.previewMode = NO;
  rate.useAllAvailableLanguages = NO;
  rate.onlyPromptIfLatestVersion = YES;
  rate.promptAgainForEachNewVersion = YES;
  rate.usesPerWeekForPrompt = 0.0f;
  rate.remindPeriod = 1.0f;
  rate.verboseLogging = NO;
  if (PATHES_EDITION == nil) {
    rate.usesUntilPrompt = 10;
    rate.eventsUntilPrompt = 10;
    rate.daysUntilPrompt = 10.0f;
  } else {
    rate.usesUntilPrompt = 5;
    rate.eventsUntilPrompt = 5;
    rate.daysUntilPrompt = 5.0f;
    if ([@"ep" isEqualToString:PATHES_EDITION]) rate.appStoreID = 512713549U;
  }
}

static BOOL updateCompleted = NO;
-(void)updateOnlineData {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [ParkData availableUpdates:NO];
  updateCompleted = YES;
  [Attraction getAllAttractions:nil reload:YES]; // improve initialization
  [pool release];
}

-(void)dataMigration { // moving downloaded data from /Documents to /Library/Cache
  // ToDo: remove in later version
  // this major design change was introduced v1.3.2 Feb 7, 2012 because of Apple restriction
  // this major design change was extended in v1.5.3 Sept 23, 2012 because of http://developer.apple.com/library/ios/#qa/qa1719/_index.html
  // It is not possible to exclude data from backups on iOS 5.0. If your app must support iOS 5.0, then you will need to store your app data in Caches to avoid that data being backed up. iOS will delete your files from the Caches directory when necessary, so your app will need to degrade gracefully if it's data files are deleted.
  NSString *oldDataPath = [MenuData oldestDataPath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  for (int i = 0; i < 2; ++i) {
    if ([fileManager fileExistsAtPath:oldDataPath]) {
      NSError *error = nil;
      NSString *dPath = [MenuData newDataPath];
      NSLog(@"Data migration: moving path from %@ to %@", oldDataPath, dPath);
      [fileManager moveItemAtPath:oldDataPath toPath:dPath error:&error];
      if (error != nil) {
        NSLog(@"Error moving path from %@ to %@ - %@", oldDataPath, dPath, [error localizedDescription]);
        error = nil;
      }
      [Update addSkipBackupAttributeToItemAtURL:dPath];  // do not backup downloaded data
      [fileManager removeItemAtPath:oldDataPath error:&error];
      if (error != nil) NSLog(@"Error removing path %@ - %@", oldDataPath, [error localizedDescription]);
    }
    oldDataPath = [MenuData oldDataPath];
  }
  oldDataPath = [ImageData oldestAdditionalImagesDataPath];
  for (int i = 0; i < 2; ++i) {
    if ([fileManager fileExistsAtPath:oldDataPath]) {
      NSError *error = nil;
      NSString *dPath = [ImageData newAdditionalImagesDataPath];
      NSLog(@"Data migration: moving path from %@ to %@", oldDataPath, dPath);
      [fileManager moveItemAtPath:oldDataPath toPath:dPath error:&error];
      if (error != nil) {
        NSLog(@"Error moving path from %@ to %@ - %@", oldDataPath, dPath, [error localizedDescription]);
        error = nil;
      }
      [Update addSkipBackupAttributeToItemAtURL:dPath];  // do not backup downloaded data
      [fileManager removeItemAtPath:oldDataPath error:&error];
      if (error != nil) NSLog(@"Error removing path %@ - %@", oldDataPath, [error localizedDescription]);
    }
    oldDataPath = [ImageData oldAdditionalImagesDataPath];
  }
}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  updateCompleted = NO;
  SettingsData *settings = [SettingsData getSettingsData];
  iRate *rate = [iRate sharedInstance];
  rate.delegate = self;
  // ToDo: more test for app version check needed
  //if (!settings.shouldSkipVersion && ![rate shouldPromptForRating:self] && [rate shouldPromptForRating:nil]) [rate promptIfNetworkAvailable:nil];
  [self dataMigration];
  [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
  [self performSelectorInBackground:@selector(updateOnlineData) withObject:nil];
  if ([settings isLocationServiceEnabled]) {
    LocationData *locData = [LocationData getLocationData];
    [locData start];
  }
  NSString *appVersion = [SettingsData getAppVersion];
  NSString *knownVersion = settings.releaseNotesKnown;
  BOOL viewReleaseNotes = NO;
  if (knownVersion == nil) {
    NSLog(@"first call of the App - init elementary data");
    [ImageData save:[NSDictionary dictionary]];
    [settings setDefaultLanguageSettings];
    if (PATHES_EDITION == nil) viewReleaseNotes = YES;
  } else if (![knownVersion isEqualToString:appVersion]) {
    if (knownVersion.length >= 3 && appVersion.length >= 3 && [[knownVersion substringToIndex:3] isEqualToString:[appVersion substringToIndex:3]]) {
      rate.declinedThisVersion = YES;
    }
    if (PATHES_EDITION == nil) viewReleaseNotes = YES;
  }
  if (viewReleaseNotes) {
    InParkViewController *controller = [[InParkViewController alloc] initWithNibName:@"InParkView" bundle:nil];
    controller.releaseNotesViewed = YES;
    viewController = controller;
  } else {
    if (PATHES_EDITION != nil) {
      viewController = [[PathesViewController alloc] initWithNibName:@"PathesView" owner:nil parkGroupId:PATHES_EDITION];
    } else {
      viewController = [[ParkSelectionViewController alloc] initWithNibName:@"ParkSelectionView"];
    }
  }
  CGRect frame = window.frame;
  frame.origin.y = 20.0;
  frame.size.height -= 20;
  viewController.view.frame = frame;
  if (!viewReleaseNotes) while (!updateCompleted) [NSThread sleepForTimeInterval:0.75];
  [window addSubview:viewController.view];
  window.rootViewController = viewController;
  [window makeKeyAndVisible];
  if (viewReleaseNotes) {
    [settings setReleaseNotesKnown:appVersion];
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:viewController fileName:@"version.txt" title:@"release.notes"];
    [viewController presentViewController:controller animated:YES completion:nil];
    [controller release];
  } else if (settings.releaseNotesKnown == nil) {
    [settings setReleaseNotesKnown:appVersion];
  }
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


-(void)applicationWillEnterForeground:(UIApplication *)application {
  NSLog(@"app will enter foreground");
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}

#pragma mark -
#pragma mark iVersionDelegate methods

-(void)iRateCouldNotConnectToAppStore:(NSError *)error {
  NSLog(@"iRate could not connect to AppStore");
}

-(BOOL)iRateShouldPromptForRating {
	//don't show prompt, just open app store
	//[[iRate sharedInstance] openRatingsPageInAppStore];
	return YES;
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

-(void)dealloc {
  [window release];
  [viewController release];
  [super dealloc];
}

@end
