//
//  CategoriesSelectionViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 07.04.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "CategoriesSelectionViewController.h"
#import "NavigationViewController.h"
#import "Categories.h"
#import "MenuData.h"
#import "SettingsData.h"
#import "Colors.h"

@implementation CategoriesSelectionViewController

@synthesize selectedCategories;
@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize theTableView;

#pragma mark -
#pragma mark Memory management

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(UIViewController<CategoriesSelectionDelegate> *)owner parkId:(NSString *)pId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    parkId = [pId retain];
    categoryNames = nil;
    selectedCategories = nil;
  }
  return self;
}

-(void)dealloc {
  [parkId release];
  parkId = nil;
  [topNavigationBar release];
  topNavigationBar = nil;
  [titleNavigationItem release];
  titleNavigationItem = nil;
  [theTableView release];
  theTableView = nil;
  [selectedImage release];
  selectedImage = nil;
  [unselectedImage release];
  unselectedImage = nil;
  [categoryNames release];
  categoryNames = nil;
  [selectedCategories release];
  selectedCategories = nil;
  [super dealloc];
}

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Relinquish ownership any cached data, images, etc. that aren't in use.
}

-(void)setCategoryNames:(NSArray *)names {
  [categoryNames release];
  categoryNames = [[NSMutableArray alloc] initWithCapacity:names.count+2];
  [categoryNames addObject:ALL_FAVORITES];
  [categoryNames addObject:ALL_WITH_WAIT_TIME];
  [categoryNames addObjectsFromArray:names];
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
  [super viewDidLoad];
  favoriteMode = NO;
  topNavigationBar.tintColor = [Colors darkBlue];
  titleNavigationItem.title = NSLocalizedString(@"categories.title", nil);
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  selectedImage = [[UIImage imageNamed:@"selected.png"] retain];
  unselectedImage = [[UIImage imageNamed:@"unselected.png"] retain];
  theTableView.backgroundColor = [Colors lightBlue];
  theTableView.backgroundView = nil;
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
  return (favoriteMode)? categoryNames.count-2 : categoryNames.count+1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"CategoriesCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.imageView.opaque = YES;
    cell.textLabel.textColor = [Colors hilightText];
    cell.textLabel.shadowColor = [UIColor blackColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
  }
  NSString *imageName = nil;
  NSString *name = nil;
  int row = (int)indexPath.row;
  if (favoriteMode) {
    name = [categoryNames objectAtIndex:row+2];
    Categories *categories = [Categories getCategories];
    imageName = [categories getIconForTypeIdOrCategoryId:[categories getCategoryOrTypeId:name]];
  } else {
    if (row == 0) {
      __block int n = 0;
      __block int m = 0;
      [selectedCategories enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        if ([key hasPrefix:PREFIX_FAVORITES]) {
          ++n;
          if (object != nil && [object boolValue]) ++m;
        }
      }];
      name = [NSString stringWithFormat:@"%@ (%d/%d)", NSLocalizedString(@"categories.all.favorites", nil), m, n];
      //imageName = @"favorite.png";
    } else if (row == 1) {
      name = NSLocalizedString(@"categories.all.with.waiting.time", nil);;
      imageName = @"clock.png";
    } else if (row == 2) {
      name = @"";
    } else {
      name = [categoryNames objectAtIndex:row-1];
      Categories *categories = [Categories getCategories];
      imageName = [categories getIconForTypeIdOrCategoryId:[categories getCategoryOrTypeId:name]];
    }
  }
  cell.textLabel.text = name;
  if (imageName != nil && ![imageName hasPrefix:@"small_button_"]) {
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[MenuData dataPath] stringByAppendingPathComponent:imageName]];
    if (image == nil) image = [[UIImage imageNamed:imageName] retain];
    UIImageView *indicatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 38.0f, 38.0f)];
    indicatorView.image = image;
    cell.accessoryView = indicatorView;
    [indicatorView release];
    [image release];
  } else {
    cell.accessoryView = nil;
  }
  if (favoriteMode) {
    name = [PREFIX_FAVORITES stringByAppendingString:name];
    cell.imageView.image = ([[selectedCategories objectForKey:name] boolValue])? selectedImage : unselectedImage;
  } else {
    if (row == 0) {
      cell.imageView.image = nil;
    } else if (row == 1) {
      cell.imageView.image = ([[selectedCategories objectForKey:ALL_WITH_WAIT_TIME] boolValue])? selectedImage : unselectedImage;
    } else if (row > 2) {
      cell.imageView.image = ([[selectedCategories objectForKey:name] boolValue])? selectedImage : unselectedImage;
    }
  }
  cell.accessoryType = (!favoriteMode && row == 0)? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return (!favoriteMode && indexPath.row == 2)? 2.0f : 44.0f;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  return (!favoriteMode && indexPath.row == 2)? nil : indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *name = nil;
  int row = (int)indexPath.row;
  if (favoriteMode) {
    name = [PREFIX_FAVORITES stringByAppendingString:[categoryNames objectAtIndex:row+2]];
  } else {
    if (row == 0) {
      CATransition *transition = [CATransition animation];
      transition.duration = 0.3;
      transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
      transition.type = kCATransitionPush;
      transition.subtype = kCATransitionFromRight;
      [self.view.window.layer addAnimation:transition forKey:nil];
      titleNavigationItem.title = NSLocalizedString(@"categories.title.favorites", nil);
      favoriteMode = YES;
    } else if (row == 1) name = ALL_WITH_WAIT_TIME;
    else if (row > 2) name = [categoryNames objectAtIndex:row-1];
  }
  if (name != nil) {
    BOOL selected = [[selectedCategories objectForKey:name] boolValue];
    [selectedCategories setObject:[NSNumber numberWithBool:!selected] forKey:name];
  }
  [tableView reloadData];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  favoriteMode = YES;
  titleNavigationItem.title = NSLocalizedString(@"categories.title.favorites", nil);
  [tableView reloadData];
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  if (favoriteMode) {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:transition forKey:nil];
    favoriteMode = NO;
    titleNavigationItem.title = NSLocalizedString(@"categories.title", nil);
    [theTableView reloadData];
    [theTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
  } else {
    ParkData *parkData = [ParkData getParkData:parkId];
    if (![delegate respondsToSelector:@selector(updateMapView)]) [parkData saveChangedCategories:selectedCategories];
    else [delegate updateMapView];
    [delegate dismissViewControllerAnimated:YES completion:nil];
  }
}

@end
