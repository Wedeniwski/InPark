//
//  CalendarViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 13.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "CalendarViewController.h"
#import "ParkData.h"
#import "MenuData.h"
#import "SettingsData.h"
#import "ImageData.h"
#import "Attraction.h"
#import "CalendarItem.h"
#import "MAEvent.h"
#import "AttractionViewController.h"
#import "Colors.h"

//#define CALENDAR_VIEW_CONTROLLER_DEBUG 1

const unsigned units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;

@implementation CalendarViewController

static NSString *parkId = nil;
static NSString *titleName = nil;
//static NSCalendar *calendar = nil;
static NSDate *currentDate = nil;
static NSDate *today = nil;
static MADayView *dayView = nil;
static NSMutableArray *allCalendarButtons = nil;
static NSMutableArray *allCalendarLabels = nil;
static NSMutableArray *allCalendarImages = nil;

@synthesize delegate;
@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize headerView, calendarView;
@synthesize monthTitle;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId title:(NSString *)tName {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    [parkId release];
    parkId = [pId retain];
    [titleName release];
    titleName = [tName retain];
    [today release];
    today = [[NSDate date] retain];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    //ParkData *parkData = [ParkData getParkData:parkId];
    //[calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:parkData.timeZoneAbbreviation]];
    NSDateComponents *components = [calendar components:units fromDate:today];
    //[components setDay:1];
    [currentDate release];
    currentDate = [[calendar dateFromComponents:components] retain];
    [calendar release];
    [dayView release];
    dayView = nil;
    seeMoreAttractionIds = [[NSMutableSet alloc] initWithCapacity:20];
  }
  return self;
}

-(void)dealloc {
  [topNavigationBar release];
  topNavigationBar = nil;
  [titleNavigationItem release];
  titleNavigationItem = nil;
  [headerView release];
	headerView = nil;
  [calendarView release];
	calendarView = nil;
  [monthTitle release];
	monthTitle = nil;
  [seeMoreBarButtonItem release];
  seeMoreBarButtonItem = nil;
  [seeMoreAttractionIds release];
  seeMoreAttractionIds = nil;
  [super dealloc];
}

-(void)viewDay {
  [self.view addSubview:dayView];
  [self.view bringSubviewToFront:topNavigationBar];
	dayView.frame = CGRectMake(0, headerView.frame.origin.y, dayView.frame.size.width, dayView.frame.size.height);
  titleNavigationItem.title = [CalendarData stringFromDate:dayView.day considerTimeZoneAbbreviation:nil];
}

-(void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [Colors darkBlue];
  topNavigationBar.tintColor = [Colors darkBlue];
	titleNavigationItem.title = titleName;
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  seeMoreBarButtonItem = [titleNavigationItem.rightBarButtonItem retain];
  seeMoreBarButtonItem.title = NSLocalizedString(@"calendar.see.more", nil);
  titleNavigationItem.rightBarButtonItem = nil;
  [seeMoreAttractionIds removeAllObjects];
  [self createCalendar];
  if (dayView != nil) [self viewDay];
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

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  [super dismissModalViewControllerAnimated:animated];
	//[self createCalendar];
}

-(void)createCalendar {
  [allCalendarButtons release];
  allCalendarButtons = [[NSMutableArray alloc] initWithCapacity:32];
  [allCalendarLabels release];
  allCalendarLabels = [[NSMutableArray alloc] initWithCapacity:32];
  [allCalendarImages release];
  allCalendarImages = [[NSMutableArray alloc] initWithCapacity:32];
  // weekdays
  SettingsData *settings = [SettingsData getSettingsData];
  CGRect r = [[UIScreen mainScreen] bounds];
  float height = headerView.frame.size.height/2;
  float width = [settings isPortraitScreen]? r.size.width/7 : r.size.height/7;
  for (int i = 0; i < 7; ++i) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(i*width, height+4, width, height-4)];
    NSString *weekday = [NSString stringWithFormat:@"calendar.weekday.%d", i];
    label.text = NSLocalizedString(weekday, nil);
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:12.0f];
    label.textColor = [Colors hilightText];
    label.shadowColor = [UIColor blackColor];
    label.shadowOffset = CGSizeMake(0, 1);
    [headerView addSubview:label];
    [label release];
  }
  // month
  float heightFactor = 1.0;
  float labelOffset = 0.0;
  float closeOffset = 0.0;
  if ([settings isPortraitScreen]) {
    heightFactor = (r.size.height-2*height-44.0-20.0)/(480.0-2*height-44.0-20.0);
    height = calendarView.frame.size.height/6 * heightFactor;// 44.0;
    labelOffset = 35.0;
    closeOffset = 25.0;
  } else {
    heightFactor = (r.size.width-2*height-44.0-20.0)/(320.0-2*height-44.0-20.0);
    height = (calendarView.frame.size.width-2*height-44.0-20.0)/6 * heightFactor;// 44.0;
    labelOffset = 17.0;
    closeOffset = 18.0;
  }
  calendarView.backgroundColor = [UIColor clearColor];
  headerView.backgroundColor = [UIColor clearColor];
  monthTitle.textColor = [Colors lightText];
  //float h = headerView.frame.origin.y+headerView.frame.size.height+1.0;
  UIImage *unknown = [UIImage imageNamed:@"unknown.png"];
  UIFont *buttonFont = [UIFont boldSystemFontOfSize:18.0f];
  UIFont *labelFont = [UIFont systemFontOfSize:10.0f];
  for (int j = 0; j < 6; ++j) {
    for (int i = 0; i < 7; ++i) {
      //-(UIButton*)createDateButton:(int)day orgx:(float)orgx orgy:(float)orgy width:(float)width height:(float)height
      UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
      [button setTitleColor:[Colors darkBlue] forState:UIControlStateDisabled];
      button.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
      button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
      button.titleLabel.font = buttonFont;
      button.frame = CGRectMake(i*width, j*height, width-1, height-1);
      UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(i*width, (j+1)*height-labelOffset*heightFactor, width, height/2)];
      label.font = labelFont;
      label.textAlignment = UITextAlignmentCenter;
      label.lineBreakMode = UILineBreakModeWordWrap;
      label.numberOfLines = 2;
      label.backgroundColor = [UIColor clearColor];
      label.hidden = YES;
      [calendarView addSubview:button];
      [calendarView addSubview:label];
      UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(i*width+width/2-8.0, (j+1)*height-closeOffset*heightFactor, 16.0, 16.0)];
      image.contentMode = UIViewContentModeScaleAspectFill;
      image.image = unknown;
      image.hidden = YES;
      [calendarView addSubview:image];
      [allCalendarButtons addObject:button];
      [allCalendarLabels addObject:label];
      [allCalendarImages addObject:image];
      [label release];
      [image release];
    }
  }
	[self fillCalendar];
}

-(void)fillCalendar {
  ParkData *parkData = [ParkData getParkData:parkId];
  CalendarData *calendarData = [parkData getCalendarData];
  UIColor *colorExclude = [Colors darkBlue]; //[UIColor colorWithRed:141/255.0 green:148/255.0 blue:157/255.0 alpha:1.0];
  UIColor *backgroundColor = [Colors lightBlue];//[UIColor colorWithRed:235/255.0 green:235/255.0 blue:235/255.0 alpha:1.0];

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"MMMM yyyy"];
  monthTitle.text = [formatter stringFromDate:currentDate];
  [formatter release];
  int minDefinedDay, minDefinedMonth, minDefinedYear;
  int maxDefinedDay, maxDefinedMonth, maxDefinedYear;
  BOOL minMaxDefined = [calendarData getMinMax:&minDefinedDay minDefinedMonth:&minDefinedMonth minDefinedYear:&minDefinedYear maxDefinedDay:&maxDefinedDay maxDefinedMonth:&maxDefinedMonth maxDefinedYear:&maxDefinedYear];
  NSCalendar *localCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *components = [localCalendar components:units fromDate:today];
  int dayOfToday = (int)[components day];
  int monthOfToday = (int)[components month];
  int yearOfToday = (int)[components year];
  components = [localCalendar components:units fromDate:currentDate];
  [components setDay:1];
  components = [localCalendar components:units fromDate:[localCalendar dateFromComponents:components]];
  int weekday = (int)[components weekday];
  int month = (int)[components month];
  int year = (int)[components year];
  [components setDay:3-weekday];
  if (weekday == 1) {
    [components setDay:[components day]-7];
    components = [localCalendar components:units fromDate:[localCalendar dateFromComponents:components]];
  }
	[components setHour:23];
	[components setMinute:50];
	[components setSecond:0];
  UIImage *closed = [UIImage imageNamed:@"closed.png"];
  UIImage *unknown = [UIImage imageNamed:@"unknown.png"];
  for (int i = 0; i < 42; ++i) {
    UIButton *button = [allCalendarButtons objectAtIndex:i];
    UILabel *label = [allCalendarLabels objectAtIndex:i];
    UIImageView *image = [allCalendarImages objectAtIndex:i];
    NSDate *date = [localCalendar dateFromComponents:components];
    components = [localCalendar components:units fromDate:date];
    int d = (int)[components day];
    int m = (int)[components month];
    int y = (int)[components year];
    [button setTitle:[NSString stringWithFormat:@"%d", d] forState:UIControlStateNormal];
    [button removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    //label.enabled = NO;
    button.tag = d + m*32 + y*13*32;
    if ((m < month && y == year) || y < year) {
      [button addTarget:self action:@selector(prevMonth:) forControlEvents:UIControlEventTouchUpInside];
      [button setTitleColor:colorExclude forState:UIControlStateNormal];
      button.backgroundColor = [Colors darkBlue];
      label.textColor = colorExclude;
      button.hidden = YES;
      label.hidden = YES;
      image.hidden = YES;
    } else if ((m > month && y == year) || y > year) {
      [button addTarget:self action:@selector(nextMonth:) forControlEvents:UIControlEventTouchUpInside];
      [button setTitleColor:colorExclude forState:UIControlStateNormal];
      button.backgroundColor = [Colors darkBlue];
      label.textColor = colorExclude;
      button.hidden = YES;
      label.hidden = YES;
      image.hidden = YES;
    } else {
      if (d == dayOfToday && m == monthOfToday && y == yearOfToday) {
        [button setTitleColor:[Colors darkBlue] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor lightGrayColor];
        label.textColor = [Colors hilightText];
      } else {
        [button setTitleColor:[Colors lightText] forState:UIControlStateNormal];
        button.backgroundColor = backgroundColor;
        label.textColor = [Colors lightText];
      }
      button.hidden = NO;
      label.hidden = NO;
      image.hidden = NO;
    }
    NSString *labelText = nil;
    BOOL addExtra = NO;
    NSArray *calendarItems = [[calendarData getCalendarItemsFor:date] retain];
    for (CalendarItem *item in calendarItems) {
      if ([item.attractionIds count] > 0) {
        if ([parkData isEntryOrExitOfPark:[item.attractionIds objectAtIndex:0]]) {
          if (!item.extraHours) {
            NSString *s = [[item getTimeFrame] stringByReplacingOccurrencesOfString:@"-" withString:@"-\n"];
            labelText = (addExtra)? [NSString stringWithFormat:@"%@+", s] : s;
          } else if (labelText != nil) labelText = [labelText stringByAppendingString:@"+"];
          else addExtra = YES;
        }
      }
    }
    [calendarItems release];
    /*
     for (NSString *attractionId in item.attractionIds) {
     if ([parkData isEntryOfPark:attractionId]) {
     if (startTime == nil || [startTime isEqualToString:[item getEndTime]]) startTime = [item getStartTime];
     if (endTime == nil || [endTime isEqualToString:[item getStartTime]]) endTime = [item getEndTime];
     break;
     }
     }
     */
    if (!label.hidden) {
      if (labelText == nil) {
        image.hidden = NO;
        label.hidden = YES;
        button.enabled = NO;
        button.titleLabel.enabled = NO;
        button.titleLabel.textColor = [Colors darkBlue];
        //NSLog(@"%02d.%02d.%04d - %02d.%02d.%04d - %02d.%02d.%04d : %d", minDefinedDay, minDefinedMonth, minDefinedYear, d, m, y, maxDefinedDay, maxDefinedMonth, maxDefinedYear, [CalendarData isBetween:y month:m day:d minDay:minDefinedDay minMonth:minDefinedMonth minYear:minDefinedYear maxDay:maxDefinedDay maxMonth:maxDefinedMonth maxYear:maxDefinedYear]);
        image.image = (minMaxDefined && [CalendarData isBetween:y month:m day:d minDay:minDefinedDay minMonth:minDefinedMonth minYear:minDefinedYear maxDay:maxDefinedDay maxMonth:maxDefinedMonth maxYear:maxDefinedYear])? closed : unknown;
      } else {
        image.hidden = YES;
        //label.hidden = NO;
        label.text = labelText;
        button.enabled = YES;
        button.titleLabel.enabled = YES;
        [button addTarget:self action:@selector(dayView:) forControlEvents:UIControlEventTouchUpInside];
      }
    }
    [components setDay:d+1];
  }
  [localCalendar release];
}

-(void)setCurrentDate:(NSDate *)value {
	[currentDate release];
	currentDate = [value retain];
	[self fillCalendar];
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  if (sender != nil && dayView != nil && dayView.frame.origin.y == headerView.frame.origin.y) {
    [UIView beginAnimations: nil context: nil]; 
    [UIView setAnimationDuration:0.5];
    [dayView setFrame:CGRectMake(0, headerView.frame.origin.y+headerView.frame.size.height+calendarView.frame.size.height, dayView.frame.size.width, dayView.frame.size.height)];
    titleNavigationItem.title = titleName;
    [UIView setAnimationDelegate:self];
    [UIView commitAnimations];
    [dayView removeFromSuperview];
    [dayView release];
    dayView = nil;
    titleNavigationItem.rightBarButtonItem = nil;
    [seeMoreAttractionIds removeAllObjects];
  } else {
    if (sender == nil) {
      [dayView removeFromSuperview];
      [dayView release];
      dayView = nil;
    }
    [delegate dismissModalViewControllerAnimated:(sender != nil)];
  }
}

-(IBAction)dayView:(id)sender {
  UIButton *button = (UIButton *)sender;
  int day = button.tag%32;
  int month = (button.tag/32)%13;
  int year = (int)button.tag/(13*32);
  ParkData *parkData = [ParkData getParkData:parkId];
  NSCalendar *localCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *components = [[NSDateComponents alloc] init];
  //[components setTimeZone:[NSTimeZone timeZoneWithAbbreviation:parkData.timeZoneAbbreviation]];
  [components setDay:day];
  [components setMonth:month];
  [components setYear:year];
	[components setHour:23];
	[components setMinute:50];
	[components setSecond:0];
  NSDate *date = [localCalendar dateFromComponents:components];
  if (dayView != nil) {
    [dayView removeFromSuperview];
    [dayView release];
    dayView = nil;
  }
  // ToDo: add wait time calendar
  CalendarData *calendarData = [parkData getCalendarData];
  NSArray *calendarItems = [[calendarData getCalendarItemsFor:date] retain];
  int minStart = 25;
  int maxEnd = 0;
  [seeMoreAttractionIds removeAllObjects];
  for (CalendarItem *item in calendarItems) {
    if (item.extraHours || item.attractionIds.count == 0) continue;
    NSString *attractionId = [item.attractionIds objectAtIndex:0];
    NSDateComponents *components = [localCalendar components:units fromDate:[calendarData getEarliestStartTimeFor:attractionId forDate:date forItem:item]];
    int h1 = (int)[components hour];
    if (h1 < minStart) minStart = h1;
    components = [localCalendar components:units fromDate:[calendarData getLatestEndTimeFor:attractionId forDate:date forItem:item]];
    int h2 = (int)[components hour];
    if (h2 == 0) h2 = 24;
    if ([components minute] > 0) ++h2;
    if ((h2-h1 > 4 || (h2 < h1 && h2+20 > h1)) && ![parkData isEntryOrExitOfPark:attractionId]) [seeMoreAttractionIds addObject:attractionId];
    if (h2 < h1) maxEnd = 25;
    else if (h2 >= maxEnd) maxEnd = h2;
    //NSLog(@"attractionIds %@, minStart: %d (%@), maxEnd: %d (%@)", item.attractionIds, minStart, [CalendarData stringFromTime:item.startTime considerTimeZoneAbbreviation:nil], maxEnd, [CalendarData stringFromTime:item.endTime considerTimeZoneAbbreviation:nil]);
  }
  [calendarItems release];
  [localCalendar release];
  if (maxEnd < minStart) maxEnd = 25;
  CGRect dayViewFrame = CGRectMake(0, headerView.frame.origin.y+headerView.frame.size.height+calendarView.frame.size.height, calendarView.frame.size.width, headerView.frame.size.height+calendarView.frame.size.height);
  dayView = [[MADayView alloc] initWithFrame:dayViewFrame startHour:minStart endHour:maxEnd+1 day:date];
  dayView.delegate = self;
  dayView.dataSource = self;
  dayView.scrollToNow = [CalendarData isToday:date];
  //[dayView reloadData];
  if (seeMoreAttractionIds.count > 0) titleNavigationItem.rightBarButtonItem = seeMoreBarButtonItem;
  else titleNavigationItem.rightBarButtonItem = nil;
  [self viewDay];
  //[UIView beginAnimations: nil context: nil];
	//[UIView setAnimationDuration:0.5];
	//[UIView setAnimationDidStopSelector:@selector(fillCalendar)];
	//[UIView setAnimationDelegate:self];
	//[UIView commitAnimations];
  [components release];
  //if ([CalendarData isToday:date])
  //[dayView performSelector:@selector(scrollToNow) withObject:nil afterDelay:0.5];
}

-(IBAction)seeMoreEventsView:(id)sender {
  if (dayView != nil) {
    titleNavigationItem.rightBarButtonItem = nil;
    [seeMoreAttractionIds removeAllObjects];
    [dayView reloadData];
  }
}

-(IBAction)prevMonth:(id)sender {
  NSCalendar *localCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *components = [localCalendar components:units fromDate:currentDate];
  components.day = 1;
  --components.month;
  [self setCurrentDate:[localCalendar dateFromComponents:components]];
  [localCalendar release];
}

-(IBAction)nextMonth:(id)sender {
  NSCalendar *localCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [localCalendar components:units fromDate:currentDate];
  components.day = 1;
	++components.month;
	[self setCurrentDate:[localCalendar dateFromComponents:components]];
  [localCalendar release];
}

#pragma mark -
#pragma mark Day view delegate

-(NSArray *)dayView:(MADayView *)dayView eventsForDate:(NSDate *)date {
  ParkData *parkData = [ParkData getParkData:parkId];
  NSString *entryId = [parkData getAttractionDataId:[parkData getEntryOfPark:nil]];
  //NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  //[formatter setDateFormat:@"HH:mm"];
  NSMutableArray *events = [[[NSMutableArray alloc] initWithCapacity:10] autorelease];
  CalendarData *calendarData = [parkData getCalendarData];
  NSCalendar *localCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSArray *calendarItems = [[calendarData getCalendarItemsFor:date] retain];
  NSMutableDictionary *imageCache = [[NSMutableDictionary alloc] initWithCapacity:50];
  for (int i = 0; i < 2; ++i) {
    for (CalendarItem *item in calendarItems) {
      if ([item.attractionIds count] > 0 && !item.extraHours) {
        NSString *attractionId = [item.attractionIds objectAtIndex:0];
        if ([seeMoreAttractionIds containsObject:attractionId]) continue;
        NSUInteger idx = [item.attractionIds indexOfObject:entryId];
        BOOL isParkEntry = (idx != NSNotFound);
        if (isParkEntry) attractionId = [item.attractionIds objectAtIndex:idx];
        if ((i == 0 && !isParkEntry) || (i == 1 && isParkEntry)) continue;
        MAEvent *event = [[MAEvent alloc] init];
        event.eventId = attractionId;
        Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
        NSString *imagePath = [attraction imagePath:parkId];
        UIImage *image = [imageCache objectForKey:imagePath];
        if (image == nil) {
          CGSize size = ([ImageData isRetinaDisplay])? CGSizeMake(112.0f, 112.0f) : CGSizeMake(56.0f, 56.0f);
          image = [ImageData rescaleImage:[UIImage imageWithContentsOfFile:imagePath] toSize:size];
          [imageCache setObject:image forKey:imagePath];
        }
        event.image = image;
        NSDateComponents *components = [localCalendar components:units fromDate:date];
        NSDateComponents *components2 = [localCalendar components:units fromDate:item.startTime];
        [components setHour:[components2 hour]];
        [components setMinute:[components2 minute]];
        event.start = [localCalendar dateFromComponents:components];
        NSDate *d = [calendarData getEarliestStartTimeFor:attractionId forDate:date forItem:item];
        if (![item.startTime isEqualToDate:d]) {
          components2 = [localCalendar components:units fromDate:d];
          [components setHour:[components2 hour]];
          [components setMinute:[components2 minute]];
          event.startExtra = [localCalendar dateFromComponents:components];
        }
        components2 = [localCalendar components:units fromDate:item.endTime];
        [components setHour:[components2 hour]];
        [components setMinute:[components2 minute]];
        event.end = [localCalendar dateFromComponents:components];
        d = [calendarData getLatestEndTimeFor:attractionId forDate:date forItem:item];
        if (![item.endTime isEqualToDate:d]) {
          components2 = [localCalendar components:units fromDate:d];
          [components setHour:[components2 hour]];
          [components setMinute:[components2 minute]];
          event.endExtra = [localCalendar dateFromComponents:components];
        }
        //NSLog(@"%@: start %@ (%@) end %@ (%@)", attractionId, [formatter stringFromDate:event.start], [formatter stringFromDate:item.startTime], [formatter stringFromDate:event.end], [formatter stringFromDate:item.endTime]);
        event.textColor = [Colors lightText];
        event.textFont = [UIFont systemFontOfSize:6];
        event.backgroundColor = [Colors lightBlue];
        NSString *s = attraction.stringAttractionName;
        if ([event durationInMinutes] >= 45) event.title = [NSString stringWithFormat:@"%@\n\n%@", [attraction startingAndEndTimes:parkId forDate:event.start maxTimes:1], [MenuData stringByHyphenating:s]];
        if ([s length] <= 20 && [event durationInMinutes] >= 30) event.title = [NSString stringWithFormat:@"%@\n\n%@", [attraction startingAndEndTimes:parkId forDate:event.start maxTimes:1], [MenuData stringByHyphenating:s]];
        else event.title = s;
        //NSLog(@"attractionId: %@ - %@", attractionId, event.title);
        [events addObject:event];
        [event release];
      }
    }
  }
  [calendarItems release];
  /*if ([CalendarData isToday:date]) {
    WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
    if ([waitingTimeData hasStartTimes]) {
      NSArray *allAttractionIds = [waitingTimeData getAttractionIdsWithWaitingTime];
      for (NSString *attractionId in allAttractionIds) {
        Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
        if (attraction == nil) continue;
        WaitingTimeItem *waitingTimeItem = [waitingTimeData getWaitingTimeFor:attractionId];
        if ([waitingTimeItem hasStartTimes]) {
          for (NSString *startTime in waitingTimeItem.startTimes) {
            NSDate *start = [formatter dateFromString:startTime];
            NSDate *end = [start dateByAddingTimeInterval:attraction.duration*60];
            MAEvent *event = [[MAEvent alloc] init];
            event.eventId = attractionId;
            NSString *imagePath = [attraction imagePath:parkId];
            UIImage *image = [imageCache objectForKey:imagePath];
            if (image == nil) {
              CGSize size = ([ImageData isRetinaDisplay])? CGSizeMake(112.0f, 112.0f) : CGSizeMake(56.0f, 56.0f);
              image = [ImageData rescaleImage:[UIImage imageWithContentsOfFile:imagePath] toSize:size];
              [imageCache setObject:image forKey:imagePath];
            }
            event.image = image;
            event.title = attraction.stringAttractionName;
            NSDateComponents *components = [localCalendar components:units fromDate:date];
            NSDateComponents *components2 = [localCalendar components:units fromDate:start];
            [components setHour:[components2 hour]];
            [components setMinute:[components2 minute]];
            event.start = [localCalendar dateFromComponents:components];
            components2 = [localCalendar components:units fromDate:end];
            [components setHour:[components2 hour]];
            [components setMinute:[components2 minute]];
            event.end = [localCalendar dateFromComponents:components];
            event.textColor = [Colors lightText];
            event.textFont = [UIFont systemFontOfSize:6];
            event.backgroundColor = [Colors lightBlue];
            [events addObject:event];
            [event release];
          }
        }
      }
    }
  }*/
  [imageCache release];
  [localCalendar release];
  //[formatter release];
  return events;
}

-(void)dayView:(MADayView *)dayView eventTapped:(MAEvent *)event {
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:event.eventId];
  AttractionViewController *controller = [[AttractionViewController alloc] initWithNibName:@"AttractionView" owner:self attraction:attraction parkId:parkId];
  [controller setSelectedDate:event.displayDate];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
 [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

@end
