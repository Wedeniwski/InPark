//
//  UpdateViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "UpdateViewController.h"
#import "ParkSelectionViewController.h"
#import "ParkData.h"
#import "ImageData.h"
#import "MenuData.h"
#import "SettingsData.h"
#import "IPadHelper.h"
#import "Colors.h"

@implementation UpdateViewController

@synthesize checkVersionInfo;
@synthesize mustUpdateParkGroupIds;
@synthesize bottomToolbar;
@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize theTableView;
@synthesize downloadIndicator, initIndicator;
@synthesize downloadProgress;
@synthesize downloadStatus;
@synthesize downloadedSize;

static NSIndexPath *selectedIndexPath = nil;

-(int)posUpdates:(int)section row:(int)row {
  if (availableUpdates == nil || [availableUpdates count] == 0) return -1;
  int i = 0;
  int n = section;
  Update *u = [availableUpdates objectAtIndex:0];
  if (n > 0) {
    for (Update *u2 in availableUpdates) {
      if (![u2.country isEqualToString:u.country] && --n == 0) break;
      ++i;
      u = u2;
    }
  }
  return i+row;
}

-(BOOL)areAllSelected {
  int i = 0;
  for (NSNumber *n in selectedUpdates) {
    if (![n boolValue] && ![[unselectableUpdates objectAtIndex:i] boolValue]) return NO;
    ++i;
  }
  return YES;
}

-(BOOL)isAllSelectionDeleted {
  int i = 0;
  for (NSNumber *n in selectedUpdates) {
    if ([n boolValue] && ![[mustUpdates objectAtIndex:i] boolValue]) return NO;
    ++i;
  }
  return YES;
}

#pragma mark -
#pragma mark View lifecycle

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    activeUpdate = nil;
    delegate = owner;
    checkVersionInfo = YES;
    mustUpdateParkGroupIds = nil;
    availableUpdates = nil;
    availableKindOfUpdates = nil;
    selectedKindOfs = nil;
    mustUpdates = nil;
    selectedUpdates = nil;
    unselectableUpdates = nil;
    selectedParkId = nil;
    namesKindOfs = nil;
  }
  return self;
}

-(BOOL)isSelectedDownload {
  //int i = 0;
  for (NSNumber *selected in selectedUpdates) {
    if ([selected boolValue]/* && ![[mustUpdates objectAtIndex:i] boolValue]*/) return YES;
    //++i;
  }
  return NO;
}

-(void)updateTableData:(NSNumber *)download {
  [ParkData save];
  [initIndicator stopAnimating];
  [downloadIndicator stopAnimating];
  if (availableUpdates == nil) {
    UIAlertView *alertDialog = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"update.alert.title", nil)
                                message:NSLocalizedString(@"update.alert.error", nil)
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                otherButtonTitles:nil];
    [alertDialog show];
    [alertDialog release];
    return;
  }
  int n = (int)[availableUpdates count];
  if (n == 0) {
    UIAlertView *alertDialog = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"update.alert.title", nil)
                                message:(firstUpdateCheck)? NSLocalizedString(@"update.alert.text", nil) : NSLocalizedString(@"update.alert.updated", nil)
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                otherButtonTitles:nil];
    [alertDialog show];
    [alertDialog release];
    return;
  }
  BOOL allAreMust = YES;
  [mustUpdates release];
  mustUpdates = [[NSMutableArray alloc] initWithCapacity:n];
  [selectedUpdates release];
  selectedUpdates = [[NSMutableArray alloc] initWithCapacity:n];
  [unselectableUpdates release];
  unselectableUpdates = [[NSMutableArray alloc] initWithCapacity:n];
  [availableKindOfUpdates release];
  availableKindOfUpdates = [[NSMutableDictionary alloc] initWithCapacity:n];
  [selectedKindOfs release];
  selectedKindOfs = [[NSMutableDictionary alloc] initWithCapacity:n];
  Update *previousUpdate = nil;
  BOOL coreUpdateNeeded = [ParkData checkIfUpdateIsNeeded:CORE_DATA_ID];
  for (Update *u in availableUpdates) {
    BOOL must = [u isMandetory:mustUpdateParkGroupIds];
    if (!must) allAreMust = NO;
    [mustUpdates addObject:[NSNumber numberWithBool:must]];
    [selectedUpdates addObject:[NSNumber numberWithBool:must]];
    BOOL unselectable = (previousUpdate != nil && [previousUpdate.parkId isEqualToString:u.parkId] && (coreUpdateNeeded || ([ParkData getParkData:u.parkId] == nil && (mustUpdateParkGroupIds == nil || ![mustUpdateParkGroupIds containsObject:u.parkId] || ![mustUpdateParkGroupIds containsObject:u.parkGroupId]))));
    [unselectableUpdates addObject:[NSNumber numberWithBool:unselectable]];
    previousUpdate = u;
  }
  if (allAreMust && selectAllButton != nil) {
    if ([originalBottomToolbar count] >= 3) {
      NSMutableArray *array = [[NSMutableArray alloc] initWithArray:originalBottomToolbar];
      [array removeObjectAtIndex:0];
      [originalBottomToolbar release];
      originalBottomToolbar = array;
    }
    [selectAllButton release];
    selectAllButton = nil;
  }
  downloadedSize.hidden = YES;
  downloadProgress.hidden = YES;
  downloadStatus.hidden = YES;
  if (![self isSelectedDownload] && selectAllButton != nil) {
    selectAllButton.title = ([self isAllSelectionDeleted])? NSLocalizedString(@"update.button.select.all", nil) : NSLocalizedString(@"update.button.delete.selection", nil);
    [bottomToolbar setItems:[NSArray arrayWithObject:selectAllButton] animated:YES];
  } else {
    [bottomToolbar setItems:originalBottomToolbar animated:YES];
  }
  [theTableView reloadData];
}

-(void)checkAvailableUpdates:(NSNumber *)download {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  availableUpdates = [[Update availableUpdates:self includingHD:(PARK_ID_EDITION == nil) checkVersionInfo:[download boolValue]] retain];
  [availableImageDataChanges release];
  availableImageDataChanges = (PARK_ID_EDITION == nil)? [[ImageData allParkIdsWithAvailableChanges] retain] : [[NSSet alloc] init];
  [self performSelectorOnMainThread:@selector(updateTableData:) withObject:download waitUntilDone:NO];
  [pool release];
}

-(void)updateData:(BOOL)download {
  [titleNavigationItem setLeftBarButtonItem:((activeUpdate != nil)? nil : leftButton) animated:YES];
  [mustUpdates release];
  mustUpdates = nil;
  [selectedUpdates release];
  selectedUpdates = nil;
  [unselectableUpdates release];
  unselectableUpdates = nil;
  [availableUpdates release];
  availableUpdates = nil;
  [availableKindOfUpdates release];
  availableKindOfUpdates = nil;
  [selectedKindOfs release];
  selectedKindOfs = nil;
  [theTableView reloadData];
  [initIndicator startAnimating];
  [self performSelectorInBackground:@selector(checkAvailableUpdates:) withObject:[NSNumber numberWithBool:download]];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  lastDownloadError = nil;
  availableImageDataChanges = nil;
  errorPopUps = NO;
  firstUpdateCheck = YES;
  downloadPos = -1;
  self.view.backgroundColor = [Colors darkBlue];
  topNavigationBar.tintColor = [Colors darkBlue];
  bottomToolbar.tintColor = [Colors darkBlue];
  titleNavigationItem.title = NSLocalizedString(@"update.title", nil);
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  leftButton = [titleNavigationItem.leftBarButtonItem retain];
  selectAllButton = nil;
  theTableView.backgroundColor = [Colors darkBlue];
  theTableView.backgroundView = nil;
  NSArray *items = bottomToolbar.items;
  if ([items count] >= 3) {
    selectAllButton = [[items objectAtIndex:0] retain];
    selectAllButton.title = NSLocalizedString(@"update.button.select.all", nil);
    downloadButton = [[items objectAtIndex:2] retain];
    downloadButton.title = NSLocalizedString(@"download", nil);
  }
  originalBottomToolbar = [[NSArray alloc] initWithArray:items];
  selectedImage = [[UIImage imageNamed:@"selected.png"] retain];
  unselectedImage = [[UIImage imageNamed:@"unselected.png"] retain];
  downloadStatus.text = @"";
  downloadedSize.text = @"";
  initIndicator.hidden = NO;
  downloadIndicator.hidden = YES;
  [self updateData:checkVersionInfo];
  bottomToolbar.items = nil;
  downloadStatus.textColor = [Colors lightText];
  downloadedSize.textColor = [Colors lightText];
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
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
  if (alertView.tag == 0) {
    if ([buttonTitle isEqualToString:NSLocalizedString(@"accept", nil)]) {
      [self download:nil];
    } else {
      [self loadBackView:alertView];
    }
  } else if (alertView.tag == 1) {
    if (downloadPos >= 0) {
      if ([buttonTitle isEqualToString:NSLocalizedString(@"retry", nil)]) {
        [selectedUpdates replaceObjectAtIndex:downloadPos withObject:[NSNumber numberWithBool:YES]];
        [self download:nil];
      } else {
        activeUpdate = nil;
        [self updateData:NO];
      }
    }
  }
}

#pragma mark -
#pragma mark Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (availableUpdates == nil || [availableUpdates count] == 0) return 0;
  if (selectedParkId != nil) return 1;
  int n = 1;
  Update *u = [availableUpdates objectAtIndex:0];
  for (Update *u2 in availableUpdates) {
    if (![u2.country isEqualToString:u.country]) ++n;
    u = u2;
  }
  return n;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (selectedParkId != nil) return [namesKindOfs count];
  int pos = [self posUpdates:(int)section row:0];
  if (pos < 0) return 0;
  Update *u = [availableUpdates objectAtIndex:pos];
  int n = 0;
  for (Update *u2 in availableUpdates) {
    if ([u2.country isEqualToString:u.country]) ++n;
  }
  return n;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (selectedParkId != nil) {
    for (Update *u in availableUpdates) {
      if (u.isHD && [u.parkId isEqualToString:selectedParkId]) return u.parkName;
    }
    return nil;
  }
  int pos = [self posUpdates:(int)section row:0];
  if (pos < 0 || [[mustUpdates objectAtIndex:pos] boolValue]) return nil;
  Update *u = [availableUpdates objectAtIndex:pos];
  return NSLocalizedString(u.country, nil);
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  __block int n = 0;
  if (selectedParkId != nil) {
    NSDictionary *updates = [availableKindOfUpdates objectForKey:selectedParkId];
    NSDictionary *selectedKindOf = [selectedKindOfs objectForKey:selectedParkId];
    [selectedKindOf enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
      if ([object boolValue]) {
        NSArray *size = [updates objectForKey:key];
        if ([size count] >= 2) n += [[size objectAtIndex:1] intValue];
      }
    }];
  } else {
    if (section+1 != [self numberOfSectionsInTableView:tableView]) return nil;
    int pos = 0;
    for (Update *u in availableUpdates) {
      if ([[selectedUpdates objectAtIndex:pos] boolValue]) n += u.fileSize;
      ++pos;
    }
  }
  return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"total", nil), [Update sizeToString:n]];
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"UpdateCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.imageView.opaque = YES;
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [Colors lightText];
    cell.textLabel.shadowColor = [UIColor blackColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
    cell.textLabel.numberOfLines = 2;
    //cell.textLabel.adjustsFontSizeToFitWidth = YES;
    //cell.textLabel.minimumFontSize = 11.0f;
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.textColor = [Colors lightText];
    cell.backgroundColor = [Colors lightBlue];
  }
  if (selectedParkId != nil) {
    NSString *kindOf = [namesKindOfs objectAtIndex:indexPath.row];
    NSDictionary *updates = [availableKindOfUpdates objectForKey:selectedParkId];
    NSArray *size = [updates objectForKey:kindOf];
    NSDictionary *selectedKindOf = [selectedKindOfs objectForKey:selectedParkId];
    cell.textLabel.text = kindOf;
    cell.detailTextLabel.text = ([size count] >= 2)? [NSString stringWithFormat:@"%d %@, %@", [[size objectAtIndex:0] intValue], NSLocalizedString(@"update.photos", nil), [Update sizeToString:[[size objectAtIndex:1] intValue]]] : nil;
    cell.imageView.image = [[selectedKindOf objectForKey:kindOf] boolValue]? selectedImage : unselectedImage;
    cell.imageView.alpha = 1.0f;
    cell.textLabel.alpha = 1.0f;
    cell.detailTextLabel.alpha = 1.0f;
    cell.accessoryType = UITableViewCellAccessoryNone;
  } else {
    int pos = [self posUpdates:(int)indexPath.section row:(int)indexPath.row];
    if (pos >= 0) {
      Update *u = [availableUpdates objectAtIndex:pos];
      cell.textLabel.text = ([u.parkName isEqualToString:CORE_DATA_NAME])? NSLocalizedString(@"update.core.data", nil) : u.parkName;
      NSString *details;
      if (u.imagePathes != nil) {
        NSDictionary *selectedKindOf = [selectedKindOfs objectForKey:u.parkId];
        if (selectedKindOf == nil) {
          details = [NSString stringWithFormat:@"%d %@, %@", u.numberOfFiles, NSLocalizedString(@"update.photos", nil), [Update sizeToString:u.fileSize]];
        } else {
          __block int n = 0;
          __block int size = 0;
          NSDictionary *updates = [availableKindOfUpdates objectForKey:u.parkId];
          [selectedKindOf enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
            if ([object boolValue]) {
              NSArray *a = [updates objectForKey:key];
              if ([a count] >= 2) {
                n += [[a objectAtIndex:0] intValue];
                size += [[a objectAtIndex:1] intValue];
              }
            }
          }];
          details = [NSString stringWithFormat:@"%d %@, %@", n, NSLocalizedString(@"update.photos", nil), [Update sizeToString:size]];
        }
      } else {
        details = [Update sizeToString:u.fileSize];
      }
      ParkData *parkData = [ParkData getParkData:u.parkId];
      if (parkData != nil && parkData.versionOfData > 0.0 && (u.imagePathes == nil || [ImageData isPathAvailableOfParkId:u.parkId])) {
        cell.detailTextLabel.text = ((u.imagePathes == nil && parkData.versionOfData == u.version) || (u.imagePathes != nil && ![availableImageDataChanges containsObject:u.parkId]))? NSLocalizedString(@"update.downloaded", nil) : [NSString stringWithFormat:@"%@ (%@)", NSLocalizedString(@"update.update", nil), details];
      } else {
        cell.detailTextLabel.text = details;
      }
      cell.imageView.image = ([[selectedUpdates objectAtIndex:pos] boolValue])? selectedImage : unselectedImage;
      if (activeUpdate != nil || [[mustUpdates objectAtIndex:pos] boolValue] || [[unselectableUpdates objectAtIndex:pos] boolValue]) {
        cell.imageView.alpha = 0.5f;
        cell.textLabel.alpha = 0.5f;
        cell.detailTextLabel.alpha = 0.5f;
        cell.accessoryType = UITableViewCellAccessoryNone;
      } else {
        cell.imageView.alpha = 1.0f;
        cell.textLabel.alpha = 1.0f;
        cell.detailTextLabel.alpha = 1.0f;
        cell.accessoryType = (u.isHD)? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
      }
    }
  }
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

/*-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (selectedParkId != nil) return tableView.rowHeight;
  int pos = [self posUpdates:indexPath.section row:indexPath.row];
  if (pos >= 0) {
    Update *u = [availableUpdates objectAtIndex:pos];
    NSString *s = ([u.parkName isEqualToString:CORE_DATA_NAME])? NSLocalizedString(@"update.core.data", nil) : u.parkName;
    UIFont *font = [UIFont boldSystemFontOfSize:18.0f];
    CGSize stringSize = [s sizeWithFont:font];
    NSLog(@"%@: %f", s, stringSize.width);
    if (stringSize.width >= tableView.frame.size.width-90.0f) return tableView.rowHeight+22.0f;
  }
  return tableView.rowHeight;
}*/

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return ([self tableView:tableView titleForHeaderInSection:section] == nil)? 0.0f : 30.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  if (selectedParkId != nil) return 30.0f;
  if (section+1 < [self numberOfSectionsInTableView:tableView]) return 0.0f;
  return (activeUpdate == nil && PARK_ID_EDITION != nil)? 80.0f : 30.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  NSString *title = [self tableView:tableView titleForHeaderInSection:section];
  if (title == nil) return nil;
  UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)] autorelease];
  headerView.backgroundColor = [Colors darkBlue];
  UILabel *headerLabel = [[[UILabel alloc] initWithFrame:CGRectMake((selectedParkId == nil)? 36.0f : 10.0f, 4.0f, tableView.bounds.size.width, 22.0f)] autorelease];
  headerLabel.text = title;
  headerLabel.textColor = [Colors lightText];
  headerLabel.shadowColor = [UIColor blackColor];
  headerLabel.shadowOffset = CGSizeMake(0, 1);
  headerLabel.font = [UIFont boldSystemFontOfSize:16];
  headerLabel.backgroundColor = [UIColor clearColor];
  [headerView addSubview:headerLabel];
  if (selectedParkId == nil) {
    UIImageView *flagView = [[[UIImageView alloc] initWithFrame:CGRectMake(4, 7, 25, 15)] autorelease];
    NSString *countryFlag = [NSString stringWithFormat:@"%@.flag", title];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[MenuData dataPath] stringByAppendingPathComponent:NSLocalizedString(countryFlag, nil)]];
    flagView.image = image;
    [image release];
    [headerView addSubview:flagView];
  }
  return headerView;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  if (selectedParkId == nil && section+1 < [self numberOfSectionsInTableView:tableView]) return nil;
  const float hight = (selectedParkId == nil && activeUpdate == nil && PARK_ID_EDITION != nil && PATHES_EDITION == nil)? 75.0f : 30.0f;
  UIView *footerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, hight)] autorelease];
  footerView.backgroundColor = [Colors darkBlue];
  UILabel *footerLabel = [[[UILabel alloc] initWithFrame:CGRectMake(36, 4, tableView.bounds.size.width, 22)] autorelease];
  footerLabel.text = [self tableView:tableView titleForFooterInSection:section];
  footerLabel.textColor = [Colors hilightText];
  footerLabel.shadowColor = [UIColor blackColor];
  footerLabel.shadowOffset = CGSizeMake(0, 1);
  footerLabel.font = [UIFont boldSystemFontOfSize:16];
  footerLabel.backgroundColor = [UIColor clearColor];
  [footerView addSubview:footerLabel];
  if (selectedParkId == nil && activeUpdate == nil && PARK_ID_EDITION != nil && PATHES_EDITION == nil) {
    UIWebView *footerWebView = [[[UIWebView alloc] initWithFrame:CGRectMake(5, 25, tableView.bounds.size.width-10, 50)] autorelease];
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    footerWebView.delegate = self;
    footerWebView.opaque = NO;
    footerWebView.backgroundColor = [UIColor clearColor];
    NSString *linkColor = [Colors htmlColorCode:[Colors hilightText]];
    [footerWebView loadHTMLString:[NSString stringWithFormat:NSLocalizedString(@"update.upgrade.hint", nil), linkColor, linkColor, linkColor, [Colors htmlColorCode:[Colors lightText]]] baseURL:baseURL];
    [footerView addSubview:footerWebView];
  }
  return footerView;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (selectedParkId != nil) return indexPath;
  if (activeUpdate != nil) return nil;
  int pos = [self posUpdates:(int)indexPath.section row:(int)indexPath.row];
  return (pos >= 0 && ![[mustUpdates objectAtIndex:pos] boolValue] && ![[unselectableUpdates objectAtIndex:pos] boolValue])? indexPath : nil;
}

-(void)updateSelectDownloadButtons:(BOOL)selectedItem {
  if (selectedItem) {
    if ([bottomToolbar.items count] > 1 && ![self isSelectedDownload]) {
      [bottomToolbar setItems:[NSArray arrayWithObject:selectAllButton] animated:YES];
    }
  } else if ([bottomToolbar.items count] <= 1) {
    [bottomToolbar setItems:originalBottomToolbar animated:YES];
  }
  if (selectAllButton != nil) {
    selectAllButton.title = ([self isAllSelectionDeleted])? NSLocalizedString(@"update.button.select.all", nil) : NSLocalizedString(@"update.button.delete.selection", nil);
  }
  downloadedSize.hidden = YES;
  downloadProgress.hidden = YES;
  downloadStatus.hidden = YES;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (selectedParkId != nil) {
    NSString *kindOf = [namesKindOfs objectAtIndex:indexPath.row];
    NSDictionary *selectedKindOf = [selectedKindOfs objectForKey:selectedParkId];
    [selectedKindOf setValue:[NSNumber numberWithBool:![[selectedKindOf objectForKey:kindOf] boolValue]] forKey:kindOf];
    [tableView reloadData];
    return;
  }
  int pos = [self posUpdates:(int)indexPath.section row:(int)indexPath.row];
	BOOL selected = [[selectedUpdates objectAtIndex:pos] boolValue];
  [selectedUpdates replaceObjectAtIndex:pos withObject:[NSNumber numberWithBool:!selected]];
  if (PARK_ID_EDITION == nil && pos+1 < [availableUpdates count]) {
    Update *update = [availableUpdates objectAtIndex:pos];
    Update *nextUpdate = [availableUpdates objectAtIndex:pos+1];
    if ([update.parkId isEqualToString:nextUpdate.parkId] && [ParkData getParkData:update.parkId] != nil && [ParkData getParkData:update.parkId] == nil) {
      [unselectableUpdates replaceObjectAtIndex:pos+1 withObject:[NSNumber numberWithBool:selected]];
      if ([[selectedUpdates objectAtIndex:pos+1] boolValue]) [selectedUpdates replaceObjectAtIndex:pos+1 withObject:[NSNumber numberWithBool:NO]];
    }
  }
  Update *update = [availableUpdates objectAtIndex:pos];
  if (update.imagePathes != nil) {
    [selectedKindOfs removeObjectForKey:update.parkId];
    [availableKindOfUpdates removeObjectForKey:update.parkId];
  }
  [self updateSelectDownloadButtons:selected];
  [tableView reloadData];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  CATransition *transition = [CATransition animation];
  transition.duration = 0.3;
  transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  transition.type = kCATransitionPush;
  transition.subtype = kCATransitionFromRight;
  [self.view.window.layer addAnimation:transition forKey:nil];
  int pos = [self posUpdates:(int)indexPath.section row:(int)indexPath.row];
  Update *update = [availableUpdates objectAtIndex:pos];
  [selectedParkId release];
  selectedParkId = [update.parkId retain];
  NSDictionary *available = [availableKindOfUpdates objectForKey:selectedParkId];
  if (available == nil) {
    available = [ImageData availableChangesSizeImagePathesByKindOfForParkId:selectedParkId];
    [availableKindOfUpdates setValue:available forKey:selectedParkId];
    NSMutableDictionary *selectedKindOf = [[NSMutableDictionary alloc] initWithCapacity:[available count]];
    NSNumber *defaultValue = [selectedUpdates objectAtIndex:pos];
    for (NSString *kindOf in available) [selectedKindOf setObject:defaultValue forKey:kindOf];
    [selectedKindOfs setValue:selectedKindOf forKey:selectedParkId];
    [selectedKindOf release];
  }
  NSMutableArray *array = [[NSMutableArray alloc] initWithArray:[available allKeys]];
  [array sortUsingSelector:@selector(compare:)];
  [namesKindOfs release];
  namesKindOfs = array;
  selectedIndexPath = [indexPath retain];
  tableView.tag = pos;
  CGRect r = tableView.frame;
  tableView.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height+bottomToolbar.frame.size.height);
  bottomToolbar.hidden = YES;
  [tableView reloadData];
  if ([namesKindOfs count] > 0) [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

#pragma mark -
#pragma mark Web view delegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted || (navigationType == UIWebViewNavigationTypeOther && [[request URL] host] != nil)) {
    NSURL *requestURL = [request URL];
    NSString *scheme = [requestURL scheme];
    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"] || [scheme isEqualToString:@"mailto"]) return ![[UIApplication sharedApplication] openURL:requestURL];
  }
  return YES;
}

#pragma mark -
#pragma mark Update delegate

-(void)updateStatusGUI:(NSArray *)args {
  NSString *status = [args objectAtIndex:0];
  double percentage = [[args objectAtIndex:1] doubleValue];
  downloadStatus.text = status;
  downloadProgress.progress = (percentage < 0.0)? 0.0 : percentage;
  if (percentage < 0.0 || percentage == 1.0) {
    if (percentage < -1.0) {
      if (!errorPopUps) {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"information", nil), activeUpdate.parkName]
                               message:status
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
        errorPopUps = YES;
      }
    } else if (percentage == -1.0) {
      if (downloadPos >= 0) {
        Update *update = [availableUpdates objectAtIndex:downloadPos];
        if ([update hasProgress] && update.imagePathes == nil) { // no automatic retry for HD downloads
          [lastDownloadError release];
          lastDownloadError = [status retain];
          errorPopUps = NO;
          [theTableView reloadData];
          [selectedUpdates replaceObjectAtIndex:downloadPos withObject:[NSNumber numberWithBool:YES]];
          [self download:nil];
          return;
        }
      }
      if (!errorPopUps) {
        if (lastDownloadError != nil && lastDownloadError.length > 0 && [status isEqualToString:NSLocalizedString(@"update.download.completion.error", nil)]) {
          status = lastDownloadError;
        }
        downloadProgress.progress = activeUpdate.downloadedPercentage;
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"download", nil)
                               message:status
                               delegate:self
                               cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                               otherButtonTitles:NSLocalizedString(@"retry", nil), nil];
        dialog.tag = 1;
        [dialog show];
        [dialog release];
        errorPopUps = YES;
        [downloadIndicator stopAnimating];
        [theTableView reloadData];
        return;
      }
    }
    [downloadIndicator stopAnimating];
    [theTableView reloadData];
    [self download:nil];
  }
}

-(void)status:(NSString *)status percentage:(double)percentage {
  NSNumber *n = [[NSNumber alloc] initWithDouble:percentage];
  NSArray *args = [[NSArray alloc] initWithObjects:status, n, nil];
  [self performSelectorOnMainThread:@selector(updateStatusGUI:) withObject:args waitUntilDone:NO];
  [n release];
  [args release];
}

-(void)updateDownloadedGUI:(NSString *)number {
  downloadedSize.text = number;
}

-(void)downloaded:(NSString *)number {
  [self performSelectorOnMainThread:@selector(updateDownloadedGUI:) withObject:number waitUntilDone:NO];
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  if (selectedParkId != nil) {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:transition forKey:nil];
    NSDictionary *selectedKindOf = [selectedKindOfs objectForKey:selectedParkId];
    BOOL selected = NO;
    NSEnumerator *i = [selectedKindOf objectEnumerator];
    while (TRUE) {
      NSNumber *n = [i nextObject];
      if (!n) break;
      if ([n boolValue]) {
        selected = YES;
        break;
      }
    }
    [selectedUpdates replaceObjectAtIndex:theTableView.tag withObject:[NSNumber numberWithBool:selected]];
    [selectedParkId release];
    selectedParkId = nil;
    [namesKindOfs release];
    namesKindOfs = nil;
    CGRect r = theTableView.frame;
    theTableView.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height-bottomToolbar.frame.size.height);
    bottomToolbar.hidden = NO;
    [theTableView reloadData];
    [theTableView scrollToRowAtIndexPath:selectedIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    [selectedIndexPath release];
    selectedIndexPath = nil;
    [self updateSelectDownloadButtons:!selected];
  } else {
    [delegate dismissModalViewControllerAnimated:YES];
  }
}

-(IBAction)download:(id)sender {
  firstUpdateCheck = NO;
  if (sender != nil) {
    UIAlertView *alertDialog = [[UIAlertView alloc]
                                initWithTitle:NSLocalizedString(@"agreement", nil)
                                message:NSLocalizedString(@"download.agreement", nil)
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"abort", nil)
                                otherButtonTitles:NSLocalizedString(@"accept", nil), nil];
    alertDialog.tag = 0;
    [alertDialog show];
    [alertDialog release];
    errorPopUps = NO;
    downloadPos = -1;
    [lastDownloadError release];
    lastDownloadError = nil;
  } else {
    activeUpdate = nil;
    int pos = 0;
    for (Update *u in availableUpdates) {
      if ([[selectedUpdates objectAtIndex:pos] boolValue]) {
        [titleNavigationItem setLeftBarButtonItem:nil animated:YES];
        activeUpdate = u;
        downloadPos = pos;
        [selectedUpdates replaceObjectAtIndex:pos withObject:[NSNumber numberWithBool:NO]];
        [downloadIndicator startAnimating];
        downloadStatus.text = @"";
        downloadStatus.hidden = NO;
        downloadedSize.text = @"";
        downloadedSize.hidden = NO;
        downloadProgress.progress = 0.0;
        downloadProgress.hidden = NO;
        if (u.imagePathes != nil) {
          NSDictionary *selectedKindOf = [selectedKindOfs objectForKey:u.parkId];
          if (selectedKindOf != nil) {
            __block int n = 0;
            __block int size = 0;
            NSMutableArray *newImagePathes = [[NSMutableArray alloc] initWithCapacity:[u.imagePathes count]];
            NSDictionary *updates = [availableKindOfUpdates objectForKey:u.parkId];
            [selectedKindOf enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
              if ([object boolValue]) {
                NSArray *a = [updates objectForKey:key];
                int l = (int)[a count];
                if (l >= 2) {
                  for (int i = 2; i < l; ++i) [newImagePathes addObject:[a objectAtIndex:i]];
                  n += [[a objectAtIndex:0] intValue];
                  size += [[a objectAtIndex:1] intValue];
                }
              }
            }];
            [u updateImagePathes:newImagePathes numberOfFiles:n fileSize:size];
            [newImagePathes release];
          }
        }
        [u update]; // core must be the first update!
        if (PARK_ID_EDITION == nil) {
          [availableImageDataChanges release];
          availableImageDataChanges = [[ImageData allParkIdsWithAvailableChanges] retain];
        }
        break;
      }
      ++pos;
    }
    bottomToolbar.items = nil;
    if (activeUpdate == nil) [self updateData:NO];
    else [theTableView reloadData];
    //[ParkData save];
  }
}

-(IBAction)selectAllItems:(id)sender {
  BOOL changes = NO;
  if (selectAllButton != nil) {
    [selectedKindOfs removeAllObjects];
    [availableKindOfUpdates removeAllObjects];
    if ([selectAllButton.title isEqualToString:NSLocalizedString(@"update.button.select.all", nil)]) {
      int n = (int)[selectedUpdates count];
      for (int i = 0; i < n; ++i) {
        BOOL unselectable = NO;
        if ([[unselectableUpdates objectAtIndex:i] boolValue]) {
          Update *update = [availableUpdates objectAtIndex:i];
          unselectable = (PARK_ID_EDITION != nil || [ParkData getParkData:update.parkId] == nil);
          if (!unselectable) [unselectableUpdates replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
        }
        if (!unselectable && ![[selectedUpdates objectAtIndex:i] boolValue]) {
          [selectedUpdates replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:YES]];
          changes = YES;
        }
      }
      if (changes) {
        selectAllButton.title = NSLocalizedString(@"update.button.delete.selection", nil);
        [bottomToolbar setItems:originalBottomToolbar animated:YES];
      }
    } else {
      int n = (int)[selectedUpdates count];
      Update *previousUpdate = nil;
      for (int i = 0; i < n; ++i) {
        Update *update = [availableUpdates objectAtIndex:i];
        if ([[selectedUpdates objectAtIndex:i] boolValue] && ![[mustUpdates objectAtIndex:i] boolValue]) {
          [selectedUpdates replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
          changes = YES;
        }
        if (previousUpdate != nil && [update.parkId isEqualToString:previousUpdate.parkId]) {
          [unselectableUpdates replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:YES]];
        }
        previousUpdate = update;
      }
      if (changes) {
        selectAllButton.title = NSLocalizedString(@"update.button.select.all", nil);
        if ([bottomToolbar.items count] > 1 && ![self isSelectedDownload]) {
          [bottomToolbar setItems:[NSArray arrayWithObject:selectAllButton] animated:YES];
        }
      }
    }
  }
  if (changes) [theTableView reloadData];
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
}

-(void)viewDidUnload {
  [super viewDidUnload];
  leftButton = nil;
  downloadButton = nil;
  selectAllButton = nil;
  bottomToolbar = nil;
  topNavigationBar = nil;
  titleNavigationItem = nil;
  theTableView = nil;
  downloadIndicator = nil;
  initIndicator = nil;
  downloadProgress = nil;
  downloadStatus = nil;
  downloadedSize = nil;
  selectedImage = nil;
  unselectedImage = nil;
  originalBottomToolbar = nil;
}

-(void)dealloc {
  [availableImageDataChanges release];
  availableImageDataChanges = nil;
  [mustUpdateParkGroupIds release];
  mustUpdateParkGroupIds = nil;
  [availableUpdates release];
  availableUpdates = nil;
  [availableKindOfUpdates release];
  availableKindOfUpdates = nil;
  [selectedKindOfs release];
  selectedKindOfs = nil;
  [mustUpdates release];
  mustUpdates = nil;
  [selectedUpdates release];
  selectedUpdates = nil;
  [unselectableUpdates release];
  unselectableUpdates = nil;
  [leftButton release];
  [downloadButton release];
  [selectAllButton release];
  [bottomToolbar release];
  [topNavigationBar release];
  [titleNavigationItem release];
  [theTableView release];
  [downloadIndicator release];
  [initIndicator release];
  [downloadProgress release];
  [downloadStatus release];
  [downloadedSize release];
  [selectedImage release];
  [unselectedImage release];
  [originalBottomToolbar release];
  [selectedParkId release];
  selectedParkId = nil;
  [namesKindOfs release];
  namesKindOfs = nil;
  [lastDownloadError release];
  lastDownloadError = nil;
  [super dealloc];
}

@end

