//
//  PSMultiValueSpecifierTable.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "PSMultiValueSpecifierTable.h"
#import "InAppSettingConstants.h"
#import "SettingsData.h"
#import "Colors.h"

@implementation PSMultiValueSpecifierTable

@synthesize theTableView;
@synthesize topNavigationBar;
@synthesize titleOfTable;

-(int)getSelectedRow {
  NSArray *a = [setting valueForKey:@"Values"];
  int l = (int)[a count];
  for (int i = 0; i < l; ++i) {
  id cellValue = [a objectAtIndex:i];
    if ([cellValue isKindOfClass:[NSNumber class]]) {
      if ([(NSNumber *)cellValue intValue] == [(NSNumber *)[self getValue] intValue]) {
        return i;
      }
    } else {  // ToDo: support also other types beside Numbers and Strings if needed
      if ([cellValue isEqualToString:[self getValue]]) {
        return i;
      }
    }
  }
  return 0;
}

-(id)initWithSetting:(InAppSetting *)inputSetting delegate:(id)inputDelegate nibName:(NSString *)nibName {
  self = [super initWithNibName:nibName bundle:nil];
  if (self != nil) {
    setting = [inputSetting retain];
    delegate = inputDelegate;
    selectedRow = [self getSelectedRow];
  }
  return self;
}

-(void)viewDidLoad {
  [super viewDidLoad];
  titleOfTable.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  titleOfTable.title = NSLocalizedString([setting valueForKey:@"Title"], nil);
  theTableView.backgroundColor = [Colors darkBlue];
  theTableView.backgroundView = nil;
  topNavigationBar.tintColor = [Colors darkBlue];
  [theTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
  [theTableView deselectRowAtIndexPath:[theTableView indexPathForSelectedRow] animated:NO];
}

-(void)dealloc {
  [setting release];
  [theTableView release];
  [topNavigationBar release];
  [titleOfTable release];
  [super dealloc];
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

#pragma mark Value

-(id)getValue {
  id value = [[NSUserDefaults standardUserDefaults] valueForKey:[setting valueForKey:@"Key"]];
  if (value == nil) {
    value = [setting valueForKey:@"DefaultValue"];
    if (value == nil) {
      NSArray *a = [setting valueForKey:@"Values"];
      if ([a count] > 0) value = [a objectAtIndex:0];
    }
  }
  return value;
}

-(void)setValue:(id)newValue {
  [[NSUserDefaults standardUserDefaults] setObject:newValue forKey:[setting valueForKey:@"Key"]];
}

#pragma action methods

-(IBAction)loadBackView:(id)sender {
	[delegate dismissModalViewControllerAnimated:YES];
}

#pragma mark Table view methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [[setting valueForKey:@"Values"] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"PSMultiValueSpecifierTableCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
  }
  NSArray *titles = [setting valueForKey:@"Titles"];
  if (titles == nil) titles = [setting valueForKey:@"Values"];
  NSString *cellTitle = NSLocalizedString([titles objectAtIndex:indexPath.row], nil);
  cell.backgroundColor = [Colors lightBlue];
  cell.textLabel.text = cellTitle;
  cell.textLabel.backgroundColor = [UIColor clearColor];
	if (indexPath.row == selectedRow) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    cell.textLabel.font = InAppSettingNormalFont;
    cell.textLabel.textColor = [Colors settingColor];
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.font = InAppSettingBoldFont;
    cell.textLabel.textColor = [Colors lightText];
    cell.textLabel.shadowColor = [UIColor blackColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
  }
  return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  id cellValue = [[setting valueForKey:@"Values"] objectAtIndex:indexPath.row];
  [self setValue:cellValue];
  selectedRow = (int)indexPath.row;
  [tableView reloadData];
  return indexPath;
}

@end