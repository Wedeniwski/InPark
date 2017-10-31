//
//  SearchSettingsViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "SearchSettingsViewController.h"
#import "SearchViewController.h"
#import "MenuData.h"
#import "SettingsData.h"
#import "Colors.h"

@implementation SearchSettingsViewController

@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize searchCriteriaSections, searchAccuracy;
@synthesize accuracyLabel;
@synthesize theTableView;

#pragma mark -
#pragma mark Memory management

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner searchData:(SearchData *)sData {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    searchData = [sData retain];
    parkIds = [[NSMutableArray alloc] initWithArray:[MenuData getParkIds]];
    countries = [[NSMutableDictionary alloc] initWithCapacity:[parkIds count]];
    for (NSString *parkId in parkIds) {
      NSString *country = [[searchData.allParkDetails objectForKey:parkId] objectForKey:@"Land"];
      [countries setValue:country forKey:parkId];
    }
    [parkIds sortUsingComparator:(NSComparator)^(id obj1, id obj2){
      NSString *country1 = [countries objectForKey:obj1];
      NSString *country2 = [countries objectForKey:obj2];
      NSComparisonResult result = [country1 compare:country2];
      if (result != NSOrderedSame) return result;
      NSString *parkName1 = [[searchData.allParkDetails objectForKey:obj1] objectForKey:@"Parkname"];
      NSString *parkName2 = [[searchData.allParkDetails objectForKey:obj2] objectForKey:@"Parkname"];
      return [parkName1 compare:parkName2]; }];
    attributeIds = [[SearchData defaultSearchAttributes] retain];
    numberOfCountries = 1;
    NSString *country = nil;
    for (NSString *parkId in parkIds) {
      NSString *c = [countries objectForKey:parkId];
      if (country != nil && ![c isEqualToString:country]) ++numberOfCountries;
      country = c;
    }
  }
  return self;
}

-(void)dealloc {
  [topNavigationBar release];
  [titleNavigationItem release];
  [searchCriteriaSections release];
  [searchAccuracy release];
  [accuracyLabel release];
  [theTableView release];
  [selectedImage release];
  [unselectedImage release];
  [searchData release];
  [parkIds release];
  [countries release];
  [attributeIds release];
  [super dealloc];
}

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Relinquish ownership any cached data, images, etc. that aren't in use.
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [Colors darkBlue];
  topNavigationBar.tintColor = [Colors darkBlue];
  titleNavigationItem.title = NSLocalizedString(@"search.settings.title", nil);
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  selectedImage = [[UIImage imageNamed:@"selected.png"] retain];
  unselectedImage = [[UIImage imageNamed:@"unselected.png"] retain];
  [searchCriteriaSections setTitle:NSLocalizedString(@"search.settings.park.selection", nil) forSegmentAtIndex:0];
  [searchCriteriaSections setTitle:NSLocalizedString(@"search.settings.attribute.selection", nil) forSegmentAtIndex:1];
  searchCriteriaSections.tintColor = [Colors darkBlue];
  searchCriteriaSections.backgroundColor = [Colors darkBlue];
  accuracyLabel.text = NSLocalizedString(@"search.settings.accuracy", nil);
  accuracyLabel.textColor = [Colors lightText];
  accuracyLabel.backgroundColor = [Colors darkBlue];
  if (searchData.accuracy == 1.0f) searchAccuracy.selectedSegmentIndex = 2;
  else if (searchData.accuracy == 0.9f) searchAccuracy.selectedSegmentIndex = 1;
  else searchAccuracy.selectedSegmentIndex = 0;
  searchAccuracy.tintColor = [Colors darkBlue];
  searchAccuracy.backgroundColor = [Colors darkBlue];
  theTableView.backgroundColor = [Colors darkBlue];
  theTableView.backgroundView = nil;
}

-(void)viewDidUnload {
  [super viewDidUnload];
  searchData = nil;
  parkIds = nil;
  countries = nil;
  attributeIds = nil;
  topNavigationBar = nil;
  titleNavigationItem = nil;
  searchCriteriaSections = nil;
  searchAccuracy = nil;
  accuracyLabel = nil;
  theTableView = nil;
  selectedImage = nil;
  unselectedImage = nil;
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
  return (searchCriteriaSections.selectedSegmentIndex == 0)? numberOfCountries : 1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (searchCriteriaSections.selectedSegmentIndex != 0) return nil;
  int m = 0;
  NSString *country = nil;
  for (NSString *parkId in parkIds) {
    NSString *c = [countries objectForKey:parkId];
    if (country != nil && ![c isEqualToString:country] && ++m > section) break;
    if (m == section) return c;
    country = c;
  }
  return nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (searchCriteriaSections.selectedSegmentIndex != 0) return [attributeIds count];
  int n = 0;
  int m = 0;
  NSString *country = nil;
  for (NSString *parkId in parkIds) {
    NSString *c = [countries objectForKey:parkId];
    if (country != nil && ![c isEqualToString:country] && ++m > section) break;
    if (m == section) ++n;
    country = c;
  }
  return n;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"SearchSettingCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.imageView.opaque = YES;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [Colors lightText];
    cell.textLabel.shadowColor = [UIColor blackColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
    cell.backgroundColor = [Colors lightBlue];
  }
  if (searchCriteriaSections.selectedSegmentIndex == 0) {
    int row = 0;
    int m = 0;
    NSString *country = nil;
    for (NSString *parkId in parkIds) {
      NSString *c = [countries objectForKey:parkId];
      if (country != nil && ![c isEqualToString:country]) ++m;
      if (m == indexPath.section) break;
      country = c;
      ++row;
    }
    row += indexPath.row;
    NSString *parkId = [parkIds objectAtIndex:row];
    cell.textLabel.text = [[searchData.allParkDetails objectForKey:parkId] objectForKey:@"Parkname"];
    cell.imageView.image = ([searchData.searchedParkIds containsObject:parkId])? selectedImage : unselectedImage;
  } else {
    NSString *attributeId = [attributeIds objectAtIndex:indexPath.row];
    cell.textLabel.text = attributeId;
    cell.imageView.image = ([searchData.searchedAttributes containsObject:attributeId])? selectedImage : unselectedImage;
  }
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  NSString *title = [self tableView:tableView titleForHeaderInSection:section];
  return (title == nil)? 0.0 : 30.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  NSString *title = [self tableView:tableView titleForHeaderInSection:section];
  if (title == nil) return nil;
  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)] autorelease];
  headerView.backgroundColor = [Colors darkBlue];
  UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(36, 4, tableView.bounds.size.width, 22)] autorelease];
  headerLabel.text = title;
  headerLabel.textColor = [Colors lightText];
  headerLabel.shadowColor = [UIColor blackColor];
  headerLabel.shadowOffset = CGSizeMake(0, 1);
  headerLabel.font = [UIFont boldSystemFontOfSize:16];
  headerLabel.backgroundColor = [UIColor clearColor];
  [headerView addSubview:headerLabel];
  UIImageView *flagView = [[[UIImageView alloc] initWithFrame:CGRectMake(4, 7, 25, 15)] autorelease];
  NSString *countryFlag = [NSString stringWithFormat:@"%@.flag", title];
  UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[MenuData dataPath] stringByAppendingPathComponent:NSLocalizedString(countryFlag, nil)]];
  flagView.image = image;
  [image release];
  [headerView addSubview:flagView];
  return headerView;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (searchCriteriaSections.selectedSegmentIndex == 0) {
    int row = 0;
    int m = 0;
    NSString *country = nil;
    for (NSString *parkId in parkIds) {
      NSString *c = [countries objectForKey:parkId];
      if (country != nil && ![c isEqualToString:country]) ++m;
      if (m == indexPath.section) break;
      country = c;
      ++row;
    }
    row += indexPath.row;
    NSString *parkId = [parkIds objectAtIndex:row];
    NSUInteger idx = [searchData.searchedParkIds indexOfObject:parkId];
    if (idx != NSNotFound) [searchData.searchedParkIds removeObjectAtIndex:idx];
    else [searchData.searchedParkIds addObject:parkId];
  } else {
    NSString *attributeId = [attributeIds objectAtIndex:indexPath.row];
    NSUInteger idx = [searchData.searchedAttributes indexOfObject:attributeId];
    if (idx != NSNotFound) [searchData.searchedAttributes removeObjectAtIndex:idx];
    else [searchData.searchedAttributes addObject:attributeId];
  }
  [tableView reloadData];
}

#pragma mark -
#pragma mark Actions

-(IBAction)searchCriteriaSectionsControlValueChanged:(id)sender {
  [theTableView reloadData];
}

-(IBAction)loadBackView:(id)sender {
  switch (searchAccuracy.selectedSegmentIndex) {
    case 2:
      searchData.accuracy = 1.0f;
      break;
    case 1:
      searchData.accuracy = 0.9f;
      break;
    default:
      searchData.accuracy = 0.8f;
      break;
  }
  [searchData.searchedParkIds sortUsingComparator:(NSComparator)^(id obj1, id obj2){
    NSString *parkName1 = [[searchData.allParkDetails objectForKey:obj1] objectForKey:@"Parkname"];
    NSString *parkName2 = [[searchData.allParkDetails objectForKey:obj2] objectForKey:@"Parkname"];
    return [parkName1 compare:parkName2]; }];
  [SearchViewController clearResultList];
  SearchViewController *controller = delegate;
  [controller.theSearchBar becomeFirstResponder];
  [delegate dismissModalViewControllerAnimated:YES];
}

@end
