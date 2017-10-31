//
//  InAppSettingsViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "InAppSettingsViewController.h"
#import "InAppSetting.h"
#import "InAppSettingConstants.h"
#import "PSMultiValueSpecifierTable.h"
#import "GeneralInfoViewController.h"
#import "MenuData.h"
#import "SettingsData.h"
#import "ProfileData.h"
#import "Categories.h"
#import "HelpData.h"
#import "LocationData.h"
#import "SettingsData.h"
#import "Colors.h"

@implementation InAppSettingsViewController

@synthesize delegate;
@synthesize viewOptionalSettings, viewChildPane;
@synthesize availableUpdates;
@synthesize parkData;
@synthesize file;
@synthesize preferenceTitle;
@synthesize preferenceSpecifiers;
@synthesize theTableView;
@synthesize topNavigationBar;
@synthesize titleOfTable;
@synthesize helpButton;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    viewOptionalSettings = YES;
    viewChildPane = NO;
    availableUpdates = 0;
  }
  return self;
}

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  [super dismissModalViewControllerAnimated:YES];
  availableUpdates = 0;  // is not correct if not all available updates are done
  [theTableView reloadData];
}

-(IBAction)loadBackView:(id)sender {
  if ([file isEqualToString:@"Root.plist"]) {
    //[settingsData save];
    [ProfileData getProfileData:YES];   // reload configurations to update changes in cache
    SettingsData *settingsData = [SettingsData getSettingsData:YES];
    [Categories getCategories:YES];
    if ([settingsData isLocationServiceEnabled]) {
      if ([LocationData isLocationDataStarted]) {
        [LocationData settingsChanged];
      } else {
        LocationData *locData = [LocationData getLocationData];
        [locData start];
      }
    } else if ([LocationData isLocationDataInitialized]) {
      [LocationData releaseLocationData];
    }
  }
	[delegate dismissModalViewControllerAnimated:YES];
}

-(IBAction)helpView:(id)sender {
  HelpData *helpData = [HelpData getHelpData];
  NSString *page = nil;
  NSString *title = nil;
  if ([preferenceSpecifiers isEqualToString:@"PreferenceSpecifiers"]) {
    page = [helpData.pages objectForKey:@"MENU_SETTINGS"];
    title = [helpData.titles objectForKey:@"MENU_SETTINGS"]; 
  } else if ([preferenceSpecifiers isEqualToString:@"Profile"]) {
    page = [helpData.pages objectForKey:@"MENU_PROFILE"];
    title = [helpData.titles objectForKey:@"MENU_PROFILE"]; 
  }
  if (title != nil && page != nil) {
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    controller.content = page;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

#pragma mark validate plist data

-(BOOL)isSettingValid:(InAppSetting *)setting {
  if (!viewOptionalSettings && [[SettingsData optionalSettings] containsObject:setting.key]) return NO;
  NSString *type = [setting getType];
  if ([type isEqualToString:@"PSMultiValueSpecifier"]) {
    if (![setting hasKey] || /*![setting hasDefaultValue] ||*/ ![setting hasTitle]) return NO;
    NSArray *values = [setting valueForKey:@"Values"];
    if (values == nil || [values count] == 0) return NO;
    NSArray *titles = [setting valueForKey:@"Titles"];
    if (titles == nil) titles = values;
    if ([titles count] != [values count]) return NO;
  } else if ([type isEqualToString:@"PSSliderSpecifier"]) {
    if (![setting hasKey] || ![setting hasDefaultValue]) return NO;
    NSNumber *minValue = [setting valueForKey:@"MinimumValue"];
    NSNumber *maxValue = [setting valueForKey:@"MaximumValue"];
    if (minValue == nil || maxValue == nil) return NO;
  } else if ([type isEqualToString:@"PSToggleSwitchSpecifier"]) {
    if (![setting hasKey] || ![setting hasDefaultValue] || ![setting hasTitle]) return NO;
  } else if ([type isEqualToString:@"PSTitleValueSpecifier"]){
    if (![setting hasKey] || ![setting hasDefaultValue] || ![setting hasTitle]) return NO;
  } else if ([type isEqualToString:@"PSChildPaneSpecifier"]) {
    if (![setting hasTitle]) return NO;
    NSString *plistFile = [setting valueForKey:@"File"];
    if (plistFile == nil) return NO;
  } else if ([type isEqualToString:@"PSTextFieldSpecifier"]) return NO; // ToDo: do not support at moment
  return YES;
}

#pragma mark setup view

-(id)initWithCoder:(NSCoder *)aDecoder {
  viewOptionalSettings = YES;
  viewChildPane = NO;
  return [self init];
}

-(id)initWithFile:(NSString *)inputFile {
  self = [self init];
  if (self != nil) {
    viewOptionalSettings = YES;
    viewChildPane = NO;
    file = [inputFile retain];
  }
  return self;
}

-(void)viewDidLoad {
  titleOfTable.title = preferenceTitle;
  if ([titleOfTable.title isEqualToString:@""]) {
    titleOfTable.title = NSLocalizedString(@"Settings", nil);
  }
  titleOfTable.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  //load settigns plist
  if (file == nil) file = [[NSString alloc] initWithString:@"Root.plist"];
  if (!preferenceSpecifiers) {
    preferenceSpecifiers = @"PreferenceSpecifiers";
    helpButton.hidden = NO;
  } else if ([preferenceSpecifiers isEqualToString:@"Profile"]) {
    helpButton.hidden = NO;
  } else {
    helpButton.hidden = YES;
  }
  self.view.backgroundColor = [Colors darkBlue];
  theTableView.backgroundColor = [Colors darkBlue];
  theTableView.backgroundView = nil;
  topNavigationBar.tintColor = [Colors darkBlue];
  helpButton.hidden = (PATHES_EDITION != nil);

  if (PATHES_EDITION != nil && parkData != nil && parkData.hasWinterData) {
    summerWinterSwitch = [[CustomSwitch alloc] initWithFrame:CGRectMake(theTableView.frame.origin.x+(theTableView.frame.size.width-95.0f)/2, theTableView.frame.origin.y+3.0f, 95.0f, 27.0f)];
    summerWinterSwitch.delegate = self;
    summerWinterSwitch.leftImageView.image = [UIImage imageNamed:@"snow.png"];
    summerWinterSwitch.rightImageView.image = [UIImage imageNamed:@"sun.png"];
    summerWinterSwitch.on = parkData.winterDataEnabled;
    [self.view addSubview:summerWinterSwitch];
    winterLabel = [[UILabel alloc] initWithFrame:CGRectMake(summerWinterSwitch.frame.origin.x-70.0f, summerWinterSwitch.frame.origin.y, 70.0f, summerWinterSwitch.frame.size.height)];
    winterLabel.hidden = !parkData.hasWinterData;
    winterLabel.text = NSLocalizedString(@"winter", nil);
    winterLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    winterLabel.textColor = [Colors lightText];
    winterLabel.shadowColor = [UIColor blackColor];
    winterLabel.shadowOffset = CGSizeMake(0, 1);
    winterLabel.backgroundColor = [UIColor clearColor];
    winterLabel.enabled = parkData.winterDataEnabled;
    [self.view addSubview:winterLabel];
    summerLabel = [[UILabel alloc] initWithFrame:CGRectMake(summerWinterSwitch.frame.origin.x+summerWinterSwitch.frame.size.width+5.0f, summerWinterSwitch.frame.origin.y, 70.0f, summerWinterSwitch.frame.size.height)];
    summerLabel.hidden = !parkData.hasWinterData;
    summerLabel.text = NSLocalizedString(@"summer", nil);
    summerLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    summerLabel.textColor = [Colors lightText];
    summerLabel.shadowColor = [UIColor blackColor];
    summerLabel.shadowOffset = CGSizeMake(0, 1);
    summerLabel.backgroundColor = [UIColor clearColor];
    summerLabel.enabled = !parkData.winterDataEnabled;
    [self.view addSubview:summerLabel];
    theTableView.frame = CGRectMake(theTableView.frame.origin.x, theTableView.frame.origin.y+33.0f, theTableView.frame.size.width, theTableView.frame.size.height-27.0f);
  }
  //load plist
  NSDictionary *settingsDictionary = [MenuData getRootOfFile:file];
  NSArray *prefSpecifiers = [settingsDictionary objectForKey:preferenceSpecifiers];
  
  //create an array for headers(PSGroupSpecifier) and a dictonary to hold arrays of settings
  headers = [[NSMutableArray alloc] init];
  displayHeaders = [[NSMutableArray alloc] init];
  settings = [[NSMutableDictionary alloc] init];
  
  //if the first item is not a PSGroupSpecifier create a header to store the settings
  NSString *currentHeader = @"";
  InAppSetting *firstSetting = [[InAppSetting alloc] initWithDictionary:[prefSpecifiers objectAtIndex:0]];
  if (![firstSetting isType:@"PSGroupSpecifier"]){
    [headers addObject:currentHeader];
    [displayHeaders addObject:currentHeader];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    [settings setObject:array forKey:currentHeader];
    [array release];
  }
  [firstSetting release];

  //set the first value in the display header to "", while the real header is set to InAppSettingNullHeader
  //this way whats set in the first entry to headers will not be seen
  BOOL currentHeaderHasElements = NO;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  for (NSDictionary *eachSetting in prefSpecifiers) {
    InAppSetting *setting = [[InAppSetting alloc] initWithDictionary:eachSetting];
    if ([setting getType] != nil) { //type is required
      if ([setting isType:@"PSGroupSpecifier"]) {
        currentHeaderHasElements = NO;
        currentHeader = [setting valueForKey:@"Title"];
      } else if ([self isSettingValid:setting]) {
        if (viewChildPane || ![setting isType:@"PSChildPaneSpecifier"]) {
          if (currentHeaderHasElements) {
            NSMutableArray *array = [settings objectForKey:currentHeader];
            [array addObject:setting];
          } else {
            [headers addObject:currentHeader];
            [displayHeaders addObject:currentHeader];
            NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:5];
            [array addObject:setting];
            [settings setObject:array forKey:currentHeader];
            [array release];
            currentHeaderHasElements = YES;
          }
        }
      }
    }
    [setting release];
  }
  [pool release];
}

-(void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [theTableView reloadData];
}

-(void)dealloc {
  [parkData release];
  [file release];
  [preferenceTitle release];
  [preferenceSpecifiers release];
  [headers release];
  [displayHeaders release];
  [settings release];
  [summerWinterSwitch release];
  [updatesBadge release];
  [winterLabel release];
  [summerLabel release];
  [theTableView release];
  [topNavigationBar release];
  [titleOfTable release];
  [helpButton release];
  [super dealloc];
}

-(BOOL)shouldAutorotate {
  UIInterfaceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
  SettingsData *settingsData = [SettingsData getSettingsData];
  if ([settingsData isPortraitScreen]) return (interfaceOrientation == UIInterfaceOrientationPortrait);
  return ([settingsData isLeftHandedLandscapeScreen])? (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) : (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  SettingsData *settingsData = [SettingsData getSettingsData];
  if ([settingsData isPortraitScreen]) return UIInterfaceOrientationPortrait;
  if ([settingsData isLeftHandedLandscapeScreen]) return UIInterfaceOrientationLandscapeLeft;
  return UIInterfaceOrientationLandscapeRight;
}

#pragma mark -
#pragma mark Custom Switch view delegate

-(void)customSwitchDelegate:(CustomSwitch *)customSwitch selectionDidChange:(BOOL)on {
  parkData.winterDataEnabled = on;
  winterLabel.enabled = on;
  summerLabel.enabled = !on;
}

#pragma mark -
#pragma mark Table view methods

-(InAppSetting *)settingAtIndexPath:(NSIndexPath *)indexPath {
  NSString *header = [headers objectAtIndex:indexPath.section];
  return [[settings objectForKey:header] objectAtIndex:indexPath.row];
}

-(void)controlEditingDidBeginAction:(UIControl *)control {
  //scroll the table view to the cell that is being edited
  //TODO: the cell does not animate to the middle of the table view when the keyboard is becoming active
  //TODO: find a better way to get the cell, what if the nesting changes?
  NSIndexPath *indexPath = [self.theTableView indexPathForCell:(UITableViewCell *)[[control superview] superview]];
  [theTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [headers count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return [displayHeaders objectAtIndex:section];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 30.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.bounds.size.width, 30.0f)] autorelease];
  headerView.backgroundColor = [Colors darkBlue];
  UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(36.0f, 4.0f, tableView.bounds.size.width, 22.0f)] autorelease];
  headerLabel.text = [displayHeaders objectAtIndex:section];
  headerLabel.textColor = [Colors lightText];
  headerLabel.shadowColor = [UIColor blackColor];
  headerLabel.shadowOffset = CGSizeMake(0, 1);
  headerLabel.font = InAppSettingBoldFont;
  headerLabel.backgroundColor = [UIColor clearColor];
  [headerView addSubview:headerLabel];
  return headerView;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSString *header = [headers objectAtIndex:section];
  return [[settings objectForKey:header] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  InAppSetting *setting = [self settingAtIndexPath:indexPath];
  NSString *cellType = [setting cellName];
  Class nsclass = NSClassFromString(cellType);
  if (!nsclass) {
    cellType = @"InAppSettingsTableCell";
    nsclass = NSClassFromString(cellType);
  }
  InAppSettingsTableCell *cell = ((InAppSettingsTableCell *)[tableView dequeueReusableCellWithIdentifier:cellType]);
  if (cell == nil) {
    cell = [[[nsclass alloc] initWithSetting:setting reuseIdentifier:cellType] autorelease];
  }
  [cell setupCell:setting];
  //if the cell is a PSTextFieldSpecifier setup an action to center the table view on the cell
  if ([setting isType:@"PSTextFieldSpecifier"]) {
    [[cell getValueInput] addTarget:self action:@selector(controlEditingDidBeginAction:) forControlEvents:UIControlEventEditingDidBegin];
  }
  [cell setValue];
  if ([setting isType:@"PSChildPaneSpecifier"]) {
    NSString *viewName = [setting valueForKey:@"File"];
    if ([viewName isEqualToString:@"UpdateView"]) {
      if (updatesBadge != nil) {
        [updatesBadge removeFromSuperview];
        [updatesBadge release];
        updatesBadge = nil;
      }
      if (availableUpdates != 0) {
        updatesBadge = [[CustomBadge customBadgeWithString:(availableUpdates < 0)? @"!" : [NSString stringWithFormat:@"%d", availableUpdates]] retain];
        updatesBadge.frame = CGRectMake(cell.frame.size.width-2*updatesBadge.frame.size.width-10.0f, 3.0f, updatesBadge.frame.size.width, updatesBadge.frame.size.height);
        [cell addSubview:updatesBadge];
      }
    }
  }
  return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  InAppSetting *setting = [self settingAtIndexPath:indexPath];
  if ([setting isType:@"PSMultiValueSpecifier"]) {
    PSMultiValueSpecifierTable *multiValueSpecifier = [[PSMultiValueSpecifierTable alloc] initWithSetting:setting delegate:self nibName:@"PSMultiValueSpecifierView"];
    [self presentViewController:multiValueSpecifier animated:YES completion:nil];
    //[self.navigationController pushViewController:multiValueSpecifier animated:YES];
    [multiValueSpecifier release];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
  } else if ([setting isType:@"PSChildPaneSpecifier"]) {
    NSString *viewName = [setting valueForKey:@"File"];
    NSString *className = [viewName stringByAppendingString:@"Controller"];
    UIViewController *controller = [[NSClassFromString(className) alloc] initWithNibName:viewName owner:self];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
    /*NSString *plistFile = [[setting valueForKey:@"File"] stringByAppendingPathExtension:@"plist"];
    InAppSettingsViewController *childPane = [[InAppSettingsViewController alloc] initWithFile:plistFile];  // ToDo!
    childPane.title = [setting valueForKey:@"Title"];
    [self presentModalViewController:childPane animated:YES];
    //[self.navigationController pushViewController:childPane animated:YES];
    [childPane release];*/
  }
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  InAppSetting *setting = [self settingAtIndexPath:indexPath];
  if ([setting isType:@"PSMultiValueSpecifier"] || [setting isType:@"PSChildPaneSpecifier"]) {
    return indexPath;
  }
  return nil;
}

@end
