//
//  ParkSelectionViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 21.05.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ParkSelectionViewController.h"
#import "ParkMainMenuViewController.h"
#import "MenuItem.h"
#import "MenuData.h"
#import "ParkData.h"
#import "ProfileData.h"
#import "SettingsData.h"
#import "HelpData.h"
#import "LocationData.h"
#import "InAppSettingsViewController.h"
#import "TutorialViewController.h"
#import "GeneralInfoViewController.h"
#import "UpdateViewController.h"
#import "SearchViewController.h"
#import "CustomBadge.h"
#import "Colors.h"
#import "iRate.h"

@implementation ParkSelectionViewController

// sigletons because of receiving memory warnings and destructor
static NSMutableArray *menuList = nil;
static NSMutableArray *parkCountryIds = nil;
static NSMutableDictionary *allParkDetails = nil;

@synthesize theTableView;
@synthesize topNavigationBar;
@synthesize titleOfTable;
@synthesize loadDataActivityIndicator;
@synthesize helpButton;
@synthesize bottomToolbar;
@synthesize noDataLabel;

static BOOL updateViewCalled = NO;
static BOOL viewInitialized = NO;

-(id)initWithNibName:(NSString *)nibNameOrNil {
  //SettingsData *settings = [SettingsData getSettingsData];
  //[settings setFacebookLike:NO];
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    [menuList release];
    menuList = [[NSMutableArray alloc] initWithCapacity:50];
    [parkCountryIds release];
    parkCountryIds = [[NSMutableArray alloc] initWithCapacity:20];
    [allParkDetails release];
    allParkDetails = [[NSMutableDictionary alloc] initWithCapacity:20];
    checkDataOnlyFirstCall = YES;
  }
  return self;
}

-(void)updateAvailableUpdates:(id)sender {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  numberOfAvailableUpdates = [ParkData availableUpdates:(sender != nil)];
  [self performSelectorOnMainThread:@selector(updateParksData) withObject:nil waitUntilDone:NO];
  [pool release];
}

-(void)updateParksData {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [menuList removeAllObjects];
  NSArray *parkIds = nil;
  if (updateViewCalled) {
    parkIds = [MenuData getParkIds];
    [parkCountryIds removeAllObjects];
    [allParkDetails removeAllObjects];
    for (NSString *pId in parkIds) {
      NSDictionary *details = [MenuData getParkDetails:pId cache:NO];
      NSString *country = [MenuData objectForKey:@"Land" at:details];
      if (country != nil) {
        if (![parkCountryIds containsObject:country]) [parkCountryIds addObject:country];
      }
      NSMutableDictionary *parkDetails = [[NSMutableDictionary alloc] initWithCapacity:5];
      [parkDetails setValue:country forKey:@"Land"];
      [parkDetails setValue:[MenuData objectForKey:@"Parkname" at:details] forKey:@"Parkname"];
      [parkDetails setValue:[details objectForKey:@"Logo"] forKey:@"Logo"];
      [parkDetails setValue:[MenuData objectForKey:@"Stadt" at:details] forKey:@"Stadt"];
      [allParkDetails setValue:parkDetails forKey:pId];
      [parkDetails release];
    }
    [parkCountryIds sortUsingSelector:@selector(compare:)];
    if (PARK_ID_EDITION != nil) [parkCountryIds addObject:NSLocalizedString(@"info", nil)];
    updateViewCalled = NO;
  } else {
    parkIds = [allParkDetails allKeys];
  }
  noDataLabel.hidden = ([parkIds count] > 0);
  for (NSString *pId in parkIds) {
    NSDictionary *details = [allParkDetails objectForKey:pId];
    NSString *country = [details objectForKey:@"Land"];
    NSNumber *order = [NSNumber numberWithInt:(country != nil)? [parkCountryIds indexOfObject:country]*([parkIds count]-1) : 0];
    MenuItem *m = [[MenuItem alloc] initWithMenuId:pId order:order distance:0.0 tolerance:0.0 name:[details objectForKey:@"Parkname"] imageName:[details objectForKey:@"Logo"] closed:NO];
    m.fileName = country;
    m.badgeText = [details objectForKey:@"Stadt"];
    [menuList addObject:m];
    [m release];
  }
  if (PARK_ID_EDITION != nil) {
    MenuItem *m = [[MenuItem alloc] initWithMenuId:nil order:nil distance:0.0 tolerance:0.0 name:NSLocalizedString(@"inpark.full.version", nil) imageName:@"inpark@2x.png" closed:NO];
    m.fileName = NSLocalizedString(@"info", nil);
    [menuList addObject:m];
    [m release];
  }
  [menuList sortUsingSelector:@selector(compare:)];
  if (viewInitialized) {
    if (customBadge != nil) {
      [customBadge removeFromSuperview];
      [customBadge release];
      customBadge = nil;
    }
    if (facebookButton != nil) {
      [facebookButton removeFromSuperview];
      [facebookButton release];
      facebookButton = nil;
    }
    if (facebookWebView != nil) {
      [facebookWebView removeFromSuperview];
      [facebookWebView release];
      facebookWebView = nil;
    }
    theTableView.rowHeight = 106;
#if defined(DEBUG_MAP) || defined(DEBUG_TOUR_OPTIMIZE) || defined(DEBUG_TOUR)
    titleOfTable.title = [NSString stringWithFormat:@"DEBUG: %@", NSLocalizedString(@"menu.park.selection", nil)];
#else
    titleOfTable.title = NSLocalizedString(@"menu.park.selection", nil);
#endif
    theTableView.scrollEnabled = YES;
    CGRect rTable = theTableView.frame;
    // crash: not initialized after memory warning
    if (rTable.origin.x != NAN && rTable.origin.y != NAN && rTable.size.height > 0 && rTable.size.width > 0) {
      float y = topNavigationBar.frame.size.height;
      float h = bottomToolbar.frame.origin.y-y-topNavigationBar.frame.origin.y;
      //SettingsData *settings = [SettingsData getSettingsData];
      //if (!settings.facebookLike) {
      facebookButton = [[UIButton alloc] initWithFrame:CGRectMake(rTable.origin.x+rTable.size.width-23.0f, y+2.0f, 21.0f, 20.5f)];
      facebookButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
      [facebookButton setImage:[UIImage imageNamed:@"facebook.png"] forState:UIControlStateNormal];
      [facebookButton addTarget:self action:@selector(facebookLike) forControlEvents:UIControlEventTouchUpInside];
      [self.view addSubview:facebookButton];
      theTableView.frame = CGRectMake(rTable.origin.x, y+facebookButton.frame.size.height+4.0f, rTable.size.width, h-facebookButton.frame.size.height-4.0f);
      /*} else {
       theTableView.frame = CGRectMake(rTable.origin.x, y, rTable.size.width, h);
       }*/
      //int numberOfAvailableUpdates = [ParkData availableUpdates:NO];
      if (numberOfAvailableUpdates > 0 || !noDataLabel.hidden) {
        customBadge = [[CustomBadge customBadgeWithString:(noDataLabel.hidden)? [NSString stringWithFormat:@"%d", numberOfAvailableUpdates] : @"!"] retain];
        customBadge.frame = CGRectMake(26, bottomToolbar.frame.origin.y+2, customBadge.frame.size.width, customBadge.frame.size.height);
        customBadge.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self.view addSubview:customBadge];
      }
    }
    bottomToolbar.hidden = NO;
  }
  [theTableView reloadData];
  HelpData *helpData = [HelpData getHelpData];
  helpButton.hidden = ([helpData.pages objectForKey:@"Park"] == nil);
  [pool release];
  theTableView.hidden = NO;
  [loadDataActivityIndicator stopAnimating];
}

#pragma mark -
#pragma mark View lifecycle

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  // Achtung: kritisch, wenn Memory-Warnungen im modalen Fenster aufgetreten sind
  theTableView.hidden = YES;
  [loadDataActivityIndicator startAnimating];
  [self performSelectorInBackground:@selector(updateAvailableUpdates:) withObject:nil];
  //[self updateParksData];
  [super dismissModalViewControllerAnimated:animated];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  viewInitialized = YES;
  updateViewCalled = YES;
  self.view.backgroundColor = [Colors darkBlue];
  theTableView.backgroundColor = [Colors darkBlue];
  theTableView.backgroundView = nil;
  topNavigationBar.tintColor = [Colors darkBlue];
  bottomToolbar.tintColor = [Colors darkBlue];
  noDataLabel.text = NSLocalizedString(@"welcome.no.park.data", nil);
  noDataLabel.textColor = [Colors lightText];
  noDataLabel.hidden = YES;
  indicatorImage = [[UIImage imageNamed:@"indicator.png"] retain];
  //[self updateParksData];
  float n = 100; //theTableView.rowHeight-6;
  UIGraphicsBeginImageContextWithOptions(CGSizeMake(n, n), NO, 0.0);
  blankImage = UIGraphicsGetImageFromCurrentImageContext();
  [blankImage retain];
  UIGraphicsEndImageContext();
  theTableView.hidden = YES;
  [loadDataActivityIndicator startAnimating];
  [self updateParksData];
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
      [self performSelector:@selector(updateView:) withObject:nil afterDelay:0.8];
    } else if ([parkIds count] == 0) {
      noDataLabel.hidden = NO;
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"update.no.parks.title", nil)
                             message:NSLocalizedString(@"update.no.parks", nil)
                             delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:nil];
      [dialog show];
      [dialog release];
      [self performSelector:@selector(updateView:) withObject:self afterDelay:0.8];
    } else {
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
      [self performSelectorInBackground:@selector(updateAvailableUpdates:) withObject:nil];
    }
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

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
	// ToDo: [self.myTableView deselectRowAtIndexPath:self.myTableView.indexPathForSelectedRow animated:NO];
  //[theTableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [parkCountryIds count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSString *country = [parkCountryIds objectAtIndex:section];
  int n = 0;
  for (MenuItem *item in menuList) {
    if ([item.fileName isEqualToString:country]) ++n;
  }
  return n;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return [parkCountryIds objectAtIndex:section];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"ParkSelectionCell";
  static NSString *cellId2 = @"ParkSelectionCell2";
  MenuItem *m = nil;
  NSString *country = [parkCountryIds objectAtIndex:indexPath.section];
  int n = -1;
  for (MenuItem *item in menuList) {
    if ([item.fileName isEqualToString:country] && ++n == indexPath.row) {
      m = item;
      break;
    }
  }
  BOOL twoLines = ([m.menuId length] == 0);
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(twoLines)? cellId2 : cellId];
  if (cell == nil) {
    if (twoLines) {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId2] autorelease];
    } else {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId] autorelease];
      cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
      cell.textLabel.textAlignment = UITextAlignmentCenter;
      cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
      UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicatorImage];
      cell.accessoryView = indicatorView;
      [indicatorView release];
      n = tableView.rowHeight-6;
      CGRect r = cell.imageView.frame;
      cell.imageView.frame = CGRectMake(r.origin.x, r.origin.y, n, n);
      cell.imageView.image = blankImage;
      AsynchronousImageView *imageView = [[AsynchronousImageView alloc] initWithFrame:CGRectMake(r.origin.x+2, r.origin.y+2, n, n)];
      imageView.layer.masksToBounds = YES;
      imageView.layer.cornerRadius = 7.0;
      imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
      imageView.layer.borderWidth = 2.0;
      imageView.tag = 3;
      [cell.contentView addSubview:imageView];
      [imageView release];
    }
    cell.detailTextLabel.textColor = [Colors lightText];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [Colors lightText];
    cell.textLabel.shadowColor = [UIColor blackColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
    cell.backgroundColor = [Colors lightBlue];
  }
  /*NSInteger sectionRows = [tableView numberOfRowsInSection:indexPath.section];
   NSInteger row = indexPath.row;
   if (row == 0 && row == sectionRows-1) ((UIImageView *)cell.backgroundView).image = [UIImage imageNamed:@"topAndBottomRow.png"];
   else if (row == 0) ((UIImageView *)cell.backgroundView).image = [UIImage imageNamed:@"topRow.png"];
   else if (row == sectionRows-1) ((UIImageView *)cell.backgroundView).image = [UIImage imageNamed:@"bottomRow.png"];
   else ((UIImageView *)cell.backgroundView).image = [UIImage imageNamed:@"middleRow.png"];*/
  NSString *s = m.imageName;
  cell.textLabel.text = m.name;
  if (twoLines) {
    cell.imageView.image = [UIImage imageNamed:s];
    cell.detailTextLabel.text = NSLocalizedString(@"inpark.full.version.why", nil);
  } else {
    [(AsynchronousImageView *)[cell.contentView viewWithTag:3] setImagePath:[[MenuData parkDataPath:m.menuId] stringByAppendingPathComponent:s]];
    cell.detailTextLabel.text = m.badgeText; // city
  }
  cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
  cell.textLabel.numberOfLines = 3;
  cell.textLabel.textAlignment = UITextAlignmentCenter;
  cell.imageView.transform = CGAffineTransformIdentity;
  //cell.backgroundView = nil;
  cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

#pragma mark -
#pragma mark Load park threads

-(void)viewPark:(NSString *)parkId {
  ParkMainMenuViewController *controller = [[ParkMainMenuViewController alloc] initWithNibName:@"ParkMainMenuView" owner:self parkId:parkId];
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
  NSIndexPath *indexPath = [theTableView indexPathForSelectedRow];
  if (indexPath != nil) [theTableView deselectRowAtIndexPath:indexPath animated:NO];
  theTableView.hidden = NO;
  [loadDataActivityIndicator stopAnimating];
}

-(void)loadParkData:(NSString *)parkId {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  ParkData *parkData = [ParkData getParkData:parkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData]; // to check if calendar refresh is needed
  CalendarData *calendarData = [parkData getCalendarData];
  [self performSelectorOnMainThread:@selector(viewPark:) withObject:parkId waitUntilDone:YES];
  if (![parkData isInitialized]) {
    NSArray *parkIds = [MenuData getParkIds];
    for (NSString *pId in parkIds) {
      if (![pId isEqualToString:parkId]) {
        ParkData *pData = [ParkData getParkData:pId];
        [pData clearCachedData];
      }
    }
    [parkData setupData];
  }
  while (!waitingTimeData.initialized) [NSThread sleepForTimeInterval:0.5];
  [calendarData updateIfNecessary];
  [pool release];
  //[self performSelectorOnMainThread:@selector(viewPark:) withObject:parkId waitUntilDone:NO];
}

#pragma mark -
#pragma mark Table view delegate

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return UITableViewCellEditingStyleDelete;
  // (tableView.editing)? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!loadDataActivityIndicator.hidden) return nil;
  MenuItem *selectedRow = nil;
  NSString *country = [parkCountryIds objectAtIndex:indexPath.section];
  int n = -1;
  for (MenuItem *item in menuList) {
    if ([item.fileName isEqualToString:country] && ++n == indexPath.row) {
      selectedRow = item;
      break;
    }
  }
  if (selectedRow != nil && [ParkData checkIfUpdateIsNeeded:selectedRow.menuId]) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:selectedRow.name
                           message:NSLocalizedString(@"update.park.data", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
    [self updateView:[NSArray arrayWithObject:selectedRow.menuId]];
    return nil;
  }
  return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (customBadge != nil) {
    [customBadge removeFromSuperview];
    [customBadge release];
    customBadge = nil;
  }
  MenuItem *selectedRow = nil;
  NSString *country = [parkCountryIds objectAtIndex:indexPath.section];
  int n = -1;
  for (MenuItem *item in menuList) {
    if ([item.fileName isEqualToString:country] && ++n == indexPath.row) {
      selectedRow = item;
      break;
    }
  }
  if (selectedRow != nil) {
    if ([selectedRow.menuId length] == 0) {
      GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:@"inpark.txt" title:@"inpark.full.version"];
      controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];  
    } else {
      [loadDataActivityIndicator startAnimating];
      [NSThread detachNewThreadSelector:@selector(loadParkData:) toTarget:self withObject:selectedRow.menuId];
      //[self viewPark:selectedRow.menuId];
    }
  }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return tableView.rowHeight;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 30.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)] autorelease];
  headerView.backgroundColor = [Colors darkBlue];
  UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(36, 4, tableView.bounds.size.width, 22)] autorelease];
  NSString *country = [parkCountryIds objectAtIndex:section];
  headerLabel.text = country;
  headerLabel.textColor = [Colors lightText];
  headerLabel.shadowColor = [UIColor blackColor];
  headerLabel.shadowOffset = CGSizeMake(0, 1);
  headerLabel.font = [UIFont boldSystemFontOfSize:16];
  headerLabel.backgroundColor = [UIColor clearColor];
  [headerView addSubview:headerLabel];
  UIImageView *flagView = [[[UIImageView alloc] initWithFrame:CGRectMake(4, 7, 25, 15)] autorelease];
  NSString *countryFlag = [NSString stringWithFormat:@"%@.flag", country];
  UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[MenuData dataPath] stringByAppendingPathComponent:NSLocalizedString(countryFlag, nil)]];
  flagView.image = image;
  [image release];
  [headerView addSubview:flagView];
  return headerView;
}

static NSString *selectedParkIdForDelete = nil;
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    MenuItem *m = nil;
    NSString *country = [parkCountryIds objectAtIndex:indexPath.section];
    int n = -1;
    for (MenuItem *item in menuList) {
      if ([item.fileName isEqualToString:country] && ++n == indexPath.row) {
        m = item;
        break;
      }
    }
    selectedParkIdForDelete = m.menuId;
    NSDictionary *details = [[MenuData getParkDetails:selectedParkIdForDelete cache:YES] retain];
    if (details != nil) {
      NSString *parkName = [MenuData objectForKey:@"Parkname" at:details];
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"dialog.delete.park.title", nil)
                             message:[NSString stringWithFormat:NSLocalizedString(@"dialog.delete.park.text", nil), parkName]
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"no", nil)
                             otherButtonTitles:NSLocalizedString(@"yes", nil), nil];
      dialog.tag = 1;
      [dialog show];
      [dialog release];
      [details release];
    }
  }   
}

#pragma mark -
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
  if (alertView.tag == 1) {
    if (selectedParkIdForDelete != nil && [buttonTitle isEqualToString:NSLocalizedString(@"yes", nil)]) {
      [ParkData removeParkData:selectedParkIdForDelete];
      updateViewCalled = YES;
      [self performSelectorInBackground:@selector(updateAvailableUpdates:) withObject:self];
    }
    selectedParkIdForDelete = nil;
  } else if (alertView.tag == 2) {
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
#pragma mark Action sheet delegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
  if ([buttonTitle isEqualToString:NSLocalizedString(@"about.title", nil)]) {  // About
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:@"about.txt" title:@"about.title"];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];  
  } else if ([buttonTitle isEqualToString:NSLocalizedString(@"settings.title", nil)]) {  // Settings
    InAppSettingsViewController *controller = [[InAppSettingsViewController alloc] initWithNibName:@"InAppSettingsView" owner:self];
    controller.preferenceTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];  
  } else if ([buttonTitle isEqualToString:NSLocalizedString(@"profile.title", nil)]) {  // Profile
    InAppSettingsViewController *controller = [[InAppSettingsViewController alloc] initWithNibName:@"InAppSettingsView" owner:self];
    controller.preferenceTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    controller.preferenceSpecifiers = @"Profile";
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
    SettingsData *settings = [SettingsData getSettingsData];
    if (!settings.profileKnown) [settings setProfileKnown:YES];
  } else if ([buttonTitle isEqualToString:NSLocalizedString(@"feedback.title", nil)]) {  // Feedback
    [self sendFeedback];
  } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tutorial.title", nil)]) {  // Tutorial
    TutorialViewController *controller = [[TutorialViewController alloc] initWithNibName:@"TutorialView" owner:self helpData:[HelpData getHelpData]];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];  
  } else if ([buttonTitle isEqualToString:NSLocalizedString(@"release.notes", nil)]) {  // Release notes
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:@"version.txt" title:@"release.notes"];
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

#pragma mark -
#pragma mark Actions

-(IBAction)searchView:(id)sender {
  NSMutableArray *mustUpdateParkIds = [[[NSMutableArray alloc] initWithCapacity:6] autorelease];
  for (NSString *parkId in [MenuData getParkIds]) {
    if ([ParkData checkIfUpdateIsNeeded:parkId]) [mustUpdateParkIds addObject:parkId];
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
  SearchViewController *controller = [[SearchViewController alloc] initWithNibName:@"SearchView" owner:self parkDetails:allParkDetails];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

-(IBAction)helpView:(id)sender {
  HelpData *helpData = [HelpData getHelpData];
  NSString *page = [helpData.pages objectForKey:@"Park"];
  NSString *title = [helpData.titles objectForKey:@"Park"];
  if (title != nil && page != nil) {
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
    controller.content = page;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(IBAction)updateView:(id)sender {
  updateViewCalled = YES;
  UpdateViewController *controller = [[UpdateViewController alloc] initWithNibName:@"UpdateView" owner:self];
  if (sender != nil && [sender isKindOfClass:[NSArray class]]) {
    NSArray *parkIds = sender;
    controller.mustUpdateParkGroupIds = parkIds;
  }
  controller.checkVersionInfo = YES;
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

-(IBAction)settingsView:(id)sender {
  UIActionSheet *sheet = [[UIActionSheet alloc]
                          initWithTitle:NSLocalizedString(@"about.action.sheet.title", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                          destructiveButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"settings.title", nil),
                          NSLocalizedString(@"profile.title", nil),
                          nil];
  [sheet showFromToolbar:bottomToolbar];
  UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
  backgroundView.backgroundColor = [Colors darkBlue];
  backgroundView.opaque = NO;
  backgroundView.alpha = 0.5;
  [sheet insertSubview:backgroundView atIndex:0];
  [backgroundView release];
  [sheet release];
}

-(IBAction)aboutPage:(id)sender {
  UIActionSheet *sheet = [[UIActionSheet alloc]
                          initWithTitle:NSLocalizedString(@"about.action.sheet.title", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                          destructiveButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"feedback.title", nil),
                          NSLocalizedString(@"tutorial.title", nil),
                          NSLocalizedString(@"about.title", nil),
                          NSLocalizedString(@"release.notes", nil),
                          nil];
  [sheet showFromToolbar:bottomToolbar];
  UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
  backgroundView.backgroundColor = [Colors darkBlue];
  backgroundView.opaque = NO;
  backgroundView.alpha = 0.5;
  [sheet insertSubview:backgroundView atIndex:0];
  [backgroundView release];
  [sheet release];
}

/*-(IBAction)editView:(id)sender {
  BOOL editing = !theTableView.editing;
  [theTableView setEditing:editing animated:YES];
  UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(editing)? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit target:self action:@selector(editView:)];
  NSMutableArray *items = [[NSMutableArray alloc] initWithArray:bottomToolbar.items];
  [items removeLastObject];
  [items addObject:editButton];
  [editButton release];
  bottomToolbar.items = items;
  [items release];
}*/

#pragma mark -
#pragma mark Mail compose delegate

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {	
	switch (result)	{
		case MFMailComposeResultCancelled:
			//message.text = @"Result: canceled";
			break;
		case MFMailComposeResultSaved:
			//message.text = @"Result: saved";
			break;
		case MFMailComposeResultSent:
			//message.text = @"Result: sent";
			break;
		case MFMailComposeResultFailed:
			//message.text = @"Result: failed";
			break;
		default:
			//message.text = @"Result: not sent";
			break;
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

-(void)sendFeedback {
  if ([MFMailComposeViewController canSendMail]) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"feedback.subject", nil)
                           message:NSLocalizedString(@"feedback.body", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;
    [mailController setToRecipients:[NSArray arrayWithObject:NSLocalizedString(@"feedback.email", nil)]];
    [mailController setSubject:NSLocalizedString(@"feedback.subject", nil)];
    NSString *emailBody = [NSString stringWithFormat:@"%@: %@\n\n%@", NSLocalizedString(@"version", nil), [SettingsData getAppVersionLong], [[ParkData getParkDataVersions] stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""]];
    [mailController setMessageBody:emailBody isHTML:NO];
    [self presentViewController:mailController animated:YES completion:nil];
    [mailController release];
  }
}

-(void)facebookLike {
  /*float y = topNavigationBar.frame.size.height;
  float h = bottomToolbar.frame.origin.y-h;
  CGRect rTable = theTableView.frame;
  theTableView.frame = CGRectMake(rTable.origin.x, y+204.0f, rTable.size.width, h-204.0f);
  CGRect r = [[UIScreen mainScreen] bounds];
  FBLikeButton *likeButton = [[FBLikeButton alloc] initWithFrame:CGRectMake(0, y+2.0f, r.size.width, 200) andUrl:@"www.facebook.com/pages/InPark/213988965299098"];
  [self.view addSubview:likeButton];
  [likeButton release];*/
  //SettingsData *settings = [SettingsData getSettingsData];
  //[settings setFacebookLike:YES];
  //[self updateParksData];
  NSString *facebookURL = [[SettingsData currentLanguage] isEqualToString:@"de.lproj"]? @"http://www.facebook.com/InPark.Guide" : @"http://www.facebook.com/InParkApp";
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:facebookURL]];
  /*[facebookButton removeFromSuperview];
  [facebookButton release];
  facebookButton = nil;
  CGRect r = [[UIScreen mainScreen] bounds];
  float y = topNavigationBar.frame.size.height;
  float h = bottomToolbar.frame.origin.y-h;
  CGRect rTable = theTableView.frame;
  theTableView.frame = CGRectMake(rTable.origin.x, y+404.0f, rTable.size.width, h-404.0f);
  facebookWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, y+2.0f, r.size.width, 400)];
  facebookWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  NSString *likeButtonIframe = @"<iframe src=\"http://www.facebook.com/plugins/like.php?app_id=218295878229334&amp;href=http%3A%2F%2Fwww.facebook.com%2Fpages%2FInPark%2F213988965299098&amp;send=false&amp;layout=standard&amp;width=310&amp;show_faces=false&amp;action=like&amp;colorscheme=light&amp;font&amp;height=35\" scrolling=\"no\" frameborder=\"0\" style=\"border:none; overflow:hidden; width:310px; height:35px;\" allowTransparency=\"true\"></iframe>";
  //NSString *likeButtonIframe = @"<iframe src=\"http://www.facebook.com/plugins/likebox.php?href=http%3A%2F%2Fwww.facebook.com%2Fpages%2FInPark%2F213988965299098&amp;width=292&amp;colorscheme=light&amp;show_faces=false&amp;border_color&amp;stream=false&amp;header=false&amp;height=62\" scrolling=\"no\" frameborder=\"0\" style=\"border:none; overflow:hidden; width:292px; height:62px;\" allowTransparency=\"true\"></iframe>";
  //NSString *likeButtonIframe = @"<script>(function(d){        var js, id = 'facebook-jssdk'; if (d.getElementById(id)) {return;}        js = d.createElement('script'); js.id = id; js.async = true;        js.src = \"//connect.facebook.net/en_US/all.js#xfbml=1\";        d.getElementsByTagName('head')[0].appendChild(js);      }(document));</script>      <div class=\"fb-like-box\" data-href=\"http://www.facebook.com/pages/InPark/213988965299098\" data-width=\"292\" data-show-faces=\"false\" data-stream=\"false\" data-header=\"false\"></div>";
  [facebookWebView loadHTMLString:[NSString stringWithFormat:@"<html><head><script>document.ontouchmove = function(event) { if (document.body.scrollHeight == document.body.clientHeight) event.preventDefault();}</script></head><body>%@</body></html>", likeButtonIframe] baseURL:nil];
  [self.view addSubview:facebookWebView];*/
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
 // Releases the view if it doesn't have a superview.
 [super didReceiveMemoryWarning];
 // Relinquish ownership any cached data, images, etc that aren't in use.
  NSLog(@"Memory waring at Park Selection View Controller");
  viewInitialized = NO;
}

-(void)viewDidUnload {
  [super viewDidUnload];
  viewInitialized = NO;
  theTableView = nil;
  topNavigationBar = nil;
  titleOfTable = nil;
  loadDataActivityIndicator = nil;
  helpButton = nil;
  bottomToolbar = nil;
  noDataLabel = nil;
}

-(void)dealloc {
  [indicatorImage release];
  indicatorImage = nil;
  [blankImage release];
  blankImage = nil;
  [customBadge removeFromSuperview];
  [customBadge release];
  customBadge = nil;
  [facebookButton removeFromSuperview];
  [facebookButton release];
  facebookButton = nil;
  [facebookWebView removeFromSuperview];
  [facebookWebView release];
  facebookWebView = nil;
  [theTableView release];
  [topNavigationBar release];
  [titleOfTable release];
  [loadDataActivityIndicator release];
  [helpButton release];
  [bottomToolbar release];
  [noDataLabel release];
  [super dealloc];
}

@end
