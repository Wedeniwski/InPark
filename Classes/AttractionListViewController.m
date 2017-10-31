//
//  AttractionListViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 12.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "AttractionListViewController.h"
#import "AttractionViewController.h"
#import "TourViewController.h"
#import "ParkMainMenuViewController.h"
#import "ApplicationCell.h"
#import "MenuItem.h"
#import "MenuData.h"
#import "ProfileData.h"
#import "TourData.h"
#import "TourItem.h"
#import "Categories.h"
#import "SettingsData.h"
#import "ParkData.h"
#import "Conversions.h"
#import "Colors.h"

@implementation AttractionListViewController

static BOOL viewInitialized = NO;
static NSArray *listOfAttractionIds = nil;
static NSMutableArray *menuList = nil;
static NSMutableArray *cellList = nil;
static NSString *parkId = nil;
static NSString *titleName = nil;
static NSString *subtitleName = nil;
static NSString *category = nil;

@synthesize delegate;
@synthesize theTableView;
@synthesize topNavigationBar;
@synthesize titleOfTable;
@synthesize bottomToolbar;
@synthesize cellOwner;

-(void)setListOfAttractionIds:(NSArray *)newListOfAttractionIds {
  [listOfAttractionIds release];
  listOfAttractionIds = [newListOfAttractionIds retain];
}

-(void)setSubtitleName:(NSString *)newSubtitleName {
  [subtitleName release];
  subtitleName = [newSubtitleName retain];
}

-(void)addCellForMenuItem:(MenuItem *)menuItem settings:(SettingsData *)settings {
  [cellOwner loadNibNamed:@"ApplicationCell" owner:self];
  ApplicationCell *cell = (ApplicationCell *)cellOwner.cell;
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:menuItem.menuId];
  cell.parkNameLabel.text = menuItem.name;
  cell.locationLabel.text = [MenuData objectForKey:ATTRACTION_THEME_AREA at:[attraction getAttractionDetails:parkId cache:YES]];
  cell.categoryLabel.text = attraction.typeName;
  cell.parkNameLabel.textColor = [Colors hilightText];
  cell.categoryLabel.textColor = [Colors lightText];
  cell.locationLabel.textColor = [Colors lightText];
  cell.fitPreferenceLabel.textColor = [Colors lightText];
  cell.backgroundColor = [Colors lightBlue];
  cell.iconView.backgroundColor = [Colors lightBlue];
  cell.iconView.imageView.backgroundColor = [Colors lightBlue];
  cell.addButton.backgroundColor = [Colors lightBlue];
  [cellList addObject:cell];
}

-(void)updateParksData {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [menuList removeAllObjects];
  ParkData *parkData = [ParkData getParkData:parkId];
  ProfileData *profileData = [ProfileData getProfileData];
  if (listOfAttractionIds != nil) {
    for (NSString *aId in listOfAttractionIds) {
      Attraction *attraction = [Attraction getAttraction:parkId attractionId:aId];
      double tolerance = 0.0;
      NSString *fromAttractionId = nil;
      double distance = [parkData currentDistanceToAll:aId tolerance:&tolerance fromAttractionId:&fromAttractionId];
      int rating = [parkData getPersonalRating:aId];
      double preferenceFit = [profileData percentageOfPreferenceFit:attraction parkId:parkId personalAttractionRating:rating adultAge:parkData.adultAge];
      MenuItem *m = [[MenuItem alloc] initWithMenuId:attraction.attractionId
                                               order:[NSNumber numberWithInt:(int)(100-preferenceFit*100)]
                                            distance:distance
                                           tolerance:tolerance
                                                name:attraction.stringAttractionName
                                           imageName:[attraction imageName:parkId]
                                              closed:[attraction isClosed:parkId]];
      [menuList addObject:m];
      [m release];
    }
  } else if ([category isEqualToString:@"MENU_ATTRACTION_BY_PROFILE"]) {
    NSArray *recommendation = [Attraction getAllRecommendedAttractions:parkId];
    for (Attraction *attraction in recommendation) {
      int rating = [parkData getPersonalRating:attraction.attractionId];
      double preferenceFit = [profileData percentageOfPreferenceFit:attraction parkId:parkId personalAttractionRating:rating adultAge:parkData.adultAge];
      if (preferenceFit >= profileData.recommendationMatch) {
        double tolerance = 0.0;
        NSString *fromAttractionId = nil;
        double distance = [parkData currentDistanceToAll:attraction.attractionId tolerance:&tolerance fromAttractionId:&fromAttractionId];
        MenuItem *m = [[MenuItem alloc] initWithMenuId:attraction.attractionId
                                                 order:[NSNumber numberWithInt:(int)(100-preferenceFit*100)]
                                              distance:distance
                                             tolerance:tolerance
                                                  name:attraction.stringAttractionName
                                             imageName:[attraction imageName:parkId]
                                                closed:[attraction isClosed:parkId]];
        [menuList addObject:m];
        [m release];
      }
    }
    if ([menuList count] == 0) {
      UIAlertView *alertDialog = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"attraction.list.no.recommendations.title", nil)
                                  message:NSLocalizedString(@"attraction.list.no.recommendations", nil)
                                  delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                  otherButtonTitles:nil];
      [alertDialog show];
      [alertDialog release];
    }
  } else {
    BOOL checkThemeArea = ([category isEqualToString:@"MENU_THEME_AREA"] || [category isEqualToString:@"MENU_ATTRACTION_BY_THEME_AREA"]
                           || [category isEqualToString:@"MENU_SHOP_BY_THEME_AREA"] || [category isEqualToString:@"MENU_DINING_BY_THEME_AREA"]
                           || [category isEqualToString:@"MENU_SERVICE_BY_THEME_AREA"] || [category isEqualToString:@"MENU_RESTROOM_BY_THEME_AREA"]);
    BOOL checkCategory = ([category isEqualToString:@"MENU_SHOP_BY_THEME_AREA"] || [category isEqualToString:@"MENU_DINING_BY_THEME_AREA"]
                          || [category isEqualToString:@"MENU_RESTROOM_BY_THEME_AREA"] || [category isEqualToString:@"MENU_RESTROOM"]
                          || [category isEqualToString:@"MENU_SERVICE_BY_THEME_AREA"] || [category isEqualToString:@"MENU_SERVICE"]
                          || [category isEqualToString:@"MENU_SHOP"] || [category isEqualToString:@"MENU_DINING"]
                          || [category isEqualToString:@"MENU_ATTRACTION"] || [category isEqualToString:@"MENU_ATTRACTION_BY_THEME_AREA"]);
    BOOL all = ([category isEqualToString:@"MENU_ATTRACTION"] && subtitleName != nil && ([subtitleName isEqualToString:NSLocalizedString(@"all", nil)] || [subtitleName isEqualToString:NSLocalizedString(@"distance", nil)]));
    BOOL checkAllCategories = ([category isEqualToString:@"MENU_ATTRACTION_BY_THEME_AREA"] || all);
    NSDictionary *frequency = [Attraction categories:titleName parkId:parkId checkThemeArea:checkThemeArea checkCategory:checkCategory checkAllCategories:checkAllCategories];
    if (frequency != nil) {
      if (checkThemeArea) {
        NSArray *n = [frequency objectForKey:(subtitleName != nil)? subtitleName : titleName];
        for (NSString *aId in n) {
          Attraction *attraction = [Attraction getAttraction:parkId attractionId:aId];
          int rating = [parkData getPersonalRating:aId];
          double preferenceFit = [profileData percentageOfPreferenceFit:attraction parkId:parkId personalAttractionRating:rating adultAge:parkData.adultAge];
          double tolerance = 0.0;
          NSString *fromAttractionId = nil;
          double distance = [parkData currentDistanceToAll:attraction.attractionId tolerance:&tolerance fromAttractionId:&fromAttractionId];
          MenuItem *m = [[MenuItem alloc] initWithMenuId:attraction.attractionId
                                                   order:[NSNumber numberWithInt:(int)(100-preferenceFit*100)]
                                                distance:distance
                                               tolerance:tolerance
                                                    name:attraction.stringAttractionName
                                               imageName:[attraction imageName:parkId]
                                                  closed:[attraction isClosed:parkId]];
          [menuList addObject:m];
          [m release];
        }
      } else if (all || checkCategory) {
        BOOL priorityDistance = [subtitleName isEqualToString:NSLocalizedString(@"distance", nil)];
        NSEnumerator *i = [frequency objectEnumerator];
        while (TRUE) {
          NSArray *a = [i nextObject];
          if (a == nil) break;
          for (NSString *aId in a) {
            Attraction *attraction = [Attraction getAttraction:parkId attractionId:aId];
            int rating = [parkData getPersonalRating:aId];
            double preferenceFit = [profileData percentageOfPreferenceFit:attraction parkId:parkId personalAttractionRating:rating adultAge:parkData.adultAge];
            double tolerance = 0.0;
            NSString *fromAttractionId = nil;
            double distance = [parkData currentDistanceToAll:attraction.attractionId tolerance:&tolerance fromAttractionId:&fromAttractionId];
            MenuItem *m = [[MenuItem alloc] initWithMenuId:attraction.attractionId
                                                     order:[NSNumber numberWithInt:(int)(100-preferenceFit*100)]
                                                  distance:distance
                                                 tolerance:tolerance
                                                      name:attraction.stringAttractionName
                                                 imageName:[attraction imageName:parkId]
                                                    closed:[attraction isClosed:parkId]];
            if (priorityDistance) m.priorityDistance = YES;
            [menuList addObject:m];
            [m release];
          }
        }
      }
    }
  }
  NSArray *a = [menuList sortedArrayUsingSelector:@selector(compare:)];
  MenuItem *previousItem = nil;
  [menuList removeAllObjects];
  for (MenuItem *item in a) {
    if (previousItem == nil || ![item.menuId isEqualToString:previousItem.menuId]) [menuList addObject:item];
    previousItem = item;
  }
  [cellList removeAllObjects];
  [theTableView reloadData];
  [pool release];
}

#pragma mark -
#pragma mark View lifecycle

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  // Achtung: kritisch, wenn Memory-Warnungen im modalen Fenster aufgetreten sind
  if (viewInitialized) {
    [theTableView reloadData];
  }
  [super dismissModalViewControllerAnimated:animated];
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId category:(NSString *)cat title:(NSString *)tName {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    [parkId release];
    parkId = [pId retain];
    [titleName release];
    titleName = [tName retain];
    [subtitleName release];
    subtitleName = nil;
    [category release];
    category = [cat retain];
    [listOfAttractionIds release];
    listOfAttractionIds = nil;
    [menuList release];
    menuList = [[NSMutableArray alloc] init];
    [cellList release];
    cellList = [[NSMutableArray alloc] init];
  }
  return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
-(void)viewDidLoad {
  [super viewDidLoad];
  viewInitialized = YES;
  indicatorImage = [[UIImage imageNamed:@"indicator60.png"] retain];
  /*if (subtitleName != nil) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10,10,80,30)];
    label.backgroundColor = nil;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.numberOfLines = 2;
    label.text = [NSString stringWithFormat:@"%@ %@", titleName, subtitleName];
    titleOfTable.titleView = label;
    [label release];
    //titleOfTable.prompt = subtitleName;
  } else {*/
  if ([LocationData isLocationDataActive]) {
    LocationData *locData = [LocationData getLocationData];
    [locData registerViewController:self];
  }
  titleOfTable.title = titleName;
  titleOfTable.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  theTableView.backgroundColor = [Colors darkBlue];
  theTableView.backgroundView = nil;
  /*for (id subView in topNavigationBar.subviews) {
   if ([subView isKindOfClass:[UILabel class]]) {
   UILabel *label = (UILabel *)subView;
   label.textColor = [Colors lightText];
   }
   
   }*/
  topNavigationBar.tintColor = [Colors darkBlue];
  bottomToolbar.tintColor = [Colors darkBlue];
  if (![delegate isKindOfClass:[ParkMainMenuViewController class]]) {
    CGRect r = theTableView.frame;
    theTableView.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height+bottomToolbar.frame.size.height);
    bottomToolbar.hidden = YES;
  }
  if (listOfAttractionIds != nil) {
    if ([delegate isKindOfClass:[TourViewController class]]) {
      TourViewController *controller = (TourViewController *)delegate;
      NSArray *aFitIds = [controller attractionIdsWhichFits:listOfAttractionIds];
      ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      if ([aFitIds count] + [tourData count] > MAX_NUMBER_OF_ITEMS_IN_TOUR) {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"warning", nil)
                               message:[NSString stringWithFormat:NSLocalizedString(@"tour.add.suggestion.list.warning", nil), MAX_NUMBER_OF_ITEMS_IN_TOUR]
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
        titleOfTable.rightBarButtonItem = nil;
      }
    }
    if (titleOfTable.rightBarButtonItem != nil) titleOfTable.rightBarButtonItem.title = NSLocalizedString(@"attraction.list.add.all", nil);
  } else titleOfTable.rightBarButtonItem = nil;
  //}
  [self updateParksData];
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

-(void)didUpdateLocationData {
  [theTableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [menuList count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingsData *settings = [SettingsData getSettingsData];
  int idx = indexPath.row;
  if (idx >= [menuList count]) return nil;
  if (idx == 0 && [cellList count] == 0) {
    int i = 0;
    for (MenuItem *menuItem in menuList) {
      [self addCellForMenuItem:menuItem settings:settings];
      if (++i >= 40) break;
    }
  } else {
    for (int n = [cellList count]; n <= idx; ++n) {
      [self addCellForMenuItem:[menuList objectAtIndex:n] settings:settings];
    }
  }
  ApplicationCell *cell = [cellList objectAtIndex:idx];
  MenuItem *m = [menuList objectAtIndex:idx];
  [cell setIconPath:[[MenuData parkDataPath:parkId] stringByAppendingPathComponent:m.imageName]];
  [cell setPreferenceFit:(1.0-m.order/100.0)];
  [cell setPreferenceHidden:(cell.fitPreferenceView.preferenceFit == 0.0)];
  double distance;
  cell.distanceLabel.text = getCurrentDistance(parkId, m.menuId, &distance);
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:m.menuId];
  cell.favoriteView.hidden = ![parkData isFavorite:attraction.attractionId];
  [cell setClosed:[attraction isClosed:parkId]];
  int tourCount = [tourData getAttractionCount:m.menuId];
  [cell setTourCount:tourCount];
  cell.addButton.tag = idx;
  cell.addButton2.tag = idx;
  if (tourCount >= settings.maxNumberOfSameAttractionInTour || ![tourData canAddToTour:m.menuId]) {
    cell.addButton.enabled = NO;
    cell.addButton2.enabled = NO;
  } else {
    cell.addButton.enabled = YES;
    cell.addButton2.enabled = YES;
  }
  // clean up memory usage
  int i = 0;
  for (ApplicationCell *appCell in cellList) {
    if (i <= idx-20 || i >= idx+20) [appCell setIconPath:nil];
    ++i;
  }
  UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicatorImage];
  cell.accessoryView = indicatorView;
  [indicatorView release];
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 74.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 0.0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSInteger idx = indexPath.row;
  MenuItem *selectedRow = [menuList objectAtIndex:idx];
  Attraction *a = [Attraction getAttraction:parkId attractionId:selectedRow.menuId];
  AttractionViewController *controller = [[AttractionViewController alloc] initWithNibName:@"AttractionView" owner:self attraction:a parkId:parkId];
  controller.enableAddToTour = YES;
  controller.selectedTourItemIndex = idx;
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  controller.tourCount = [tourData getAttractionCount:selectedRow.menuId];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
  [theTableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  if ([delegate isKindOfClass:[TourViewController class]]) {
    TourViewController *controller = (TourViewController *)delegate;
    [controller askIfTourOptimizing];
    [controller updateTourData];
  }
  [menuList removeAllObjects];
  [cellList removeAllObjects];
  if ([LocationData isLocationDataInitialized]) {
    LocationData *locData = [LocationData getLocationData];
    [locData unregisterViewController];
  }
	[delegate dismissModalViewControllerAnimated:(sender != nil)];
}

-(IBAction)mainMenuView:(id)sender {
	[delegate dismissModalViewControllerAnimated:NO];
  if ([delegate isKindOfClass:[ParkMainMenuViewController class]]) {
    ParkMainMenuViewController *controller = (ParkMainMenuViewController *)delegate;
    [controller.delegate dismissModalViewControllerAnimated:(sender != nil)];
  }
}

-(IBAction)tourView:(id)sender {
  if ([delegate isKindOfClass:[ParkMainMenuViewController class]]) {
    [delegate dismissModalViewControllerAnimated:NO];
    ParkMainMenuViewController *controller = (ParkMainMenuViewController *)delegate;
    [controller tourView:sender];
  }
}

-(IBAction)mapView:(id)sender {
  if ([delegate isKindOfClass:[ParkMainMenuViewController class]]) {
    [delegate dismissModalViewControllerAnimated:NO];
    ParkMainMenuViewController *controller = (ParkMainMenuViewController *)delegate;
    [controller mapView:sender];
  }
}

-(IBAction)generalView:(id)sender {
  if ([delegate isKindOfClass:[ParkMainMenuViewController class]]) {
    [delegate dismissModalViewControllerAnimated:NO];
    ParkMainMenuViewController *controller = (ParkMainMenuViewController *)delegate;
    [controller generalView:sender];
  }
}

-(IBAction)addAllToTour:(id)sender {
  if ([delegate isKindOfClass:[TourViewController class]]) {
    TourViewController *controller = (TourViewController *)delegate;
    [controller addAttractionIds:listOfAttractionIds];
  }
	[self loadBackView:self];
}

static AttractionViewController *updateController = nil;
static NSArray *trainRouteForSelection = nil;
-(void)updateCell:(NSString *)attractionId atRow:(int)row {
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  NSString *exitId = [parkData getRootAttractionId:[parkData exitAttractionIdOf:attractionId]];
  if (trainRouteForSelection != nil) {
    Attraction *attraction = [trainRouteForSelection lastObject];
    attractionId = attraction.attractionId;
    [trainRouteForSelection release];
    trainRouteForSelection = nil;
  }
  NSString *entryId = [parkData firstEntryAttractionIdOf:attractionId];
  TourItem *t = [[TourItem alloc] initWithAttractionId:attractionId entry:entryId exit:exitId];
  int tourCount = [tourData add:t startTime:[[NSDate date] timeIntervalSince1970]];
  [t release];
  ApplicationCell *appCell = (ApplicationCell *)[theTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
  SettingsData *settings = [SettingsData getSettingsData];
  if (tourCount < 0 || tourCount >= settings.maxNumberOfSameAttractionInTour) {
    appCell.addButton.enabled = NO;
    appCell.addButton2.enabled = NO;
  } else {
    appCell.addButton.enabled = YES;
    appCell.addButton2.enabled = YES;
  }
  if (updateController != nil) [updateController updateTourCount:tourCount];
  updateController = nil;
  [theTableView reloadData];
  //return tourCount;
}

-(void)addToTour:(int)row target:(AttractionViewController *)controller {
  updateController = controller;
  MenuItem *m = [menuList objectAtIndex:row];
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  NSString *attractionId = m.menuId;
  if ([tourData canAddToTour:attractionId]) {
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
    if ([attraction isTrain]) {
      UIActionSheet *sheet = [[UIActionSheet alloc]
                              initWithTitle:NSLocalizedString(@"tour.add.train.destination.title", nil)
                              delegate:self
                              cancelButtonTitle:nil//NSLocalizedString(@"cancel", nil)
                              destructiveButtonTitle:nil
                              otherButtonTitles:nil];
      BOOL oneWay;
      trainRouteForSelection = [[parkData getTrainAttractionRoute:attractionId oneWay:&oneWay] retain];
      for (Attraction *station in trainRouteForSelection) {
        [sheet addButtonWithTitle:station.stringAttractionName];
      }
      //sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"cancel", nil)];  // bug in iOS 4.2
      sheet.tag = row;
      //[sheet showFromToolbar:bottomToolbar];
      [sheet showInView:[UIApplication sharedApplication].keyWindow];
      //[sheet showInView:theTableView]; // crash on iPad!
      UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
      backgroundView.backgroundColor = [Colors darkBlue];
      backgroundView.opaque = NO;
      backgroundView.alpha = 0.5;
      [sheet insertSubview:backgroundView atIndex:0];
      [backgroundView release];
      [sheet release];
    } else {
      [self updateCell:attractionId atRow:row];
    }
  }
}

#pragma mark -
#pragma mark Action sheet delegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex < 0) return;
  if (trainRouteForSelection == nil) {
    NSLog(@"ERROR: Internal error for selection the destination");
    return;
  }
  const char *buttonTitle = [[actionSheet buttonTitleAtIndex:buttonIndex] UTF8String];
  for (Attraction *station in trainRouteForSelection) {
    if (strcmp(station.attractionName, buttonTitle) == 0) {
      [self updateCell:station.attractionId atRow:actionSheet.tag];
      break;
    }
  }
}

#pragma mark -
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  [self loadBackView:alertView];
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  NSLog(@"Memory waring at Attraction List View Controller");
  viewInitialized = NO;
}

-(void)viewDidUnload {
  [super viewDidUnload];
  viewInitialized = NO;
  /*listOfAttractionIds = nil;
  menuList = nil;
  category = nil;
  parkId = nil;
  titleName = nil;
  subtitleName = nil;*/
  theTableView = nil;
  topNavigationBar = nil;
  titleOfTable = nil;
  bottomToolbar = nil;
  cellOwner = nil;
}

-(void)dealloc {
  [indicatorImage release];
  indicatorImage = nil;
  /*[listOfAttractionIds release];
  [menuList release];
  [category release];
  [parkId release];
  [titleName release];
  [subtitleName release];*/
  [theTableView release];
  [topNavigationBar release];
  [titleOfTable release];
  [bottomToolbar release];
  [cellOwner release];
  [super dealloc];
}

@end
