//
//  PathesViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.02.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PathesViewController.h"
#import "UpdateViewController.h"
#import "CategoriesSelectionViewController.h"
#import "AttractionViewController.h"
#import "CalendarViewController.h"
#import "WaitTimeOverviewViewController.h"
#import "InfoListViewController.h"
#import "InAppSettingsViewController.h"
#import "ParkMainMenuViewController.h"
#import "CustomBadge.h"
#import "PathesCell.h"
#import "Attraction.h"
#import "Categories.h"
#import "ParkData.h"
#import "MenuData.h"
#import "MenuItem.h"
#import "WaitingTimeData.h"
#import "SettingsData.h"
#import "CalendarData.h"
#import "ImageData.h"
#import "Conversions.h"
#import "Colors.h"
#import "iRate.h"
#import "IPadHelper.h"

@implementation PathesViewController

static NSMutableArray *menuList = nil;
static NSMutableArray *sectionIndexTitles = nil;
static NSMutableArray *sectionIndex = nil;
static NSMutableArray *cellList = nil;
static BOOL parkSelectionEnabled = NO;
static NSString *parkGroupId = nil;
static NSString *selectedParkId = nil;
static BOOL updateViewCalled = NO;
static BOOL refreshParkData = NO;
static BOOL noMemoryWarningOccur = YES;
static BOOL viewInitialized = NO;

@synthesize delegate;
@synthesize backgroundView;
@synthesize contentController;
@synthesize parkLogoImageView;
@synthesize parkNameLabel, parkOpeningLabel, parkSelectionLabel;
@synthesize parkSelectionButton;
@synthesize theTableView;
@synthesize cellOwner;
@synthesize moreInfoLabel;
@synthesize bottomToolbar;
@synthesize refreshButton, calendarButton, moreInfoButton;
@synthesize activityIndicatorView;
@synthesize noDataLabel, accuracyLabel;
@synthesize enableWalkToAttraction;

-(void)addCellForMenuItem:(MenuItem *)menuItem settings:(SettingsData *)settings {
  NSString *attractionId = menuItem.menuId;
  [cellOwner loadNibNamed:@"PathesCell" owner:self];
  PathesCell *cell = (PathesCell *)cellOwner.cell;
  Attraction *attraction = [Attraction getAttraction:selectedParkId attractionId:attractionId];
  [cell setAttractionId:attractionId name:menuItem.name];
  //cell.locationLabel.text = [MenuData objectForKey:ATTRACTION_THEME_AREA at:[attraction getAttractionDetails:selectedParkId cache:YES]];
  cell.categoryLabel.text = attraction.typeName;
  cell.attractionNameLabel.textColor = [Colors hilightText];
  cell.categoryLabel.textColor = [Colors lightText];
  cell.backgroundColor = nil;//[Colors lightBlue];
  cell.iconView.backgroundColor = nil;//[Colors lightBlue];
  cell.iconView.imageView.backgroundColor = nil;//[Colors lightBlue];
  cell.distanceLabel.textColor = [Colors lightText];
  cell.waitingTimeLabel.textColor = [Colors lightText];
  cell.waitingTimeBadge.backgroundColor = [UIColor clearColor];
  cell.waitingTimeBadge.badgeCornerRoundness = 0.1;
  cell.waitingTimeBadge.badgeShining = YES;
  cell.waitingTimeBadge.contentScaleFactor = [[UIScreen mainScreen] scale];
  cell.waitingTimeBadge.badgeTextColor = [UIColor whiteColor];
  cell.waitingTimeBadge.badgeFrame = YES;
  cell.waitingTimeBadge.badgeFrameColor = [UIColor whiteColor];
  cell.waitingTimeBadge.badgeScaleFactor = 1.7;
  //cell.backgroundView.alpha = 0.7f;
  for (UIView *view in [theTableView subviews]) {
    //if ([view isKindOfClass:[UITableViewIndex class]]) {
    if ([view respondsToSelector:@selector(setIndexColor:)] && [[[view class] description] isEqualToString:@"UITableViewIndex"]) {
      [view performSelector:@selector(setIndexColor:) withObject:[Colors lightText]];
    }
  }
  [cellList addObject:cell];
}

-(void)updateCell:(PathesCell *)cell menuItem:(MenuItem *)menuItem attractionId:(NSString *)attractionId settings:(SettingsData *)settings {
  if (menuItem.badgeText == nil) {
    double distance;
    menuItem.badgeText = getCurrentDistance(selectedParkId, attractionId, &distance);
  }
  cell.distanceLabel.text = menuItem.badgeText;
  Attraction *attraction = [Attraction getAttraction:selectedParkId attractionId:attractionId];
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  if (attraction.waiting || [waitingTimeData isClosed:attractionId considerCalendar:NO]) {
    cell.waitingTimeLabel.hidden = NO;
    NSDate *date = [NSDate date];
    BOOL hasTimes = NO;
    if (settings.waitingTimesUpdate < 0) {
      cell.waitingTimeLabel.text = [NSString stringWithFormat:@"%@:\n%@", NSLocalizedString(@"waiting.time", nil), NSLocalizedString(@"waiting.time.disabled", nil)];
      hasTimes = YES;
    } else if ([parkData isEntryOrExitOfPark:attraction.attractionId]) {
      NSString *startingAndEndTimes = [attraction startingAndEndTimes:selectedParkId forDate:date maxTimes:-1];
      if (startingAndEndTimes != nil) {
        cell.waitingTimeLabel.text = [NSString stringWithFormat:@"%@:\n%@", NSLocalizedString(@"attraction.park.hours", nil), startingAndEndTimes];
        hasTimes = YES;
      }
    } else if (![attraction needToAttendAtOpeningTime:selectedParkId forDate:date]) {
      NSString *startingAndEndTimes = [attraction startingAndEndTimes:selectedParkId forDate:date maxTimes:4];
      if (startingAndEndTimes != nil) {
        if ([startingAndEndTimes isEqualToString:NSLocalizedString(@"attraction.today.closed", nil)]) cell.waitingTimeLabel.text = startingAndEndTimes;
        else if ([startingAndEndTimes isEqualToString:NSLocalizedString(@"wait.times.overview.unknown", nil)]) cell.waitingTimeLabel.text = [NSString stringWithFormat:@"%@:\n%@", NSLocalizedString(@"attraction.details.times", nil), startingAndEndTimes];
        else cell.waitingTimeLabel.text = [NSString stringWithFormat:@"%@:\n%@", NSLocalizedString(@"attraction.details.times.continuously", nil), startingAndEndTimes];
        hasTimes = YES;
      }
    } else {
      BOOL hasMoreThanOneTime = NO;
      NSString *startingTimes = [attraction startingTimes:selectedParkId forDate:date onlyNext4Times:YES hasMoreThanOneTime:&hasMoreThanOneTime];
      if (startingTimes != nil) {
        cell.waitingTimeLabel.text = [NSString stringWithFormat:@"%@:\n%@", ((hasMoreThanOneTime)? NSLocalizedString(@"attraction.details.times", nil) : NSLocalizedString(@"attraction.details.time", nil)), startingTimes];
        hasTimes = YES;
      }
    }
    if ([waitingTimeData isClosed:attractionId considerCalendar:YES]) {
      cell.waitingTimeButton.enabled = YES;
      cell.closedImageView.hidden = NO;
      cell.waitingTimeBadge.hidden = YES;
      cell.waitingTimeLabel.text = [NSString stringWithFormat:@"%@:\n\n\n\n\n", NSLocalizedString(@"waiting.time.closed", nil)];
    } else {
      cell.closedImageView.hidden = YES;
      WaitingTimeItem *waitingTimeItem = [waitingTimeData getWaitingTimeFor:attractionId];
      NSString *t = [waitingTimeData setBadge:cell.waitingTimeBadge forWaitingTimeItem:waitingTimeItem atIndex:-1 showAlsoOldTimes:NO];
      if (t == nil) {
        if (hasTimes && [cell.waitingTimeLabel.text hasSuffix:NSLocalizedString(@"wait.times.overview.unknown", nil)] && [cell.waitingTimeLabel.text hasPrefix:NSLocalizedString(@"attraction.details.times", nil)]) hasTimes = NO;
        if (hasTimes) {
          cell.waitingTimeButton.enabled = NO;
          cell.waitingTimeBadge.hidden = YES;
        } else {
          cell.waitingTimeButton.enabled = YES;
          cell.waitingTimeBadge.hidden = NO;
          cell.waitingTimeLabel.text = [NSString stringWithFormat:@"%@:\n\n\n\n\n", NSLocalizedString(@"waiting.time", nil)];
        }
      } else {
        cell.waitingTimeButton.enabled = NO;
        cell.waitingTimeBadge.hidden = YES;
        if (!hasTimes || ![t isEqualToString:NSLocalizedString(@"waiting.time.unknown", nil)]) cell.waitingTimeLabel.text = t;
      }
    }
  } else {
    cell.waitingTimeButton.enabled = NO;
    cell.closedImageView.hidden = YES;
    cell.waitingTimeBadge.hidden = YES;
    cell.waitingTimeLabel.hidden = YES;
  }
}

-(void)showBackgroundImage:(UIImage *)image {
  backgroundView.alpha = 0.0f;
  backgroundView.image = image;
  backgroundView.hidden = NO;
  [image release];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.5];
  backgroundView.alpha = 0.2f;
  [UIView commitAnimations];
}

-(void)createBackgroundImage:(id)sender {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *backgroundPath = [NSString stringWithFormat:@"%@/%@ - main background.jpg", [MenuData parkDataPath:selectedParkId], selectedParkId];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:backgroundPath]) {
    if (sender != nil) {
      UIImage *image = [[UIImage alloc] initWithContentsOfFile:backgroundPath];
      [self performSelectorOnMainThread:@selector(showBackgroundImage:) withObject:image waitUntilDone:NO];
    }
  } else {
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@ - background.jpg", [MenuData parkDataPath:selectedParkId], selectedParkId]];
    if (image != nil) {
      UIImage *bImage = [[ImageData makeBackgroundImage:image] retain];
      [UIImagePNGRepresentation(bImage) writeToFile:backgroundPath atomically:YES];
      [image release];
      if (sender != nil) [self performSelectorOnMainThread:@selector(showBackgroundImage:) withObject:bImage waitUntilDone:NO];
      else [bImage release];
    }
  }
  [pool release];
}

-(void)showParkName {
  if (parkNames.count == 0) {
    noDataLabel.text = NSLocalizedString(@"pathes.no.valid.park.data", nil);
    noDataLabel.hidden = NO;
    return;
  }
  noDataLabel.text = NSLocalizedString(@"pathes.no.park.data", nil);
  int i = 0;
  for (ParkData *parkData in parkDataList) {
    if ([parkData.parkId isEqualToString:selectedParkId]) break;
    ++i;
  }
  if (i < parkDataList.count) {
    parkNameLabel.text = [parkNames objectAtIndex:i];
    parkNameLabel.textColor = [Colors lightText];
    parkNameLabel.backgroundColor = [UIColor clearColor];
    parkNameLabel.hidden = NO;
    parkOpeningLabel.hidden = YES;
    parkLogoImageView.layer.masksToBounds = YES;
    parkLogoImageView.layer.cornerRadius = 5.0;
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[parkLogos objectAtIndex:i]];
    parkLogoImageView.image = image;
    [image release];
  }
}

-(void)showTutorial {
  if (tutorialView != nil) return;
  PathesCell *cell = [cellList objectAtIndex:0];
  if (cell != nil) {
    SettingsData *settings = [SettingsData getSettingsData];
    float width = UIScreen.mainScreen.applicationFrame.size.width;
    float height = UIScreen.mainScreen.applicationFrame.size.height;
    BOOL isPortraitScreen = [settings isPortraitScreen];
    if (!isPortraitScreen) {
      float f = width;
      width = height; height = f;
    }
    BOOL iPad = [IPadHelper isIPad];
    tutorialView = [[TutorialView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, height)];
    tutorialView.owner = self;
    parkSelectionLabel.alpha = 0.0f; // don't show
    CGRect rectInTableView = [theTableView convertRect:[theTableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] toView:self.view];
    float w = (isPortraitScreen)? 75.0f : 135.0f;
    if (iPad && isPortraitScreen) w = 115.0f;
    [tutorialView addFrame:CGRectMake(cell.contentView.frame.origin.x+55.0f, cell.contentView.frame.origin.y+rectInTableView.origin.y-2.0f, width-cell.contentView.frame.origin.x-cell.waitingTimeBadge.frame.size.width-w, cell.contentView.frame.size.height+5.0f) alignmentLeft:isPortraitScreen alignmentBottom:YES withText:NSLocalizedString(@"tutorial.wait.times.details.attraction", nil)];
    [tutorialView addFrame:CGRectMake(cell.contentView.frame.origin.x-2.0f, cell.contentView.frame.origin.y+rectInTableView.origin.y+1.0f+((iPad && !isPortraitScreen)? 0.0 : cell.contentView.frame.size.height), 40.0f, cell.contentView.frame.size.height+5.0f) alignmentLeft:YES alignmentBottom:(isPortraitScreen || iPad) withText:NSLocalizedString(@"tutorial.wait.times.details.favorites", nil)];
    [tutorialView addFrame:CGRectMake(width-cell.contentView.frame.origin.x-cell.waitingTimeBadge.frame.size.width-2.0f, rectInTableView.origin.y+cell.waitingTimeBadge.frame.origin.y+2.0f, cell.waitingTimeBadge.frame.size.width-2.0f, cell.waitingTimeBadge.frame.size.height-2.0f) alignmentLeft:NO alignmentBottom:YES withText:NSLocalizedString(@"tutorial.wait.times.details.wait.time", nil)];
    if (PATHES_EDITION != nil) {
      [tutorialView addFrame:CGRectMake(calendarButton.frame.origin.x-4.0f, bottomToolbar.frame.origin.y+calendarButton.frame.origin.y-4.0f, calendarButton.frame.size.width+8.0f, calendarButton.frame.size.height+8.0f) alignmentLeft:YES alignmentBottom:YES withText:NSLocalizedString(@"tutorial.wait.times.details.calendar", nil)];
    }
    //[tutorialView addLabelFrame:CGRectMake(10.0f, v.frame.size.height-140.0f, v.frame.size.width-20.0f, 120.0f) withText:NSLocalizedString(@"pathes.menu.visit.notes", nil)];
    [self.view addSubview:tutorialView];
    backgroundView.hidden = YES;
  }
}

-(void)loadParkData {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [parkDataList release];
  parkDataList = [[ParkData getParkDataListFor:parkGroupId] retain];
  int n = (int)[parkDataList count];
  [parkNames release];
  [parkLogos release];
  parkNames = [[NSMutableArray alloc] initWithCapacity:n];
  parkLogos = [[NSMutableArray alloc] initWithCapacity:n];
  for (ParkData *parkData in parkDataList) {
    NSDictionary *details = [MenuData getParkDetails:parkData.parkId cache:NO];
    NSString *parkName = [MenuData objectForKey:@"Parkname" at:details];
    if (parkName != nil) [parkNames addObject:parkName];
    NSString *parkLogo = [[MenuData parkDataPath:parkData.parkId] stringByAppendingPathComponent:[details objectForKey:@"Logo"]];
    if (parkLogo != nil) [parkLogos addObject:parkLogo];
  }
  parkSelectionEnabled = (n > 1);
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  if (parkData == nil && parkDataList != nil && n > 0) {
    parkData = [parkDataList objectAtIndex:0];
    [selectedParkId release];
    selectedParkId = [parkData.parkId retain];
  }
  if (parkData != nil) {
    [self performSelectorOnMainThread:@selector(showParkName) withObject:nil waitUntilDone:NO];
    if ([LocationData isLocationDataActive]) {
      LocationData *locData = [LocationData getLocationData];
      [locData registerViewController:self];
    }
    [parkData getCalendarData:self];
    //[self performSelectorOnMainThread:@selector(viewPark:) withObject:parkId waitUntilDone:YES];
    if (![parkData isInitialized]) {
      NSArray *parkIds = [MenuData getParkIds];
      for (NSString *pId in parkIds) {
        if (![pId isEqualToString:selectedParkId]) {
          ParkData *pData = [ParkData getParkData:pId];
          [pData clearCachedData];
        }
      }
      [parkData setupData];
    }
    [parkData getWaitingTimeData:self];
    //while (!waitingTimeData.initialized) [NSThread sleepForTimeInterval:0.75];
  }
  numberOfAvailableUpdates = (PATHES_EDITION != nil)? [ParkData availableUpdates:NO] : 0;
  [self performSelectorOnMainThread:@selector(updateParksData:) withObject:self waitUntilDone:NO];
  for (ParkData *parkData in parkDataList) {
    if (![selectedParkId isEqualToString:parkData.parkId]) [parkData getCalendarData];
  }
  [pool release];
}

-(void)updateParksData:(id)sender {
  if (!bottomToolbar.hidden && calendarButton.hidden) {
    ParkData *parkData = [ParkData getParkData:selectedParkId];
    CalendarData *calendarData = [parkData getCalendarData];
    if ([calendarData isEmpty]) return;
  }
  refreshButton.hidden = YES;
  if (updatesBadge != nil) {
    [updatesBadge removeFromSuperview];
    [updatesBadge release];
    updatesBadge = nil;
    [updatesBadgeButton removeFromSuperview];
    [updatesBadgeButton release];
    updatesBadgeButton = nil;
  }
  if (PATHES_EDITION != nil) {
    int d = [CalendarData dayOfToday];
    if (calendarButton.tag != d) {
      [calendarButton setImage:[CalendarData calendarIcon:NO] forState:UIControlStateNormal];
      calendarButton.tag = d;
    }
  }
  parkSelectionButton.hidden = !parkSelectionEnabled;
  [menuList removeAllObjects];
  if (numberOfAvailableUpdates > 0 || !noDataLabel.hidden) {
    updatesBadge = [[CustomBadge customBadgeWithString:(noDataLabel.hidden)? [NSString stringWithFormat:@"%d", numberOfAvailableUpdates] : @"!"] retain];
    updatesBadge.frame = CGRectMake(contentController.frame.size.width-updatesBadge.frame.size.width, contentController.frame.origin.y, updatesBadge.frame.size.width, updatesBadge.frame.size.height);
    [self.view addSubview:updatesBadge];
    updatesBadgeButton = [[UIButton alloc] initWithFrame:updatesBadge.frame];
    [updatesBadgeButton addTarget:self action:@selector(options:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:updatesBadgeButton];
  }
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  if (parkData == nil) {
    [activityIndicatorView stopAnimating];
    return;
  }
  Categories *categories = [Categories getCategories];
  const int n = [categories numberOfTypes];
  NSMutableSet *relevantTypeIDs = [[NSMutableSet alloc] initWithCapacity:n];
  NSMutableSet *relevantFavoriteTypeIDs = [[NSMutableSet alloc] initWithCapacity:n];
  NSDictionary *selectedCategories = [parkData selectedCategoriesForCategoryNames:[Attraction categoriesForParkId:selectedParkId]];
  [selectedCategories enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    if (object != nil && [object boolValue]) {
      if ([key hasPrefix:PREFIX_FAVORITES]) [relevantFavoriteTypeIDs addObjectsFromArray:[categories getTypeIds:[categories getCategoryId:[key substringFromIndex:[PREFIX_FAVORITES length]]]]];
      else [relevantTypeIDs addObjectsFromArray:[categories getTypeIds:[categories getCategoryId:key]]];
    }
  }];
  SettingsData *settings = [SettingsData getSettingsData];
  NSDictionary *allAttractions = [Attraction getAllAttractions:selectedParkId reload:NO];
  BOOL priorityDistance = ((PATHES_EDITION != nil && contentController.selectedSegmentIndex == 1) || (PATHES_EDITION == nil && contentController.selectedSegmentIndex == 2));
  BOOL allWithWaitingTime = [[selectedCategories objectForKey:ALL_WITH_WAIT_TIME] boolValue];
  NSEnumerator *i = [allAttractions objectEnumerator];
  while (TRUE) {
    Attraction *attraction = [i nextObject];
    if (attraction == nil) break;
    if ([attraction isClosed:parkData.parkId]) continue;
    NSString *attractionId = attraction.attractionId;
    BOOL addAttraction = (allWithWaitingTime && attraction.waiting);
    if (!addAttraction) addAttraction = [relevantTypeIDs containsObject:attraction.typeId];
    if (!addAttraction && [parkData isFavorite:attractionId]) addAttraction = [relevantFavoriteTypeIDs containsObject:attraction.typeId];
    if (addAttraction) {
      double distance = 0.0;
      MenuItem *m = [[MenuItem alloc] initWithMenuId:attractionId
                                               order:[NSNumber numberWithInt:0]
                                            distance:distance
                                           tolerance:0.0
                                                name:attraction.stringAttractionName
                                           imageName:[attraction imageName:selectedParkId]
                                              closed:NO];
      m.badgeText = getCurrentDistance(selectedParkId, attractionId , &distance);
      m.distance = distance;
      if (!m.closed) {
        if (priorityDistance) m.priorityDistance = YES;
        [menuList addObject:m];
      }
      [m release];
    }
  }
  [relevantFavoriteTypeIDs release];
  [relevantTypeIDs release];
  [menuList sortUsingSelector:@selector(compare:)];
  if (indexSelectorView != nil) {
    [indexSelectorView removeFromSuperview];
    [indexSelectorView release];
    indexSelectorView = nil;
  }
  [sectionIndexTitles removeAllObjects];
  [sectionIndex removeAllObjects];
  BOOL isPortraitScreen = [settings isPortraitScreen];
  float height = (isPortraitScreen)? UIScreen.mainScreen.applicationFrame.size.height : UIScreen.mainScreen.applicationFrame.size.width;
  if (PATHES_EDITION != nil) {
    bottomToolbar.hidden = NO;
    bottomToolbar.alpha = 1.0f;
    moreInfoLabel.hidden = NO;
    moreInfoLabel.alpha = 1.0f;
    accuracyLabel.hidden = NO;
    accuracyLabel.alpha = 1.0f;
    CGRect r = theTableView.frame;
    r.size.height = height-parkSelectionLabel.frame.size.height-contentController.frame.size.height-bottomToolbar.frame.size.height;
    theTableView.frame = r;
  } else {
    CGRect r = theTableView.frame;
    r.size.height = height-parkSelectionLabel.frame.size.height-contentController.frame.size.height;
    theTableView.frame = r;
  }
  if (!priorityDistance) {
    NSString *previousIndex = nil;
    int i = 0;
    for (MenuItem *menuItem in menuList) {
      if ([menuItem.name length] > 0) {
        NSString *t = ([menuItem.name length] > 1 && [menuItem.name hasPrefix:@"\""])? [menuItem.name substringWithRange:NSMakeRange(1, 1)] : [menuItem.name substringToIndex:1];
        t = [t uppercaseString];
        if (previousIndex == nil || ![t isEqualToString:previousIndex]) {
          if ([sectionIndexTitles count] > 0) [sectionIndexTitles addObject:@"\u2022"];
          previousIndex = t;
          [sectionIndexTitles addObject:previousIndex];
          [sectionIndex addObject:[NSNumber numberWithInt:i]];
        }
      }
      ++i;
    }
    if (sectionIndexTitles.count >= 15) {
      float h = (theTableView.frame.size.height-30.0f)/sectionIndexTitles.count;
      if (h < 9) {
        for (int i = [sectionIndexTitles count]-2; i > 0; i -= 2) {
          if ([[sectionIndexTitles objectAtIndex:i] isEqualToString:@"\u2022"]) [sectionIndexTitles removeObjectAtIndex:i];
        }
        h = (theTableView.frame.size.height-30.0f)/sectionIndexTitles.count;
      }
      if (h >= 9) {
        indexSelectorView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, theTableView.frame.origin.y+10.0f, 20.0f, theTableView.frame.size.height-20.0f)];
        indexSelectorView.layer.cornerRadius = indexSelectorView.frame.size.width/2;
        const float w = indexSelectorView.frame.size.width;
        int i = 0;
        for (NSString *string in sectionIndexTitles) {
          UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f, i*h+5.0f, w, h)] autorelease];
          label.backgroundColor = [UIColor clearColor];
          label.textColor = [Colors lightText];
          label.textAlignment = UITextAlignmentCenter;
          label.font = [UIFont boldSystemFontOfSize:11.0];
          label.text = string;
          [indexSelectorView addSubview:label];
          ++i;
        }
        [self.view addSubview:indexSelectorView];
      }
    } else {
      [sectionIndexTitles removeAllObjects];
      [sectionIndex removeAllObjects];
    }
  }
  calendarButton.enabled = YES;
  contentController.enabled = YES;
  moreInfoButton.enabled = YES;
  backgroundView.alpha = 0.2f;
  [theTableView reloadData];
  theTableView.hidden = NO;
  parkLogoImageView.alpha = 1.0f;
  parkSelectionButton.alpha = 1.0f;
  [LocationData setAccuracyLabel:accuracyLabel forParkData:parkData addTime:YES];
  Attraction *attraction = [Attraction getAttraction:selectedParkId attractionId:[parkData getEntryOfPark:nil]];
  NSString *startingAndEndTimes = [attraction startingAndEndTimes:selectedParkId forDate:nil maxTimes:-1];
  if (startingAndEndTimes != nil) {
    startingAndEndTimes = [attraction moreSpaceStartingAndEndTimes:startingAndEndTimes];
    parkOpeningLabel.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"attraction.park.hours", nil), startingAndEndTimes];
    parkOpeningLabel.hidden = NO;
  }
  /*BOOL refreshTutorial = NO;
  if (tutorialView != nil) {
    NSLog(@"refresh tutorial view");
    refreshTutorial = YES;
    [self endTutorial];
  }*/
  id arg = self;
  @synchronized([PathesViewController class]) {
    [cellList removeAllObjects];
    parkData = [ParkData getParkData:CORE_DATA_ID];
    if (noMemoryWarningOccur && [theTableView numberOfRowsInSection:0] > 0 && !parkData.tutorialWaitTimeViewed) {
      parkData.tutorialWaitTimeViewed = YES;
      [parkData save:YES];
      if (cellList.count == 0) {
        int i = 0;
        for (MenuItem *menuItem in menuList) {
          [self addCellForMenuItem:menuItem settings:settings];
          if (++i >= 10) break;
        }
      }
      arg = nil;
      [self performSelector:@selector(showTutorial) withObject:nil afterDelay:0.1];
    }
  }
  parkSelectionButton.enabled = YES;
  [activityIndicatorView stopAnimating];
  if (backgroundView.image == nil || sender != nil) [self performSelectorInBackground:@selector(createBackgroundImage:) withObject:arg];
}

-(void)changingWaitingTimeForAttractionId:(NSString *)attractionId {
  if (tutorialView != nil) [self endTutorial];
  scrollTablePosition = NO;
  WaitTimeOverviewViewController *controller = [[WaitTimeOverviewViewController alloc] initWithNibName:@"WaitTimeOverviewView" owner:self parkId:selectedParkId attractionId:attractionId];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

-(void)switchFavoriteForAttractionId:(NSString *)attractionId {
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  if ([parkData isFavorite:attractionId]) [parkData removeFavorite:attractionId];
  else [parkData addFavorite:attractionId];
  [theTableView reloadData];
}

#pragma mark -
#pragma mark - View lifecycle

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkGroupId:(NSString *)pId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    [parkGroupId release];
    parkGroupId = [pId retain];
    [selectedParkId release];
    parkSelectionEnabled = NO;
    checkDataOnlyFirstCall = YES;
    enableWalkToAttraction = (PATHES_EDITION == nil);
    NSArray *parkData = [ParkData getParkDataListFor:pId];
    if (parkData != nil && [parkData count] > 0) {
      ParkData *pData = [parkData objectAtIndex:0];
      selectedParkId = [pData.parkId retain];
    } else {
      selectedParkId = [pId retain];
    }
    [menuList release];
    menuList = [[NSMutableArray alloc] initWithCapacity:100];
    parkDataList = nil;
    parkNames = nil;
    parkLogos = nil;
    [sectionIndexTitles release];
    sectionIndexTitles = [[NSMutableArray alloc] initWithCapacity:30];
    [sectionIndex release];
    sectionIndex = [[NSMutableArray alloc] initWithCapacity:30];
    [cellList release];
    cellList = [[NSMutableArray alloc] initWithCapacity:100];
  }
  return self;
}

-(void)updateView:(NSArray *)mustUpdateParkGroupIds {
  updateViewCalled = YES;
  refreshParkData = YES;
  UpdateViewController *controller = [[UpdateViewController alloc] initWithNibName:@"UpdateView" owner:self];
  controller.mustUpdateParkGroupIds = mustUpdateParkGroupIds;
  controller.checkVersionInfo = YES;
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  viewInitialized = YES;
  refreshParkData = NO;
  scrollTablePosition = YES;
  self.view.backgroundColor = [Colors darkBlue];
  indicatorImage = [[UIImage imageNamed:@"indicator.png"] retain];
  favoriteStarImage = [[UIImage imageNamed:@"favorite_star.png"] retain];
  favoriteStarFrameImage = [[UIImage imageNamed:@"favorite_star_frame.png"] retain];
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(100.0f, 100.0f), NO, 0.0);
  blankImage = UIGraphicsGetImageFromCurrentImageContext();
  [blankImage retain];
  UIGraphicsEndImageContext();
  SettingsData *settings = [SettingsData getSettingsData];
  CGRect r = [[UIScreen mainScreen] bounds];
  BOOL isPortraitScreen = [settings isPortraitScreen];
  float width = (isPortraitScreen)? r.size.width : r.size.height;
  r = refreshButton.frame;
  if (PATHES_EDITION == nil) {
    refreshButton.frame = CGRectMake(5*width/8, r.origin.y, r.size.width, r.size.height);
    bottomToolbar.hidden = YES;
    moreInfoLabel.hidden = YES;
    accuracyLabel.hidden = YES;
    parkSelectionLabel.hidden = YES;
    CGRect r = theTableView.frame;
    float height = (isPortraitScreen)? UIScreen.mainScreen.applicationFrame.size.height : UIScreen.mainScreen.applicationFrame.size.width;
    r.size.height = height-parkSelectionLabel.frame.size.height-contentController.frame.size.height;
    theTableView.frame = r;
    r = backgroundView.frame;
    r.size.height += bottomToolbar.frame.size.height;
    backgroundView.frame = r;
  } else {
    refreshButton.frame = CGRectMake(3*width/8, r.origin.y, r.size.width, r.size.height);
    bottomToolbar.hidden = NO;
    bottomToolbar.tintColor = [Colors darkBlue];
    //moreInfoLabel.backgroundColor = nil;
    moreInfoLabel.textColor = [Colors hilightText];
    moreInfoLabel.text = NSLocalizedString(@"pathes.more.inpark", nil);
    parkSelectionLabel.text = NSLocalizedString(@"menu.park.selection", nil);
    parkSelectionLabel.textColor = [Colors hilightText];
    parkSelectionLabel.alpha = 0.0f;
    parkSelectionLabel.hidden = NO;
  }
  parkOpeningLabel.textColor = [Colors lightText];
  noDataLabel.text = NSLocalizedString(@"pathes.no.park.data", nil);
  noDataLabel.textColor = [Colors lightText];
  //theTableView.backgroundColor = [Colors darkBlue];
  //theTableView.backgroundView = nil;
  theTableView.separatorColor = [Colors lightBlue];
  theTableView.backgroundColor = [UIColor clearColor];
  theTableView.backgroundView = nil;
  theTableView.rowHeight = 64.0f;
  //theTableView.alpha = 0.7f;
  theTableView.opaque = NO;
  refreshControl = [[ODRefreshControl alloc] initInScrollView:theTableView];
  [refreshControl addTarget:self action:@selector(dropViewDidBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
  if (indexSelectorView != nil) {
    [indexSelectorView removeFromSuperview];
    [indexSelectorView release];
    indexSelectorView = nil;
  }
  contentController.tintColor = [Colors darkBlue];
  [contentController removeAllSegments];
  int idx = 0;
  if (PATHES_EDITION == nil) [contentController insertSegmentWithTitle:NSLocalizedString(@"back", nil) atIndex:idx++ animated:NO];
  [contentController insertSegmentWithTitle:NSLocalizedString(@"pathes.tab.0", nil) atIndex:idx animated:NO];
  [contentController insertSegmentWithTitle:[NSString stringWithFormat:NSLocalizedString(@"pathes.tab.1", nil), 0] atIndex:++idx animated:NO];
  [contentController insertSegmentWithTitle:[NSString stringWithFormat:NSLocalizedString(@"pathes.tab.2", nil), 0] atIndex:++idx animated:NO];
  if (PATHES_EDITION != nil) [contentController insertSegmentWithTitle:[NSString stringWithFormat:NSLocalizedString(@"options", nil), 0] atIndex:++idx animated:NO];
  previousContentSelection = (PATHES_EDITION != nil)? 0 : 1;
  contentController.selectedSegmentIndex = previousContentSelection;
  parkSelectionButton.hidden = !parkSelectionEnabled;
  moreInfoButton.title = NSLocalizedString(@"pathes.more.info", nil);
  noDataLabel.hidden = YES;
  parkSelectionButton.enabled = NO;
  calendarButton.hidden = YES;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(waitingTimeDataUpdated)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (checkDataOnlyFirstCall) {
    checkDataOnlyFirstCall = NO;
    NSArray *parkIds = [MenuData getParkIds];
    NSArray *missingParkIds = [ParkData getMissingParkIds:parkIds];
    if ([missingParkIds count] > 0) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"update.park.data.missing", nil)
                             message:NSLocalizedString(@"update.park.data", nil)
                             delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:nil];
      [dialog show];
      [dialog release];
      [self performSelector:@selector(updateView:) withObject:missingParkIds afterDelay:0.8];
      return;
    } else if ([parkIds count] == 0) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"update.no.parks.title", nil)
                             message:NSLocalizedString(@"update.no.parks", nil)
                             delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:nil];
      [dialog show];
      [dialog release];
      [self performSelector:@selector(updateView:) withObject:[NSArray arrayWithObject:selectedParkId] afterDelay:0.8];
      return;
    }
    noDataLabel.hidden = NO;
    NSMutableArray *mustUpdateParkIds = [[[NSMutableArray alloc] initWithCapacity:6] autorelease];
    for (ParkData *parkData in [ParkData getParkDataListFor:parkGroupId]) {
      noDataLabel.hidden = YES;
      NSString *pId = parkData.parkId;
      if (![parkIds containsObject:pId] || [ParkData checkIfUpdateIsNeeded:pId]) [mustUpdateParkIds addObject:pId];
    }
    if ([mustUpdateParkIds count] > 0) {
      NSString *t = [MenuData getParkName:[mustUpdateParkIds objectAtIndex:0] cache:YES];
      if (t == nil) t = NSLocalizedString(@"update.park.data.missing", nil);
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:t
                             message:NSLocalizedString(@"update.park.data", nil)
                             delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:nil];
      [dialog show];
      [dialog release];
      [self performSelector:@selector(updateView:) withObject:mustUpdateParkIds afterDelay:0.8];
      return;
    }
    SettingsData *settings = [SettingsData getSettingsData];
    if (settings.didDetectAppUpdate != nil) {
      BOOL b = [settings.skippedVersion isEqualToString:settings.didDetectAppUpdate];
      if (!settings.shouldSkipVersion || !b) {
        if (!b) {
          settings.skippedVersion = settings.didDetectAppUpdate;
          settings.shouldSkipVersion = NO;
        }
        iRate *rate = [iRate sharedInstance];
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"update.app.title", nil)
                               message:[NSString stringWithFormat:NSLocalizedString(@"update.app.text", nil), rate.applicationName, settings.didDetectAppUpdate]
                               delegate:self
                               cancelButtonTitle:NSLocalizedString(@"update.app.no", nil)
                               otherButtonTitles:NSLocalizedString(@"update.app.update", nil), NSLocalizedString(@"update.app.remind", nil), nil];
        dialog.tag = 2;
        [dialog show];
      }
    }
    [activityIndicatorView startAnimating];
    theTableView.hidden = YES;
    backgroundView.hidden = YES;
    [self performSelectorInBackground:@selector(loadParkData) withObject:nil];
  }
}

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  [super dismissModalViewControllerAnimated:animated];
  // Achtung: kritisch, wenn Memory-Warnungen im modalen Fenster aufgetreten sind
  if (viewInitialized && refreshParkData) {
    [activityIndicatorView startAnimating];
    if (updatesBadge != nil) {
      [updatesBadge removeFromSuperview];
      [updatesBadge release];
      updatesBadge = nil;
      [updatesBadgeButton removeFromSuperview];
      [updatesBadgeButton release];
      updatesBadgeButton = nil;
    }
    ParkData *parkData = [ParkData getParkData:selectedParkId];
    if (scrollTablePosition && parkData != nil && [parkData isInitialized] && [menuList count] > 0) {
      [theTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
    }
    theTableView.hidden = YES;
    indexSelectorView.hidden = YES;
  }
  if (refreshParkData) [self performSelectorInBackground:@selector(loadParkData) withObject:nil];
  else [self updateParksData:nil]; //   [theTableView reloadData];
  if (viewInitialized && refreshParkData) {
    noDataLabel.hidden = [ParkData hasParkDataFor:parkGroupId];
    if (updateViewCalled) [self performSelector:@selector(alertView:clickedButtonAtIndex:) withObject:nil afterDelay:1.5]; // Hack!
  }
  scrollTablePosition = YES;
  updateViewCalled = NO;
  refreshParkData = NO;
}

-(BOOL)shouldAutorotate {
  UIInterfaceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
  SettingsData *settings = [SettingsData getSettingsData];
  if ([settings isPortraitScreen]) return (interfaceOrientation == UIInterfaceOrientationPortrait);
  return ([settings isLeftHandedLandscapeScreen])? (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) : (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  SettingsData *settings = [SettingsData getSettingsData];
  if ([settings isPortraitScreen]) return UIInterfaceOrientationPortrait;
  if ([settings isLeftHandedLandscapeScreen]) return UIInterfaceOrientationLandscapeLeft;
  return UIInterfaceOrientationLandscapeRight;
}

#pragma mark -
#pragma mark Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (contentController.enabled || tutorialView != nil) {
    const int n = (int)menuList.count;
    SettingsData *settings = [SettingsData getSettingsData];
    refreshControl.enabled = (n > 0 && settings.waitingTimesUpdate >= 0);
    return n;
  }
  refreshControl.enabled = NO;
  return parkDataList.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return [self tableView:tableView titleForFooterInSection:section];
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  if (!contentController.enabled && tutorialView == nil) return nil;
  if (menuList.count == 0) return nil;
  SettingsData *settings = [SettingsData getSettingsData];
  if (settings.waitingTimesUpdate < 0) return nil;
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  double d = waitingTimeData.lastSuccessfulUpdate;
  if (d == 0) return [waitingTimeData lastAccessFailed]? NSLocalizedString(@"waiting.time.updated.failed", nil) : nil;
  NSDate *date = [NSDate dateWithTimeIntervalSince1970:d];
  if ([waitingTimeData lastAccessFailed]) return [NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"waiting.time.updated.failed.last", nil), [CalendarData stringFromDate:date considerTimeZoneAbbreviation:nil], [CalendarData stringFromTimeLong:date considerTimeZoneAbbreviation:nil]];
  return [NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"waiting.time.updated", nil), [CalendarData stringFromDate:date considerTimeZoneAbbreviation:nil], [CalendarData stringFromTimeLong:date considerTimeZoneAbbreviation:nil]];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (theTableView.hidden) return nil;
  if (!contentController.enabled && tutorialView == nil) {
    static NSString *cellId = @"ParkSelectionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (cell == nil) {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId] autorelease];
      cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
      cell.textLabel.backgroundColor = [UIColor clearColor];
      cell.textLabel.textColor = [Colors lightText];
      cell.textLabel.shadowColor = [UIColor blackColor];
      cell.textLabel.shadowOffset = CGSizeMake(0, 1);
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 0;
      cell.textLabel.textAlignment = UITextAlignmentCenter;
      cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
      cell.detailTextLabel.textAlignment = UITextAlignmentLeft;
      cell.detailTextLabel.backgroundColor = [UIColor clearColor];
      cell.detailTextLabel.textColor = [Colors lightText];
      cell.detailTextLabel.numberOfLines = 0;
      cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      cell.backgroundColor = [Colors lightBlue];
      UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicatorImage];
      cell.accessoryView = indicatorView;
      [indicatorView release];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      CGRect r = cell.imageView.frame;
      //cell.imageView.transform = CGAffineTransformIdentity;
      cell.imageView.frame = CGRectMake(r.origin.x, r.origin.y, 100.0f, 100.0f);
      cell.imageView.image = blankImage;
      AsynchronousImageView *imageView = [[AsynchronousImageView alloc] initWithFrame:CGRectMake(r.origin.x+2, r.origin.y+2, 100.0f, 100.0f)];
      imageView.layer.masksToBounds = YES;
      imageView.layer.cornerRadius = 7.0;
      imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
      imageView.layer.borderWidth = 2.0;
      imageView.tag = 3;
      [cell.contentView addSubview:imageView];
      [imageView release];
    }
    int row = (int)indexPath.row;
    cell.textLabel.text = [parkNames objectAtIndex:row];
    ParkData *parkData = [parkDataList objectAtIndex:row];
    //Attraction *attraction = [Attraction getAttraction:parkData.parkId attractionId:[parkData getEntryOfPark:nil]];
    NSArray *entrances = [Attraction getAttractions:parkData.parkId typeId:@"ENTRANCE"];
    if (entrances.count > 0) {
      cell.detailTextLabel.text = [[entrances objectAtIndex:0] entranceStartingAndEndTimes:parkData.parkId forDate:nil];
    } else cell.detailTextLabel.text = nil;
    [(AsynchronousImageView *)[cell.contentView viewWithTag:3] setImagePath:[parkLogos objectAtIndex:indexPath.row]];
    return cell;
  }
  SettingsData *settings = [SettingsData getSettingsData];
  int idx = (int)indexPath.row;
  if (idx >= menuList.count) return nil;
  if (idx == 0 && cellList.count == 0) {
    int i = 0;
    for (MenuItem *menuItem in menuList) {
      [self addCellForMenuItem:menuItem settings:settings];
      if (++i >= 10) break;
    }
  } else {
    for (int n = (int)cellList.count; n <= idx; ++n) {
      [self addCellForMenuItem:[menuList objectAtIndex:n] settings:settings];
    }
  }
  PathesCell *cell = [cellList objectAtIndex:idx];
  MenuItem *m = [menuList objectAtIndex:idx];
  [cell setIconPath:[[MenuData parkDataPath:selectedParkId] stringByAppendingPathComponent:m.imageName]];
  NSString *attractionId = m.menuId;
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  cell.favoriteView.image = [parkData isFavorite:attractionId]? favoriteStarImage : favoriteStarFrameImage;
  [self updateCell:cell menuItem:m attractionId:attractionId settings:settings];
  // clean up memory usage
  int i = 0;
  for (PathesCell *appCell in cellList) {
    if (i <= idx-20 || i >= idx+20) [appCell setIconPath:nil];
    ++i;
  }
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return (contentController.enabled || tutorialView != nil)? 74.0f : 106.0f;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView.alpha < 1.0f) return nil;
  if (!contentController.enabled && tutorialView == nil) {
    ParkData *parkData = [parkDataList objectAtIndex:indexPath.row];
    if ([ParkData checkIfUpdateIsNeeded:parkData.parkId]) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:[MenuData getParkName:parkData.parkId cache:YES]
                             message:NSLocalizedString(@"update.park.data", nil)
                             delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:nil];
      [dialog show];
      [dialog release];
      [self performSelector:@selector(updateView:) withObject:[NSArray arrayWithObject:parkData.parkId] afterDelay:0.8];
      return nil;
    }
  }
  return indexPath;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return [self tableView:tableView heightForFooterInSection:section];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return ([self tableView:tableView titleForFooterInSection:section] == nil)? 0.0f : 14.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  NSString *title = [self tableView:tableView titleForHeaderInSection:section];
  if (title == nil) return nil;
  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 14.0f)] autorelease];
  headerView.backgroundColor = [UIColor clearColor];
  UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, tableView.bounds.size.width-10.0f, 12.0f)] autorelease];
  headerLabel.textAlignment = UITextAlignmentCenter;
  headerLabel.font = [UIFont systemFontOfSize:10];
  headerLabel.text = title;
  headerLabel.textColor = [Colors lightText];
  headerLabel.backgroundColor = [UIColor clearColor];
  [headerView addSubview:headerLabel];
  return headerView;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  NSString *title = [self tableView:tableView titleForFooterInSection:section];
  if (title == nil) return nil;
  UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 14.0f)] autorelease];
  footerView.backgroundColor = [UIColor clearColor];
  UILabel *footerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, tableView.bounds.size.width-10.0f, 12.0f)] autorelease];
  footerLabel.textAlignment = UITextAlignmentCenter;
  footerLabel.font = [UIFont systemFontOfSize:10];
  footerLabel.text = title;
  footerLabel.textColor = [Colors lightText];
  footerLabel.backgroundColor = [UIColor clearColor];
  [footerView addSubview:footerLabel];
  return footerView;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tutorialView != nil) [self endTutorial];
  NSInteger idx = indexPath.row;
  if (contentController.enabled || tutorialView != nil) {
    MenuItem *selectedRow = [menuList objectAtIndex:idx];
    Attraction *attraction = [Attraction getAttraction:selectedParkId attractionId:selectedRow.menuId];
    AttractionViewController *controller = [[AttractionViewController alloc] initWithNibName:@"AttractionView" owner:self attraction:attraction parkId:selectedParkId];
    //AttractionRouteViewController *controller = [[AttractionRouteViewController alloc] initWithNibName:@"AttractionRouteView" owner:self parkId:selectedParkId attractionId:attraction.attractionId];
    controller.enableWalkToAttraction = enableWalkToAttraction;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
    scrollTablePosition = NO;
    [theTableView deselectRowAtIndexPath:indexPath animated:NO];
  } else {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    theTableView.alpha = 0.0f;
    parkNameLabel.alpha = 0.0f;
    parkOpeningLabel.alpha = 0.0f;
    parkSelectionLabel.alpha = 0.0f;
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    [UIView commitAnimations];
  }
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  if ([LocationData isLocationDataStarted]) {
    LocationData *locData = [LocationData getLocationData];
    [locData unregisterViewController];
  }
  if ([delegate currentParkModus] == ParkModusNotSelected) {
    [delegate dismissModalViewControllerAnimated:NO];
    [delegate loadBackView:nil];
  } else {
    [delegate dismissModalViewControllerAnimated:(sender != nil)];
  }
}

-(IBAction)options:(id)sender {
  if (PATHES_EDITION != nil) {
    if (tutorialView != nil) [self endTutorial];
    contentController.selectedSegmentIndex = 3;
    [self contentControllerValueChanged:sender];
  }
}

-(void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
  if (indexSelectorView != nil) {
    [indexSelectorView removeFromSuperview];
    [indexSelectorView release];
    indexSelectorView = nil;
  }
  SettingsData *settings = [SettingsData getSettingsData];
  float height = [settings isPortraitScreen]? UIScreen.mainScreen.applicationFrame.size.height : UIScreen.mainScreen.applicationFrame.size.width;
  if (animationID != nil/* || contentController.enabled*/ || tutorialView != nil) {
    //parkSelectionLabel.hidden = NO;
    //parkNameLabel.hidden = YES;
    parkOpeningLabel.hidden = YES;
    contentController.enabled = NO;
    CGRect r = theTableView.frame;
    theTableView.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, height-parkSelectionLabel.frame.size.height-contentController.frame.size.height);
    [theTableView reloadData];
  } else {
    NSIndexPath *idx = theTableView.indexPathForSelectedRow;
    [theTableView deselectRowAtIndexPath:idx animated:NO];
    CGRect r = theTableView.frame;
    theTableView.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, height-parkSelectionLabel.frame.size.height-contentController.frame.size.height-bottomToolbar.frame.size.height);
    parkSelectionButton.enabled = NO;
    ParkData *parkData = [parkDataList objectAtIndex:idx.row];
    if ([selectedParkId isEqualToString:parkData.parkId]) {
      [self updateParksData:nil];
    } else {
      [selectedParkId release];
      selectedParkId = [parkData.parkId retain];
      [activityIndicatorView startAnimating];
      theTableView.hidden = YES;
      UIImage *image = [[UIImage alloc] initWithContentsOfFile:[parkLogos objectAtIndex:idx.row]];
      parkLogoImageView.image = image;
      parkLogoImageView.alpha = 0.0f;
      [image release];
      [self performSelectorInBackground:@selector(loadParkData) withObject:nil];
    }
    parkNameLabel.text = [parkNames objectAtIndex:idx.row];
  }
  [theTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.5f];
  theTableView.alpha = 1.0f;
  if (animationID == nil && tutorialView == nil) {
    parkNameLabel.alpha = 1.0f;
    parkOpeningLabel.alpha = 1.0f;
  }
  [UIView commitAnimations];
}

-(IBAction)changePark:(id)sender {
  if (tutorialView != nil) [self endTutorial];
  if (updatesBadge != nil) {
    [updatesBadge removeFromSuperview];
    [updatesBadge release];
    updatesBadge = nil;
    [updatesBadgeButton removeFromSuperview];
    [updatesBadgeButton release];
    updatesBadgeButton = nil;
  }
  calendarButton.enabled = NO;
  moreInfoButton.enabled = NO;
  [UIView beginAnimations:@"SwitchPark" context:nil];
  [UIView setAnimationDuration:0.5f];
  theTableView.alpha = 0.0f;
  indexSelectorView.alpha = 0.0f;
  parkNameLabel.alpha = 0.0f;
  parkOpeningLabel.alpha = 0.0f;
  parkLogoImageView.alpha = 0.0f;
  parkSelectionButton.alpha = 0.0f;
  bottomToolbar.alpha = 0.0f;
  moreInfoLabel.alpha = 0.0f;
  accuracyLabel.alpha = 0.0f;
  backgroundView.alpha = 0.0f;
  parkSelectionLabel.alpha = 1.0f;
  [UIView setAnimationDelegate:self];
  [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
  [UIView commitAnimations];
}

-(IBAction)moreInfo:(id)sender {
  if (tutorialView != nil) [self endTutorial];
  InfoListViewController *controller = [[InfoListViewController alloc] initWithNibName:@"InfoListView" owner:self];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

-(IBAction)calendar:(id)sender {
  NSString *titleName = NSLocalizedString(@"calendar.title", nil);
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  CalendarData *calendarData = [parkData getCalendarData];
  if ([calendarData isEmpty]) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:titleName
                           message:NSLocalizedString(@"calendar.no", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  } else {
    CalendarViewController *controller = [[CalendarViewController alloc] initWithNibName:@"CalendarView" owner:self parkId:selectedParkId title:titleName];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(IBAction)refresh:(id)sender {
  previousContentSelection = (PATHES_EDITION == nil)? 1 : 0;
  contentController.selectedSegmentIndex = (PATHES_EDITION == nil)? 2 : 1;
  [self contentControllerValueChanged:self];
}

-(IBAction)contentControllerValueChanged:(id)sender {
  if (tutorialView != nil) [self endTutorial];
  int settingsIdx = 2;
  if (PATHES_EDITION == nil) {
    if (contentController.selectedSegmentIndex == 0) {
      [self loadBackView:sender];
      return;
    }
    settingsIdx = 3;
  } else {
    if (contentController.selectedSegmentIndex == 3) {
      InAppSettingsViewController *controller = [[InAppSettingsViewController alloc] initWithNibName:@"InAppSettingsView" owner:self];
      controller.preferenceTitle = NSLocalizedString(@"settings.title", nil);
      controller.viewOptionalSettings = NO;
      controller.viewChildPane = YES;
      controller.availableUpdates = (noDataLabel.hidden)? numberOfAvailableUpdates : -1;
      controller.parkData = [ParkData getParkData:selectedParkId];
      controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];  
      contentController.selectedSegmentIndex = previousContentSelection;
      refreshParkData = YES;
      scrollTablePosition = NO;
      return;
    }
  }
  if (contentController.selectedSegmentIndex == settingsIdx) {
    CategoriesSelectionViewController *controller = [[CategoriesSelectionViewController alloc] initWithNibName:@"CategoriesSelectionView" owner:self parkId:selectedParkId];
    NSArray *categoryNames = [Attraction categoriesForParkId:selectedParkId];
    controller.categoryNames = categoryNames;
    ParkData *parkData = [ParkData getParkData:selectedParkId];
    controller.selectedCategories = [parkData selectedCategoriesForCategoryNames:categoryNames];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
    contentController.selectedSegmentIndex = previousContentSelection;
    //refreshParkData = YES;
  } else if (contentController.selectedSegmentIndex != previousContentSelection) {
    if ([menuList count] > 0) {
      [theTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
    }
    [self updateParksData:nil];
    previousContentSelection = contentController.selectedSegmentIndex;
  }
}

#pragma mark -
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  //if (tutorialView == nil && [cellList count] > 0) [self showTutorial];
  if (alertView.tag == 2) {
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"update.app.no", nil)]) {
      SettingsData *settings = [SettingsData getSettingsData];
      settings.shouldSkipVersion = YES;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"update.app.update", nil)]) {
      iRate *rate = [iRate sharedInstance];
      //[rate openRatingsPageInAppStore];
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/app/id%d", rate.appStoreID]]];
    }
  }
}

#pragma mark -
#pragma mark Touches Responder

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  if (touch.view == indexSelectorView) {
    indexSelectorView.backgroundColor = [UIColor lightGrayColor];
    CGPoint p = [touch locationInView:touch.view];
    int n = [sectionIndexTitles count];
    if (n > 1) {
      float h = indexSelectorView.frame.size.height-10.0f;
      int i = ([[sectionIndexTitles objectAtIndex:1] isEqualToString:@"\u2022"])? round(0.5*(n-1)*(p.y-5.0f)/h) : floor(n*(p.y-5.0f)/h);
      if (i < 0) i = 0;
      else if (i >= [sectionIndex count]) i = [sectionIndex count]-1;
      i = [[sectionIndex objectAtIndex:i] intValue];
      [theTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
  }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *touch = [touches anyObject];
  if (touch.view == indexSelectorView) {
    indexSelectorView.backgroundColor = [UIColor lightGrayColor];
    CGPoint p = [touch locationInView:touch.view];
    int n = [sectionIndexTitles count];
    if (n > 1) {
      float h = indexSelectorView.frame.size.height-10.0f;
      int i = ([[sectionIndexTitles objectAtIndex:1] isEqualToString:@"\u2022"])? round(0.5*(n-1)*(p.y-5.0f)/h) : floor(n*(p.y-5.0f)/h);
      if (i < 0) i = 0;
      else if (i >= [sectionIndex count]) i = [sectionIndex count]-1;
      i = [[sectionIndex objectAtIndex:i] intValue];
      for (NSIndexPath *indexPath in [theTableView indexPathsForVisibleRows]) {
        if (indexPath.row == i) return;
      }
      [theTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
  }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  indexSelectorView.backgroundColor = [UIColor clearColor];
}

#pragma mark -
#pragma mark Location data delegate

-(void)didUpdateLocationData {
  if ((contentController.enabled || tutorialView != nil) && menuList.count > 0) {
    SettingsData *settings = [SettingsData getSettingsData];
    for (MenuItem *item in menuList) item.badgeText = nil;
    NSArray *visibleIndex = [theTableView indexPathsForVisibleRows];
    const BOOL refreshButtonNeeded = ((PATHES_EDITION != nil && contentController.selectedSegmentIndex == 1) || (PATHES_EDITION == nil && contentController.selectedSegmentIndex == 2));
    BOOL refresh = !refreshButton.hidden;
    double previousDistance = 0.0;
    @synchronized([PathesViewController class]) {
      for (NSIndexPath *indexPath in visibleIndex) {
        int idx = indexPath.row;
        MenuItem *m = [menuList objectAtIndex:idx];
        NSString *attractionId = m.menuId;
        double distance;
        m.badgeText = getCurrentDistance(selectedParkId, attractionId , &distance);
        if (m.distance != distance) {
          m.distance = distance;
          if (cellList.count > idx) {
            PathesCell *cell = [cellList objectAtIndex:idx];
            [self updateCell:cell menuItem:m attractionId:attractionId settings:settings];
          }
          if (refreshButtonNeeded && distance < previousDistance) {
            refresh = YES;
            break;
          }
        }
        previousDistance = distance;
      }
    }
    if (refresh) refreshButton.hidden = NO;
  }
}

-(void)didUpdateLocationError {
  accuracyLabel.hidden = YES;
}

#pragma mark -
#pragma mark Tutorial view delegate

-(void)endTutorial {
  NSLog(@"end tutorial view");
  [tutorialView removeFromSuperview];
  [tutorialView release];
  tutorialView = nil;
  parkNameLabel.alpha = 1.0f;
  parkOpeningLabel.alpha = 1.0f;
  parkLogoImageView.alpha = 1.0f;
  parkSelectionButton.alpha = 1.0f;
  contentController.alpha = 1.0f;
  bottomToolbar.alpha = 1.0f;
  moreInfoLabel.alpha = 1.0f;
  accuracyLabel.alpha = 1.0f;
  [self performSelectorInBackground:@selector(createBackgroundImage:) withObject:self];
}

#pragma mark -
#pragma mark Refresh control delegate

-(void)dropViewDidBeginRefreshing:(ODRefreshControl *)refreshCntrl {
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  [waitingTimeData performSelectorInBackground:@selector(enforceUpdate:) withObject:refreshControl];
  /*double delayInSeconds = 3.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    //[waitingTimeData performSelectorInBackground:@selector(enforceUpdate:) withObject:refreshCntrl];
    [refreshControl endRefreshing];
  });*/
}

#pragma mark -
#pragma mark Waiting time data delegate

-(void)waitingTimeDataUpdatedOnMainThread {
  if (contentController.enabled || tutorialView != nil) [self updateParksData:nil];
}

-(void)waitingTimeDataUpdated {
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  [parkData getCalendarData];
  [self performSelectorOnMainThread:@selector(waitingTimeDataUpdatedOnMainThread) withObject:nil waitUntilDone:NO];
}

-(void)refreshViewOnMainThread {
  if ((PATHES_EDITION == nil && contentController.selectedSegmentIndex == 2) || (PATHES_EDITION != nil && contentController.selectedSegmentIndex == 1)) [self refresh:self];
}

-(void)refreshView {
  [self performSelectorOnMainThread:@selector(refreshViewOnMainThread) withObject:nil waitUntilDone:NO];
}

#pragma mark -
#pragma mark Calendar data delegate

-(void)calendarDataUpdatedOnMainThread {
  calendarButton.hidden = NO;
  if (contentController.enabled || tutorialView != nil) [self updateParksData:nil];
}

-(void)calendarDataUpdated {
  [self performSelectorOnMainThread:@selector(calendarDataUpdatedOnMainThread) withObject:nil waitUntilDone:NO];
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  NSLog(@"Memory waring at Pathes View Controller");
  viewInitialized = NO;
  noMemoryWarningOccur = NO;
}

-(void)viewDidUnload {
  [super viewDidUnload];
  viewInitialized = NO;
  backgroundView = nil;
  contentController = nil;
  parkLogoImageView = nil;
  parkNameLabel = nil;
  parkOpeningLabel = nil;
  parkSelectionLabel = nil;
  parkSelectionButton = nil;
  theTableView = nil;
  cellOwner = nil;
  moreInfoLabel = nil;
  bottomToolbar = nil;
  refreshButton = nil;
  moreInfoButton = nil;
  calendarButton = nil;
  activityIndicatorView = nil;
  noDataLabel = nil;
  accuracyLabel = nil;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  ParkData *parkData = [ParkData getParkData:selectedParkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  [waitingTimeData unregisterViewController];
  CalendarData *calendarData = [parkData getCalendarData];
  [calendarData unregisterViewController];
  [indicatorImage release];
  indicatorImage = nil;
  [favoriteStarImage release];
  favoriteStarImage = nil;
  [favoriteStarFrameImage release];
  favoriteStarFrameImage = nil;
  [blankImage release];
  blankImage = nil;
  [parkDataList release];
  parkDataList = nil;
  [parkNames release];
  parkNames = nil;
  [parkLogos release];
  parkLogos = nil;
  [updatesBadge removeFromSuperview];
  [updatesBadge release];
  updatesBadge = nil;
  [refreshControl release];
  refreshControl = nil;
  [updatesBadgeButton removeFromSuperview];
  [updatesBadgeButton release];
  updatesBadgeButton = nil;
  [indexSelectorView removeFromSuperview];
  [indexSelectorView release];
  indexSelectorView = nil;
  [backgroundView release];
  [contentController release];
  [parkLogoImageView release];
  [parkNameLabel release];
  [parkOpeningLabel release];
  [parkSelectionLabel release];
  [parkSelectionButton release];
  [theTableView release];
  [cellOwner release];
  [moreInfoLabel release];
  [bottomToolbar release];
  [refreshButton release];
  [calendarButton release];
  [moreInfoButton release];
  [activityIndicatorView release];
  [noDataLabel release];
  [accuracyLabel release];
  [super dealloc];
}

@end
