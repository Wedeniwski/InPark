//
//  ParkMainMenuViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 16.07.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ParkMainMenuViewController.h"
#import "AttractionListViewController.h"
#import "Attraction.h"
#import "MenuItem.h"
#import "MenuData.h"
#import "ParkData.h"
#import "TourData.h"
#import "ImageData.h"
#import "Categories.h"
#import "ProfileData.h"
#import "SettingsData.h"
#import "HelpData.h"
#import "TourViewController.h"
#import "NavigationViewController.h"
#import "InAppSettingsViewController.h"
#import "GeneralInfoListViewController.h"
#import "GeneralInfoViewController.h"
#import "ParkingViewController.h"
#import "CalendarViewController.h"
#import "PathesViewController.h"
#import "CoverFlowItemView.h"
#import "AsynchronousImageView.h"
#import "CustomBadge.h"
#import "MSLabel.h"
#import "IPadHelper.h"
#import "Colors.h"

typedef enum {
  ParkMainMenuViewControllerAlertViewProfileSet
} ParkMainMenuViewControllerAlertView;

@implementation ParkMainMenuViewController

// sigletons because of receiving memory warnings and destructor
static BOOL viewInitialized = NO;
static ParkModus parkModus = ParkModusNotSelected;
static BOOL selectedMenuCoverflowView = YES;
static NSMutableArray *menuList = nil;
static NSArray *interestingAttractions = nil;
static NSString *parkId = nil;
static NSString *parkName = nil;
static NSString *selectedList2 = nil;  // level 2 of selected park, e.g. Attraktionen
static NSString *selectedList3 = nil;  // level 3 of selected park, e.g. Kategorien

@synthesize delegate;
@synthesize theTableView;
@synthesize topNavigationBar;
@synthesize titleOfTable;
@synthesize loadDataActivityIndicator;
@synthesize helpButton;
@synthesize bottomToolbar;
@synthesize backgroundView;
@synthesize interestingLabel;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    parkModus = ParkModusNotSelected;
    selectedMenuCoverflowView = NO;
    [parkId release];
    parkId = [pId retain];
    [parkName release];
    parkName = [[MenuData getParkName:parkId cache:YES] retain];
    [menuList release];
    menuList = [[NSMutableArray alloc] initWithCapacity:20];
    [interestingAttractions release];
    interestingAttractions = nil;
    selectedList2 = nil;
    [selectedList3 release];
    selectedList3 = nil;
  }
  return self;
}

-(NSString *)currentLocationStatus {
  if (![LocationData isLocationDataInitialized]) return NSLocalizedString(@"location.init", nil);
  LocationData *locData = [LocationData getLocationData];
  if (locData.lastError != nil) return NSLocalizedString(@"location.error", nil);
  if (![LocationData isLocationDataActive]) return NSLocalizedString(@"location.init", nil);
  if (locData.lastUpdatedLocation == nil) return NSLocalizedString(@"location.unknown", nil);
  ParkData *parkData = [ParkData getParkData:parkId];
  if ([parkData isCurrentlyInsidePark]) return (parkData.currentTrackData != nil)? NSLocalizedString(@"location.active.in.park", nil) : NSLocalizedString(@"location.in.park", nil);
  if (parkData.currentTrackData != nil) return NSLocalizedString(@"location.active.not.in.park", nil);
  return NSLocalizedString(@"location.not.in.park", nil);
}

-(void)waitUntilarkDataIsInitializedBeforePresenting:(UIViewController *)controller {
  NSLog(@"wait until park data initialization is completed");
  ParkData *parkData = [ParkData getParkData:parkId];
  while (![parkData isInitialized]) [NSThread sleepForTimeInterval:0.3];
  [self performSelectorOnMainThread:@selector(checkIfParkDataIsInitializedBeforePresenting:) withObject:controller waitUntilDone:NO];
}

-(void)enableViewController:(BOOL)enable {
  if (enable) {
    [loadDataActivityIndicator stopAnimating];
    theTableView.alpha = 1.0f;
    backButton.enabled = YES;
    switchViewButton.enabled = YES;
    waitingTimeOverviewButton.enabled = YES;
    helpButton.enabled = YES;
    for (UIBarButtonItem *button in bottomToolbar.items) button.enabled = YES;
    bottomToolbar.alpha = 1.0f;
  } else {
    [loadDataActivityIndicator startAnimating];
    backButton.enabled = NO;
    switchViewButton.enabled = NO;
    waitingTimeOverviewButton.enabled = NO;
    helpButton.enabled = NO;
    for (UIBarButtonItem *button in bottomToolbar.items) button.enabled = NO;
    bottomToolbar.alpha = 0.5f;
    theTableView.alpha = 0.5f;
  }
}

-(void)checkIfParkDataIsInitializedBeforePresenting:(UIViewController *)controller {
  ParkData *parkData = [ParkData getParkData:parkId];
  if ([parkData isInitialized]) {
    [self enableViewController:YES];
    if (controller != nil) {
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];
    } else {
      [self loadBackView:nil];
    }
  } else {
    [self enableViewController:NO];
    [NSThread detachNewThreadSelector:@selector(waitUntilarkDataIsInitializedBeforePresenting:) toTarget:self withObject:controller];
    //[self performSelectorInBackground:@selector(waitUntilarkDataIsInitializedBeforePresenting:) withObject:controller];
  }
}

-(void)updateParksData {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [menuList removeAllObjects];
  if (selectedList2 == nil)
    if (parkModus != ParkModusVisit) titleOfTable.title = parkName;
    else titleOfTable.title = [self currentLocationStatus]; //NSLocalizedString(@"park.info", nil);
  else if ([selectedList2 isEqualToString:@"MENU_ATTRACTION"]) titleOfTable.title = NSLocalizedString(@"menu.button.attractions", nil);
  else if ([selectedList2 isEqualToString:@"MENU_THEME_AREA"]) titleOfTable.title = NSLocalizedString(@"menu.button.areas", nil);
  else if ([selectedList2 isEqualToString:@"MENU_RESTROOM"]) titleOfTable.title = NSLocalizedString(@"menu.button.restroom", nil);
  else if ([selectedList2 isEqualToString:@"MENU_SERVICE"]) titleOfTable.title = NSLocalizedString(@"menu.button.service", nil);
  else if ([selectedList2 isEqualToString:@"MENU_SHOP"]) titleOfTable.title = NSLocalizedString(@"menu.button.shop", nil);
  else if ([selectedList2 isEqualToString:@"MENU_DINING"]) titleOfTable.title = NSLocalizedString(@"menu.button.dining", nil);
  else if ([selectedList2 isEqualToString:@"MENU_GENERAL"]) {
    titleOfTable.title = NSLocalizedString(@"menu.button.general", nil);
    MenuItem *m = [[MenuItem alloc] initWithMenuId:@"MENU_CALENDAR" order:[NSNumber numberWithInt:1] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"menu.button.calendar", nil) imageName:nil closed:NO];
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MENU_WAITING_TIME" order:[NSNumber numberWithInt:2] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"main.menu.wait.time", nil) imageName:nil closed:NO];
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MENU_OPENING_TIMES" order:[NSNumber numberWithInt:3] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"menu.opening.times", nil) imageName:nil closed:NO];
    m.fileName = @"opening.txt";
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MENU_PRICES" order:[NSNumber numberWithInt:4] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"menu.prices", nil) imageName:nil closed:NO];
    m.fileName = @"prices.txt";
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MENU_DIRECTIONS" order:[NSNumber numberWithInt:5] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"menu.directions", nil) imageName:nil closed:NO];
    m.fileName = @"directions.txt";
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MENU_INFORMATION" order:[NSNumber numberWithInt:6] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"menu.information", nil) imageName:nil closed:NO];
    m.fileName = @"information.txt";
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MENU_ATTRACTION_BY_PROFILE" order:[NSNumber numberWithInt:7] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"menu.interesting.attractions", nil) imageName:nil closed:NO];
    [menuList addObject:m];
    [m release];
    NSString *website = [[MenuData getParkDetails:parkId cache:YES] objectForKey:@"Website"];
    if (website != nil) {
      m = [[MenuItem alloc] initWithMenuId:@"MENU_OFFICIAL_WEBSITE" order:[NSNumber numberWithInt:8] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"menu.official.website", nil) imageName:nil closed:NO];
      m.fileName = website;
      [menuList addObject:m];
      [m release];
    }
  }
  if (parkModus == ParkModusNotSelected) {
    MenuItem *m = [[MenuItem alloc] initWithMenuId:@"MAIN_MENU_INFORMATION" order:[NSNumber numberWithInt:1] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"main.menu.information", nil) imageName:@"information.png" closed:NO];
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MAIN_MENU_VISIT" order:[NSNumber numberWithInt:2] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"main.menu.visit", nil) imageName:@"visit.png" closed:NO];
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MAIN_MENU_WAIT_TIMES_OVERVIEW" order:[NSNumber numberWithInt:3] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"main.menu.wait.time", nil) imageName:@"wait_time.png" closed:NO];
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MAIN_MENU_NEWS" order:[NSNumber numberWithInt:4] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"main.menu.news", nil) imageName:@"news.png" closed:NO];
    [menuList addObject:m];
    [m release];
    m = [[MenuItem alloc] initWithMenuId:@"MAIN_MENU_PROFILE" order:[NSNumber numberWithInt:5] distance:0.0 tolerance:0.0 name:NSLocalizedString(@"main.menu.profile", nil) imageName:@"profile.png" closed:NO];
    [menuList addObject:m];
    [m release];
  } else {
    __block NSMutableSet *all = [[NSMutableSet alloc] initWithCapacity:300];
    NSNumber *ZERO = [NSNumber numberWithInt:0];
    NSNumber *NINENINE = [NSNumber numberWithInt:99];
    BOOL checkThemeArea = ([selectedList2 isEqualToString:@"MENU_THEME_AREA"] || [selectedList3 isEqualToString:@"MENU_ATTRACTION_BY_THEME_AREA"]
                           || [selectedList3 isEqualToString:@"MENU_SHOP_BY_THEME_AREA"] || [selectedList3 isEqualToString:@"MENU_DINING_BY_THEME_AREA"]
                           || [selectedList3 isEqualToString:@"MENU_SERVICE_BY_THEME_AREA"] || [selectedList3 isEqualToString:@"MENU_RESTROOM_BY_THEME_AREA"]);
    BOOL checkCategory = ([selectedList3 isEqualToString:@"MENU_SHOP_BY_THEME_AREA"] || [selectedList3 isEqualToString:@"MENU_DINING_BY_THEME_AREA"]
                          || [selectedList3 isEqualToString:@"MENU_RESTROOM_BY_THEME_AREA"] || [selectedList2 isEqualToString:@"MENU_RESTROOM"]
                          || [selectedList3 isEqualToString:@"MENU_SERVICE_BY_THEME_AREA"] || [selectedList2 isEqualToString:@"MENU_SERVICE"]
                          || [selectedList2 isEqualToString:@"MENU_SHOP"] || [selectedList2 isEqualToString:@"MENU_DINING"]
                          || [selectedList2 isEqualToString:@"MENU_ATTRACTION"] || [selectedList3 isEqualToString:@"MENU_ATTRACTION_BY_THEME_AREA"]);
    BOOL checkAllCategories = ([selectedList2 isEqualToString:@"MENU_ATTRACTION"] || [selectedList3 isEqualToString:@"MENU_ATTRACTION_BY_THEME_AREA"]);
    NSString *kindOf = titleOfTable.title;
    NSDictionary *frequency = [Attraction categories:kindOf parkId:parkId checkThemeArea:checkThemeArea checkCategory:checkCategory checkAllCategories:checkAllCategories];
    if (frequency != nil) {
      BOOL setImages = YES;
      Categories *categories = [Categories getCategories];
      for (NSString *name in frequency) {
        NSString *imageName = [categories getIconForTypeIdOrCategoryId:[categories getCategoryOrTypeId:name]];
        if (imageName == nil || [imageName hasPrefix:@"small_button_"]) {
          setImages = NO;
          break;
        }
      }
      [frequency enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        NSArray *n = object;
        if (!checkThemeArea && (checkCategory || checkAllCategories) && n != nil) [all addObjectsFromArray:n];
        NSString *name = (n != nil)? [NSString stringWithFormat:@"%@ (%d)", key, [n count]] : key;
        NSString *imageName = (setImages)? [categories getIconForTypeIdOrCategoryId:[categories getCategoryOrTypeId:key]] : nil;
        MenuItem *m = [[MenuItem alloc] initWithMenuId:key order:NINENINE distance:0.0 tolerance:0.0 name:name imageName:imageName closed:NO];
        [menuList addObject:m];
        [m release];
      }];
    }
    if ([all count] > 0) {
      NSString *key = NSLocalizedString(@"all", nil);
      NSString *name = [NSString stringWithFormat:@"%@ (%d)", key, [all count]];
      MenuItem *m = [[MenuItem alloc] initWithMenuId:key order:ZERO distance:0.0 tolerance:0.0 name:name imageName:nil closed:NO];
      [menuList addObject:m];
      [m release];
      name = key = NSLocalizedString(@"map", nil);
      m = [[MenuItem alloc] initWithMenuId:key order:ZERO distance:0.0 tolerance:0.0 name:name imageName:nil closed:NO];
      [menuList addObject:m];
      [m release];
      name = key = NSLocalizedString(@"distance", nil);
      m = [[MenuItem alloc] initWithMenuId:key order:ZERO distance:0.0 tolerance:0.0 name:name imageName:nil closed:NO];
      [menuList addObject:m];
      [m release];
    }
    [all release];
    [menuList sortUsingSelector:@selector(compare:)];
  }
  [self enableViewController:YES];
  [theTableView reloadData];
  [pool release];
}

-(void)buttonViewModus:(BOOL)initBottomToolbar {
  if (initBottomToolbar) {
    NSMutableArray *m = [[NSMutableArray alloc] initWithArray:bottomToolbar.items];
    //[m setArray:bottomToolbar.items];
    if (parkModus == ParkModusInformation) {
      [m removeObjectAtIndex:[bottomToolbar.items count]-2];
      /*UIButton *button = [menuButtons lastObject];
      [button removeFromSuperview];
      [menuButtons removeLastObject];
      UILabel *label = [menuLabels lastObject];
      [label removeFromSuperview];
      [menuLabels removeLastObject];*/
    } else if (parkModus == ParkModusVisit) {
      [m removeLastObject];
    }
    bottomToolbar.items = m;
    [m release];
  }
  BOOL c = selectedMenuCoverflowView;
  switchViewButton.hidden = NO;
  waitingTimeOverviewButton.hidden = c;
  fitsToProfileBadge.hidden = c;
  for (UIButton *button in menuButtons) button.hidden = c;
  for (UILabel *label in menuLabels) label.hidden = c;
  openFlowLeftTitleLabel.hidden = !c;
  openFlowTitleLabel.hidden = !c;
  openFlowRightTitleLabel.hidden = !c;
  coverFlowView.hidden = !c;
  if (c) {
    [switchViewButton setBackgroundImage:[UIImage imageNamed:@"list.png"] forState:UIControlStateNormal];
  } else {
    [switchViewButton setBackgroundImage:[UIImage imageNamed:@"coverflow.png"] forState:UIControlStateNormal];
  }
}

-(ParkModus)currentParkModus {
  return parkModus;
}

#pragma mark -
#pragma mark View lifecycle

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  if (parkModus == ParkModusVisit) {
    LocationData *locData = [LocationData getLocationData];
    [locData registerViewController:self];
  } else if (parkModus == ParkModusNotSelected) {
    if (viewInitialized) [self updateRecommendations];
  }
  [localImageData release];
  localImageData = [[ImageData localData] retain];
  [super dismissModalViewControllerAnimated:animated];
}

-(void)showBackgroundImage:(UIImage *)image {
  backgroundView.image = image;
  [image release];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.5];
  backgroundView.alpha = 0.3;
  [UIView commitAnimations];
}

-(void)setButtonImages:(NSArray *)images {
  int l = [menuButtons count];
  for (int i = 0; i < l; ++i) {
    UIButton *button = [menuButtons objectAtIndex:i];
    [button setBackgroundImage:[images objectAtIndex:i] forState:UIControlStateNormal];
  }
}

-(void)createBackgroundImage {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSDictionary *parkDetails = [[MenuData getParkDetails:parkId cache:YES] retain];
  NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:9];
  Attraction *attraction = [Attraction getMostRecommendedAttraction:parkId];
  NSString *imagePath = (attraction != nil)? [attraction imagePath:parkId] : nil;
  UIImage *image = (imagePath != nil)? [UIImage imageWithContentsOfFile:imagePath] : nil;
  [images addObject:(image != nil)? image : [UIImage imageNamed:@"information.png"]];
  [images addObject:[CalendarData calendarIcon:YES]];
  image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Attraktionen"]]];
  [images addObject:(image != nil)? image : [UIImage imageNamed:@"information.png"]];
  image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Themenbereiche"]]];
  [images addObject:(image != nil)? image : [UIImage imageNamed:@"information.png"]];
  image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Gastro"]]];
  [images addObject:(image != nil)? image : [UIImage imageNamed:@"information.png"]];
  image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Shops"]]];
  [images addObject:(image != nil)? image : [UIImage imageNamed:@"information.png"]];
  image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_WC"]]];
  [images addObject:(image != nil)? image : [UIImage imageNamed:@"information.png"]];
  image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Service"]]];
  [images addObject:(image != nil)? image : [UIImage imageNamed:@"information.png"]];
  [images addObject:[UIImage imageNamed:@"general.png"]];
  [self performSelectorOnMainThread:@selector(setButtonImages:) withObject:images waitUntilDone:YES];
  [images release];
  NSString *backgroundPath = [NSString stringWithFormat:@"%@/%@ - main background.jpg", [MenuData parkDataPath:parkId], parkId];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:backgroundPath]) {
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:backgroundPath];
    [self performSelectorOnMainThread:@selector(showBackgroundImage:) withObject:image waitUntilDone:NO];
  } else {
    image = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@ - background.jpg", [MenuData parkDataPath:parkId], parkId]];
    if (image != nil) {
      UIImage *bImage = [[ImageData makeBackgroundImage:image] retain];
      [UIImagePNGRepresentation(bImage) writeToFile:backgroundPath atomically:YES];
      [image release];
      [self performSelectorOnMainThread:@selector(showBackgroundImage:) withObject:bImage waitUntilDone:NO];
    }
  }
  [parkDetails release];
  [pool release];
}

-(void)updateRecommendations {
  SettingsData *settings = [SettingsData getSettingsData];
  BOOL isPortraitScreen = [settings isPortraitScreen];
  BOOL iPad = [IPadHelper isIPad];
  [interestingAttractions release];
  interestingAttractions = [[Attraction getAllRecommendedAttractions:parkId] retain];
  int n = [interestingAttractions count];
  if (n > 0) {
    interestingLabel.textColor = [Colors lightText];
    interestingLabel.font = [UIFont systemFontOfSize:(iPad)? 14.0f : 10.0f];
    interestingLabel.text = [NSString stringWithFormat:NSLocalizedString(@"menu.interesting.attractions.hint", nil), n];
    if (iPad || !isPortraitScreen) [interestingLabel sizeToFit];
  } else interestingLabel.hidden = YES;
  logoImageView.numberOfCovers = n+1;
}

-(void)viewDidLoad {
  [super viewDidLoad];
  viewInitialized = YES;
  self.view.backgroundColor = [Colors darkBlue];
  SettingsData *settings = [SettingsData getSettingsData];
  BOOL isPortraitScreen = [settings isPortraitScreen];
  BOOL iPad = [IPadHelper isIPad];
  titleOfTable.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  backButton = [titleOfTable.leftBarButtonItem retain];
  titleOfTable.leftBarButtonItem = nil;
  HelpData *helpData = [HelpData getHelpData];
  helpButton.hidden = ![helpData.keys containsObject:@"Park_Item"];
  CGRect r = backgroundView.frame;
  backgroundView.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height+bottomToolbar.frame.size.height);
  //titleOfTable.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  theTableView.backgroundColor = [UIColor clearColor];
  theTableView.backgroundView = nil;
  //theTableView.rowHeight = 64.0f;
  theTableView.alpha = 0.7f;
  theTableView.opaque = NO;
  theTableView.autoresizingMask = UIViewAutoresizingNone;
  r = [[UIScreen mainScreen] bounds];
  float screenWidth = (isPortraitScreen)? r.size.width : r.size.height;
  float screenHeight = (isPortraitScreen)? r.size.height : r.size.width;
  float width = (iPad)? 600.0f : 200.0f;
  localImageData = [[ImageData localData] retain];
  if (iPad) {
    if (isPortraitScreen) {
      logoImageView = [[CoverFlowView alloc] initWithFrame:CGRectMake(0.0f, interestingLabel.frame.origin.y+interestingLabel.frame.size.height, screenWidth, width+133.0f)];
      interestingTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, logoImageView.frame.origin.y+logoImageView.frame.size.height-98.0f, logoImageView.frame.size.width, 16.0f)];
    } else {
      logoImageView = [[CoverFlowView alloc] initWithFrame:CGRectMake(2.0f, topNavigationBar.frame.size.height+2.0f+(screenHeight-topNavigationBar.frame.size.height-width-24.0f)/2.0f, width+94.0f, width+94.0f)];
      interestingTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, logoImageView.frame.origin.y+logoImageView.frame.size.height-78.0f, logoImageView.frame.size.width, 16.0f)];
    }
  } else {
    if (isPortraitScreen) {
      width = (screenHeight >= 568.0f)? 270.0f : 180.0f;
      logoImageView = [[CoverFlowView alloc] initWithFrame:CGRectMake(0.0f, interestingLabel.frame.origin.y+interestingLabel.frame.size.height, screenWidth, width+33.0f)];
      interestingTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, logoImageView.frame.origin.y+logoImageView.frame.size.height-28.0f, logoImageView.frame.size.width, 12.0f)];
    } else {
      logoImageView = [[CoverFlowView alloc] initWithFrame:CGRectMake(2.0f, topNavigationBar.frame.size.height+2.0f+(screenHeight-topNavigationBar.frame.size.height-width-24.0f)/2.0f, width+33.0f, width+33.0f)];
      interestingTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, logoImageView.frame.origin.y+logoImageView.frame.size.height-28.0f, logoImageView.frame.size.width, 12.0f)];
    }
  }
  logoImageView.dataSource = self;
  logoImageView.coverflowDelegate = self;
  logoImageView.coverSize = CGSizeMake(width, width);
  [self updateRecommendations];
  [self.view addSubview:logoImageView];
  interestingTitleLabel.textColor = [Colors lightText];
  interestingTitleLabel.font = [UIFont systemFontOfSize:(iPad)? 14.0f : 10.0f];
  interestingTitleLabel.backgroundColor = [UIColor clearColor];
  interestingTitleLabel.textAlignment = NSTextAlignmentCenter;
  interestingTitleLabel.text = parkName;
  [self.view addSubview:interestingTitleLabel];
  [self.view bringSubviewToFront:theTableView];
  theTableView.frame = CGRectMake(theTableView.frame.origin.x, theTableView.frame.origin.y+screenHeight, theTableView.frame.size.width, screenHeight-topNavigationBar.frame.size.height-bottomToolbar.frame.size.height-10.0f);
  theTableView.hidden = NO;
  topNavigationBar.tintColor = [Colors darkBlue];
  bottomToolbar.tintColor = [Colors darkBlue];
  bottomToolbar.hidden = YES;
  fitsToProfileBadge = nil;
  menuButtons = [[NSMutableArray alloc] initWithCapacity:10];
  menuLabels = [[NSMutableArray alloc] initWithCapacity:10];
  const int numberOfButtons = 8;
  const float imageWidth = (iPad)? ((isPortraitScreen)? 200.0f : 144.0f) : 84.0f;
  const float labelHeight = 21.0f;
  const float top = (isPortraitScreen)? backgroundView.frame.origin.y+32.0f : backgroundView.frame.origin.y;
  int row = (isPortraitScreen)? 3 : 5;
  width = (screenWidth-row*imageWidth)/(row+1);
  float height = (isPortraitScreen)? (screenHeight-40.0f-bottomToolbar.frame.size.height-topNavigationBar.frame.size.height-((numberOfButtons+row-1)/row)*(imageWidth+labelHeight))/(row+1) : (screenHeight-bottomToolbar.frame.size.height-topNavigationBar.frame.size.height-((numberOfButtons+row-1)/row)*(imageWidth+labelHeight))/(row+1);
  //if (iPad && !isPortraitScreen) height -= 13.0f;
  for (int i = 0, x = 0; i <= numberOfButtons; ++i, ++x) {
    //if ((iPad && i == 2) || (!iPad && ((isPortraitScreen && i == 2) || (!isPortraitScreen && i == 3)))) {
    if (i == 2) {
      //switchViewButton = [[UIButton alloc] initWithFrame:CGRectMake(width*(x%row+1)+imageWidth*(x%row+1)-32.0f, backgroundView.frame.origin.y+height*(x/row+1)+(labelHeight+imageWidth)*(x/row), 32.0f, 32.0f)];
      switchViewButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth-37.0f, topNavigationBar.frame.size.height+5.0f, 32.0f, 32.0f)];
      switchViewButton.layer.masksToBounds = YES;
      switchViewButton.layer.cornerRadius = 7.0;
      switchViewButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
      switchViewButton.layer.borderWidth = 2.0;
      switchViewButton.contentMode = UIViewContentModeScaleAspectFit;
      [switchViewButton addTarget:self action:@selector(switchView:) forControlEvents:UIControlEventTouchUpInside];
      [self.view addSubview:switchViewButton];
      waitingTimeOverviewButton = [[UIButton alloc] initWithFrame:CGRectMake(width*(x%row+1)+imageWidth*(x%row), top+height*(x/row+1)+(labelHeight+imageWidth)*(x/row), imageWidth, imageWidth)];
      waitingTimeOverviewButton.contentMode = UIViewContentModeScaleAspectFit;
      waitingTimeOverviewButton.alpha = 0.7f;
      [waitingTimeOverviewButton setBackgroundImage:[UIImage imageNamed:@"wait_time2.png"] forState:UIControlStateNormal];
      [waitingTimeOverviewButton addTarget:self action:@selector(waitingTimeOverview:) forControlEvents:UIControlEventTouchUpInside];
      [self.view addSubview:waitingTimeOverviewButton];
      MSLabel *label = [[MSLabel alloc] initWithFrame:CGRectMake(width*(x%row+1)+imageWidth*(x%row), top+(height+imageWidth)*(x/row+1)+labelHeight*(x/row), imageWidth, labelHeight+((iPad)? 10.0f : 5.0f))];
      label.numberOfLines = 2;
      label.font = [UIFont boldSystemFontOfSize:(iPad)? 14.0f : 9.0f];
      label.lineHeight = (iPad)? 15 : 10;
      label.textColor = [Colors lightText];
      label.textAlignment = UITextAlignmentCenter;
      label.verticalAlignment = MSLabelVerticalAlignmentTop;
      label.backgroundColor = [UIColor clearColor];
      label.text = NSLocalizedString(@"main.menu.wait.time", nil);
      [self.view addSubview:label];
      [menuLabels addObject:label];
      [label release];
      continue;
    }
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(width*(x%row+1)+imageWidth*(x%row), top+height*(x/row+1)+(labelHeight+imageWidth)*(x/row), imageWidth, imageWidth)];
    if (i != 1) {
      button.layer.masksToBounds = YES;
      button.layer.cornerRadius = 7.0f;
      if (i != 0) {
        button.layer.borderColor = [UIColor lightGrayColor].CGColor;
        button.layer.borderWidth = 2.0f;
      }
    }
    MSLabel *label = [[MSLabel alloc] initWithFrame:CGRectMake(width*(x%row+1)+imageWidth*(x%row), top+(height+imageWidth)*(x/row+1)+labelHeight*(x/row), imageWidth, labelHeight+((iPad)? 10.0f : 5.0f))];
    label.font = [UIFont boldSystemFontOfSize:(iPad)? 14.0f : 9.0f];
    label.lineHeight = (iPad)? 15 : 10;
    label.textColor = [Colors lightText];
    label.textAlignment = UITextAlignmentCenter;
    label.verticalAlignment = MSLabelVerticalAlignmentTop;
    label.backgroundColor = [UIColor clearColor];
    BOOL setCustomBadge = NO;
    switch (i) {
      case 0:
        r = button.frame;
        const float w = (iPad)? 14.0f : 9.0f;
        fitsToProfileBadge = [[CustomBadge customBadgeWithString:@""] retain];
        fitsToProfileBadge.backgroundColor = [UIColor clearColor];
        fitsToProfileBadge.badgeCornerRoundness = 0.1;
        fitsToProfileBadge.badgeShining = YES;
        fitsToProfileBadge.contentScaleFactor = [[UIScreen mainScreen] scale];
        fitsToProfileBadge.badgeFrame = YES;
        fitsToProfileBadge.badgeFrameColor = [UIColor lightGrayColor];
        fitsToProfileBadge.badgeScaleFactor = 1.7;
        fitsToProfileBadge.badgeInsetColor = [Colors lightBlue];
        fitsToProfileBadge.frame = CGRectMake(r.origin.x-w, r.origin.y-w, r.size.width+2*w, r.size.height+2*w);
        [self.view addSubview:fitsToProfileBadge];
        button.frame = CGRectMake(r.origin.x+w, r.origin.y+w, r.size.width-2*w, r.size.height-2*w);
        [button addTarget:self action:@selector(recommendationView:) forControlEvents:UIControlEventTouchUpInside];
        label.text = NSLocalizedString(@"menu.interesting.attractions", nil);
        //label.numberOfLines = 2;
        break;
      case 1:
        button.alpha = 0.7f;
        [button addTarget:self action:@selector(calendarView:) forControlEvents:UIControlEventTouchUpInside];
        label.text = NSLocalizedString(@"menu.button.calendar", nil);
        break;
      case 2:
      case 3:
        [button addTarget:self action:@selector(attractionsView:) forControlEvents:UIControlEventTouchUpInside];
        label.text = NSLocalizedString(@"menu.button.attractions", nil);
        if (!isPortraitScreen) ++x;
        break;
      case 4:
        [button addTarget:self action:@selector(themeAreasView:) forControlEvents:UIControlEventTouchUpInside];
        label.text = NSLocalizedString(@"menu.button.areas", nil);
        break;
      case 5:
        [button addTarget:self action:@selector(cateringView:) forControlEvents:UIControlEventTouchUpInside];
        label.text = NSLocalizedString(@"menu.button.dining", nil);
        break;
      case 6:
        [button addTarget:self action:@selector(shopsView:) forControlEvents:UIControlEventTouchUpInside];
        label.text = NSLocalizedString(@"menu.button.shop", nil);
        break;
      case 7:
        [button addTarget:self action:@selector(restroomView:) forControlEvents:UIControlEventTouchUpInside];
        label.text = NSLocalizedString(@"menu.button.restroom", nil);
        break;
      case 8:
        [button addTarget:self action:@selector(serviceView:) forControlEvents:UIControlEventTouchUpInside];
        label.text = NSLocalizedString(@"menu.button.service", nil);
        break;
      case 9:
        button.alpha = 0.7f;
        [button addTarget:self action:@selector(generalView:) forControlEvents:UIControlEventTouchUpInside];
        label.text = NSLocalizedString(@"menu.button.general", nil);
        break;
      default:
        break;
    }
    [self.view addSubview:button];
    [self.view addSubview:label];
    if (setCustomBadge) [self.view addSubview:newsBadge];
    [menuButtons addObject:button];
    [menuLabels addObject:label];
    [button release];
    [label release];
  }
  //float leftBorder = (isPortraitScreen)? 7.5f : -15.0f;
  float coverWidth = (iPad)? 600.0f : ((isPortraitScreen)? 270.0f : 180.0f);
  float deltaToLabel = (iPad)? ((isPortraitScreen)? 10.0f : -10.0f) : ((isPortraitScreen)? 12.0f : 20.0f);
  float yPosFlow = (isPortraitScreen)? topNavigationBar.frame.size.height+15.0f+backgroundView.frame.size.height/4.0f : topNavigationBar.frame.size.height+9.0f+deltaToLabel;
  if (!iPad && isPortraitScreen) yPosFlow -= (screenHeight < 568.0f)? 50.0f : 10.0f;
  float leftBorder = (isPortraitScreen)? 2.0f : 100.0f;
  float rightBorder = (isPortraitScreen)? 2.0f : 100.0f;
  openFlowLeftTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftBorder, yPosFlow-deltaToLabel, screenWidth-leftBorder-rightBorder, (iPad)? 17.0f : 12.0f)];
  openFlowLeftTitleLabel.font = [UIFont boldSystemFontOfSize:(iPad)? 14.0f : 10.0f];
  openFlowLeftTitleLabel.textColor = [Colors lightText];
  openFlowLeftTitleLabel.textAlignment = UITextAlignmentLeft;
  openFlowLeftTitleLabel.backgroundColor = [UIColor clearColor];
  openFlowTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftBorder, yPosFlow-deltaToLabel-4.0f, screenWidth-leftBorder-rightBorder, (iPad)? 25.0f : 20.0f)];
  openFlowTitleLabel.font = [UIFont boldSystemFontOfSize:(iPad)? 20.0f : 15.0f];
  openFlowTitleLabel.textColor = [Colors lightText];
  openFlowTitleLabel.textAlignment = UITextAlignmentCenter;
  openFlowTitleLabel.backgroundColor = [UIColor clearColor];
  openFlowRightTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftBorder, yPosFlow-deltaToLabel, screenWidth-leftBorder-rightBorder, (iPad)? 17.0f : 12.0f)];
  openFlowRightTitleLabel.font = [UIFont boldSystemFontOfSize:(iPad)? 14.0f : 10.0f];
  openFlowRightTitleLabel.textColor = [Colors lightText];
  openFlowRightTitleLabel.textAlignment = UITextAlignmentRight;
  openFlowRightTitleLabel.backgroundColor = [UIColor clearColor];
  [self.view addSubview:openFlowLeftTitleLabel];
  [self.view addSubview:openFlowTitleLabel];
  [self.view addSubview:openFlowRightTitleLabel];
  float flowViewWidth = (iPad)? 750.0f : ((isPortraitScreen)? 320.0f : 200.0f);
  coverFlowView = [[CoverFlowView alloc] initWithFrame:CGRectMake(leftBorder, yPosFlow, screenWidth-leftBorder-rightBorder, flowViewWidth)];
  coverFlowView.coverflowDelegate = self;
  [self.view addSubview:coverFlowView];

  [self.view bringSubviewToFront:topNavigationBar];
  [self.view bringSubviewToFront:bottomToolbar];
  [self.view bringSubviewToFront:helpButton];
  [self.view bringSubviewToFront:loadDataActivityIndicator];

  coverFlowView.coverSize = CGSizeMake(coverWidth, coverWidth);
  backgroundView.alpha = 0;
  if (parkModus != ParkModusNotSelected) {
    ParkModus modus = parkModus;
    parkModus = ParkModusNotSelected;
    [self showTableView:NO];
    [self backView:nil animated:NO];
    parkModus = modus;
    [self buttonViewModus:YES];
  } else {
    [self showTableView:YES];
  }
  [self performSelectorInBackground:@selector(createBackgroundImage) withObject:nil];
  if (!settings.profileKnown) {
    [settings setProfileKnown:YES];
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"menu.button.recommendations", nil)
                           message:NSLocalizedString(@"recommendations.set.profile", nil)
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"no", nil)
                           otherButtonTitles:NSLocalizedString(@"yes", nil), nil];
    dialog.tag = ParkMainMenuViewControllerAlertViewProfileSet;
    [dialog show];
    [dialog release];
  }
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

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [self updateParksData];
}

#pragma mark -
#pragma mark Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [menuList count];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"ParkSelectionCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [Colors lightText];
    cell.textLabel.shadowColor = [UIColor blackColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
    cell.backgroundColor = [Colors lightBlue];
    cell.alpha = 0.7;
  }
  MenuItem *m = [menuList objectAtIndex:indexPath.row];
  NSString *s = m.imageName;
  cell.textLabel.text = m.name;
  //NSLog(@"table cell at row: %d  name: %@", indexPath.row, m.name);
  if (s == nil || [s length] == 0) {
    cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
    cell.textLabel.numberOfLines = 1;
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.imageView.image = nil;
  } else {
    cell.accessoryView = nil;
    cell.imageView.layer.masksToBounds = NO;
    cell.imageView.layer.cornerRadius = 0.0;
    cell.imageView.layer.borderWidth = 0.0;
    cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
    cell.textLabel.numberOfLines = 1;
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    // ToDo: cell.imageView.frame = CGRectMake(3, 3, 32, 32);
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[MenuData dataPath] stringByAppendingPathComponent:s]];
    if (image == nil) image = [[UIImage imageNamed:s] retain];
    cell.imageView.image = image;
    cell.imageView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    [image release];
  }
  if ([m.name length] == 0) {
    UIView *bg = [[UIView alloc] initWithFrame:cell.frame];
    bg.backgroundColor = [UIColor lightGrayColor];
    cell.backgroundView = bg;
    cell.textLabel.backgroundColor = [UIColor lightGrayColor];
    [bg release];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
  } else {
    //cell.backgroundView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if (parkModus == ParkModusNotSelected && [m.menuId isEqualToString:@"MAIN_MENU_NEWS"]) {
      if (newsBadge != nil) {
        [newsBadge removeFromSuperview];
        [newsBadge release];
        newsBadge = nil;
      }
      ParkData *parkData = [ParkData getParkData:parkId];
      if (parkData.numberOfNewNewsEntries > 0) {
        newsBadge = [[CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d", parkData.numberOfNewNewsEntries]] retain];
        float offsetX = 138.0f;
        float offsetY = 3*tableView.rowHeight+9.0f;
        SettingsData *settings = [SettingsData getSettingsData];
        BOOL isPortraitScreen = [settings isPortraitScreen];
        if ([IPadHelper isIPad] && isPortraitScreen) {
          offsetX += 34.0f;
          offsetY += 20.0f;
        }
        newsBadge.autoresizingMask = UIViewAutoresizingNone;
        newsBadge.frame = CGRectMake(offsetX, offsetY+2.0f, newsBadge.frame.size.width, newsBadge.frame.size.height);
        [theTableView addSubview:newsBadge];
      }
    }
  }
  return cell;
}

#pragma mark -
#pragma mark Load park threads

-(void)viewParkNews {
  ParkData *parkData = [ParkData getParkData:parkId];
  NewsData *news = [parkData getNewsData];
  [self enableViewController:YES];
  NSIndexPath *indexPath = [theTableView indexPathForSelectedRow];
  NSString *titleName = NSLocalizedString(@"news.title", nil);
  if (news.newsData != nil) {
    if (newsBadge != nil) {
      [newsBadge removeFromSuperview];
      [newsBadge release];
      newsBadge = nil;
    }
    [theTableView reloadData];
    GeneralInfoListViewController *controller = [[GeneralInfoListViewController alloc] initWithNibName:@"GeneralInfoListView" owner:self helpData:news.newsData title:titleName];
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
    [parkData resetNumberOfNewNewsEntries];
  } else {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:titleName
                           message:NSLocalizedString(@"news.no", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  }
  if (indexPath != nil) [theTableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(void)loadParkNews {
  @synchronized([ParkMainMenuViewController class]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData getNewsData];
    [pool release];
    [self performSelectorOnMainThread:@selector(viewParkNews) withObject:nil waitUntilDone:NO];
  }
}

-(void)viewCalendar {
  NSIndexPath *indexPath = [theTableView indexPathForSelectedRow];
  NSString *titleName = NSLocalizedString(@"calendar.title", nil);
  if (indexPath != nil) [theTableView deselectRowAtIndexPath:indexPath animated:NO];
  ParkData *parkData = [ParkData getParkData:parkId];
  CalendarData *calendarData = [parkData getCalendarData];
  while ([calendarData isUpdateActive]) [NSThread sleepForTimeInterval:0.5];
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
    CalendarViewController *controller = [[CalendarViewController alloc] initWithNibName:@"CalendarView" owner:self parkId:parkId title:titleName];
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
  [self enableViewController:YES];
}

-(void)loadCalendarView {
  [self performSelectorOnMainThread:@selector(viewCalendar) withObject:nil waitUntilDone:NO];
}

#pragma mark -
#pragma mark Table view delegate

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return (tableView.editing)? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!loadDataActivityIndicator.hidden) return nil;
  MenuItem *m = [menuList objectAtIndex:indexPath.row];
  return ([m.name length] == 0)? nil : indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UIViewController *controller = nil;
  MenuItem *selectedRow = [menuList objectAtIndex:indexPath.row];
  if (selectedRow.fileName != nil) {
    if ([selectedRow.fileName hasPrefix:@"http"]) {
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:selectedRow.fileName]];
      [theTableView deselectRowAtIndexPath:indexPath animated:NO];
    } else {
      controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:selectedRow.fileName title:selectedRow.name];
      ((GeneralInfoViewController *)controller).subdirectory = parkId;
    }
  } else if ([selectedRow.menuId isEqualToString:NSLocalizedString(@"all", nil)]) {
    controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:selectedList2 title:titleOfTable.title];
    [((AttractionListViewController *)controller) setSubtitleName:NSLocalizedString(@"all", nil)];
  } else if ([selectedRow.menuId isEqualToString:NSLocalizedString(@"map", nil)]) {
    controller = [[NavigationViewController alloc] initWithNibName:@"NavigationView" owner:self parkId:parkId];
    NSString *currentSelectedMenuId = nil;
    if (selectedList3 != nil) currentSelectedMenuId = selectedList3;
    else if (selectedList2 != nil) currentSelectedMenuId = selectedList2;
    [(NavigationViewController *)controller setupSelectedCategoriesWithMenuId:currentSelectedMenuId];    
  } else if ([selectedRow.menuId isEqualToString:NSLocalizedString(@"distance", nil)]) {
    controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:selectedList2 title:titleOfTable.title];
    [((AttractionListViewController *)controller) setSubtitleName:NSLocalizedString(@"distance", nil)];
  } else if ([selectedRow.menuId isEqualToString:@"MAIN_MENU_INFORMATION"]) {
    [self backView:nil];
    parkModus = ParkModusInformation;
    coverFlowView.dataSource = self;
    coverFlowView.numberOfCovers = 6;
    selectedMenuCoverflowView = NO;
    [self buttonViewModus:YES];
  } else if ([selectedRow.menuId isEqualToString:@"MAIN_MENU_VISIT"]) {
    SettingsData *settings = [SettingsData getSettingsData];
    if (!settings.visitNotesKnown) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:selectedRow.name
                             message:NSLocalizedString(@"main.menu.visit.notes", nil)
                             delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:nil];
      [dialog show];
      [dialog release];
      [settings setVisitNotesKnown:YES];
    }
    [self backView:nil];
    parkModus = ParkModusVisit;
    LocationData *locData = [LocationData getLocationData];
    [locData unregisterDataPool:parkId];
    [locData registerViewController:self];
    [locData start];
    coverFlowView.dataSource = self;
    coverFlowView.numberOfCovers = 6;
    selectedMenuCoverflowView = NO;
    [self buttonViewModus:YES];
  } else if ([selectedRow.menuId isEqualToString:@"MAIN_MENU_WAIT_TIMES_OVERVIEW"]) {
    PathesViewController *c = [[PathesViewController alloc] initWithNibName:@"PathesView" owner:self parkGroupId:parkId];
    c.enableWalkToAttraction = NO;
    controller = c;
  } else if ([selectedRow.menuId isEqualToString:@"MAIN_MENU_NEWS"]) {
    [self enableViewController:NO];
    [NSThread detachNewThreadSelector:@selector(loadParkNews) toTarget:self withObject:nil];
  } else if ([selectedRow.menuId isEqualToString:@"MAIN_MENU_PROFILE"]) {
    InAppSettingsViewController *c = [[InAppSettingsViewController alloc] initWithNibName:@"InAppSettingsView" owner:self];
    c.preferenceTitle = NSLocalizedString(@"profile.title", nil);
    c.preferenceSpecifiers = @"Profile";
    controller = c;
  } else if ([selectedRow.menuId isEqualToString:@"MENU_ATTRACTION_BY_PROFILE"]) {
    [self recommendationView:self];
    [theTableView deselectRowAtIndexPath:indexPath animated:NO];
  } else if ([selectedRow.menuId isEqualToString:@"MENU_WAITING_TIME"]) {
    controller = [[PathesViewController alloc] initWithNibName:@"PathesView" owner:self parkGroupId:parkId];
  } else if ([selectedRow.menuId isEqualToString:@"MENU_CALENDAR"]) {
    [self calendarView:self];
    [theTableView deselectRowAtIndexPath:indexPath animated:NO];
  } else {
    if (selectedList3 == nil) {
      if ([selectedList2 isEqualToString:@"MENU_THEME_AREA"] || [selectedRow.name hasSuffix:@")"]) {
        controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:selectedList2 title:selectedRow.menuId];
      } else {
        selectedList3 = [selectedRow.menuId retain];
        [self updateParksData];
      }
    } else {
      if ([selectedList3 isEqualToString:@"MENU_ATTRACTION_BY_THEME_AREA"] || [selectedList3 isEqualToString:@"MENU_SHOP_BY_THEME_AREA"]
          || [selectedList3 isEqualToString:@"MENU_DINING_BY_THEME_AREA"] || [selectedList3 isEqualToString:@"MENU_RESTROOM_BY_THEME_AREA"]
          || [selectedList3 isEqualToString:@"MENU_SERVICE_BY_THEME_AREA"]) {
        // ToDo: NSDictionary *selectedParkObject = [MenuData getParkMenuStructure];
        NSString *previousTitle = @"";//[MenuData objectForKey:@"Name" at:[[selectedParkObject objectForKey:selectedList1] objectForKey:selectedList2]];
        controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:selectedList3 title:previousTitle];
        AttractionListViewController *c = (AttractionListViewController *)controller;
        [c setSubtitleName:selectedRow.menuId];
      } else {
        controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:selectedRow.menuId title:selectedRow.menuId];
      }
    }
  }
  if (controller != nil) {
    if ([controller isKindOfClass:[GeneralInfoViewController class]]) {
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];
    } else {
      [self checkIfParkDataIsInitializedBeforePresenting:controller];
    }
    [theTableView deselectRowAtIndexPath:indexPath animated:NO];
  }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  MenuItem *m = [menuList objectAtIndex:indexPath.row];
  return ([m.name length] == 0)? 3.0 : tableView.rowHeight;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 0.0;
}

#pragma mark -
#pragma mark Actions

-(void)didUpdateLocationData {
  if (selectedList2 == nil) {
    NSString *locationStatus = [self currentLocationStatus];
    if (![locationStatus isEqualToString:titleOfTable.title]) titleOfTable.title = locationStatus;
  }
}

-(void)didUpdateLocationError {
  [self performSelectorOnMainThread:@selector(updateParksData) withObject:nil waitUntilDone:NO];
}

-(IBAction)loadBackView:(id)sender {
  if (sender != nil) {
    [self checkIfParkDataIsInitializedBeforePresenting:nil];
    return;
  }
  UIButton *button = [menuButtons objectAtIndex:0];
  if (button.frame.origin.y < 0.0f) {
    if (newsBadge != nil) newsBadge.hidden = YES;
    for (button in menuButtons) button.hidden = YES;
    for (UILabel *label in menuLabels) label.hidden = YES;
    switchViewButton.hidden = YES;
    waitingTimeOverviewButton.hidden = YES;
    openFlowLeftTitleLabel.hidden = YES;
    openFlowTitleLabel.hidden = YES;
    openFlowRightTitleLabel.hidden = YES;
    coverFlowView.hidden = YES;
  }
  if ([LocationData isLocationDataStarted]) {
    LocationData *locData = [LocationData getLocationData];
    [locData stop];
    [locData unregisterViewController];
  }
  [delegate dismissModalViewControllerAnimated:YES];
}

-(void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
  [selectedList3 release];
  selectedList2 = selectedList3 = nil;
  [self updateParksData];
}

-(IBAction)backView:(id)sender animated:(BOOL)animated {
  SettingsData *settings = [SettingsData getSettingsData];
  CGRect r = [[UIScreen mainScreen] bounds];
  BOOL isPortraitScreen = [settings isPortraitScreen];
  float height = (isPortraitScreen)? r.size.height : r.size.width;
  if (parkModus == ParkModusNotSelected) height = -height;
  if (animated) {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
  }
  if (newsBadge != nil) {
    r = newsBadge.frame;
    newsBadge.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  }
  if (fitsToProfileBadge != nil) {
    r = fitsToProfileBadge.frame;
    fitsToProfileBadge.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  }
  for (UIButton *button in menuButtons) {
    r = button.frame;
    button.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  }
  for (UILabel *label in menuLabels) {
    r = label.frame;
    label.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  }
  r = theTableView.frame;
  if (parkModus == ParkModusNotSelected) {
    BOOL iPad = [IPadHelper isIPad];
    ParkData *parkData = [ParkData getParkData:parkId];
    if (parkData.hasWinterData) {
      if (iPad) {
        theTableView.rowHeight = 40.0f;
        if (isPortraitScreen) {
          float h = logoImageView.frame.size.height-14.0f;
          theTableView.frame = CGRectMake(r.origin.x, r.origin.y-height-h, r.size.width, r.size.height+h-bottomToolbar.frame.size.height);
        } else {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x-h, r.origin.y-(height-topNavigationBar.frame.size.height-26.0f-h)/2.0f-110.0f, r.size.width+h, r.size.height);
        }
      } else {
        if (isPortraitScreen) {
          float h = logoImageView.frame.size.height+45.0f;
          theTableView.frame = CGRectMake(r.origin.x, r.origin.y-height-h, r.size.width, r.size.height+h-bottomToolbar.frame.size.height);
        } else {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x-h, r.origin.y-(height-topNavigationBar.frame.size.height-26.0f-h)/2.0f-46.0f, r.size.width+h, r.size.height);
        }
      }
    } else {
      if (iPad) {
        theTableView.rowHeight = 40.0f;
        if (isPortraitScreen) {
          float h = logoImageView.frame.size.height-48.0f;
          theTableView.frame = CGRectMake(r.origin.x, r.origin.y-height-h, r.size.width, r.size.height+h-bottomToolbar.frame.size.height);
        } else {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x-h, r.origin.y-(height-topNavigationBar.frame.size.height-26.0f-h)/2.0f-80.0f, r.size.width+h, r.size.height);
        }
      } else {
        if (isPortraitScreen) {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x, r.origin.y-height-h, r.size.width, r.size.height+h-bottomToolbar.frame.size.height);
        } else {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x-h, r.origin.y-(height-topNavigationBar.frame.size.height-26.0f-h)/2.0f-26.0f, r.size.width+h, r.size.height);
        }
      }
    }
    r = logoImageView.frame;
    logoImageView.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    bottomToolbar.hidden = NO;
    summerWinterSwitch.hidden = YES;
    winterLabel.hidden = YES;
    summerLabel.hidden = YES;
    interestingLabel.hidden = YES;
    interestingTitleLabel.hidden = YES;
    r = backgroundView.frame;
    backgroundView.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height-bottomToolbar.frame.size.height);
  } else theTableView.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  r = switchViewButton.frame;
  switchViewButton.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  r = waitingTimeOverviewButton.frame;
  waitingTimeOverviewButton.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  r = openFlowLeftTitleLabel.frame;
  openFlowLeftTitleLabel.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  r = openFlowTitleLabel.frame;
  openFlowTitleLabel.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  r = openFlowRightTitleLabel.frame;
  openFlowRightTitleLabel.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  r = coverFlowView.frame;
  coverFlowView.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  if (animated) [UIView commitAnimations];
  else [self animationDidStop:nil finished:nil context:nil];
  theTableView.rowHeight = 44.0f;
  //theTableView.rowHeight = 35.0f;
  titleOfTable.leftBarButtonItem = nil;
}

-(IBAction)backView:(id)sender {
  [self backView:sender animated:YES];
}

-(IBAction)helpView:(id)sender {
  HelpData *helpData = [HelpData getHelpData];
  NSString *page = nil;
  NSString *title = nil;
  if (selectedList3 != nil) {
    page = [helpData.pages objectForKey:selectedList3];
    title = [helpData.titles objectForKey:selectedList3];
  } else if (selectedList2 != nil) {
    page = [helpData.pages objectForKey:selectedList2];
    title = [helpData.titles objectForKey:selectedList2];
  } else {
    page = [helpData.pages objectForKey:@"Park_Item"];
    title = [helpData.titles objectForKey:@"Park_Item"]; 
  }
  if (title != nil && page != nil) {
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
    controller.content = page;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(IBAction)switchView:(id)sender {
  selectedMenuCoverflowView = !selectedMenuCoverflowView;
  if (selectedMenuCoverflowView && coverFlowView.dataSource == nil) {
    coverFlowView.dataSource = self;
    coverFlowView.numberOfCovers = 6;
  }
  [self buttonViewModus:NO];
}

-(IBAction)tourView:(id)sender {
  TourViewController *controller = [[TourViewController alloc] initWithNibName:@"TourView" owner:self parkId:parkId];
  [self checkIfParkDataIsInitializedBeforePresenting:controller];
}

-(IBAction)mapView:(id)sender {
  NavigationViewController *controller = [[NavigationViewController alloc] initWithNibName:@"NavigationView" owner:self parkId:parkId];
  [self checkIfParkDataIsInitializedBeforePresenting:controller];
}

-(IBAction)parkingView:(id)sender {
  if ([LocationData isLocationDataActive]) {
    ParkingViewController *controller = [[ParkingViewController alloc] initWithNibName:@"ParkingView" owner:self title:NSLocalizedString(@"menu.button.parking", nil) parkId:parkId];
    [self checkIfParkDataIsInitializedBeforePresenting:controller];
  } else {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"location.error", nil)
                           message:NSLocalizedString(@"location.required", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  }
}

-(IBAction)recommendationView:(id)sender {
  AttractionListViewController *controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:@"MENU_ATTRACTION_BY_PROFILE" title:NSLocalizedString(@"menu.interesting.attractions", nil)];
  [self checkIfParkDataIsInitializedBeforePresenting:controller];
}

-(void)showTableView:(BOOL)animated {
  SettingsData *settings = [SettingsData getSettingsData];
  CGRect r = [[UIScreen mainScreen] bounds];
  BOOL isPortraitScreen = [settings isPortraitScreen];
  float height = r.size.height;
  float width = r.size.width;
  if (!isPortraitScreen) {
    float f = height;
    height = width; width = f;
  }
  r = theTableView.frame;
  [self updateParksData];
  if (parkModus == ParkModusNotSelected) {
    BOOL iPad = [IPadHelper isIPad];
    ParkData *parkData = [ParkData getParkData:parkId];
    BOOL enableWinter = NO;
    if (parkData.hasWinterData) {
      if (iPad) {
        theTableView.rowHeight = 40.0f;
        if (isPortraitScreen) {
          float h = logoImageView.frame.size.height-14.0f;
          theTableView.frame = CGRectMake(r.origin.x, r.origin.y-height+h, width, r.size.height-h+bottomToolbar.frame.size.height);
        } else {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x+h, r.origin.y-height+(height-topNavigationBar.frame.size.height-26.0f-h)/2.0f+110.0f, width-h, r.size.height);
        }
      } else {
        if (isPortraitScreen) {
          float h = logoImageView.frame.size.height+45.0f;
          theTableView.frame = CGRectMake(r.origin.x, r.origin.y-height+h, width, r.size.height-h+bottomToolbar.frame.size.height);
        } else {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x+h, r.origin.y-height+(height-topNavigationBar.frame.size.height-26.0f-h)/2.0f+46.0f, width-h, r.size.height);
        }
      }
      enableWinter = parkData.winterDataEnabled;
    } else {
      if (iPad) {
        theTableView.rowHeight = 40.0f;
        if (isPortraitScreen) {
          float h = logoImageView.frame.size.height-48.0f;
          theTableView.frame = CGRectMake(r.origin.x, r.origin.y-height+h, width, r.size.height-h+bottomToolbar.frame.size.height);
        } else {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x+h, r.origin.y-height+(height-topNavigationBar.frame.size.height-26.0f-h)/2.0f+80.0f, width-h, r.size.height);
        }
      } else {
        if (isPortraitScreen) {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x, r.origin.y-height+h, width, r.size.height-h+bottomToolbar.frame.size.height);
        } else {
          float h = logoImageView.frame.size.height+4.0f;
          theTableView.frame = CGRectMake(r.origin.x+h, r.origin.y-height+(height-topNavigationBar.frame.size.height-26.0f-h)/2.0f+26.0f, width-h, r.size.height);
        }
      }
    }
    //float yPos = theTableView.frame.origin.y+height;
    //if (isPortraitScreen) yPos += 1.5*width-300.0f;
    float h = (iPad && isPortraitScreen)? 30.0f : 40.0f;
    summerWinterSwitch = [[CustomSwitch alloc] initWithFrame:CGRectMake(theTableView.frame.origin.x+(theTableView.frame.size.width-95.0f)/2, theTableView.frame.origin.y+29.0f/2-h, 95.0f, 27.0f)];
    summerWinterSwitch.autoresizingMask = UIViewAutoresizingNone;
    summerWinterSwitch.delegate = self;
    summerWinterSwitch.hidden = !parkData.hasWinterData;
    summerWinterSwitch.leftImageView.image = [UIImage imageNamed:@"snow.png"];
    summerWinterSwitch.rightImageView.image = [UIImage imageNamed:@"sun.png"];
    summerWinterSwitch.on = enableWinter;
    [self.view addSubview:summerWinterSwitch];
    winterLabel = [[UILabel alloc] initWithFrame:CGRectMake(summerWinterSwitch.frame.origin.x-70.0f, summerWinterSwitch.frame.origin.y, 70.0f, summerWinterSwitch.frame.size.height)];
    winterLabel.hidden = !parkData.hasWinterData;
    winterLabel.text = NSLocalizedString(@"winter", nil);
    winterLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    winterLabel.textColor = [Colors lightText];
    winterLabel.shadowColor = [UIColor blackColor];
    winterLabel.shadowOffset = CGSizeMake(0, 1);
    winterLabel.backgroundColor = [UIColor clearColor];
    winterLabel.enabled = enableWinter;
    [self.view addSubview:winterLabel];
    summerLabel = [[UILabel alloc] initWithFrame:CGRectMake(summerWinterSwitch.frame.origin.x+summerWinterSwitch.frame.size.width+5.0f, summerWinterSwitch.frame.origin.y, 70.0f, summerWinterSwitch.frame.size.height)];
    summerLabel.hidden = !parkData.hasWinterData;
    summerLabel.text = NSLocalizedString(@"summer", nil);
    summerLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    summerLabel.textColor = [Colors lightText];
    summerLabel.shadowColor = [UIColor blackColor];
    summerLabel.shadowOffset = CGSizeMake(0, 1);
    summerLabel.backgroundColor = [UIColor clearColor];
    summerLabel.enabled = !enableWinter;
    [self.view addSubview:summerLabel];
    if (fitsToProfileBadge != nil) {
      r = fitsToProfileBadge.frame;
      fitsToProfileBadge.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
    }
    for (UIButton *button in menuButtons) {
      r = button.frame;
      button.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
    }
    for (UILabel *label in menuLabels) {
      r = label.frame;
      label.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
    }
    r = switchViewButton.frame;
    switchViewButton.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
    r = waitingTimeOverviewButton.frame;
    waitingTimeOverviewButton.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
    r = openFlowLeftTitleLabel.frame;
    openFlowLeftTitleLabel.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
    r = openFlowTitleLabel.frame;
    openFlowTitleLabel.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
    r = openFlowRightTitleLabel.frame;
    openFlowRightTitleLabel.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
    r = coverFlowView.frame;
    coverFlowView.frame = CGRectMake(r.origin.x, r.origin.y+height, r.size.width, r.size.height);
  } else if (coverFlowView.frame.origin.y > 0.0f) {
    if (animated) {
      [UIView beginAnimations:nil context:NULL];
      [UIView setAnimationDuration:0.5];
    }
    theTableView.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    if (newsBadge != nil) {
      r = newsBadge.frame;
      newsBadge.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    }
    if (fitsToProfileBadge != nil) {
      r = fitsToProfileBadge.frame;
      fitsToProfileBadge.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    }
    for (UIButton *button in menuButtons) {
      r = button.frame;
      button.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    }
    for (UILabel *label in menuLabels) {
      r = label.frame;
      label.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    }
    r = switchViewButton.frame;
    switchViewButton.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    r = waitingTimeOverviewButton.frame;
    waitingTimeOverviewButton.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    r = openFlowLeftTitleLabel.frame;
    openFlowLeftTitleLabel.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    r = openFlowTitleLabel.frame;
    openFlowTitleLabel.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    r = openFlowRightTitleLabel.frame;
    openFlowRightTitleLabel.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    r = coverFlowView.frame;
    coverFlowView.frame = CGRectMake(r.origin.x, r.origin.y-height, r.size.width, r.size.height);
    if (animated) [UIView commitAnimations];
    titleOfTable.leftBarButtonItem = backButton;
  }
}

-(IBAction)attractionsView:(id)sender {
  selectedList2 = @"MENU_ATTRACTION";
  selectedList3 = nil;
  [self showTableView:YES];
}

-(IBAction)themeAreasView:(id)sender {
  selectedList2 = @"MENU_THEME_AREA";
  selectedList3 = nil;
  [self showTableView:YES];
}

-(IBAction)restroomView:(id)sender {
  selectedList2 = @"MENU_RESTROOM";
  selectedList3 = nil;
  [self showTableView:YES];
}

-(IBAction)serviceView:(id)sender {
  selectedList2 = @"MENU_SERVICE";
  selectedList3 = nil;
  [self showTableView:YES];
}

-(IBAction)shopsView:(id)sender {
  selectedList2 = @"MENU_SHOP";
  selectedList3 = nil;
  [self showTableView:YES];
}

-(IBAction)cateringView:(id)sender {
  selectedList2 = @"MENU_DINING";
  selectedList3 = nil;
  [self showTableView:YES];
}

-(IBAction)calendarView:(id)sender {
  [self enableViewController:NO];
  [NSThread detachNewThreadSelector:@selector(loadCalendarView) toTarget:self withObject:nil];
}

-(IBAction)generalView:(id)sender {
  selectedList2 = @"MENU_GENERAL";
  selectedList3 = nil;
  [self showTableView:YES];
}

-(IBAction)waitingTimeOverview:(id)sender {
  PathesViewController *controller = [[PathesViewController alloc] initWithNibName:@"PathesView" owner:self parkGroupId:parkId];
  [self checkIfParkDataIsInitializedBeforePresenting:controller];
}

#pragma mark -
#pragma mark Custom Switch view delegate

-(void)customSwitchDelegate:(CustomSwitch *)customSwitch selectionDidChange:(BOOL)on {
  ParkData *parkData = [ParkData getParkData:parkId];
  parkData.winterDataEnabled = on;
  winterLabel.enabled = on;
  summerLabel.enabled = !on;
}

#pragma mark -
#pragma mark Cover Flow view delegate

-(void)coverflowView:(CoverFlowView *)coverflow selectionDidChange:(int)index {
  if (parkModus == ParkModusNotSelected) {
    if (index == 0) {
      interestingTitleLabel.text = parkName;
    } else {
      Attraction *attraction = [interestingAttractions objectAtIndex:index-1];
      interestingTitleLabel.text = attraction.stringAttractionName;
    }
    return;
  }
  switch (index) {
    case 1:
      openFlowLeftTitleLabel.text = NSLocalizedString(@"menu.button.attractions", nil);
      openFlowTitleLabel.text = NSLocalizedString(@"menu.button.areas", nil);
      openFlowRightTitleLabel.text = NSLocalizedString(@"menu.button.dining", nil);
      break;
    case 2:
      openFlowLeftTitleLabel.text = NSLocalizedString(@"menu.button.areas", nil);
      openFlowTitleLabel.text = NSLocalizedString(@"menu.button.dining", nil);
      openFlowRightTitleLabel.text = NSLocalizedString(@"menu.button.shop", nil);
      break;
    case 3:
      openFlowLeftTitleLabel.text = NSLocalizedString(@"menu.button.dining", nil);
      openFlowTitleLabel.text = NSLocalizedString(@"menu.button.shop", nil);
      openFlowRightTitleLabel.text = NSLocalizedString(@"menu.button.restroom", nil);
      break;
    case 4:
      openFlowLeftTitleLabel.text = NSLocalizedString(@"menu.button.shop", nil);
      openFlowTitleLabel.text = NSLocalizedString(@"menu.button.restroom", nil);
      openFlowRightTitleLabel.text = NSLocalizedString(@"menu.button.service", nil);
      break;
    case 5:
      openFlowLeftTitleLabel.text = NSLocalizedString(@"menu.button.restroom", nil);
      openFlowTitleLabel.text = NSLocalizedString(@"menu.button.service", nil);
      openFlowRightTitleLabel.text = @"";
      break;
    default:
      openFlowLeftTitleLabel.text = @"";
      openFlowTitleLabel.text = NSLocalizedString(@"menu.button.attractions", nil);
      openFlowRightTitleLabel.text = NSLocalizedString(@"menu.button.areas", nil);
      break;
  }
}

-(void)coverflowView:(CoverFlowView *)coverflow didSelectAtIndex:(int)index {
  if (parkModus == ParkModusNotSelected) return;
  //[self coverflowView:coverflow selectionDidChange:index]; // if selection occurred at the edges
  switch (index) {
    case 1:
      [self themeAreasView:self];
      break;
    case 2:
      [self cateringView:self];
      break;
    case 3:
      [self shopsView:self];
      break;
    case 4:
      [self restroomView:self];
      break;
    case 5:
      [self serviceView:self];
      break;
    default:
      [self attractionsView:self];
      break;
  }
}

#pragma mark -
#pragma mark Cover Flow view data source

-(CoverFlowItemView *)coverflowView:(CoverFlowView *)coverflow atIndex:(int)index {
	CoverFlowItemView *cover = [coverflow dequeueReusableCoverView];
	if (cover == nil) {
		float f = coverflow.coverSize.width;
		cover = [[[CoverFlowItemView alloc] initWithFrame:CGRectMake(0, 0, f, f)] autorelease];
	}
  NSString *imagePath = nil;
  NSDictionary *parkDetails = [MenuData getParkDetails:parkId cache:YES];
  if (parkModus == ParkModusNotSelected) {
    if (index == 0) {
      imagePath = [[NSString alloc] initWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Logo"]];
    } else {
      Attraction *attraction = [interestingAttractions objectAtIndex:index-1];
      NSArray *images = [ImageData imageProperiesForParkId:parkId attractionId:attraction.attractionId data:localImageData];
      if (images != nil && [images count] > 0) {
        ImageProperty *imageProperty = [images objectAtIndex:0];
        imagePath = [[NSString alloc] initWithFormat:@"%@/%@/%@/%s", [ImageData additionalImagesDataPath], parkId, attraction.attractionId, imageProperty.imageName];
      } else imagePath = [[attraction imagePath:parkId] retain];
    }
  } else {
    switch (index) {
      case 1:
        imagePath = [[NSString alloc] initWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Themenbereiche"]];
        break;
      case 2:
        imagePath = [[NSString alloc] initWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Gastro"]];
        break;
      case 3:
        imagePath = [[NSString alloc] initWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Shops"]];
        break;
      case 4:
        imagePath = [[NSString alloc] initWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_WC"]];
        break;
      case 5:
        imagePath = [[NSString alloc] initWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Service"]];
        break;
      default:
        imagePath = [[NSString alloc] initWithFormat:@"%@/%@", [MenuData parkDataPath:parkId], [parkDetails objectForKey:@"Icon_Attraktionen"]];
        break;
    }
  }
  //float width = [IPadHelper isIPad]? 400.0f : 250.0f;
  //[openFlowView setImage:[AsynchronousImageView rescaleImage:image toSize:CGSizeMake(width, width)] forIndex:index];
  [cover setImagePath:imagePath];
  [imagePath release];
	return cover;
}

#pragma mark -
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
  if (alertView.tag == ParkMainMenuViewControllerAlertViewProfileSet) {
    if ([buttonTitle isEqualToString:NSLocalizedString(@"yes", nil)]) {
      InAppSettingsViewController *controller = [[InAppSettingsViewController alloc] initWithNibName:@"InAppSettingsView" owner:self];
      controller.preferenceTitle = NSLocalizedString(@"profile.title", nil);
      controller.preferenceSpecifiers = @"Profile";
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];
    }
  }
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Relinquish ownership any cached data, images, etc that aren't in use.
  NSLog(@"Memory waring at Park Main Menu View Controller");
  viewInitialized = NO;
  selectedMenuCoverflowView = NO;
}

-(void)viewDidUnload {
  [super viewDidUnload];
  viewInitialized = NO;
  newsBadge = nil;
  backgroundView = nil;
  theTableView = nil;
  topNavigationBar = nil;
  titleOfTable = nil;
  loadDataActivityIndicator = nil;
  helpButton = nil;
  backButton = nil;
  bottomToolbar = nil;
  interestingLabel = nil;
  fitsToProfileBadge = nil;
  menuButtons = nil;
  menuLabels = nil;
  logoImageView = nil;
  switchViewButton = nil;
  waitingTimeOverviewButton = nil;
  openFlowLeftTitleLabel = nil;
  openFlowTitleLabel = nil;
  openFlowRightTitleLabel = nil;
  coverFlowView = nil;
  summerWinterSwitch = nil;
}

-(void)dealloc {
  [localImageData release];
  localImageData = nil;
  [newsBadge release];
  [backgroundView release];
  [theTableView release];
  [topNavigationBar release];
  [titleOfTable release];
  [loadDataActivityIndicator release];
  [helpButton release];
  [backButton release];
  [bottomToolbar release];
  [interestingLabel release];
  [fitsToProfileBadge release];
  [menuButtons release];
  [menuLabels release];
  [logoImageView removeFromSuperview];
  [logoImageView release];
  [switchViewButton removeFromSuperview];
  [switchViewButton release];
  [waitingTimeOverviewButton removeFromSuperview];
  [waitingTimeOverviewButton release];
  [openFlowLeftTitleLabel removeFromSuperview];
  [openFlowLeftTitleLabel release];
  [openFlowTitleLabel removeFromSuperview];
  [openFlowTitleLabel release];
  [openFlowRightTitleLabel removeFromSuperview];
  [openFlowRightTitleLabel release];
  [coverFlowView removeFromSuperview];
  [coverFlowView release];
  [summerWinterSwitch removeFromSuperview];
  [summerWinterSwitch release];
  [winterLabel removeFromSuperview];
  [winterLabel release];
  [summerLabel removeFromSuperview];
  [summerLabel release];
  [interestingTitleLabel removeFromSuperview];
  [interestingTitleLabel release];
  [super dealloc];
}

@end
