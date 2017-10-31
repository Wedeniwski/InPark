//
//  WaitTimeOverviewViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.04.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WaitTimeOverviewViewController.h"
#import "Attraction.h"
#import "SettingsData.h"
#import "MenuData.h"
#import "ParkData.h"
#import "ProfileData.h"
#import "WaitingTimeData.h"
#import "CalendarData.h"
#import "LocationData.h"
#import "WaitTimeCell.h"
#import "Colors.h"
#import "IPadHelper.h"

@implementation WaitTimeOverviewViewController

@synthesize cellOwner;
@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize recentWaitTimesLabel;
@synthesize recentWaitTimesTable;
@synthesize localTimeLabel;
@synthesize currentWaitTimeLabel;
@synthesize currentWaitTimeBadge;
@synthesize closedImageView;
@synthesize confirmButton, submitButton;
@synthesize userNameLabel;
@synthesize userNameTextField;
@synthesize waitingTimePickerView;
@synthesize cancelButton, submitWaitTimeButton, rulesButton;
@synthesize activityIndicatorView;

static NSString *parkId = nil;
static NSString *attractionId = nil;
static NSString *lastComment = nil;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractionId:(NSString *)aId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    // Custom initialization
    delegate = owner;
    [parkId release];
    parkId = [pId retain];
    [attractionId release];
    attractionId = [aId retain];
    waitingTimeItem = nil;
  }
  return self;
}

-(void)updateData {
  SettingsData *settings = [SettingsData getSettingsData];
  ParkData *parkData = [ParkData getParkData:parkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  [waitingTimeItem release];
  waitingTimeItem = [[waitingTimeData getWaitingTimeFor:attractionId] retain];
  NSString *time = [CalendarData stringFromTimeLong:waitingTimeData.baseTime considerTimeZoneAbbreviation:parkData.timeZoneAbbreviation];
  recentWaitTimesLabel.text = (time == nil)? nil : [NSString stringWithFormat:NSLocalizedString(@"wait.times.overview.recent", nil), time];
  recentWaitTimesTable.scrollEnabled = (![settings isPortraitScreen] || ([waitingTimeItem count] >= 3 && [waitingTimeItem containsComment]));
  [recentWaitTimesTable reloadData];
  if ([waitingTimeData isClosed:attractionId considerCalendar:YES]) {
    currentWaitTimeLabel.text = NSLocalizedString(@"tour.item.closed", nil);
    currentWaitTimeBadge.hidden = YES;
    closedImageView.hidden = NO;
  } else {
    currentWaitTimeBadge.backgroundColor = [UIColor clearColor];
    currentWaitTimeBadge.badgeCornerRoundness = 0.1;
    currentWaitTimeBadge.badgeShining = YES;
    currentWaitTimeBadge.contentScaleFactor = [[UIScreen mainScreen] scale];
    currentWaitTimeBadge.badgeTextColor = [UIColor whiteColor];
    currentWaitTimeBadge.badgeFrame = YES;
    currentWaitTimeBadge.badgeFrameColor = [UIColor whiteColor];
    currentWaitTimeBadge.badgeScaleFactor = 1.7;
    NSString *t = [waitingTimeData setBadge:currentWaitTimeBadge forWaitingTimeItem:waitingTimeItem atIndex:-1 showAlsoOldTimes:NO];
    if (t != nil) {
      NSString *preFix = [NSString stringWithFormat:@"%@:\n", NSLocalizedString(@"waiting.time", nil)];
      if ([t hasPrefix:preFix]) t = [t substringFromIndex:preFix.length];
      currentWaitTimeBadge.hidden = YES;
      currentWaitTimeLabel.text = t;
    } else if ([currentWaitTimeBadge.badgeText isEqualToString:NSLocalizedString(@"waiting.time.unknown", nil)]) {
      if ([parkData isTodayClosed]) {
        currentWaitTimeBadge.hidden = YES;
        currentWaitTimeLabel.text = NSLocalizedString(@"waiting.time.park.closed", nil);
      } else {
        currentWaitTimeBadge.hidden = NO;
        currentWaitTimeLabel.text = NSLocalizedString(@"wait.times.overview.current.unknown", nil);
      }
    } else if (waitingTimeItem.totalWaitingTime < 0) {
      currentWaitTimeBadge.hidden = NO;
      currentWaitTimeLabel.text = (waitingTimeItem.totalWaitingTime < -1)? NSLocalizedString(@"wait.times.overview.maybe.closed", nil) : NSLocalizedString(@"wait.times.overview.approx", nil);
    } else {
      currentWaitTimeBadge.hidden = NO;
      currentWaitTimeLabel.text = NSLocalizedString(@"wait.times.overview.current", nil);
    }
    closedImageView.hidden = YES;
  }
  if (waitingTimeItem == nil || [waitingTimeItem count] == 0) {
    [confirmButton setTitle:NSLocalizedString(@"wait.times.overview.confirm", nil) forState:UIControlStateNormal];
    confirmButton.enabled = NO;
    confirmButton.alpha = 0.5f;
  } else {
    confirmButton.enabled = YES;
    confirmButton.alpha = 1.0f;
    if ([waitingTimeItem waitTimeAt:0] < 0) {
      [confirmButton setTitle:NSLocalizedString(@"wait.times.overview.confirm.closed", nil) forState:UIControlStateNormal];
    } else {
      [confirmButton setTitle:NSLocalizedString(@"wait.times.overview.confirm", nil) forState:UIControlStateNormal];
    }
  }
  [lastComment release];
  lastComment = nil;
  [self cancelWaitingTimeChange:nil];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [Colors darkBlue];
  topNavigationBar.tintColor = [Colors darkBlue];
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 480, 44)];
  titleLabel.backgroundColor = [UIColor clearColor];
  titleLabel.numberOfLines = 2;
  titleLabel.adjustsFontSizeToFitWidth = YES;
  titleLabel.minimumFontSize = 14.0f;
  titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
  titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
  titleLabel.textAlignment = UITextAlignmentCenter;
  titleLabel.textColor = [UIColor whiteColor];
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
  titleLabel.text = attraction.stringAttractionName;
  titleNavigationItem.titleView = titleLabel;
  [titleLabel release];
  recentWaitTimesLabel.textColor = [Colors lightText];
  recentWaitTimesTable.separatorColor = [Colors lightBlue];
  //recentWaitTimesTable.backgroundColor = [UIColor clearColor];
  recentWaitTimesTable.backgroundColor = [Colors blueTransparent];
  recentWaitTimesTable.backgroundView = nil;
  recentWaitTimesTable.rowHeight = 35.0f;
  localTimeLabel.textColor = [Colors lightText];
  localTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"wait.times.overview.local.time", nil), [MenuData getParkName:parkId cache:YES]];
  currentWaitTimeLabel.textColor = [Colors lightText];
  [confirmButton setTitleColor:[Colors darkBlue] forState:UIControlStateNormal];
  [confirmButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
  [submitButton setTitleColor:[Colors darkBlue] forState:UIControlStateNormal];
  [submitButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
  [submitButton setTitle:NSLocalizedString(@"wait.times.overview.submit", nil) forState:UIControlStateNormal];
  [submitWaitTimeButton setTitleColor:[Colors darkBlue] forState:UIControlStateNormal];
  [submitWaitTimeButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
  [submitWaitTimeButton setTitle:NSLocalizedString(@"submit", nil) forState:UIControlStateNormal];
  [cancelButton setTitleColor:[Colors darkBlue] forState:UIControlStateNormal];
  [cancelButton setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
  [cancelButton setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
  userNameLabel.textColor = [Colors lightText];
  userNameTextField.backgroundColor = [Colors lightBlue];
  userNameTextField.textColor = [Colors hilightText];
  [rulesButton setTitle:NSLocalizedString(@"wait.times.overview.rules", nil) forState:UIControlStateNormal];
  [rulesButton setTitleColor:[Colors lightBlue] forState:UIControlStateNormal];
  SettingsData *settings = [SettingsData getSettingsData];
  BOOL iPad = [IPadHelper isIPad];
  BOOL isPortraitScreen = [settings isPortraitScreen];
  if (!isPortraitScreen || iPad) {
    if (iPad) {
      CGRect r = recentWaitTimesTable.frame;
      recentWaitTimesTable.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, 250.0f);
      r = localTimeLabel.frame;
      localTimeLabel.frame = CGRectMake(r.origin.x, recentWaitTimesTable.frame.origin.y+recentWaitTimesTable.frame.size.height, r.size.width, r.size.height);
    } else {
      CGRect r = recentWaitTimesTable.frame;
      recentWaitTimesTable.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, 50.0f);
    }
    CGRect r = [[UIScreen mainScreen] bounds];
    float m = (isPortraitScreen)? r.size.width/2.0f : r.size.height/2.0f;//(submitButton.frame.origin.x+r.origin.x+r.size.width)/2.0f;
    r = confirmButton.frame;
    confirmButton.frame = CGRectMake(m+5.0f, submitButton.frame.origin.y, m-5.0f-submitButton.frame.origin.x, r.size.height);
    confirmButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    r = submitButton.frame;
    submitButton.frame = CGRectMake(r.origin.x, r.origin.y, m-5.0f-r.origin.x, r.size.height);
    submitButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
  }
  [self updateData];
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
  return (waitingTimeItem == nil)? 1 : [waitingTimeItem count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"WaitTimeCell";
  WaitTimeCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    [cellOwner loadNibNamed:cellId owner:self];
    cell = (WaitTimeCell *)cellOwner.cell;
    cell.userNameLabel.textColor = [Colors lightText];
    cell.submittedTimestampLabel.textColor = [Colors lightText];
    cell.backgroundColor = [Colors lightBlue];
    cell.waitingTimeBadge.backgroundColor = [UIColor clearColor];
    cell.waitingTimeBadge.badgeCornerRoundness = 0.1;
    cell.waitingTimeBadge.badgeShining = YES;
    cell.waitingTimeBadge.contentScaleFactor = [[UIScreen mainScreen] scale];
    cell.waitingTimeBadge.badgeTextColor = [UIColor whiteColor];
    cell.waitingTimeBadge.badgeFrame = YES;
    cell.waitingTimeBadge.badgeFrameColor = [UIColor whiteColor];
    cell.waitingTimeBadge.badgeScaleFactor = 1.1;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  if (waitingTimeItem == nil) {
    [waitingTimeData setBadge:cell.waitingTimeBadge forWaitingTimeItem:waitingTimeItem atIndex:-1 showAlsoOldTimes:NO];
    cell.userNameLabel.text = NSLocalizedString(@"wait.times.overview.no.current", nil);
    CGRect r = cell.submittedTimestampLabel.frame;
    cell.submittedTimestampLabel.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, 15.0f);
    cell.submittedTimestampLabel.text = nil;
  } else {
    int idx = (int)indexPath.row;
    [waitingTimeData setBadge:cell.waitingTimeBadge forWaitingTimeItem:waitingTimeItem atIndex:idx showAlsoOldTimes:YES];
    //NSLog(@"idx: %d - %@ - %@", idx, t, cell.waitingTimeBadge.badgeText);
    BOOL closed = ([waitingTimeItem waitTimeAt:idx] < 0);
    cell.closedImageView.hidden = (waitingTimeItem != nil && !closed);
    cell.waitingTimeBadge.hidden = (waitingTimeItem == nil || closed);
    NSString *userName = [waitingTimeItem userNameAt:idx];
    if (userName == nil) userName = NSLocalizedString(@"wait.times.overview.unknown", nil);
    cell.userNameLabel.text = [NSString stringWithFormat:NSLocalizedString(@"wait.times.overview.time.by", nil), userName];
    NSString *comment = [waitingTimeItem commentsAt:idx];
    if (comment == nil) {
      CGRect r = cell.submittedTimestampLabel.frame;
      cell.submittedTimestampLabel.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, 15.0f);
      NSDate *submittedTimestamp = [waitingTimeItem submittedTimestampAt:idx];
      cell.submittedTimestampLabel.text = [NSString stringWithFormat:@"%@ (%@)", [CalendarData stringFromTimeLong:submittedTimestamp considerTimeZoneAbbreviation:parkData.timeZoneAbbreviation], [CalendarData stringFromDate:submittedTimestamp considerTimeZoneAbbreviation:parkData.timeZoneAbbreviation]];
    } else {
      CGRect r = cell.submittedTimestampLabel.frame;
      cell.submittedTimestampLabel.frame = CGRectMake(r.origin.x, r.origin.y, r.size.width, ([comment length] >= 40)? 40.0f : 30.0f);
      NSDate *submittedTimestamp = [waitingTimeItem submittedTimestampAt:idx];
      cell.submittedTimestampLabel.text = [NSString stringWithFormat:@"%@ (%@)\n%@", [CalendarData stringFromTimeLong:submittedTimestamp considerTimeZoneAbbreviation:parkData.timeZoneAbbreviation], [CalendarData stringFromDate:submittedTimestamp considerTimeZoneAbbreviation:parkData.timeZoneAbbreviation], comment];
    }
  }
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  float h = recentWaitTimesTable.rowHeight;
  NSString *comment = [waitingTimeItem commentsAt:(int)indexPath.row];
  if (comment == nil) return h;
  return ([comment length] >= 40)? h+25.0f : h+15.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  return 0.0;
}

#pragma mark -
#pragma mark Text view delegate

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  SettingsData *settings = [SettingsData getSettingsData];
  float y = [settings isPortraitScreen]? self.view.frame.origin.y : self.view.frame.origin.x;
  if (y >= 0) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    CGRect r = self.view.frame;
    if ([settings isPortraitScreen]) self.view.frame = CGRectMake(r.origin.x, y-210.0f, r.size.width, r.size.height);
    else self.view.frame = CGRectMake(y-160.0f, r.origin.y, r.size.width, r.size.height);
    [UIView commitAnimations];
  }
  return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  SettingsData *settings = [SettingsData getSettingsData];
  float y = [settings isPortraitScreen]? self.view.frame.origin.y : self.view.frame.origin.x;
  if (y < 0) {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    CGRect r = self.view.frame;
    if ([settings isPortraitScreen]) self.view.frame = CGRectMake(r.origin.x, y+210.0f, r.size.width, r.size.height);
    else self.view.frame = CGRectMake(y+160.0f, r.origin.y, r.size.width, r.size.height);
    [UIView commitAnimations];
  }
  if (waitingTimePickerView.hidden) {
    ProfileData *profileData = [ProfileData getProfileData];
    profileData.userName = textField.text;
  }
  return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  textField.text = [WaitingTimeItem removeTokens:textField.text maxLength:(waitingTimePickerView.hidden)? 20 : 100];
  [textField resignFirstResponder];
  return NO;
}

-(BOOL)textFieldShouldClear:(UITextField *)textField {
  textField.text = nil;
  if (waitingTimePickerView.hidden) {
    ProfileData *profileData = [ProfileData getProfileData];
    profileData.userName = nil;
  }
  return NO;
}

#pragma mark -
#pragma mark Picker view delegate

-(void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
}

#pragma mark -
#pragma mark Picker view data source

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
  return 1;
}

-(NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
  return [[WaitingTimeData waitingTimeData] count];
}

-(NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return [[WaitingTimeData waitingTimeData] objectAtIndex:row];
}

#pragma mark -
#pragma mark Alert view delegate

-(void)submitTourItem:(NSArray *)args {
  ParkData *parkData = [ParkData getParkData:parkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  NSString *comment = ([args count] > 3)? [args objectAtIndex:3] : nil;
  if ([waitingTimeData submitTourItem:[args objectAtIndex:0] waitingTime:[[args objectAtIndex:1] intValue] comment:comment]) {
    [self performSelectorOnMainThread:@selector(updateData) withObject:nil waitUntilDone:NO];
  } else {
    NSString *title = NSLocalizedString(@"network.error", nil);
    NSString *message = NSLocalizedString(@"wait.times.overview.submit.error", nil);
    if (![LocationData isLocationDataActive]) {
      if (![LocationData isLocationDataStarted]) {
        LocationData *locData = [LocationData getLocationData];
        [locData start];
        [locData registerViewController:delegate];
      }
      title = NSLocalizedString(@"pathes.location.service", nil);
      message = NSLocalizedString(@"pathes.location.not.identified.again", nil);
    } else {
      LocationData *locData = [LocationData getLocationData];
      if (locData.lastUpdatedLocation == nil) {
        title = NSLocalizedString(@"pathes.location.service", nil);
        message = NSLocalizedString(@"pathes.location.not.identified.again", nil);
      } else if (![parkData isCurrentlyInsidePark]) {
        title = NSLocalizedString(@"pathes.location.service", nil);
        message = NSLocalizedString(@"pathes.waiting.time.only.inside.park.again", nil);
      } else {
        TourItem *tourItem = [args objectAtIndex:0];
        Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
        if (attraction == nil || [[args objectAtIndex:1] intValue] > 180) {
          UIAlertView *dialog = [[UIAlertView alloc]
                                 initWithTitle:NSLocalizedString(@"error", nil)
                                 message:NSLocalizedString(@"location.error", nil)
                                 delegate:nil
                                 cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                 otherButtonTitles:nil];
          [dialog show];
          [dialog release];
          return;
        }
      }
    }
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:title
                           message:message
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"yes", nil)
                           otherButtonTitles:NSLocalizedString(@"no", nil), nil];
    dialog.tag = [[args objectAtIndex:2] intValue];
    [dialog show];
    [dialog release];
  }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
  if (alertView.tag == 1) {
    if ([buttonTitle isEqualToString:NSLocalizedString(@"yes", nil)]) {
      LocationData *locData = [LocationData getLocationData];
      [locData start];
    }
  } else if (alertView.tag == 2 || alertView.tag == 3) {
    if ([buttonTitle isEqualToString:NSLocalizedString(@"submit", nil)] || [buttonTitle isEqualToString:NSLocalizedString(@"yes", nil)]) {
      ParkData *parkData = [ParkData getParkData:parkId];
      WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
      int waitingTime = -1;
      if (alertView.tag == 2) waitingTime = [waitingTimeData isClosed:attractionId considerCalendar:YES]? -1 : [waitingTimeItem latestWaitingTime];
      else waitingTime = [WaitingTimeData selectedWaitingTimeAtIndex:(int)[waitingTimePickerView selectedRowInComponent:0]];
      NSString *entryId = [parkData firstEntryAttractionIdOf:attractionId];
      NSString *exitId = [parkData getRootAttractionId:[parkData exitAttractionIdOf:attractionId]];
      TourItem *tourItem = [[TourItem alloc] initWithAttractionId:attractionId entry:entryId exit:exitId];
      titleNavigationItem.leftBarButtonItem.enabled = NO;
      userNameTextField.enabled = NO;
      submitButton.enabled = NO;
      submitButton.alpha = 0.5f;
      confirmButton.enabled = NO;
      confirmButton.alpha = 0.5f;
      [activityIndicatorView startAnimating];
      [self performSelectorInBackground:@selector(submitTourItem:) withObject:[NSArray arrayWithObjects:tourItem, [NSNumber numberWithInt:waitingTime], [NSNumber numberWithInt:(int)alertView.tag], lastComment, nil]];
      [tourItem release];
    } else {
      [self updateData];
    }
  } else if (alertView.tag == 4) {
    if ([buttonTitle isEqualToString:NSLocalizedString(@"accept", nil)]) {
      ParkData *parkData = [ParkData getParkData:CORE_DATA_ID];
      parkData.rulesForCommentsAccepted = YES;
      [self submitWaitingTimeChange:self];
      [parkData save:YES];
    }
  }
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
	[delegate dismissModalViewControllerAnimated:YES];
}

-(BOOL)prepareWaitTimeChanges {
#ifndef SUBMIT_WAITING_TIME_WITHOUT_LOCATION
  if (![LocationData isLocationDataActive]) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"pathes.location.service.needed", nil)
                           message:NSLocalizedString(@"pathes.location.service.disabled", nil)
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"yes", nil)
                           otherButtonTitles:NSLocalizedString(@"no", nil), nil];
    dialog.tag = 1;
    [dialog show];
    [dialog release];
    return NO;
  }
  LocationData *locData = [LocationData getLocationData];
  if (locData.lastUpdatedLocation == nil) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"pathes.location.service", nil)
                           message:NSLocalizedString(@"pathes.location.not.identified", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
    return NO;
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  if (![parkData isCurrentlyInsidePark]) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"pathes.location.service", nil)
                           message:NSLocalizedString(@"pathes.waiting.time.only.inside.park", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
    return NO;
  }
#endif
  return YES;
}

-(IBAction)confirmWaitTime:(id)sender {
  [userNameTextField resignFirstResponder];
  if (/*![self prepareWaitTimeChanges] ||*/ waitingTimeItem == nil || [waitingTimeItem count] == 0) return;
  NSString *title = [confirmButton titleForState:UIControlStateNormal];
  NSString *message = nil;
  if ([waitingTimeItem waitTimeAt:0] < 0) {
    message = NSLocalizedString(@"wait.times.overview.confirm.closed.send", nil);
  } else {
    message = [NSString stringWithFormat:NSLocalizedString(@"wait.times.overview.confirm.send", nil), [waitingTimeItem latestWaitingTime]];
  }
  UIAlertView *dialog = [[UIAlertView alloc]
                         initWithTitle:title
                         message:message
                         delegate:self
                         cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                         otherButtonTitles:NSLocalizedString(@"submit", nil), nil];
  dialog.tag = 2;
  [dialog show];
  [dialog release];
}

-(IBAction)submitWaitTime:(id)sender {
  [userNameTextField resignFirstResponder];
  //if (![self prepareWaitTimeChanges]) return;
  int latestWaitingTime = (waitingTimeItem == nil)? 0 : [waitingTimeItem latestWaitingTime];
  [waitingTimePickerView selectRow:[WaitingTimeData closestTimeDataIndexFor:latestWaitingTime] inComponent:0 animated:NO];
  userNameLabel.text = NSLocalizedString(@"wait.times.overview.comment", nil);
  userNameTextField.placeholder = @"";
  userNameTextField.text = @"";
  waitingTimePickerView.hidden = NO;
  if (![IPadHelper isIPad]) {
    recentWaitTimesLabel.hidden = YES;
    recentWaitTimesTable.hidden = YES;
    localTimeLabel.hidden = YES;
  }
  confirmButton.hidden = YES;
  submitButton.hidden = YES;
  cancelButton.hidden = NO;
  submitWaitTimeButton.hidden = NO;
}

-(IBAction)cancelWaitingTimeChange:(id)sender {
  [userNameTextField resignFirstResponder];
  userNameTextField.placeholder = NSLocalizedString(@"wait.times.overview.unknown", nil);
  ProfileData *profileData = [ProfileData getProfileData];
  if (profileData.userName != nil && [profileData.userName length] > 0) userNameTextField.text = profileData.userName;
  userNameLabel.text = NSLocalizedString(@"wait.times.overview.user.name", nil);
  waitingTimePickerView.hidden = YES;
  recentWaitTimesLabel.hidden = NO;
  recentWaitTimesTable.hidden = NO;
  localTimeLabel.hidden = NO;
  confirmButton.hidden = NO;
  submitButton.hidden = NO;
  cancelButton.hidden = YES;
  submitWaitTimeButton.hidden = YES;
  userNameTextField.enabled = YES;
  titleNavigationItem.leftBarButtonItem.enabled = YES;
  submitButton.enabled = YES;
  submitButton.alpha = 1.0f;
  [activityIndicatorView stopAnimating];
}

-(IBAction)submitWaitingTimeChange:(id)sender {
  [userNameTextField resignFirstResponder];
  ParkData *parkData = [ParkData getParkData:CORE_DATA_ID];
  if ([userNameTextField.text length] > 0 && !parkData.rulesForCommentsAccepted) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"wait.times.overview.rules.title", nil)
                           message:NSLocalizedString(@"wait.times.overview.rules.accept", nil)
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"abort", nil)
                           otherButtonTitles:NSLocalizedString(@"accept", nil), nil];
    dialog.tag = 4;
    [dialog show];
    [dialog release];
    return;
  }
  NSString *title = [submitButton titleForState:UIControlStateNormal];
  NSString *message = nil;
  int waitTime = [WaitingTimeData selectedWaitingTimeAtIndex:(int)[waitingTimePickerView selectedRowInComponent:0]];
  if (waitTime < 0) {
    if ([userNameTextField.text length] > 0) message = NSLocalizedString(@"wait.times.overview.confirm.closed.send.comment", nil);
    else message = NSLocalizedString(@"wait.times.overview.confirm.closed.send", nil);
  } else if ((waitingTimeItem == nil && [WaitingTimeItem willWaitTimeBeRefused:waitTime]) || (waitingTimeItem != nil && [waitingTimeItem willWaitTimeBeRefused:waitTime])) {
    message = [NSString stringWithFormat:NSLocalizedString(@"wait.times.overview.confirm.send.wrong", nil), waitTime];
  } else {
    if ([userNameTextField.text length] > 0) message = [NSString stringWithFormat:NSLocalizedString(@"wait.times.overview.confirm.send.comment", nil), waitTime];
    else message = [NSString stringWithFormat:NSLocalizedString(@"wait.times.overview.confirm.send", nil), waitTime];
  }
  UIAlertView *dialog = [[UIAlertView alloc]
                         initWithTitle:title
                         message:message
                         delegate:self
                         cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                         otherButtonTitles:NSLocalizedString(@"submit", nil), nil];
  dialog.tag = 3;
  [dialog show];
  [dialog release];
  lastComment = [userNameTextField.text retain];
  [self cancelWaitingTimeChange:nil];
}

-(IBAction)rulesForComments:(id)sender {
  UIAlertView *dialog = [[UIAlertView alloc]
                         initWithTitle:NSLocalizedString(@"wait.times.overview.rules.title", nil)
                         message:NSLocalizedString(@"wait.times.overview.rules.details", nil)
                         delegate:nil
                         cancelButtonTitle:NSLocalizedString(@"ok", nil)
                         otherButtonTitles:nil];
  [dialog show];
  [dialog release];
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

-(void)viewDidUnload {
  [super viewDidUnload];
  topNavigationBar = nil;
  titleNavigationItem = nil;
  recentWaitTimesLabel = nil;
  recentWaitTimesTable = nil;
  localTimeLabel = nil;
  currentWaitTimeLabel = nil;
  currentWaitTimeBadge = nil;
  closedImageView = nil;
  confirmButton = nil;
  submitButton = nil;
  userNameLabel = nil;
  userNameTextField = nil;
  waitingTimePickerView = nil;
  cancelButton = nil;
  submitWaitTimeButton = nil;
  rulesButton = nil;
  activityIndicatorView = nil;
}

-(void)dealloc {
  [waitingTimeItem release];
  waitingTimeItem = nil;
  [topNavigationBar release];
  [titleNavigationItem release];
  [recentWaitTimesLabel release];
  [recentWaitTimesTable release];
  [closedImageView release];
  [localTimeLabel release];
  [currentWaitTimeLabel release];
  [currentWaitTimeBadge release];
  [confirmButton release];
  [submitButton release];
  [userNameLabel release];
  [userNameTextField release];
  [waitingTimePickerView release];
  [cancelButton release];
  [submitWaitTimeButton release];
  [rulesButton release];
  [activityIndicatorView release];
  [super dealloc];
}

@end
