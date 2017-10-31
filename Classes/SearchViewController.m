//
//  SearchViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "SearchViewController.h"
#import "AttractionViewController.h"
#import "SearchSettingsViewController.h"
#import "GeneralInfoViewController.h"
#import "AttractionCell.h"
#import "Attraction.h"
#import "ParkData.h"
#import "SettingsData.h"
#import "ProfileData.h"
#import "MenuData.h"
#import "MenuItem.h"
#import "HelpData.h"
#import "Colors.h"

@implementation SearchViewController

static BOOL viewInitialized = NO;
static SearchData *searchData = nil;
static NSMutableArray *resultList = nil;

@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize theSearchBar;
@synthesize theTableView;
@synthesize searchIndicator;
@synthesize cellOwner;

#pragma mark -
#pragma mark View lifecycle

+(void)clearResultList {
  [resultList removeAllObjects];
  for (NSString *parkId in searchData.searchedParkIds) {
    [resultList addObject:[NSArray arrayWithObjects:nil]];
  }
}

+(BOOL)isResultListEmpty {
  for (NSString *parkId in searchData.searchedParkIds) {
    if ([resultList count] > 0) return NO;;
  }
  return YES;
}

-(void)setupSearchData {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [searchData release];
  searchData = nil;
  [resultList release];
  resultList = nil;
  searchData = [[SearchData alloc] initWithDetails:allParkDetails];
  resultList = [[NSMutableArray alloc] initWithCapacity:[searchData.searchedParkIds count]];
  [SearchViewController clearResultList];
  [self performSelectorOnMainThread:@selector(updateView) withObject:nil waitUntilDone:NO];
  [pool release];
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkDetails:(NSDictionary *)parkDetails {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    allParkDetails = [parkDetails retain];
  }
  return self;
}

-(void)dealloc {
  [allParkDetails release];
  [indicatorImage release];
  indicatorImage = nil;
  [topNavigationBar release];
  [titleNavigationItem release];
  [theSearchBar release];
  [theTableView release];
  [searchIndicator release];
  [cellOwner release];
  [super dealloc];
}

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
  NSLog(@"Memory waring at Search View Controller");
  viewInitialized = NO;
}

#pragma mark - View lifecycle

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  // Achtung: kritisch, wenn Memory-Warnungen im modalen Fenster aufgetreten sind
  if (viewInitialized) {
    [SearchViewController clearResultList];
    [theTableView reloadData];
    [theSearchBar becomeFirstResponder];
  }
  searchEnabled = YES;
  [super dismissModalViewControllerAnimated:animated];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  viewInitialized = YES;
  searchEnabled = YES;
  indicatorImage = [[UIImage imageNamed:@"indicator60.png"] retain];
  topNavigationBar.tintColor = [Colors darkBlue];
  theSearchBar.tintColor = [Colors darkBlue];
  theTableView.backgroundColor = [Colors darkBlue];
  theTableView.backgroundView = nil;
  theTableView.separatorColor = [Colors darkBlue];
  titleNavigationItem.title = NSLocalizedString(@"search.title", nil);
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  titleNavigationItem.rightBarButtonItem.title = NSLocalizedString(@"settings.title", nil);
  titleNavigationItem.leftBarButtonItem.enabled = NO;
  titleNavigationItem.rightBarButtonItem.enabled = NO;
  [searchIndicator startAnimating];
  searchIndicator.hidden = NO;
  [self performSelectorInBackground:@selector(setupSearchData) withObject:nil];
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [theSearchBar becomeFirstResponder];
}

-(void)viewDidUnload {
 [super viewDidUnload];
  viewInitialized = NO;
  topNavigationBar = nil;
  titleNavigationItem = nil;
  theTableView = nil;
  searchIndicator = nil;
  cellOwner = nil;
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
  int n = 0;
  for (NSArray *items in resultList) {
    if ([items count] > 0) ++n;
  }
  return n;
}

-(NSString *)getParkIdForSection:(NSInteger)section {
  int n = -1;
  int idx = 0;
  for (NSString *parkId in searchData.searchedParkIds) {
    NSArray *items = [resultList objectAtIndex:idx];
    if ([items count] > 0 && ++n == section) return parkId;
    ++idx;
  }
  return nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSString *parkId = [self getParkIdForSection:section];
  if (parkId == nil) return 0;
  NSUInteger idx = [searchData.searchedParkIds indexOfObject:parkId];
  if (idx == NSNotFound) return 0;
  return [[resultList objectAtIndex:idx] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  NSString *parkId = [self getParkIdForSection:section];
  if (parkId == nil) return @"";
  NSUInteger idx = [searchData.searchedParkIds indexOfObject:parkId];
  if (idx == NSNotFound) return [[searchData.allParkDetails objectForKey:parkId] objectForKey:@"Parkname"];
  NSArray *menuItems = [resultList objectAtIndex:idx];
  return [NSString stringWithFormat:@"%@ (%d)", [[searchData.allParkDetails objectForKey:parkId] objectForKey:@"Parkname"], [menuItems count]];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *parkId = [self getParkIdForSection:indexPath.section];
  NSUInteger idx = [searchData.searchedParkIds indexOfObject:parkId];
  if (idx == NSNotFound) return nil;
  NSArray *menuItems = [resultList objectAtIndex:idx];
  MenuItem *menuItem = [menuItems objectAtIndex:indexPath.row];
  static NSString *appCellId = @"AttractionCell";
  AttractionCell *appCell = (AttractionCell *)[tableView dequeueReusableCellWithIdentifier:appCellId];
  if (appCell == nil) {
    [cellOwner loadNibNamed:appCellId owner:self];
    appCell = (AttractionCell *)cellOwner.cell;
    appCell.attractionNameLabel.textColor = [Colors hilightText];
    appCell.categoryLabel.textColor = [Colors lightText];
    appCell.locationLabel.textColor = [Colors lightText];
    appCell.fitPreferenceLabel.textColor = [Colors lightText];
    appCell.backgroundColor = [Colors lightBlue];
    appCell.iconView.backgroundColor = [Colors lightBlue];
    appCell.iconView.imageView.backgroundColor = [Colors lightBlue];
  }
  UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicatorImage];
  appCell.accessoryView = indicatorView;
  [indicatorView release];
  // ToDo: check what is faster [appCell setIcon:selectedAttraction.image];
  //[appCell setIcon:[UIImage imageNamed:m.imageName]];
  [appCell setIconPath:[[MenuData parkDataPath:parkId] stringByAppendingPathComponent:menuItem.imageName]];
  [appCell setAttractionName:menuItem.name];
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:menuItem.menuId];
  [appCell setLocation:[MenuData objectForKey:ATTRACTION_THEME_AREA at:[attraction getAttractionDetails:parkId cache:YES]]];
  [appCell setCategory:attraction.typeName];
  [appCell setPreferenceFit:(1.0-menuItem.order/100.0)];
  [appCell setPreferenceHidden:(appCell.fitPreferenceView.preferenceFit == 0.0)];
  ParkData *parkData = [ParkData getParkData:parkId];
  appCell.favoriteView.hidden = ![parkData isFavorite:attraction.attractionId];
  return appCell;
}

#pragma mark -
#pragma mark Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 70.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 30.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)] autorelease];
  headerView.backgroundColor = [Colors darkBlue];
  UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(36, 4, tableView.bounds.size.width, 22)] autorelease];
  headerLabel.text = [self tableView:tableView titleForHeaderInSection:section];
  headerLabel.textColor = [Colors lightText];
  headerLabel.shadowColor = [UIColor blackColor];
  headerLabel.shadowOffset = CGSizeMake(0, 1);
  headerLabel.font = [UIFont boldSystemFontOfSize:16];
  headerLabel.backgroundColor = [UIColor clearColor];
  [headerView addSubview:headerLabel];
  return headerView;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *parkId = [self getParkIdForSection:indexPath.section];
  NSUInteger idx = [searchData.searchedParkIds indexOfObject:parkId];
  if (idx == NSNotFound) return;
  NSArray *menuItems = [resultList objectAtIndex:idx];
  MenuItem *menuItem = [menuItems objectAtIndex:indexPath.row];
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:menuItem.menuId];
  AttractionViewController *controller = [[AttractionViewController alloc] initWithNibName:@"AttractionView" owner:self attraction:attraction parkId:parkId];
  controller.enableAddToTour = NO;
  controller.enableWalkToAttraction = NO;
  //controller.enableViewAllPicturesButton = NO;
  controller.enableViewOnMap = NO;
  controller.enableWaitTime = NO;
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
  [theTableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark UISearchBarDelegate Methods

-(void)updateView {
  titleNavigationItem.leftBarButtonItem.enabled = YES;
  titleNavigationItem.rightBarButtonItem.enabled = YES;
  [theTableView reloadData];
  if ([SearchViewController isResultListEmpty]) [theSearchBar becomeFirstResponder];
  [searchIndicator stopAnimating];
  searchIndicator.hidden = YES;
}

-(void)search:(NSString *)text {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSDictionary *searchResult = [searchData search:text];
  ProfileData *profileData = [ProfileData getProfileData];
  [searchResult enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSString *parkId = key;
    NSArray *attractions = object;
    ParkData *parkData = [ParkData getParkData:parkId];
    NSMutableArray *menuItems = [[NSMutableArray alloc] initWithCapacity:[attractions count]];
    for (Attraction *attraction in attractions) {
      int rating = [parkData getPersonalRating:attraction.attractionId];
      double preferenceFit = [profileData percentageOfPreferenceFit:attraction parkId:parkId personalAttractionRating:rating adultAge:parkData.adultAge];
      MenuItem *m = [[MenuItem alloc] initWithMenuId:attraction.attractionId
                                               order:[NSNumber numberWithInt:(int)(100-preferenceFit*100)]
                                            distance:0.0
                                           tolerance:0.0
                                                name:attraction.stringAttractionName
                                           imageName:[attraction imageName:parkId]
                                              closed:NO];
      [menuItems addObject:m];
      [m release];
    }
    [menuItems sortUsingSelector:@selector(compare:)];
    NSUInteger idx = [searchData.searchedParkIds indexOfObject:parkId];
    if (idx != NSNotFound) [resultList replaceObjectAtIndex:idx withObject:menuItems];
    else NSLog(@"Error: park %@ not found in searched park IDs", parkId);
    [menuItems release];
  }];
  [self performSelectorOnMainThread:@selector(updateView) withObject:nil waitUntilDone:NO];
  [pool release];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
  if (searchIndicator.hidden) {
    NSString *t = searchBar.text;
    if (t != nil && [t length] > 1 && [t hasSuffix:@"\n"]) [searchBar resignFirstResponder];
  }
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  if (searchIndicator.hidden) {
    [SearchViewController clearResultList];
    [theTableView reloadData];
  }
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
  if (searchIndicator.hidden && searchEnabled) {
    titleNavigationItem.leftBarButtonItem.enabled = NO;
    titleNavigationItem.rightBarButtonItem.enabled = NO;
    [searchIndicator startAnimating];
    searchIndicator.hidden = NO;
    [self performSelectorInBackground:@selector(search:) withObject:searchBar.text];
  }
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  if (searchIndicator.hidden) {
    searchBar.text = @"";
    [SearchViewController clearResultList];
    [theTableView reloadData];
  }
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  if (searchIndicator.hidden) [searchBar resignFirstResponder];
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  searchEnabled = NO;
  [delegate dismissModalViewControllerAnimated:YES];
}

-(IBAction)helpView:(id)sender {
  HelpData *helpData = [HelpData getHelpData];
  NSString *page = [helpData.pages objectForKey:@"MENU_SEARCH"];
  NSString *title = [helpData.titles objectForKey:@"MENU_SEARCH"];
  if (title != nil && page != nil) {
    searchEnabled = NO;
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    controller.content = page;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(IBAction)settingsView:(id)sender {
  searchEnabled = NO;
  SearchSettingsViewController *controller = [[SearchSettingsViewController alloc] initWithNibName:@"SearchSettingsView" owner:self searchData:searchData];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}


@end
