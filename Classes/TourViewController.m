//
//  TourViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.08.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "TourViewController.h"
#import "AttractionViewController.h"
#import "AttractionRouteViewController.h"
#import "ParkMainMenuViewController.h"
#import "RatingViewController.h"
#import "AttractionListViewController.h"
#import "GeneralInfoViewController.h"
#import "ImagesSelectionViewController.h"
#import "Attraction.h"
#import "TourItem.h"
#import "TourViewTableCell.h"
#import "RouteViewTableCell.h"
#import "RouteViewDoneTableCell.h"
#import "MapPin.h"
#import "AttractionAnnotation.h"
#import "RouteAnnotation.h"
#import "RouteView.h"
#import "MenuData.h"
#import "ParkData.h"
#import "ExtendedTrackPoint.h"
#import "Categories.h"
#import "SettingsData.h"
#import "ProfileData.h"
#import "HelpData.h"
#import "LocationData.h"
#import "CalendarData.h"
#import "CalendarItem.h"
#import "Conversions.h"
#import "Comment.h"
#import "IPadHelper.h"
#import "Colors.h"
#import "JSON.h"
#import "ASIFormDataRequest.h"

#ifdef FAKE_CORE_LOCATION
#import "FTLocationSimulator.h"
#endif

@implementation TourViewController

static BOOL viewInitialized = NO;
static NSString *parkId = nil;
static NSDate *now = nil;
static TourItem *selectedTourItem = nil;
static NSArray *detailedTourDescription = nil;
static int detailedTourDescriptionAtIndex = -1;
static NSString *detailedTourDescriptionFromAttractionId = nil;
static MapPin *firstPin = nil;
static MapPin *lastPin = nil;

@synthesize delegate;
@synthesize topNavigationBar;
@synthesize navigationTitle;
@synthesize tourTableView;
@synthesize startActivityIndicator;
@synthesize totalTourLabel;
@synthesize helpButton, locationButton;
@synthesize bottomToolbar, editBottomToolbar, doneBottomToolbar, timePickerBottomToolbar;
@synthesize tourStartButton, tourMapButton, tourCompletedButton, tourButton, addButton, tourItemsButton, editButton, timePickerClearButton, timePickerDoneButton;
@synthesize cellOwner;
@synthesize backgroundTimePicker;
@synthesize timePicker;
@synthesize mapView;
@synthesize copyrightLabel, accuracyLabel;

typedef enum {
  TourViewControllerActionSheetTourTrack,
  TourViewControllerActionSheetDeleteTrack,
  TourViewControllerActionSheetSendTrack,
  TourViewControllerActionSheetPublishTrackOnFacebook,
  TourViewControllerActionSheetTourAction,
  TourViewControllerActionSheetAddAction,
  TourViewControllerActionSheetTourItemsAction,
  TourViewControllerActionSheetEditAction,
  TourViewControllerActionSheetRecommendations,
  TourViewControllerActionSheetOpenTour,
  TourViewControllerActionSheetDeleteTour,
  TourViewControllerActionSheetDeleteTourItems,
  TourViewControllerNewTour,
  TourViewControllerRenameTour,
  TourViewControllerRenameNewTour,
  TourViewControllerTrackName,
  TourViewControllerOptimizeTour,
  TourViewControllerCompleteTour,
  TourViewControllerCompleteTourItem,
  TourViewControllerStartTourTrainItem,
  TourViewControllerCompleteTourTrainItem
} TourViewControllerActionSheet;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    [parkId release];
    parkId = [pId retain];
    [now release];
    now = [[NSDate date] retain];
    //[selectedTourItem release];
    selectedTourItem = nil;
    [detailedTourDescription release];
    detailedTourDescription = nil;
    [detailedTourDescriptionFromAttractionId release];
    detailedTourDescriptionFromAttractionId = nil;
    detailedTourDescriptionAtIndex = -1;
    [firstPin release];
    firstPin = nil;
    [lastPin release];
    lastPin = nil;
  }
  return self;
}

-(NSArray *)attractionIdsWhichFits:(NSArray *)attractionIds {
  ParkData *parkData = [ParkData getParkData:parkId];
  ProfileData *profile = [ProfileData getProfileData];
  NSMutableArray *aFitIds = [[[NSMutableArray alloc] initWithCapacity:[attractionIds count]] autorelease];
  for (NSString *attractionId in attractionIds) {
    Attraction *a = [Attraction getAttraction:parkId attractionId:attractionId];
    if (a != nil && [profile percentageOfPreferenceFit:a parkId:parkId personalAttractionRating:[parkData getPersonalRating:attractionId] adultAge:parkData.adultAge] > 0.0) {
      //if ([a isTrain]) { // Züge werden vorerst nur mit gleichem Ausgang hinzugefügt
      TourItem *t = [[TourItem alloc] initWithAttractionId:attractionId entry:[parkData firstEntryAttractionIdOf:attractionId] exit:[parkData getRootAttractionId:[parkData exitAttractionIdOf:attractionId]]];
      [aFitIds addObject:t];
      [t release];
    } else {
      NSLog(@"Attraction %@ from recommendation NOT added because it does not fit to profile", attractionId);
    }
  }
  return aFitIds;
}

-(void)addAttractionIds:(NSArray *)attractionIds {
  NSArray *aFitIds = [self attractionIdsWhichFits:attractionIds];
  int l = (int)[aFitIds count];
  if (l < [attractionIds count]) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"info", nil)
                           message:NSLocalizedString(@"tour.suggestion.add.all.not.fit.profile", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  }
  if (l > 0) {
    --l;
    ParkData *parkData = [ParkData getParkData:parkId];
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    for (int i = 0; i < l; ++i) {
      [tourData add:[aFitIds objectAtIndex:i] startTime:0.0];
    }
    [tourData add:[aFitIds objectAtIndex:l] startTime:[[NSDate date] timeIntervalSince1970]]; // check if date is needed because of optimize
  }
  //[self updateViewValues:[tourData optimize]];
}

-(void)orderAnnotationsViews {
  for (id annotation in mapView.annotations) {
    if ([annotation isKindOfClass:[RouteAnnotation class]]) {
      RouteView *routeView = (RouteView *)[mapView viewForAnnotation:annotation];
      [[routeView superview] sendSubviewToBack:routeView];
    } else if ([annotation isKindOfClass:[MapPin class]]) {
      AttractionAnnotation *attractionAnnotation = (AttractionAnnotation *)[mapView viewForAnnotation:annotation];
      [[attractionAnnotation superview] bringSubviewToFront:attractionAnnotation];
    }
  }
  if (mapView.showsUserLocation && mapView.userLocation != nil) {
    UIView *user = [mapView viewForAnnotation:mapView.userLocation];
    if (user != nil) [mapView.superview bringSubviewToFront:user];
  }
}

-(void)addRouteViewPath:(NSArray *)path {
  ParkData *parkData = [ParkData getParkData:parkId];
  //TrackPoint *lastTrackPoint = nil;
  NSString *aId = nil;
  NSUInteger aIdx = 0;
  NSUInteger bIdx = 0;
  for (NSString *bId in path) {
    bIdx = [parkData.allAttractionIds indexOfObject:bId];
    if (bIdx == NSNotFound) {
      NSLog(@"Internal error: attractions %@ unknown", bId);
      bIdx = -1;
    }
    if (aId != nil) {
      TrackSegment *t = [parkData.trackSegments objectForKey:[TrackSegment getTrackSegmentId:aIdx toAttractionIdx:bIdx]];
      if (t == nil) NSLog(@"Error! Missing track segment between %@ and %@", aId, bId);
      else {
        RouteAnnotation *routeAnnotation = [[RouteAnnotation alloc] initWithTrackSegment:t];
        [mapView addAnnotation:routeAnnotation];
        [routeAnnotation release];
        //lastTrackPoint = [t trackPointOf:bId];
      }
    }
    aId = bId;
    aIdx = bIdx;
  }
}

-(void)updateMapView {
  if (!mapView.hidden) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [mapView removeAnnotations:mapView.annotations];
    ParkData *parkData = [ParkData getParkData:parkId];
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    if ([tourData.tourItems count] > 0 && parkData.currentTrackData != nil) {
      int m = [parkData.currentTrackData numberOfTourItemsDone];
      int n = (detailedTourDescription != nil)? detailedTourDescriptionAtIndex/2+1 : m;
      if (n == 0 || ![parkData.currentTrackData walkToEntry]) {
        TourItem *t = [tourData.tourItems objectAtIndex:n];
        [firstPin release];
        [lastPin release];
        lastPin = nil;
        firstPin = [[MapPin alloc] initWithAttractionId:(n > 0)? t.exitAttractionId : t.attractionId parkId:parkId];
        [mapView addAnnotation:firstPin];
        if (![AttractionRouteViewController setCenterCoordinate:firstPin.coordinate onMapView:mapView zoomLevel:17 animated:NO]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
      } else if (n < [tourData.tourItems count]) {
        [firstPin release];
        firstPin = nil;
        [lastPin release];
        lastPin = nil;
        TourItem *t = [tourData.tourItems objectAtIndex:n-1];
        TourItem *t2 = [tourData.tourItems objectAtIndex:n];
        NSString *fromAttractionId = (n == m && detailedTourDescriptionFromAttractionId != nil)? detailedTourDescriptionFromAttractionId : t.exitAttractionId;
        NSArray *path = [parkData getMinPathFrom:fromAttractionId fromAll:YES toAllAttractionId:t2.entryAttractionId];
        if (path != nil) {
          n = (int)[path count];
          if (n > 0) {
            [self addRouteViewPath:path];
            for (NSString *aId in path) {
              MapPin *pin = [[MapPin alloc] initWithAttractionId:aId parkId:parkId];
              if ([pin hasImage]) {
                [mapView addAnnotation:pin];
                if (firstPin == nil) firstPin = [pin retain];
                [lastPin release];
                lastPin = [pin retain];
              }
              [pin release];
            }
            if (![AttractionRouteViewController setCenterCoordinate:firstPin.coordinate onMapView:mapView zoomLevel:17 animated:NO]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
            [mapView selectAnnotation:firstPin animated:YES];
          }
        }
      }
    }
    [self orderAnnotationsViews];
    [pool release];
  }
}

-(void)updateViewValues {  // wird intern für das Verschieben von Tour-Einträge benötigt
  [self updateViewValues:0.0 enableScroll:NO];
}

-(void)updateViewValues:(double)nowOptimized enableScroll:(BOOL)enableScroll {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  ParkData *parkData = [ParkData getParkData:parkId];
  BOOL enableStart = YES;
  if ([LocationData isLocationDataActive]) {
    LocationData *locData = [LocationData getLocationData];
    if ([locData isDataPoolRegistered:parkId]) {
      tourStartButton.title = NSLocalizedString(@"stop", nil);
      tourStartButton.style = UIBarButtonItemStyleDone;
      [startActivityIndicator stopAnimating];
      enableStart = NO;
      mapView.showsUserLocation = YES;
      [LocationData setAccuracyLabel:accuracyLabel forParkData:parkData addTime:NO];
      CGRect rect = accuracyLabel.frame;
      accuracyLabel.frame = CGRectMake(rect.origin.x, topNavigationBar.frame.origin.y+topNavigationBar.frame.size.height-10, rect.size.width, rect.size.height);
      locationButton.hidden = mapView.hidden;
    }
  } else if (![LocationData isLocationDataStarted]) {
    mapView.showsUserLocation = NO;
    accuracyLabel.hidden = YES;
    locationButton.hidden = YES;
  }
  if (enableStart) {
    tourStartButton.title = NSLocalizedString(@"start", nil);
    tourStartButton.style = UIBarButtonItemStyleBordered;
    [startActivityIndicator stopAnimating];
  }
  tourCompletedButton.style = (parkData.currentTrackData != nil)? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  SettingsData *settings = [SettingsData getSettingsData];
  [now release];
  now = (nowOptimized > 0.0)? [[NSDate alloc] initWithTimeIntervalSince1970:nowOptimized] : [[NSDate alloc] init];
  [tourData updateTourData:(nowOptimized > 0.0)? nowOptimized : [now timeIntervalSince1970]];
  NSString *tourDistance = distanceToString([settings isMetricMeasure], [tourData getRemainingTourDistance]);
  NSString *tourDuration;
  int d = [tourData getRemainingTourTime];
  if (d >= 60) {
    if (d%60 == 0) {
      tourDuration = [NSString stringWithFormat:NSLocalizedString(@"tour.duration.value1", nil), d/60];
    } else {
      tourDuration = [NSString stringWithFormat:NSLocalizedString(@"tour.duration.value2", nil), d/60, d%60];
    }
  } else {
    tourDuration = [NSString stringWithFormat:NSLocalizedString(@"tour.duration.value3", nil), d];
  }
  totalTourLabel.text = [NSString stringWithFormat:@"%@: %@\n%@ / %@", NSLocalizedString((editButton.style == UIBarButtonItemStyleDone)? @"tour.title.edit" : @"tour.title", nil), parkData.currentTourName, tourDuration, tourDistance];
  [tourTableView reloadData];
  //-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
  if (enableScroll && !canMoveRow && detailedTourDescription == nil && editButton.style == UIBarButtonItemStyleBordered && [tourData count] > 0) {
    int pos = [tourData scrollToIndex];
    if (pos > 0 && [parkData.currentTrackData walkToEntry]) {
      [tourTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2*pos-1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else {
      [tourTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2*pos inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
  }
  [pool release];
}

-(void)updateTourData {
  [ParkData load];    // ToDo: Performance?!
  if ([LocationData isLocationDataActive]) {
    LocationData *locData = [LocationData getLocationData];
    [locData registerViewController:self];
  }
  [self updateViewValues:0.0 enableScroll:NO];
}

static int rowTourViewControllerStartTourTrainItem;
static BOOL closedTourViewControllerStartTourTrainItem;
static BOOL toTourItemTourViewControllerStartTourTrainItem;
-(void)switchAttractionDone:(int)row closed:(BOOL)closed toTourItem:(BOOL)toTourItem {
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  if (canMoveRow) {
    selectedTourItem = [tourData objectAtIndex:row];
    backgroundTimePicker.hidden = NO;
    timePicker.hidden = NO;
    doneBottomToolbar.hidden = YES;
    timePickerBottomToolbar.hidden = NO;
    navigationTitle.leftBarButtonItem.enabled = NO;
    tourButton.enabled = NO;
    addButton.enabled = NO;
    tourItemsButton.enabled = NO;
    editButton.enabled = NO;
    CGRect rTable = tourTableView.frame;
    tourTableView.frame = CGRectMake(rTable.origin.x, rTable.origin.y, rTable.size.width, timePicker.frame.origin.y-rTable.origin.y);
    [tourTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    NSDate *d = [[NSDate alloc] initWithTimeInterval:selectedTourItem.calculatedTimeInterval sinceDate:now];
    unsigned units = NSHourCalendarUnit | NSMinuteCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:units fromDate:d];
    timePicker.date = [calendar dateFromComponents:components];
    CalendarData *calendarData = [parkData getCalendarData];
    NSArray *calendarItems = [calendarData getCalendarItemsFor:selectedTourItem.attractionId forDate:d];
    if (calendarItems == nil || [calendarItems count] == 0) calendarItems = [calendarData getCalendarItemsFor:[parkData getEntryOfPark:nil] forDate:d];
    [d release];
    if (calendarItems != nil && [calendarItems count] > 0) {
      CalendarItem *calendarItem1 = [calendarItems objectAtIndex:0];
      CalendarItem *calendarItem2 = [calendarItems lastObject];
      components = [calendar components:units fromDate:calendarItem1.startTime];
      int h = (int)[components hour];
      int m = (int)[components minute];
      components = [calendar components:units fromDate:timePicker.date];
      timePicker.date = [calendar dateFromComponents:components];
      [components setHour:h];
      [components setMinute:m];
      timePicker.minimumDate = [calendar dateFromComponents:components];
      components = [calendar components:units fromDate:calendarItem2.endTime];
      h = (int)[components hour];
      m = (int)[components minute];
      components = [calendar components:units fromDate:timePicker.date];
      [components setHour:h];
      [components setMinute:m];
      timePicker.maximumDate = [calendar dateFromComponents:components];
      if ([timePicker.date earlierDate:timePicker.minimumDate]) timePicker.date = timePicker.minimumDate;
      else if ([timePicker.date laterDate:timePicker.maximumDate]) timePicker.date = timePicker.maximumDate;
    }
    [calendar release];
  } else {
    if (detailedTourDescription != nil) {
      [detailedTourDescription release];
      detailedTourDescription = nil;
      [detailedTourDescriptionFromAttractionId release];
      detailedTourDescriptionFromAttractionId = nil;
      detailedTourDescriptionAtIndex = -1;
    }
    [now release];
    now = [[NSDate alloc] init];
    TourItem *tourItem = [tourData.tourItems objectAtIndex:row];
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
    BOOL completed = (parkData.currentTrackData != nil && ([parkData.currentTrackData walkToEntry] ^ [attraction isRealAttraction]));
    if (parkData.currentTrackData != nil && row == [parkData.currentTrackData numberOfTourItemsDone] && ![parkData.currentTrackData walkToEntry]) {
      if ([attraction isTrain]) {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"tour.item.train.completed", nil)
                               message:nil //NSLocalizedString(@"tour.item.train.selected", nil)
                               delegate:self
                               cancelButtonTitle:NSLocalizedString(@"tour.item.closed", nil)
                               otherButtonTitles:nil];
        attraction = [Attraction getAttraction:parkId attractionId:tourItem.exitAttractionId];
        [dialog addButtonWithTitle:attraction.stringAttractionName];
        BOOL oneWay;
        NSArray *trainRouteForSelection = [parkData getTrainAttractionRoute:attraction.attractionId oneWay:&oneWay];
        for (Attraction *station in trainRouteForSelection) {
          if (![station.attractionId isEqualToString:attraction.attractionId]) [dialog addButtonWithTitle:station.stringAttractionName];
        }
        [dialog addButtonWithTitle:NSLocalizedString(@"tour.item.train.no.ride", nil)];
        dialog.tag = TourViewControllerCompleteTourTrainItem;
        [dialog show];
        [dialog release];
        return;
      }
      if ([attraction isRealAttraction]) {
        double time = [now timeIntervalSince1970] - [parkData.currentTrackData timeOfLastTrackFromAttraction];
        UIAlertView *dialog = nil;
        if (attraction.waiting) {
          dialog = [[UIAlertView alloc]
                    initWithTitle:attraction.stringAttractionName
                    message:NSLocalizedString(@"tour.item.completed", nil)
                    delegate:self
                    cancelButtonTitle:((time < 60.0*attraction.duration)? NSLocalizedString(@"tour.item.closed", nil) : nil)
                    otherButtonTitles:NSLocalizedString(@"yes", nil), NSLocalizedString(@"tour.item.complete.submit.wait.time", nil), NSLocalizedString(@"no", nil), NSLocalizedString(@"cancel", nil), nil];
        } else {
          dialog = [[UIAlertView alloc]
                    initWithTitle:attraction.stringAttractionName
                    message:NSLocalizedString(@"tour.item.completed", nil)
                    delegate:self
                    cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                    otherButtonTitles:NSLocalizedString(@"yes", nil), NSLocalizedString(@"no", nil), nil];
        }
        dialog.tag = TourViewControllerCompleteTourItem;
        [dialog show];
        [dialog release];
        return;
      }
    }
    if ([attraction isTrain]) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"tour.item.train.current.station", nil)
                             message:nil
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                             otherButtonTitles:nil];
      attraction = [Attraction getAttraction:parkId attractionId:tourItem.entryAttractionId];
      [dialog addButtonWithTitle:attraction.stringAttractionName];
      BOOL oneWay;
      NSArray *trainRouteForSelection = [parkData getTrainAttractionRoute:attraction.attractionId oneWay:&oneWay];
      for (Attraction *station in trainRouteForSelection) {
        if (![station.attractionId isEqualToString:attraction.attractionId]) [dialog addButtonWithTitle:station.stringAttractionName];
      }
      rowTourViewControllerStartTourTrainItem = row;
      closedTourViewControllerStartTourTrainItem = closed;
      toTourItemTourViewControllerStartTourTrainItem = toTourItem;
      dialog.tag = TourViewControllerStartTourTrainItem;
      [dialog show];
      [dialog release];
      return;
    }
    [tourData switchDoneAtIndex:row startTime:[now timeIntervalSince1970] completed:completed closed:closed submitWaitTime:NO toTourItem:toTourItem];
#ifdef DEBUG_MAP
    TrackSegment *track = [parkData.currentTrackData.trackSegments lastObject];
    TrackPoint *trackPoint = [track toTrackPoint];
    TrackPoint *locationPoint = [parkData getAttractionLocation:attraction.attractionId];
    if (locationPoint != nil) {
      NSArray *comments = [parkData getComments:attraction.attractionId];
      NSString *comment = distanceToString(YES, [trackPoint distanceTo:locationPoint]);
      if (comments != nil && [comments count] > 0) {
        Comment *lastComment = [comments objectAtIndex:0];
        comment = [NSString stringWithFormat:@"%@, %@", lastComment.comment, comment];
      }
      [parkData addComment:comment attractionId:attraction.attractionId];
      [parkData save:NO];
    }
#endif
    if ([tourData isAllDone]) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"tour.completed.title", nil)
                             message:NSLocalizedString(@"tour.completed.text", nil)
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:NSLocalizedString(@"tour.close", nil), NSLocalizedString(@"tour.close.and.send", nil), nil];
      dialog.tag = TourViewControllerCompleteTour;
      [dialog show];
      [dialog release];
    } else if ([tourData isExitOfParkDone]) {
      // falls kein eingang mehr im tour und ausgang erledigt, dann alle noch offenen Einträge zum löschen anbieten und tour abschließen
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"tour.complete.title", nil)
                             message:NSLocalizedString(@"tour.complete.text", nil)
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"no", nil)
                             otherButtonTitles:NSLocalizedString(@"tour.close", nil), NSLocalizedString(@"tour.close.and.send", nil), nil];
      dialog.tag = TourViewControllerCompleteTour;
      [dialog show];
      [dialog release];
    } else {
      [self askIfTourOptimizing];
    }
    [self updateViewValues:0.0 enableScroll:YES];
    [self updateMapView];
  }
}

/*-(void)updateTourNamesSegment {
  while (tourNamesSegmentControl.numberOfSegments > 0) {
    [tourNamesSegmentControl removeSegmentAtIndex:tourNamesSegmentControl.numberOfSegments-1 animated:YES];
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  NSArray *tourNames = [parkData getTours];
  NSUInteger j = [tourNames indexOfObject:parkData.currentTourName];
  if (j == NSNotFound) {
    j = 0;
    parkData.currentTourName = [tourNames objectAtIndex:0];
  }
  int l = [tourNames count];
  int i = 0;
  int k = 3*(j/3);
  while (i < 3 && k < l) {
    [tourNamesSegmentControl insertSegmentWithTitle:[tourNames objectAtIndex:k] atIndex:i animated:YES];
    ++i; ++k;
  }
  if (i == 3) [tourNamesSegmentControl insertSegmentWithTitle:@"..." atIndex:i animated:YES];
  tourNamesSegmentControl.selectedSegmentIndex = j%3;
}*/

-(void)askIfTourOptimizing {
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  if ((parkData.currentTrackData == nil || [parkData.currentTrackData walkToEntry]) && [tourData lastOptimized] == 0.0) {
    [tourData dontAskNextTimeForTourOptimization];
    ProfileData *profileData = [ProfileData getProfileData];
    if ([profileData askForOptimization]) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"tour.optimize.title", nil)
                             message:NSLocalizedString(@"tour.optimize.text", nil)
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"yes", nil)
                             otherButtonTitles:NSLocalizedString(@"no", nil), nil];
      dialog.tag = TourViewControllerOptimizeTour;
      [dialog show];
      [dialog release];
    } else if ([profileData automaticOptimization]) {
      [self updateViewValues:[tourData optimize] enableScroll:NO];
    }
  }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
-(void)viewDidLoad {
  viewInitialized = YES;
  canMoveRow = NO;
  viewAlsoDone = YES;
  //if ([IPadHelper isIPad]) totalTourLabel.textColor = [UIColor blackColor];
  self.view.backgroundColor = [Colors darkBlue];
  tourTableView.backgroundColor = [Colors lightBlue];
  tourTableView.backgroundView = nil;
  topNavigationBar.tintColor = [Colors darkBlue];
  bottomToolbar.tintColor = [Colors darkBlue];
  editBottomToolbar.tintColor = [Colors darkBlue];
  doneBottomToolbar.tintColor = [Colors darkBlue];
  timePickerBottomToolbar.tintColor = [Colors darkBlue];
  navigationTitle.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  tourMapButton.title = NSLocalizedString(@"tour.button.map", nil);
  tourCompletedButton.title = NSLocalizedString(@"tour.button.completed", nil);
  tourButton.title = NSLocalizedString(@"tour.button.tour", nil);
  tourItemsButton.title = NSLocalizedString(@"tour.button.items", nil);
  timePickerClearButton.title = NSLocalizedString(@"clear", nil);
  timePickerDoneButton.title = NSLocalizedString(@"set", nil);
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  if ([tourData count] > 0) {
    editButton.style = UIBarButtonItemStyleBordered;
    editBottomToolbar.hidden = YES;
    bottomToolbar.hidden = NO;
  } else {
    editButton.style = UIBarButtonItemStyleDone;
    editBottomToolbar.hidden = NO;
    bottomToolbar.hidden = YES;
  }
  doneBottomToolbar.hidden = YES;
  timePickerBottomToolbar.hidden = YES;
  HelpData *helpData = [HelpData getHelpData];
  helpButton.hidden = ([helpData.pages objectForKey:@"MENU_TOUR"] == nil);
  locationButton.hidden = YES;

  if ([LocationData isLocationDataActive]) {
    LocationData *locData = [LocationData getLocationData];
    [locData registerViewController:self];
  }
  
  MKCoordinateRegion region = [parkData getParkRegion];
  manuallyChangingMapRect = YES;
  [mapView setRegion:region animated:NO];
  //[mapView regionThatFits:region];
  lastGoodMapRect = mapView.visibleMapRect;
  manuallyChangingMapRect = NO;
  refreshRoute = YES;
  overlay = nil;
  originalDistanceLabelColor = nil;

  SettingsData *settings = [SettingsData getSettingsData];
  if ([settings isMapTypeSatellite]) {
    mapView.mapType = MKMapTypeSatellite;
    copyrightLabel.text = @"";
  } else if ([settings isMapTypeStandard]) {
    mapView.mapType = MKMapTypeStandard;
    copyrightLabel.text = @"";
  } else if ([settings isMapTypeHybrid]) {
    mapView.mapType = MKMapTypeHybrid;
    copyrightLabel.text = @"";
  } else { //if ([settings isMapTypeOverlay]) {
    mapView.mapType = MKMapTypeSatellite;
    lastGoodMapRect = mapView.visibleMapRect;
    overlay = [[ParkOverlayView alloc] initWithRegion:lastGoodMapRect parkId:parkId];
    [mapView addOverlay:overlay];
    copyrightLabel.text = (parkData.mapCopyright != nil)? parkData.mapCopyright : NSLocalizedString(@"copyright", nil);
  }
  //[mapView setRegion:region animated:NO];
  TrackPoint *entryLocation = [parkData getAttractionLocation:[parkData getEntryOfPark:nil]];
  if (entryLocation != nil) {
    CLLocationCoordinate2D c = {entryLocation.latitude, entryLocation.longitude};
    if (![AttractionRouteViewController setCenterCoordinate:c onMapView:mapView zoomLevel:17 animated:NO]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
  } else {
    if (![AttractionRouteViewController setCenterCoordinate:region.center onMapView:mapView zoomLevel:17 animated:NO]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
  }

  tourTableView.rowHeight = 48.0f;
  [self updateViewValues:0.0 enableScroll:YES];
  [super viewDidLoad];

  [cellOwner loadNibNamed:@"RouteViewHighLightTableCell" owner:self];
  highLightTableCell = (RouteViewHighLightTableCell *)[cellOwner.cell retain];
  //highLightTableCell.accessoryType = UITableViewCellAccessoryNone;
  highLightTableCell.selectionStyle = UITableViewCellSelectionStyleNone;
  [parkData getWaitingTimeData:self];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(waitingTimeDataUpdated)
                                               name:UIApplicationWillEnterForegroundNotification
                                             object:nil];
  [self askIfTourOptimizing];
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
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  int n = (editButton.style == UIBarButtonItemStyleDone)? [tourData count] : 2*[tourData count]-1;
  if (detailedTourDescription != nil) n += [detailedTourDescription count]-1;
  return n;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editButton.style != UIBarButtonItemStyleDone) {
    int row = (int)indexPath.row;
    if (detailedTourDescription != nil) {
      if (row >= detailedTourDescriptionAtIndex && row < detailedTourDescriptionAtIndex+[detailedTourDescription count]) {
        NSString *t = [detailedTourDescription objectAtIndex:row-detailedTourDescriptionAtIndex];
        CGSize w0 = [t sizeWithFont:[UIFont systemFontOfSize:10.0f]];
        SettingsData *settings = [SettingsData getSettingsData];
        float w1 = [settings isPortraitScreen]? tableView.frame.size.width : [[UIScreen mainScreen] bounds].size.height;
        return (w0.width > w1-15.0f)? 28.0 : 14.0;
      } else if (row >= detailedTourDescriptionAtIndex+[detailedTourDescription count]) {
        row -= [detailedTourDescription count]-1;
      }
    }
    if (row%2 == 1) return 14.0;
    ParkData *parkData = [ParkData getParkData:parkId];
    int n = [parkData.currentTrackData numberOfTourItemsDone];
    row /= 2;
    if (row == n) return 98.0;
    if (row > n) return 60.0;
  }
  return tableView.rowHeight;
}

// Customize the appearance of table view cells.
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  int row = (int)indexPath.row;
  if (editButton.style != UIBarButtonItemStyleDone) {
    if (detailedTourDescription != nil && row >= detailedTourDescriptionAtIndex && row < detailedTourDescriptionAtIndex+[detailedTourDescription count]) {
      static NSString *cellId = @"RouteCell";
      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
      if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
        cell.textLabel.font = [UIFont systemFontOfSize:10.0f];
        cell.textLabel.textColor = [Colors hilightText];
      }
      int j = row-detailedTourDescriptionAtIndex;
      if (j == 0) {
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
      } else {
        cell.textLabel.textAlignment = UITextAlignmentLeft;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
      }
      NSString *t = [detailedTourDescription objectAtIndex:j];
      CGSize w0 = [t sizeWithFont:cell.textLabel.font];
      SettingsData *settings = [SettingsData getSettingsData];
      float w1 = [settings isPortraitScreen]? tableView.frame.size.width : [[UIScreen mainScreen] bounds].size.height;
      if (w0.width > w1-15.0f) {
        cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.textLabel.numberOfLines = 2;
      } else {
        cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
        cell.textLabel.numberOfLines = 1;
      }
      cell.textLabel.text = t;
      return cell;
    }
    if (detailedTourDescription != nil && row >= detailedTourDescriptionAtIndex+[detailedTourDescription count]) row -= [detailedTourDescription count]-1;
    if (row%2 == 0) {
      row /= 2;
      TourItem *tourItem = [tourData objectAtIndex:row];
      Attraction *entryAttraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
      Attraction *exitAttraction = [Attraction getAttraction:parkId attractionId:tourItem.exitAttractionId];
      BOOL enabled = ([LocationData isLocationDataActive] && accuracyLabel.tag == 0);// && ![parkData.currentTrackData isTrackingFromParkingToParkEntrance]);
      if (enabled) {
        LocationData *locData = [LocationData getLocationData];
        if (![locData isDataPoolRegistered:parkId]) enabled = NO;
      }
      BOOL done = [parkData.currentTrackData isDoneAtTourIndex:row];
      if (done) {
        static NSString *routeDoneCellId = @"RouteViewDoneTableCell";
        RouteViewDoneTableCell *cell = (RouteViewDoneTableCell *)[tableView dequeueReusableCellWithIdentifier:routeDoneCellId];
        if (cell == nil) {
          [cellOwner loadNibNamed:routeDoneCellId owner:self];
          cell = (RouteViewDoneTableCell *)cellOwner.cell;
          [cell.ratingView setForegroundImage:[UIImage imageNamed:@"thumbs_up.png"]];
          [cell.ratingView setBackgroundImage:nil];
          cell.selectionStyle = UITableViewCellSelectionStyleNone;
          cell.attractionNameLabel.textColor = [Colors lightText];
          cell.entryAttractionNameLabel.textColor = [Colors lightText];
          cell.exitAttractionNameLabel.textColor = [Colors lightText];
          cell.timeLabel.textColor = [Colors darkBlue];
          cell.ratingLabel.textColor = [Colors hilightText];
        }
        if ([entryAttraction isTrain] && ![entryAttraction.attractionId isEqualToString:exitAttraction.attractionId]) {
          cell.attractionNameLabel.hidden = YES;
          cell.entryAttractionNameLabel.hidden = NO;
          cell.exitAttractionNameLabel.hidden = NO;
          cell.entryAttractionNameLabel.text = entryAttraction.stringAttractionName;
          cell.exitAttractionNameLabel.text = exitAttraction.stringAttractionName;
        } else {
          cell.attractionNameLabel.hidden = NO;
          cell.entryAttractionNameLabel.hidden = YES;
          cell.exitAttractionNameLabel.hidden = YES;
          cell.attractionNameLabel.text = entryAttraction.stringAttractionName;
        }
        double time1 = [parkData.currentTrackData doneTimeIntervalAtEntryTourIndex:row];
        double time2 = [parkData.currentTrackData doneTimeIntervalAtExitTourIndex:row];
        if (time1 > 0.0 && tourItem.completed) {
          cell.timeLabel.text = [NSString stringWithFormat:@"%@ %@", [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:time1] considerTimeZoneAbbreviation:nil], [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:time2] considerTimeZoneAbbreviation:nil]];
        } else {
          cell.timeLabel.text = [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:time2] considerTimeZoneAbbreviation:nil];
        }
        cell.timeLabel.enabled = tourItem.completed;
        if ([entryAttraction isRealAttraction]) {
          int rating = [parkData getPersonalRating:tourItem.attractionId];
          cell.ratingLabel.text = (rating == 0)? [NSLocalizedString(@"tour.cell.rating.text", nil) stringByAppendingString:@" ?"] : NSLocalizedString(@"tour.cell.rating.text", nil);
          [cell.ratingView setRating:rating];
        } else {
          cell.ratingLabel.text = @"";
          [cell.ratingView setRating:0];
        }
        [cell setCompleted:tourItem.completed];
        return cell;
      } else {
        if (row == [parkData.currentTrackData numberOfTourItemsDone]) {
          RouteViewHighLightTableCell *cell = highLightTableCell;
          cell.iconButton.tag = row;
          cell.iconButton.enabled = enabled;
          NSDate *date = [[NSDate alloc] initWithTimeInterval:tourItem.calculatedTimeInterval sinceDate:now];
          cell.timeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"tour.cell.highlight.time", nil), [CalendarData stringFromTime:date considerTimeZoneAbbreviation:nil]];
          [date release];
          cell.timeLabel.textColor = [Colors lightText];
          cell.attractionNameLabel.textColor = [Colors lightText];
          cell.attractionName2Label.textColor = [Colors lightText];
          cell.descriptionLabel.textColor = [Colors lightText];
          cell.detailDescriptionLabel.textColor = [Colors lightText];
          if (![entryAttraction isRealAttraction]) {
            cell.attractionNameLabel.text = entryAttraction.stringAttractionName;
            cell.attractionName2Label.hidden = YES;
            cell.descriptionLabel.text = NSLocalizedString(@"tour.cell.highlight.description", nil);
            cell.detailDescriptionLabel.text = NSLocalizedString(@"tour.cell.highlight.detailed.description", nil);
            cell.toTourItem = YES;
            [cell setIconName:@"button-entrance40.png"];
            [cell setImagePath:[entryAttraction imagePath:parkId]];
          } else if (parkData.currentTrackData == nil || [parkData.currentTrackData walkToEntry]) {
            cell.attractionNameLabel.text = entryAttraction.stringAttractionName;
            cell.attractionName2Label.hidden = YES;
            cell.descriptionLabel.text = NSLocalizedString(@"tour.cell.highlight.entrance.description", nil);
            cell.detailDescriptionLabel.text = NSLocalizedString(@"tour.cell.highlight.entrance.detailed.description", nil);
            cell.toTourItem = NO;
            [cell setIconName:@"button-entrance40.png"];
            [cell setImagePath:[entryAttraction imagePath:parkId]];
          } else {
            if (![entryAttraction isTrain] && strcmp(exitAttraction.attractionName, entryAttraction.attractionName) && ![exitAttraction.attractionId isEqualToString:[parkData exitAttractionIdOf:entryAttraction.attractionId]]) {
              TrackSegment *track = [parkData.currentTrackData.trackSegments lastObject];
              ExtendedTrackPoint *t = (ExtendedTrackPoint *)[track fromTrackPoint];
              double time = t.recordTime;
              if (time > 0.0) {
                cell.attractionNameLabel.text = [NSString stringWithFormat:@"%@ %@", [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:time] considerTimeZoneAbbreviation:nil], entryAttraction.stringAttractionName];
              } else {
                cell.attractionNameLabel.text = entryAttraction.stringAttractionName;
              }
              cell.attractionName2Label.text = [NSString stringWithFormat:@"= %@", exitAttraction.stringAttractionName];
              cell.attractionName2Label.hidden = NO;
            } else {
              TrackSegment *track = [parkData.currentTrackData.trackSegments lastObject];
              ExtendedTrackPoint *t = (ExtendedTrackPoint *)[track fromTrackPoint];
              double time = t.recordTime;
              if (time > 0.0) {
                cell.attractionNameLabel.text = [NSString stringWithFormat:@"%@ %@", [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:time] considerTimeZoneAbbreviation:nil], exitAttraction.stringAttractionName];
              } else {
                cell.attractionNameLabel.text = exitAttraction.stringAttractionName;
              }
              cell.attractionName2Label.hidden = YES;
            }
            cell.descriptionLabel.text = NSLocalizedString(@"tour.cell.highlight.exit.description", nil);
            cell.detailDescriptionLabel.text = NSLocalizedString(@"tour.cell.highlight.exit.detailed.description", nil);
            cell.toTourItem = YES;
            [cell setIconName:@"button-exit40.png"];
            [cell setImagePath:[exitAttraction imagePath:parkId]];
          }
          if (!entryAttraction.waiting || ([entryAttraction isTrain] && ![entryAttraction.attractionId isEqualToString:exitAttraction.attractionId])) {
            cell.waitingTimeLabel.hidden = YES;
          } else {
            cell.waitingTimeLabel.hidden = NO;
            CalendarData *calendarData = [parkData getCalendarData];
            if (tourItem.timeVisit != nil || ![entryAttraction isRealAttraction] || [calendarData hasCalendarItems:tourItem.attractionId]) {
              cell.waitingTimeLabel.text = @"";
            } else {
              WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
              [waitingTimeData setLabel:cell.waitingTimeLabel forTourItem:tourItem color:YES extendedFormat:YES];
            }
          }
          return cell;
        } else {
          static NSString *routeCellId = @"RouteViewTableCell";
          RouteViewTableCell *cell = (RouteViewTableCell *)[tableView dequeueReusableCellWithIdentifier:routeCellId];
          if (cell == nil) {
            [cellOwner loadNibNamed:routeCellId owner:self];
            cell = (RouteViewTableCell *)cellOwner.cell;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionLabel.text = NSLocalizedString(@"tour.cell.highlight.entrance.description", nil);
            cell.descriptionLabel.textColor = [Colors lightText];
            cell.attractionNameLabel.textColor = [Colors lightText];
            cell.entryAttractionNameLabel.textColor = [Colors lightText];
            cell.exitAttractionNameLabel.textColor = [Colors lightText];
          }
          if (enabled && ![parkData.currentTrackData walkToEntry]) enabled = NO;
          cell.toTourItem = ![entryAttraction isRealAttraction];
          cell.locationLabel.text = [MenuData objectForKey:ATTRACTION_THEME_AREA at:[entryAttraction getAttractionDetails:parkId cache:YES]];
          [cell setClosed:tourItem.closed];
          if ([entryAttraction isTrain] && ![entryAttraction.attractionId isEqualToString:exitAttraction.attractionId]) {
            cell.attractionNameLabel.hidden = YES;
            cell.entryAttractionNameLabel.hidden = NO;
            cell.exitAttractionNameLabel.hidden = NO;
            cell.waitingTimeLabel.hidden = YES;
            cell.entryAttractionNameLabel.text = entryAttraction.stringAttractionName;
            cell.exitAttractionNameLabel.text = exitAttraction.stringAttractionName;
          } else {
            cell.attractionNameLabel.hidden = NO;
            cell.entryAttractionNameLabel.hidden = YES;
            cell.exitAttractionNameLabel.hidden = YES;
            cell.waitingTimeLabel.hidden = NO;
            cell.attractionNameLabel.text = entryAttraction.stringAttractionName;
            CalendarData *calendarData = [parkData getCalendarData];
            if (tourItem.timeVisit != nil) {
              cell.waitingTimeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"tour.cell.opening.times", nil), tourItem.timeVisit];
              cell.waitingTimeLabel.textColor = [Colors hilightText];
            } else if (!entryAttraction.waiting || (![entryAttraction isRealAttraction] || [calendarData hasCalendarItems:tourItem.attractionId])) {
              cell.waitingTimeLabel.text = @"";
            } else {
              WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
              [waitingTimeData setLabel:cell.waitingTimeLabel forTourItem:tourItem color:YES extendedFormat:YES];
            }
          }
          cell.iconButton.tag = row;
          cell.iconButton.enabled = enabled;
          cell.iconButton.alpha = 1.0;
          if (!tourItem.closed) {
            if (enabled) {
              [cell setIconName:@"button-entrance40.png"];
              cell.iconButton.alpha = 0.5;
              cell.descriptionLabel.hidden = NO;
            } else {
              [cell setIconName:@"green-button40.png"];
              cell.descriptionLabel.hidden = YES;
            }
          } else cell.descriptionLabel.hidden = YES;
          cell.timeLabel.enabled = enabled;
          if (tourItem.preferredTime > 0.0) {
            cell.timeLabel.text = [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:tourItem.preferredTime] considerTimeZoneAbbreviation:nil];
            cell.timeLabel.textColor = [UIColor blueColor];
          } else {
            NSDate *date = [[NSDate alloc] initWithTimeInterval:tourItem.calculatedTimeInterval sinceDate:now];
            cell.timeLabel.text = [CalendarData stringFromTimeShort:date considerTimeZoneAbbreviation:nil];
            [date release];
            cell.timeLabel.textColor = [Colors darkBlue];
          }
          cell.openingTimeLabel.textColor = [Colors darkBlue];
          double distance;
          cell.openingTimeLabel.text = getCurrentDistance(parkId, tourItem.attractionId, &distance);
          return cell;
        }
      }
    } else {
      static NSString *cellId = @"RouteCell";
      UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
      if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
        cell.textLabel.font = [UIFont systemFontOfSize:10.0];
        cell.textLabel.textColor = [Colors hilightText];
      }
      cell.textLabel.textAlignment = UITextAlignmentCenter;
      cell.textLabel.lineBreakMode = UILineBreakModeTailTruncation;
      cell.textLabel.numberOfLines = 1;
      row /= 2;
      TourItem *tourItem = [tourData objectAtIndex:row];
      SettingsData *settings = [SettingsData getSettingsData];
      int n = [parkData.currentTrackData numberOfTourItemsDoneAndActive];
      BOOL done = (row+1 < n); // [parkData.currentTrackData isDoneAndActiveAtTourIndex:row+1];
      cell.selectionStyle = (done)? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleBlue;
      NSMutableString *s = [[NSMutableString alloc] initWithCapacity:40];
      if (done) {
        [s appendString:NSLocalizedString(@"tour.cell.completed.distance.text", nil)];
        [s appendString:@" "];
      }
      [s appendString:distanceToString([settings isMetricMeasure], tourItem.distanceToNextAttraction)];
      if (row+1 == n) {
        TourItem *nextTourItem = [tourData objectAtIndex:row+1];
        if (nextTourItem.currentWalkFromAttractionId != nil) {
          [s appendString:@" "];
          [s appendString:NSLocalizedString(@"distance.position", nil)];
        }
      }
      cell.textLabel.text = [NSString stringWithFormat:(done)? NSLocalizedString(@"tour.cell.completed.route.text", nil) : NSLocalizedString(@"tour.cell.route.text", nil), s, [tourData getFormat:tourItem.walkingTime]];
      [s release];
      return cell;
    }
  }
  // Modus: Bearbeiten
  static NSString *tourCellId = @"TourViewTableCell";
  TourViewTableCell *cell = (TourViewTableCell *)[tableView dequeueReusableCellWithIdentifier:tourCellId];
  if (cell == nil) {
    [cellOwner loadNibNamed:tourCellId owner:self];
    cell = (TourViewTableCell *)cellOwner.cell;
    if (originalDistanceLabelColor == nil) originalDistanceLabelColor = [cell.currentDistanceLabel.textColor retain];
    cell.entryAttractionNameLabel.textColor = [Colors hilightText];
    cell.exitAttractionNameLabel.textColor = [Colors hilightText];
  }
  if (canMoveRow) {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  } else {
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  TourItem *tourItem = [tourData objectAtIndex:row];
  Attraction *entryAttraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
  Attraction *exitAttraction = [Attraction getAttraction:parkId attractionId:tourItem.exitAttractionId];
  if ([entryAttraction isTrain] && ![entryAttraction.attractionId isEqualToString:exitAttraction.attractionId]) {
    cell.attractionNameLabel.hidden = YES;
    cell.entryAttractionNameLabel.hidden = NO;
    cell.exitAttractionNameLabel.hidden = NO;
    cell.entryAttractionNameLabel.enabled = YES;
    cell.exitAttractionNameLabel.enabled = YES;
    cell.entryAttractionNameLabel.text = entryAttraction.stringAttractionName;
    cell.exitAttractionNameLabel.text = exitAttraction.stringAttractionName;
  } else {
    cell.attractionNameLabel.hidden = NO;
    cell.entryAttractionNameLabel.hidden = YES;
    cell.exitAttractionNameLabel.hidden = YES;
    cell.attractionNameLabel.text = entryAttraction.stringAttractionName;
  }
  cell.attractionNameLabel.textColor = (selectedTourItem != tourItem)? [Colors lightText] : [Colors darkBlue];
  cell.iconButton.tag = row;
  SettingsData *settings = [SettingsData getSettingsData];
  BOOL done = (parkData.currentTrackData != nil && [parkData.currentTrackData isDoneAndActiveAtTourIndex:row]);
  CGRect cTable = cell.attractionNameLabel.frame;
  cell.attractionNameLabel.frame = CGRectMake(cell.distanceLabel.frame.origin.x, cTable.origin.y, cTable.size.width+cTable.origin.x-cell.distanceLabel.frame.origin.x, cTable.size.height);
  cell.attractionNameLabel.enabled = YES;
  cell.distanceLabel.enabled = YES;
  NSMutableString *s = [[NSMutableString alloc] initWithCapacity:60];
  NSString *t = ([parkData isEntryOrExitOfPark:entryAttraction.attractionId])? [entryAttraction startingAndEndTimes:parkId forDate:nil maxTimes:-1] : [entryAttraction startingTimes:parkId forDate:nil onlyNext4Times:YES hasMoreThanOneTime:nil];
  double distance;
  NSString *currentDistance = getCurrentDistance(parkId, tourItem.attractionId, &distance);
  if (t != nil && [t length] > 0) {
    [s appendString:t];
    if ([currentDistance length] > 0) [s appendString:@", "];
  }
  [s appendString:currentDistance];
  cell.currentDistanceLabel.text = s;
  [s release];
  cell.currentDistanceLabel.textColor = originalDistanceLabelColor;
  [cell setClosed:[entryAttraction isClosed:parkId]];
  if (tourItem.distanceToNextAttraction > 0.0) {
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:30];
    [s appendString:(done)? NSLocalizedString(@"tour.cell.completed.distance.text", nil) : NSLocalizedString(@"attraction.route", nil)];
    [s appendString:@" "];
    [s appendString:distanceToString([settings isMetricMeasure], tourItem.distanceToNextAttraction)];
    cell.distanceLabel.text = s;
    [s release];
  } else {
    cell.distanceLabel.text = @"";
  }
  cell.distanceLabel.textColor = [Colors darkBlue];
  if (done) {
    cell.hidden = !viewAlsoDone;
    [cell setCompleted:tourItem.completed]; // ToDo: enable only last done entry
    double time1 = [parkData.currentTrackData doneTimeIntervalAtEntryTourIndex:row];
    double time2 = [parkData.currentTrackData doneTimeIntervalAtExitTourIndex:row];
    if (time1 > 0.0) {
      cell.timeLabel.text = [NSString stringWithFormat:@"%@ %@", [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:time1] considerTimeZoneAbbreviation:nil], [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:time2] considerTimeZoneAbbreviation:nil]];
    } else {
      cell.timeLabel.text = [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:time2] considerTimeZoneAbbreviation:nil];
    }
    cell.timeLabel.textColor = [UIColor darkGrayColor];
  } else {
    cell.hidden = NO;
    BOOL enabled = ((canMoveRow && row == 0 && [parkData isEntryOfPark:tourItem.attractionId]) || ([LocationData isLocationDataActive] && ![parkData.currentTrackData containsTrackingFromParking]));
    cell.iconButton.enabled = enabled;
    cell.iconButton.hidden = (selectedTourItem == tourItem);
    cell.timeLabel.enabled = enabled;
    [cell setIconName:@"green-button40.png"];
    if (tourItem.preferredTime > 0.0) {
      cell.timeLabel.text = [CalendarData stringFromTimeShort:[NSDate dateWithTimeIntervalSince1970:tourItem.preferredTime] considerTimeZoneAbbreviation:nil];
      cell.timeLabel.textColor = (selectedTourItem != tourItem)? [UIColor blueColor] : [UIColor redColor];
    } else {
      NSDate *date = [[NSDate alloc] initWithTimeInterval:tourItem.calculatedTimeInterval sinceDate:now];
      cell.timeLabel.text = [CalendarData stringFromTimeShort:date considerTimeZoneAbbreviation:nil];      
      [date release];
      cell.timeLabel.textColor = (selectedTourItem != tourItem)? [Colors lightText] : [UIColor redColor];
    }
  }
  return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!tableView.editing) return UITableViewCellEditingStyleNone;
  ParkData *parkData = [ParkData getParkData:parkId];
  return (indexPath.row >= [parkData.currentTrackData numberOfTourItemsDoneAndActive])? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

// Override to support editing the table view.
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
   ParkData *parkData = [ParkData getParkData:parkId];
   TourData *tourData = [parkData getTourData:parkData.currentTourName];
   [tourData removeObjectAtIndex:indexPath.row startTime:[now timeIntervalSince1970]];
   [self updateViewValues:0.0 enableScroll:NO];
 }   
}

// Override to support rearranging the table view.
-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
  ParkData *parkData = [ParkData getParkData:parkId];
  if (parkData.currentTrackData == nil || toIndexPath.row >= [parkData.currentTrackData numberOfTourItemsDoneAndActive]) {
    BOOL canMove = YES;
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    if (toIndexPath.row == 0) {
      TourItem *a = [tourData objectAtIndex:0];
      if ([parkData isEntryOfPark:a.attractionId]) canMove = NO;
    }
    if (canMove) {
      [tourData moveFrom:fromIndexPath.row to:toIndexPath.row startTime:[now timeIntervalSince1970]];
      [tourData dontAskNextTimeForTourOptimization];
    }
  }
  [self performSelector:@selector(updateViewValues) withObject:nil afterDelay:0.4];
}

// Override to support conditional rearranging of the table view.
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!canMoveRow) return NO;
  ParkData *parkData = [ParkData getParkData:parkId];
  if (indexPath.row == 0) {
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    TourItem *a = [tourData objectAtIndex:0];
    if ([parkData isEntryOfPark:a.attractionId]) return NO;
  }
  if (parkData.currentTrackData == nil) return YES;
  return (indexPath.row >= [parkData.currentTrackData numberOfTourItemsDoneAndActive]);
}

#pragma mark -
#pragma mark Table view delegate

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  if (!canMoveRow) {
    int row = (int)indexPath.row;
    if (editButton.style != UIBarButtonItemStyleDone) {
      if (detailedTourDescription != nil && row >= detailedTourDescriptionAtIndex+[detailedTourDescription count]) row -= [detailedTourDescription count]-1;
      row /= 2;
    }
    ParkData *parkData = [ParkData getParkData:parkId];
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    TourItem *tourItem = [tourData objectAtIndex:row];
    Attraction *entryAttraction = [Attraction getAttraction:parkId attractionId:tourItem.attractionId];
    Attraction *exitAttraction = [Attraction getAttraction:parkId attractionId:tourItem.exitAttractionId];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[RouteViewHighLightTableCell class]]) {
      RouteViewHighLightTableCell *highlightCell = (RouteViewHighLightTableCell *)cell;
      if ([highlightCell.attractionNameLabel.text isEqualToString:exitAttraction.stringAttractionName]) entryAttraction = exitAttraction;
    }
    AttractionViewController *controller = [[AttractionViewController alloc] initWithNibName:@"AttractionView" owner:self attraction:entryAttraction parkId:parkId];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editButton.style != UIBarButtonItemStyleDone) {
    int row = (int)indexPath.row;
    if (detailedTourDescription != nil) {
      if (row > detailedTourDescriptionAtIndex) {
        if (row < detailedTourDescriptionAtIndex+[detailedTourDescription count]) return nil;
        else row -= [detailedTourDescription count]-1;
      }
    }
    if (row%2 == 0) return nil;
    ParkData *parkData = [ParkData getParkData:parkId];
    return ([parkData.currentTrackData isDoneAndActiveAtTourIndex:row/2+1])? nil : indexPath;
  }
  return (canMoveRow)? indexPath : nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editButton.style != UIBarButtonItemStyleDone) {
    if (detailedTourDescription != nil && indexPath.row == detailedTourDescriptionAtIndex) {
      [detailedTourDescription release];
      detailedTourDescription = nil;
      [detailedTourDescriptionFromAttractionId release];
      detailedTourDescriptionFromAttractionId = nil;
      detailedTourDescriptionAtIndex = -1;
    } else {
      ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      [now release];
      now = [[NSDate alloc] init];
      [tourData updateTourData:[now timeIntervalSince1970]];
      int row = (int)indexPath.row;
      if (detailedTourDescription != nil && row >= detailedTourDescriptionAtIndex+[detailedTourDescription count]) row -= [detailedTourDescription count]-1;
      row /= 2;
      TourItem *a = [tourData objectAtIndex:row];
      TourItem *b = [tourData objectAtIndex:row+1];
      [detailedTourDescription release];
      BOOL currentPosition = (b.currentWalkFromAttractionId != nil);
      detailedTourDescriptionFromAttractionId = [((currentPosition)? b.currentWalkFromAttractionId : a.exitAttractionId) retain];
      detailedTourDescription = [[tourData createRouteDescriptionFrom:detailedTourDescriptionFromAttractionId currentPosition:currentPosition to:b.entryAttractionId attractionIdsOfDescription:nil] retain];
      detailedTourDescriptionAtIndex = 2*row+1;
    }
    [self updateViewValues:0.0 enableScroll:NO];
    [self updateMapView];
  }
}

#pragma mark -
#pragma mark Picker view delegate

-(void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  // ToDo
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
#pragma mark Map View Delegate methods

//MKUserLocation
/*-(void)mapView:(MKMapView *)map didUpdateUserLocation:(MKUserLocation *)userLocation {
  UIView *user = [map viewForAnnotation:userLocation];
  [map bringSubviewToFront:user];
  if (locationButton.selected) {
    MKCoordinateRegion region = (overlay == nil)? [[ParkData getParkData:parkId] getParkRegion] : MKCoordinateRegionForMapRect(overlay.boundingMapRect);
#ifdef FAKE_CORE_LOCATION
    LocationData *locData = [LocationData getLocationData];
    CLLocationCoordinate2D coordinate = locData.locationManager.location.coordinate;
#else
    CLLocationCoordinate2D coordinate = mapView.userLocation.coordinate;
#endif
    if (CLLocationCoordinate2DIsValid(coordinate) && [ParkOverlayView coordinate:coordinate isInside:region]) {
      [mapView setCenterCoordinate:coordinate animated:YES];
    }
  }
}*/

-(MKOverlayView *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)olay {
  // If using *several* MKOverlays simultaneously, you could test against the class
  // and return a different MKOverlayView as the handler for that overlay layer type.
  // CustomOverlayView handles both TileOverlay types in this demo.
  //ParkOverlayView *overlayView = [[ParkOverlayView alloc] initWithOverlay:overlay];
  return (ParkOverlayView *)olay;//[overlayView autorelease];
}

-(BOOL)intersectsMapRect:(MKMapRect)mapRect {
  if (overlay == nil) return YES;
  double x1 = MAX(overlay.boundingMapRect.origin.x, mapRect.origin.x);
  double x2 = MIN(overlay.boundingMapRect.origin.x + overlay.boundingMapRect.size.width, mapRect.origin.x + mapRect.size.width);
  if (x2 <= x1) return NO;
  double y1 = MAX(overlay.boundingMapRect.origin.y, mapRect.origin.y);
  double y2 = MIN(overlay.boundingMapRect.origin.y + overlay.boundingMapRect.size.height, mapRect.origin.y + mapRect.size.height);
  return (y2 > y1);
}

// ToDo: check gps data also at http://www.atlsoft.de/gpx/

-(void)mapView:(MKMapView *)map regionWillChangeAnimated:(BOOL)animated {
  if (manuallyChangingMapRect) return;
  if (previousZoomScale != ROUTE_REFRESH_WITHOUT_HIDING) {
    for (id annotation in map.annotations) {
      if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        RouteView *routeView = (RouteView *)[map viewForAnnotation:annotation];
        routeView.hidden = YES;
      }
    }
  }
  previousZoomScale = (CGFloat)(map.bounds.size.width / map.visibleMapRect.size.width);
  if ([self intersectsMapRect:mapView.visibleMapRect]) {
    lastGoodMapRect = mapView.visibleMapRect;
  } else {
    [mapView setVisibleMapRect:lastGoodMapRect animated:YES];
  }
}

-(void)mapView:(MKMapView *)map regionDidChangeAnimated:(BOOL)animated {
  if (manuallyChangingMapRect) return; //prevents possible infinite recursion when we call setVisibleMapRect below
  int zoomLevel = (int)[ParkOverlayView zoomLevelForMap:map];
  //NSLog(@"ZOOM Level: %d", zoomLevel);
  if ((overlay != nil && !MKMapRectIntersectsRect(overlay.boundingMapRect, map.visibleMapRect)) || zoomLevel < 15) {
    manuallyChangingMapRect = YES;
    [mapView setVisibleMapRect:lastGoodMapRect animated:YES];
    manuallyChangingMapRect = NO;
  }
  refreshRoute = (refreshRoute || previousZoomScale != (CGFloat)(map.bounds.size.width / map.visibleMapRect.size.width));
  if (refreshRoute) {
    NSMutableArray *annotations = [[NSMutableArray alloc] initWithCapacity:[map.annotations count]];
    for (id annotation in map.annotations) {
      if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        [annotations addObject:annotation];
      } else if ([annotation isKindOfClass:[MapPin class]]) {
        AttractionAnnotation *annotationView = (AttractionAnnotation *)[map viewForAnnotation:annotation];
        [annotationView updateImage:4.0f/(zoomLevel-14.0f)];
        [annotationView setNeedsDisplay];
      }
    }
    [map removeAnnotations:annotations];
    [map addAnnotations:annotations];
    refreshRoute = NO;
    [annotations release];
  } else {
    for (id annotation in mapView.annotations) {
      if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        RouteView *routeView = (RouteView *)[mapView viewForAnnotation:annotation];
        routeView.hidden = NO;
      }
    }
  }
  [self orderAnnotationsViews];
}

-(MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation {
#ifdef FAKE_CORE_LOCATION
  if ([annotation isMemberOfClass:[MKUserLocation class]]) {
    if ([LocationData isLocationDataActive]) {
      LocationData *locData = [LocationData getLocationData];
      locData.locationManager.mapView = map;
      return locData.locationManager.fakeUserLocationView;
    }
  }
#endif
	if ([annotation isKindOfClass:[MapPin class]]) {
    AttractionAnnotation *pin = (AttractionAnnotation *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"AttractionAnnotation"];
    if (pin == nil) {
      pin = [[[AttractionAnnotation alloc] initWithAnnotation:annotation reuseIdentifier:@"AttractionAnnotation"] autorelease];
      //pin.animatesDrop = NO;
      pin.canShowCallout = YES;
      pin.enabled = YES;
    } else {
      pin.annotation = annotation;
    }
    MapPin *mapPin = (MapPin *)annotation;
    if ((firstPin != nil && [firstPin.attractionId isEqualToString:mapPin.attractionId]) || (lastPin != nil && [lastPin.attractionId isEqualToString:mapPin.attractionId])) {
      pin.leftCalloutAccessoryView = nil;
      pin.rightCalloutAccessoryView = nil;
    } else {
      pin.leftCalloutAccessoryView = nil;
      pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    [pin updateImage:4.0f/([ParkOverlayView zoomLevelForMap:map]-14.0f)];
    return pin;
  } else if ([annotation isKindOfClass:[RouteAnnotation class]]) {
    RouteView *routeView = [[[RouteView alloc] initWithAnnotation:annotation reuseIdentifier:@"RouteViewAnnotation"] autorelease];
    routeView.canShowCallout = NO;
    routeView.enabled = NO;
    routeView.mapView = mapView;
    return routeView;
  }
  return nil;
}

-(void)mapView:(MKMapView *)map didSelectAnnotationView:(MKAnnotationView *)view {
  if ([view isKindOfClass:[AttractionAnnotation class]]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    view.alpha = 1.0f;
    MapPin *mapPin = (MapPin *)view.annotation;
    UIImage *image = [mapPin getImage];
    if (image != nil) {
      UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
      imgView.bounds = CGRectMake(0.0, 0.0, 30.0, 30.0);
      view.leftCalloutAccessoryView = imgView;
      [imgView release];
    } else {
      view.leftCalloutAccessoryView = nil;
    }
    if (!locationButton.selected) [mapView setCenterCoordinate:mapPin.coordinate animated:YES];
    [pool release];
  }
  [self orderAnnotationsViews];
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
  if ([view isKindOfClass:[AttractionAnnotation class]]) {
    MapPin *mapPin = (MapPin *)view.annotation;
    view.alpha = (mapPin.overlap)? 0.7f : 1.0f;
    view.leftCalloutAccessoryView = nil;
  }
  [self orderAnnotationsViews];
}

-(void)mapView:(MKMapView *)map annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
  MapPin *p = (MapPin *)view.annotation;
  AttractionViewController *controller = [[AttractionViewController alloc] initWithNibName:@"AttractionView" owner:self attraction:[Attraction getAttraction:parkId attractionId:p.attractionId] parkId:parkId];
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

#pragma mark -
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
  if (alertView.tag == TourViewControllerOptimizeTour) {
    if ([buttonTitle isEqualToString:NSLocalizedString(@"yes", nil)]) {
      ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      [self updateViewValues:[tourData optimize] enableScroll:NO];
    }
  } else if (alertView.tag == TourViewControllerCompleteTour) {
    if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.close", nil)]) { // aktuellen Track schließen
      ParkData *parkData = [ParkData getParkData:parkId];
      if (![parkData completeCurrentTrack]) {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"error", nil)
                               message:NSLocalizedString(@"tour.track.save.error", nil)
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
      }
      if ([LocationData isLocationDataActive] && [tourStartButton.title isEqualToString:NSLocalizedString(@"stop", nil)]) [self startTour:self];
      [self updateViewValues:0.0 enableScroll:NO];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.close.and.send", nil)]) { // aktuellen Track verschicken und schließen
      ParkData *parkData = [ParkData getParkData:parkId];
      TrackData *trackData = [parkData completeCurrentTrack];
      if (trackData != nil && [MFMailComposeViewController canSendMail]) {
        [self displayComposerSheet:trackData];
      } else {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"error", nil)
                               message:NSLocalizedString(@"tour.track.save.error", nil)
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
      }
      if ([LocationData isLocationDataActive] && [tourStartButton.title isEqualToString:NSLocalizedString(@"stop", nil)]) [self startTour:self];
      [self updateViewValues:0.0 enableScroll:NO];
    }
  } else if (alertView.tag == TourViewControllerCompleteTourItem) {
    if ([buttonTitle isEqualToString:NSLocalizedString(@"cancel", nil)]) return;
    ParkData *parkData = [ParkData getParkData:parkId];
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    int row = [parkData.currentTrackData numberOfTourItemsDone];
    TourItem *tourItem = [tourData.tourItems objectAtIndex:row];
    BOOL submitWaitTime = NO;
    if ([buttonTitle isEqualToString:NSLocalizedString(@"no", nil)]) { // Attraktion nicht erledigt
      tourItem.completed = NO;
      tourItem.closed = NO;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.item.closed", nil)]) { // Attraktion geschlossen
      tourItem.completed = NO;
      tourItem.closed = YES;
    } else { // Attraktion erledigt
      tourItem.completed = YES;
      tourItem.closed = NO;
      submitWaitTime = [buttonTitle isEqualToString:NSLocalizedString(@"tour.item.complete.submit.wait.time", nil)];
    }
    [tourData switchDoneAtIndex:row startTime:[now timeIntervalSince1970] completed:tourItem.completed closed:tourItem.closed submitWaitTime:submitWaitTime toTourItem:YES];
    if ([tourData isAllDone]) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"tour.completed.title", nil)
                             message:NSLocalizedString(@"tour.completed.text", nil)
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:NSLocalizedString(@"tour.close", nil), NSLocalizedString(@"tour.close.and.send", nil), nil];
      dialog.tag = TourViewControllerCompleteTour;
      [dialog show];
      [dialog release];
    }
    [self askIfTourOptimizing];
    [self updateViewValues:0.0 enableScroll:YES];
    [self updateMapView];
  } else if (alertView.tag == TourViewControllerStartTourTrainItem) {
    if (![buttonTitle isEqualToString:NSLocalizedString(@"cancel", nil)]) {
      ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      TourItem *tourItem = [tourData.tourItems objectAtIndex:rowTourViewControllerStartTourTrainItem];
      BOOL oneWay;
      NSArray *trainRouteForSelection = [parkData getTrainAttractionRoute:tourItem.attractionId oneWay:&oneWay];
      const char *cButtonTitle = [buttonTitle UTF8String];
      for (Attraction *station in trainRouteForSelection) {
        if (strcmp(station.attractionName, cButtonTitle) == 0) {
          [tourItem set:station.attractionId entry:station.attractionId exit:tourItem.exitAttractionId];
          break;
        }
      }
      [tourData switchDoneAtIndex:rowTourViewControllerStartTourTrainItem startTime:[now timeIntervalSince1970] completed:NO closed:closedTourViewControllerStartTourTrainItem submitWaitTime:NO toTourItem:toTourItemTourViewControllerStartTourTrainItem];
    }
    [self updateViewValues:0.0 enableScroll:YES];
    [self updateMapView];
  } else if (alertView.tag == TourViewControllerCompleteTourTrainItem) {
    ParkData *parkData = [ParkData getParkData:parkId];
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    int row = [parkData.currentTrackData numberOfTourItemsDone];
    TourItem *tourItem = [tourData.tourItems objectAtIndex:row];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.item.train.no.ride", nil)]) { // Attraktion nicht erledigt
      tourItem.completed = NO;
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.item.closed", nil)]) { // Attraktion geschlossen
      tourItem.completed = NO;
      tourItem.closed = YES;
    } else { // Attraktion erledigt
      tourItem.completed = YES;
      tourItem.closed = NO;
      BOOL oneWay;
      NSArray *trainRouteForSelection = [parkData getTrainAttractionRoute:tourItem.attractionId oneWay:&oneWay];
      const char *cButtonTitle = [buttonTitle UTF8String];
      for (Attraction *station in trainRouteForSelection) {
        if (strcmp(station.attractionName, cButtonTitle) == 0) {
          tourItem.exitAttractionId = station.attractionId;
          break;
        }
      }
    }
    [tourData switchDoneAtIndex:row startTime:[now timeIntervalSince1970] completed:tourItem.completed closed:tourItem.closed submitWaitTime:NO toTourItem:YES];
    [self askIfTourOptimizing];
    [self updateViewValues:0.0 enableScroll:YES];
    [self updateMapView];
  } else if (alertView.tag == TourViewControllerActionSheetOpenTour) {
    if ([buttonTitle isEqualToString:NSLocalizedString(@"yes", nil)]) {
      ParkData *parkData = [ParkData getParkData:parkId];
      NSLog(@"Open tour %@", buttonTitle);
      if (![buttonTitle isEqualToString:parkData.currentTourName]) {
        [parkData setCurrentTourName:buttonTitle];
      }
      [self updateViewValues:0.0 enableScroll:NO];  // falls es über löschen aufgerufen wurde
    }
  } else {
    UITextField *textField = [alertView textFieldAtIndex:0];
    NSString *changedTextInput = (textField != nil)? [textField.text retain] : nil;
    if (changedTextInput != nil) {
      ParkData *parkData = [ParkData getParkData:parkId];
      if (alertView.tag == TourViewControllerNewTour) {
        if ([buttonTitle isEqualToString:NSLocalizedString(@"ok", nil)]) {
          if ([parkData addNewTourName:changedTextInput]) {
            [self updateViewValues:0.0 enableScroll:NO];
          } else {
            UIAlertView *dialog = [[UIAlertView alloc]
                                   initWithTitle:NSLocalizedString(@"error", nil)
                                   message:NSLocalizedString(@"tour.name.new.error", nil)
                                   delegate:nil
                                   cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                   otherButtonTitles:nil];
            [dialog show];
            [dialog release];
          }
        }
      } else if (alertView.tag == TourViewControllerRenameTour || alertView.tag == TourViewControllerRenameNewTour) {
        [UIMenuController sharedMenuController].menuVisible = YES;
        if ([buttonTitle isEqualToString:NSLocalizedString(@"ok", nil)]) {
          if ([parkData renameTourNameFrom:parkData.currentTourName to:changedTextInput]) {
            [self updateViewValues:0.0 enableScroll:NO];
          } else {
            UIAlertView *dialog = [[UIAlertView alloc]
                                   initWithTitle:NSLocalizedString(@"error", nil)
                                   message:NSLocalizedString(@"tour.name.new.error", nil)
                                   delegate:nil
                                   cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                   otherButtonTitles:nil];
            [dialog show];
            [dialog release];
          }
        }
      } else if (alertView.tag == TourViewControllerTrackName) {
        [UIMenuController sharedMenuController].menuVisible = YES;
        if (changedTextInput == nil) changedTextInput = [parkData.currentTourName retain];
        TrackData *trackData = [[TrackData alloc] initWithTrackName:changedTextInput parkId:parkId fromAttractionId:UNKNOWN_ATTRACTION_ID];
        parkData.currentTrackData = trackData;
        [trackData release];
        [self startUpdateLocationData];
      } else {
        NSLog(@"Internal error! Tag %d unknown.", (int)alertView.tag);
      }
      [changedTextInput release];
    }
  }
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  if (canMoveRow) {
    [self editAction:sender];
  } else {
    //[mapView removeAnnotations:mapView.annotations];
    mapView.delegate = nil;
    if ([LocationData isLocationDataInitialized]) {
      LocationData *locData = [LocationData getLocationData];
      [locData unregisterViewController];
    }
    [delegate dismissModalViewControllerAnimated:(sender != nil)];
  }
}

-(void)startUpdateLocationData {
  ParkData *parkData = [ParkData getParkData:parkId];
  LocationData *locData = [LocationData getLocationData];
  [locData registerDataPool:parkData.currentTrackData parkId:parkId];
  [locData registerViewController:self];
  [locData start];
  [self updateViewValues:0.0 enableScroll:YES];
}

-(IBAction)startTour:(id)sender {
  BOOL start = NO;
  if ([LocationData isLocationDataActive]) {
    LocationData *locData = [LocationData getLocationData];
    if ([locData isDataPoolRegistered:parkId]) {
      tourStartButton.title = NSLocalizedString(@"start", nil);
      tourStartButton.style = UIBarButtonItemStyleBordered;
      [locData unregisterViewController];
      [locData unregisterDataPool:nil];
      //[locData stop];
      ParkData *parkData = [ParkData getParkData:parkId];
      [parkData save:YES]; // ToDo: nur gpx Datei speichern, d.h. [parkData.currentTourData saveData];
      [self updateViewValues:0.0 enableScroll:YES];
      return;
    } else {
      start = YES;
    }
  }
  if (!start && [LocationData isLocationDataStarted]) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"location.error", nil)
                           message:NSLocalizedString(@"location.required", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  } else {
    tourStartButton.title = NSLocalizedString(@"stop", nil);
    tourStartButton.style = UIBarButtonItemStyleDone;
    ParkData *parkData = [ParkData getParkData:parkId];
    if (parkData.currentTrackData == nil) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"track.name", nil)
                             message:[NSString stringWithFormat:NSLocalizedString(@"track.name.tour", nil), parkData.currentTourName]
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:nil];
      dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
      UITextField *textField = [dialog textFieldAtIndex:0];
      textField.keyboardAppearance = UIKeyboardAppearanceAlert;
      textField.text = [TrackData defaultName:parkData.currentTourName];
      dialog.tag = TourViewControllerTrackName;
      [dialog show];
      //[UIMenuController sharedMenuController].menuVisible = NO;
      //[textField selectAll:self];
      [dialog release];
    } else {
      [self startUpdateLocationData];
    }
  }
  if (mapView.showsUserLocation && mapView.userLocation != nil) {
    UIView *user = [mapView viewForAnnotation:mapView.userLocation];
    if (user != nil) [mapView.superview bringSubviewToFront:user];
  }
}

-(IBAction)mapViewAction:(id)sender {
  CGRect rMap = mapView.frame;
  CGRect rTable = tourTableView.frame;
  if (tourMapButton.style == UIBarButtonItemStyleDone) {
    tourMapButton.style = UIBarButtonItemStyleBordered;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    tourTableView.frame = CGRectMake(rTable.origin.x, rTable.origin.y-rMap.size.height, rTable.size.width, rTable.size.height+rMap.size.height);
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:mapView cache:NO];
    [UIView commitAnimations];
    mapView.hidden = YES;
    copyrightLabel.hidden = YES;
  } else {
    //mapView.bounds = CGRectMake(0, 0, rMap.size.width, rMap.size.height);
    mapView.hidden = NO;
    copyrightLabel.hidden = NO;
    tourMapButton.style = UIBarButtonItemStyleDone;
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5];
    tourTableView.frame = CGRectMake(rTable.origin.x, rTable.origin.y+rMap.size.height, rTable.size.width, rTable.size.height-rMap.size.height);
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:mapView cache:NO];
    [UIView commitAnimations];
    [self updateMapView];
  }
  [self updateViewValues:0.0 enableScroll:YES];
}

-(IBAction)tourCompletedAction:(id)sender {
  UIActionSheet *sheet = nil;
  ParkData *parkData = [ParkData getParkData:parkId];
  if (parkData.currentTrackData != nil) {
    sheet = [[UIActionSheet alloc]
             initWithTitle:NSLocalizedString(@"tour.track.sheet.title", nil)
             delegate:self
             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
             destructiveButtonTitle:nil
             otherButtonTitles:NSLocalizedString(@"tour.track.sheet.button1", nil),
             NSLocalizedString(@"tour.track.sheet.button2", nil),
             NSLocalizedString(@"tour.track.sheet.button3", nil),
             NSLocalizedString(@"tour.track.sheet.button4", nil),
             NSLocalizedString(@"tour.track.sheet.button5", nil),
             nil];
  } else {
    sheet = [[UIActionSheet alloc]
             initWithTitle:NSLocalizedString(@"tour.track.sheet.title", nil)
             delegate:self
             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
             destructiveButtonTitle:nil
             otherButtonTitles:NSLocalizedString(@"tour.track.sheet.button1", nil),
             NSLocalizedString(@"tour.track.sheet.button2", nil),
             NSLocalizedString(@"tour.track.sheet.button3", nil),
             nil];
  }
  sheet.tag = TourViewControllerActionSheetTourTrack;
  [sheet showFromBarButtonItem:tourCompletedButton animated:YES];
  UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
  backgroundView.backgroundColor = [Colors darkBlue];
  backgroundView.opaque = NO;
  backgroundView.alpha = 0.5;
  [sheet insertSubview:backgroundView atIndex:0];
  [backgroundView release];
  [sheet release];
}

-(void)didUpdateLocationData {
  if (locationButton.selected) {
    MKCoordinateRegion region = (overlay == nil)? [[ParkData getParkData:parkId] getParkRegion] : MKCoordinateRegionForMapRect(overlay.boundingMapRect);
#ifdef FAKE_CORE_LOCATION
    LocationData *locData = [LocationData getLocationData];
    CLLocationCoordinate2D coordinate = locData.locationManager.location.coordinate;
#else
    CLLocationCoordinate2D coordinate = mapView.userLocation.coordinate;
#endif
    if (CLLocationCoordinate2DIsValid(coordinate) && [ParkOverlayView coordinate:coordinate isInside:region]) {
      //MKCoordinateRegion region = mapView.region;
      //region.center = coordinate;
      //NSLog(@"New user location lat %f  - long %f", region.center.latitude, region.center.longitude);
      //[mapView setRegion:region animated:YES];
      manuallyChangingMapRect = YES;
      previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
      [mapView setCenterCoordinate:coordinate animated:YES];
      manuallyChangingMapRect = NO;
    }
  }
  if (!canMoveRow) {
    /* Funktioniert zwar, springt aber zu oft
     if (detailedTourDescription != nil) {
      int row = detailedTourDescriptionAtIndex/2;
      ParkData *parkData = [ParkData getParkData:parkId];
      if (parkData.currentTrackData != nil && [parkData.currentTrackData numberOfTourItemsDone]-1 == row) {
        TourData *tourData = [parkData getTourData:parkData.currentTourName];
        TourItem *a = [tourData objectAtIndex:row];
        TourItem *b = [tourData objectAtIndex:row+1];
        NSArray *newDetailedTourDescription = [tourData createRouteDescriptionFrom:(b.currentWalkFromAttractionId != nil)? b.currentWalkFromAttractionId : a.exitAttractionId to:b.entryAttractionId];
        if (![newDetailedTourDescription isEqualToArray:detailedTourDescription]) {
          [detailedTourDescription release];
          detailedTourDescription = [newDetailedTourDescription retain];
          [self updateMapView];
        }
      }
    }*/
    [self updateViewValues:0.0 enableScroll:NO]; // sonst können keine Zeilen im Bearbeitungsmodus verschoben werden
  }
}

-(IBAction)helpView:(id)sender {
  HelpData *helpData = [HelpData getHelpData];
  NSString *page = [helpData.pages objectForKey:@"MENU_TOUR"];
  NSString *title = [helpData.titles objectForKey:@"MENU_TOUR"];
  if (title != nil && page != nil) {
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    controller.content = page;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(IBAction)tourAction:(id)sender {
  UIActionSheet *sheet = [[UIActionSheet alloc]
                          initWithTitle:NSLocalizedString(@"tour.action.sheet.title", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                          destructiveButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"tour.action.sheet.button1", nil),
                          NSLocalizedString(@"tour.action.sheet.button2", nil),
                          NSLocalizedString(@"tour.action.sheet.button3", nil),
                          NSLocalizedString(@"tour.action.sheet.button4", nil),
                          nil];
  sheet.tag = TourViewControllerActionSheetTourAction;
  [sheet showFromBarButtonItem:tourButton animated:YES];
  UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
  backgroundView.backgroundColor = [Colors darkBlue];
  backgroundView.opaque = NO;
  backgroundView.alpha = 0.5;
  [sheet insertSubview:backgroundView atIndex:0];
  [backgroundView release];
  [sheet release];
}

-(IBAction)addAction:(id)sender {
  UIActionSheet *sheet = [[UIActionSheet alloc]
                          initWithTitle:NSLocalizedString(@"tour.add.action.sheet.title", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                          destructiveButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"tour.add.action.sheet.button1", nil),
                          NSLocalizedString(@"tour.add.action.sheet.button2", nil),
                          NSLocalizedString(@"tour.add.action.sheet.button3", nil),
                          NSLocalizedString(@"tour.add.action.sheet.button4", nil),
                          NSLocalizedString(@"tour.add.action.sheet.button5", nil),
                          NSLocalizedString(@"tour.add.action.sheet.button6", nil),
                          NSLocalizedString(@"tour.add.action.sheet.button7", nil),
                          nil];
#ifdef DEBUG_MAP
  [sheet addButtonWithTitle:NSLocalizedString(@"all", nil)];
#endif
  sheet.tag = TourViewControllerActionSheetAddAction;
  [sheet showFromBarButtonItem:addButton animated:YES];
  UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
  backgroundView.backgroundColor = [Colors darkBlue];
  backgroundView.opaque = NO;
  backgroundView.alpha = 0.5;
  [sheet insertSubview:backgroundView atIndex:0];
  [backgroundView release];
  [sheet release];
}

-(IBAction)tourItemsAction:(id)sender {
  UIActionSheet *sheet = [[UIActionSheet alloc]
                          initWithTitle:NSLocalizedString(@"tour.items.action.sheet.title", nil)
                          delegate:self
                          cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                          destructiveButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"tour.items.action.sheet.button1", nil),
                          NSLocalizedString(@"tour.items.action.sheet.button2", nil),
                          nil];
  sheet.tag = TourViewControllerActionSheetTourItemsAction;
  [sheet showFromBarButtonItem:tourItemsButton animated:YES];
  UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
  backgroundView.backgroundColor = [Colors darkBlue];
  backgroundView.opaque = NO;
  backgroundView.alpha = 0.5;
  [sheet insertSubview:backgroundView atIndex:0];
  [backgroundView release];
  [sheet release];
}

-(IBAction)editAction:(id)sender {
  if (tourMapButton.style == UIBarButtonItemStyleDone) {
    [self mapViewAction:sender];
  }
  if (canMoveRow) {
    canMoveRow = NO;
    [tourTableView setEditing:NO animated:YES];
    doneBottomToolbar.hidden = YES;
    editBottomToolbar.hidden = NO;
    bottomToolbar.hidden = YES;
    timePickerClearButton.title = NSLocalizedString(@"clear", nil);
    CGRect rTable = tourTableView.frame;
    tourTableView.frame = CGRectMake(rTable.origin.x, rTable.origin.y, rTable.size.width, timePicker.frame.origin.y+timePicker.frame.size.height-rTable.origin.y);
    [self askIfTourOptimizing];
    [self updateViewValues:0.0 enableScroll:NO];
  } else {
    if (editButton.style == UIBarButtonItemStyleDone) {
      editButton.style = UIBarButtonItemStyleBordered;
      editBottomToolbar.hidden = YES;
      bottomToolbar.hidden = NO;
      [self updateViewValues:0.0 enableScroll:YES];
    } else {
      [detailedTourDescription release];
      detailedTourDescription = nil;
      [detailedTourDescriptionFromAttractionId release];
      detailedTourDescriptionFromAttractionId = nil;
      detailedTourDescriptionAtIndex = -1;
      editButton.style = UIBarButtonItemStyleDone;
      editBottomToolbar.hidden = NO;
      bottomToolbar.hidden = YES;
      [self updateViewValues:0.0 enableScroll:NO];
    }
  }
}

-(IBAction)viewLocation:(id)sender {
  locationButton.selected = !locationButton.selected;
  [self didUpdateLocationData];
}

/*-(IBAction)viewDone:(id)sender {
  viewAlsoDone = !viewAlsoDone;
  if (!viewAlsoDone) {
    ParkData *parkData = [ParkData getParkData:parkId];
    int n = [parkData.currentTrackData numberOfTourItemsDone];
    if (n > 0) {
      NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:n];
      for (int i = 0; i < n; ++i) {
        if ([parkData.currentTrackData isDoneAtTourIndex:i]) {
          [array addObject:[NSIndexPath indexPathForRow:i inSection:0]];  // ToDo: sort by name
        }
      }
      [tourTableView deleteRowsAtIndexPaths:array withRowAnimation:YES];
      [array release];
    }
  }
  [self updateViewValues:0.0];
}*/

// Displays an email composition interface inside the application. Populates all the Mail fields. 
-(void)displayComposerSheet:(TrackData *)trackData {
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;

  NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateStyle:NSDateFormatterMediumStyle];
  [dateFormat setTimeStyle:NSDateFormatterNoStyle];
  NSString *s = NSLocalizedString(@"tour.email.subject", nil);
	[picker setSubject:[NSString stringWithFormat:s, [dateFormat stringFromDate:now], [MenuData getParkName:parkId cache:YES]]];
  [dateFormat release];

  ParkData *parkData = [ParkData getParkData:parkId];
  NSError *error = nil;
  NSData *gpxData = [[NSData alloc] initWithContentsOfFile:[trackData gpxFilePath] options:NSDataReadingUncached error:&error];
  if (gpxData != nil) {
    [picker addAttachmentData:gpxData mimeType:@"text/xml" fileName:[NSString stringWithFormat:@"%@_%@.gpx", [MenuData getParkName:parkId cache:YES], trackData.trackName]];
  } else {
    NSLog(@"Error to read file '%@' (%@)", [trackData gpxFilePath], [error localizedDescription]);
  }
	// Fill out the email body text
	NSString *emailBody = trackData.trackDescription;
  if (trackData == parkData.currentTrackData) {
    TourData *tourData = [parkData getTourData:parkData.currentTourName];
    emailBody = [tourData createTrackDescription];
  }
	[picker setMessageBody:emailBody isHTML:NO];
	[self presentViewController:picker animated:YES completion:nil];
  [picker release];
  [gpxData release];
}

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
  [self updateViewValues:0.0 enableScroll:NO];
}

-(IBAction)clearPreferredTime:(id)sender {
  BOOL changed = (selectedTourItem.preferredTime != 0);
  if (changed) selectedTourItem.preferredTime = 0;
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  [tourData updateTourData:[now timeIntervalSince1970]];
  [parkData save:YES];
  if (changed) [self askIfTourOptimizing];
  selectedTourItem = nil;
  CGRect rTable = tourTableView.frame;
  tourTableView.frame = CGRectMake(rTable.origin.x, rTable.origin.y, rTable.size.width, timePicker.frame.origin.y+timePicker.frame.size.height-rTable.origin.y);
  backgroundTimePicker.hidden = YES;
  timePicker.hidden = YES;
  doneBottomToolbar.hidden = NO;
  timePickerBottomToolbar.hidden = YES;
  navigationTitle.leftBarButtonItem.enabled = YES;
  tourButton.enabled = YES;
  addButton.enabled = YES;
  tourItemsButton.enabled = YES;
  editButton.enabled = YES;
  [self updateViewValues:0.0 enableScroll:NO];
}

-(IBAction)setPreferredTime:(id)sender {
  unsigned units = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit;
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *components = [calendar components:units fromDate:now];
  int y = (int)[components year];
  int m = (int)[components month];
  int d = (int)[components day];
  components = [calendar components:units fromDate:timePicker.date];
  [components setYear:y];
  [components setMonth:m];
  [components setDay:d];
  timePicker.date = [calendar dateFromComponents:components];
  [calendar release];
  NSLog(@"set time %@", timePicker.date);
  NSTimeInterval newTime = [timePicker.date timeIntervalSince1970];
  BOOL changed = (selectedTourItem.preferredTime != newTime);
  if (changed) selectedTourItem.preferredTime = newTime;
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  [tourData updateTourData:[now timeIntervalSince1970]];
  [parkData save:YES];
  if (changed) [self askIfTourOptimizing];
  selectedTourItem = nil;
  CGRect rTable = tourTableView.frame;
  tourTableView.frame = CGRectMake(rTable.origin.x, rTable.origin.y, rTable.size.width, timePicker.frame.origin.y+timePicker.frame.size.height-rTable.origin.y);
  backgroundTimePicker.hidden = YES;
  timePicker.hidden = YES;
  doneBottomToolbar.hidden = NO;
  timePickerBottomToolbar.hidden = YES;
  navigationTitle.leftBarButtonItem.enabled = YES;
  tourButton.enabled = YES;
  addButton.enabled = YES;
  tourItemsButton.enabled = YES;
  editButton.enabled = YES;
  [self updateViewValues:0.0 enableScroll:NO];
  [startActivityIndicator stopAnimating];
}

-(IBAction)timePickerValueChanged:(id)sender {
  /*ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  selectedTourItem.preferredTime = [[timePicker date] timeIntervalSince1970];
  [tourData updateTourData:[now timeIntervalSince1970]];
  [self updateViewValues:0.0];*/
}

#pragma mark -
#pragma mark Action sheet delegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (actionSheet.tag == TourViewControllerActionSheetTourTrack) {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.track.sheet.button1", nil)] // Track löschen...
        || [buttonTitle isEqualToString:NSLocalizedString(@"tour.track.sheet.button2", nil)] // Track verschicken...
        || [buttonTitle isEqualToString:NSLocalizedString(@"tour.track.sheet.button3", nil)]) { // Track auf Facebook veröffentlichen...
      ParkData *parkData = [ParkData getParkData:parkId];
      NSArray *trackNames = [parkData getCompletedTracks];
      if ([trackNames count] > 0) {
        UIActionSheet *sheet = [[UIActionSheet alloc]
                                initWithTitle:buttonTitle
                                delegate:self
                                cancelButtonTitle:nil //NSLocalizedString(@"cancel", nil)
                                destructiveButtonTitle:nil
                                otherButtonTitles:nil];
        for (NSString *trackName in trackNames) {
          [sheet addButtonWithTitle:trackName];
        }
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"cancel", nil)];  // bug in iOS 4.2
        if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.track.sheet.button1", nil)]) sheet.tag = TourViewControllerActionSheetDeleteTrack;
        else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.track.sheet.button2", nil)]) sheet.tag = TourViewControllerActionSheetSendTrack;
        else sheet.tag = TourViewControllerActionSheetPublishTrackOnFacebook;
        [sheet showFromToolbar:bottomToolbar];
        UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
        backgroundView.backgroundColor = [Colors darkBlue];
        backgroundView.opaque = NO;
        backgroundView.alpha = 0.5;
        [sheet insertSubview:backgroundView atIndex:0];
        [backgroundView release];
        [sheet release];
      } else {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"error", nil)
                               message:NSLocalizedString(@"tour.no.track.error", nil)
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
      }
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.track.sheet.button4", nil)]) { // aktuellen Track schließen
      ParkData *parkData = [ParkData getParkData:parkId];
      if (![parkData completeCurrentTrack]) {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"error", nil)
                               message:NSLocalizedString(@"tour.track.save.error", nil)
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
      }
      if ([LocationData isLocationDataActive] && [tourStartButton.title isEqualToString:NSLocalizedString(@"stop", nil)]) [self startTour:self];
      [self updateViewValues:0.0 enableScroll:NO];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.track.sheet.button5", nil)]) { // aktuellen Track verschicken
      ParkData *parkData = [ParkData getParkData:parkId];
      if (parkData.currentTrackData != nil && [MFMailComposeViewController canSendMail]) {
        if (![parkData.currentTrackData saveData]) {
          UIAlertView *dialog = [[UIAlertView alloc]
                                 initWithTitle:NSLocalizedString(@"error", nil)
                                 message:NSLocalizedString(@"tour.track.save.error", nil)
                                 delegate:nil
                                 cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                 otherButtonTitles:nil];
          [dialog show];
          [dialog release];
        }
        [self displayComposerSheet:parkData.currentTrackData];
      }
    }
  } else if (actionSheet.tag == TourViewControllerActionSheetDeleteTrack) {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
      ParkData *parkData = [ParkData getParkData:parkId];
      NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
      [parkData removeTrackData:buttonTitle];
    }
  } else if (actionSheet.tag == TourViewControllerActionSheetSendTrack) {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
      ParkData *parkData = [ParkData getParkData:parkId];
      NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
      TrackData *trackData = [parkData getTrackData:buttonTitle];
      if (trackData != nil && [MFMailComposeViewController canSendMail]) {
        [self displayComposerSheet:trackData];
      }
    }
  } else if (actionSheet.tag == TourViewControllerActionSheetPublishTrackOnFacebook) {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
      ParkData *parkData = [ParkData getParkData:parkId];
      NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
      TrackData *trackData = [parkData getTrackData:buttonTitle];
      if (trackData != nil) [self publishTrackAtFacebook:trackData];
    }
  } else if (actionSheet.tag == TourViewControllerActionSheetTourAction) {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.action.sheet.button1", nil)]) { // Neue Tour...
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:buttonTitle
                             message:NSLocalizedString(@"tour.name", nil)
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                             otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
      dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
      UITextField *textField = [dialog textFieldAtIndex:0];
      textField.keyboardAppearance = UIKeyboardAppearanceAlert;
      dialog.tag = TourViewControllerNewTour;
      [dialog show];
      [dialog release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.action.sheet.button2", nil)]) { // Tour öffnen...
      UIActionSheet *sheet = [[UIActionSheet alloc]
                              initWithTitle:buttonTitle
                              delegate:self
                              cancelButtonTitle:nil//NSLocalizedString(@"cancel", nil)
                              destructiveButtonTitle:nil
                              otherButtonTitles:nil];
      ParkData *parkData = [ParkData getParkData:parkId];
      NSArray *tourNames = [parkData getTourNames];
      for (NSString *tourName in tourNames) {
        [sheet addButtonWithTitle:tourName];
      }
      sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"cancel", nil)];  // bug in iOS 4.2
      sheet.tag = TourViewControllerActionSheetOpenTour;
      [sheet showFromToolbar:bottomToolbar];
      UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
      backgroundView.backgroundColor = [Colors darkBlue];
      backgroundView.opaque = NO;
      backgroundView.alpha = 0.5;
      [sheet insertSubview:backgroundView atIndex:0];
      [backgroundView release];
      [sheet release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.action.sheet.button3", nil)]) { // Tour umbenennen...
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:buttonTitle
                             message:NSLocalizedString(@"tour.name", nil)
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                             otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
      dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
      UITextField *textField = [dialog textFieldAtIndex:0];
      textField.keyboardAppearance = UIKeyboardAppearanceAlert;
      ParkData *parkData = [ParkData getParkData:parkId];
      textField.text = parkData.currentTourName;
      dialog.tag = TourViewControllerRenameTour;
      [dialog show];
      //[UIMenuController sharedMenuController].menuVisible = NO;
      //[textField selectAll:self];
      [dialog release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.action.sheet.button4", nil)]) { // Tour löschen...
      UIActionSheet *sheet = [[UIActionSheet alloc]
                              initWithTitle:NSLocalizedString(@"tour.delete.sheet.title", nil)
                              delegate:self
                              cancelButtonTitle:nil
                              destructiveButtonTitle:NSLocalizedString(@"yes", nil)
                              otherButtonTitles:NSLocalizedString(@"no", nil), nil];
      sheet.tag = TourViewControllerActionSheetDeleteTour;
      [sheet showFromToolbar:bottomToolbar];
      UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
      backgroundView.backgroundColor = [Colors darkBlue];
      backgroundView.opaque = NO;
      backgroundView.alpha = 0.5;
      [sheet insertSubview:backgroundView atIndex:0];
      [backgroundView release];
      [sheet release];
    }
  } else if (actionSheet.tag == TourViewControllerActionSheetAddAction) {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.add.action.sheet.button1", nil)]) { // Empfehlungen hinzufügen
      AttractionListViewController *controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:@"MENU_ATTRACTION_BY_PROFILE" title:buttonTitle];
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.add.action.sheet.button2", nil)]) { // Tourvorschläge hinzufügen
      ParkData *parkData = [ParkData getParkData:parkId];
      UIActionSheet *sheet = [[UIActionSheet alloc]
                              initWithTitle:buttonTitle
                              delegate:self
                              cancelButtonTitle:nil //NSLocalizedString(@"cancel", nil)
                              destructiveButtonTitle:nil
                              otherButtonTitles:nil];
      NSArray *a = [parkData getTourSuggestions];
      for (NSString *tourName in a) {
        [sheet addButtonWithTitle:tourName];
      }
      sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"cancel", nil)];  // bug in iOS 4.2
      sheet.tag = TourViewControllerActionSheetRecommendations;
      [sheet showFromToolbar:bottomToolbar];
      UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
      backgroundView.backgroundColor = [Colors darkBlue];
      backgroundView.opaque = NO;
      backgroundView.alpha = 0.5;
      [sheet insertSubview:backgroundView atIndex:0];
      [backgroundView release];
      [sheet release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.add.action.sheet.button3", nil)]) { // Attraktionen hinzufügen
      AttractionListViewController *controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:@"MENU_ATTRACTION" title:buttonTitle];
      [controller setSubtitleName:NSLocalizedString(@"all", nil)];
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.add.action.sheet.button4", nil)]) { // WC hinzufügen
      AttractionListViewController *controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:@"MENU_RESTROOM" title:buttonTitle];
      [controller setSubtitleName:NSLocalizedString(@"all", nil)];
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.add.action.sheet.button5", nil)]) { // Service hinzufügen
      AttractionListViewController *controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:@"MENU_SERVICE" title:buttonTitle];
      [controller setSubtitleName:NSLocalizedString(@"all", nil)];
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.add.action.sheet.button6", nil)]) { // Shops hinzufügen
      AttractionListViewController *controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:@"MENU_SHOP" title:buttonTitle];
      [controller setSubtitleName:NSLocalizedString(@"all", nil)];
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.add.action.sheet.button7", nil)]) { // Gastronomie hinzufügen
      AttractionListViewController *controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:@"MENU_DINING" title:buttonTitle];
      [controller setSubtitleName:NSLocalizedString(@"all", nil)];
      [self presentViewController:controller animated:YES completion:nil];
      [controller release];
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"all", nil)]) { // Alle definierten Attraktionen hinzufügen
      NSDictionary *allAttractions = [Attraction getAllAttractions:parkId reload:NO];
      NSArray *allAttractionIds = [allAttractions allKeys];
      int n = (int)[allAttractionIds count]-1;
      ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      for (int i = 0; i < n; ++i) {
        [tourData add:[allAttractionIds objectAtIndex:i] startTime:0.0];
      }
      [tourData add:[allAttractionIds objectAtIndex:n] startTime:[[NSDate date] timeIntervalSince1970]]; // check if date is needed because of optimize
      [tourData optimize];
    }    
  } else if (actionSheet.tag == TourViewControllerActionSheetTourItemsAction) {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.items.action.sheet.button1", nil)]) { // Einträge bearbeiten
      ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      if ([tourData count] == 0) {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"error", nil)
                               message:NSLocalizedString(@"tour.items.edit.error", nil)
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
      } else {
        canMoveRow = YES;
        doneBottomToolbar.hidden = NO;
        bottomToolbar.hidden = YES;
        editBottomToolbar.hidden = YES;
        [tourTableView setEditing:YES animated:YES];
        [self updateViewValues:0.0 enableScroll:NO];
      }
    } else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.items.action.sheet.button2", nil)]) { // Alle Einträge löschen
      UIActionSheet *sheet = [[UIActionSheet alloc]
                              initWithTitle:NSLocalizedString(@"tour.items.delete.sheet.title", nil)
                              delegate:self
                              cancelButtonTitle:nil
                              destructiveButtonTitle:NSLocalizedString(@"yes", nil)
                              otherButtonTitles:NSLocalizedString(@"no", nil), nil];
      sheet.tag = TourViewControllerActionSheetDeleteTourItems;
      [sheet showFromToolbar:bottomToolbar];
      UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
      backgroundView.backgroundColor = [Colors darkBlue];
      backgroundView.opaque = NO;
      backgroundView.alpha = 0.5;
      [sheet insertSubview:backgroundView atIndex:0];
      [backgroundView release];
      [sheet release];
      /* ToDo: ParkData *parkData = [ParkData getParkData:parkId];
       TourData *tourData = [parkData getTourData:parkData.currentTourName];
       [self updateViewValues:[tourData optimize]];*/
    /*} else if ([buttonTitle isEqualToString:NSLocalizedString(@"tour.items.action.sheet.button4", nil)]) { // Reihenfolge optimieren
      ToDo: ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      [self updateViewValues:[tourData optimize]];*/
    }
  } else if (actionSheet.tag == TourViewControllerActionSheetDeleteTour) {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
      ParkData *parkData = [ParkData getParkData:parkId];
      if ([[parkData getTourNames] count] <= 1) {
        [parkData deleteTour:parkData.currentTourName];
        TourData *tourData = [parkData getTourData:parkData.currentTourName];
        [tourData updateTourData:[now timeIntervalSince1970]];
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"tour.action.sheet.button1", nil)
                               message:NSLocalizedString(@"tour.name", nil)
                               delegate:self
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textField = [dialog textFieldAtIndex:0];
        textField.keyboardAppearance = UIKeyboardAppearanceAlert;
        textField.text = parkData.currentTourName;
        dialog.tag = TourViewControllerRenameNewTour;
        [dialog show];
        //[UIMenuController sharedMenuController].menuVisible = NO;
        //[textField selectAll:self];
        [dialog release];
      } else {
        [parkData deleteTour:parkData.currentTourName];
        actionSheet.tag = TourViewControllerActionSheetTourAction;
        // Tour öffnen (redudanter code!)
        UIActionSheet *sheet = [[UIActionSheet alloc]
                                initWithTitle:NSLocalizedString(@"tour.action.sheet.button2", nil)
                                delegate:self
                                cancelButtonTitle:nil//NSLocalizedString(@"cancel", nil)
                                destructiveButtonTitle:nil
                                otherButtonTitles:nil];
        ParkData *parkData = [ParkData getParkData:parkId];
        NSArray *tourNames = [parkData getTourNames];
        for (NSString *tourName in tourNames) {
          [sheet addButtonWithTitle:tourName];
        }
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"cancel", nil)];  // bug in iOS 4.2
        sheet.tag = TourViewControllerActionSheetOpenTour;
        [sheet showFromToolbar:bottomToolbar];
        UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
        backgroundView.backgroundColor = [Colors darkBlue];
        backgroundView.opaque = NO;
        backgroundView.alpha = 0.5;
        [sheet insertSubview:backgroundView atIndex:0];
        [backgroundView release];
        [sheet release];
      }
    }
  } else if (actionSheet.tag == TourViewControllerActionSheetDeleteTourItems) {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
      ParkData *parkData = [ParkData getParkData:parkId];
      TourData *tourData = [parkData getTourData:parkData.currentTourName];
      if ([parkData completeCurrentTrack]) [tourData clear];
      else {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"error", nil)
                               message:NSLocalizedString(@"tour.track.save.error", nil)
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
      }
      [self updateViewValues:0.0 enableScroll:NO];
    }
  } else if (actionSheet.tag == TourViewControllerActionSheetRecommendations) {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
      NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
      ParkData *parkData = [ParkData getParkData:parkId];
      NSArray *attractionIds = [parkData getTourSuggestion:buttonTitle];
      if (attractionIds != nil && [attractionIds count] > 0) {
        AttractionListViewController *controller = [[AttractionListViewController alloc] initWithNibName:@"AttractionListView" owner:self parkId:parkId category:nil title:buttonTitle];
        [controller setListOfAttractionIds:attractionIds];
        [self presentViewController:controller animated:YES completion:nil];
        [controller release];
      }
    }
  } else if (actionSheet.tag == TourViewControllerActionSheetOpenTour) {
    if (buttonIndex != actionSheet.cancelButtonIndex) {
      NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
      ParkData *parkData = [ParkData getParkData:parkId];
      //if (parkData.currentTrackData == nil) {
      NSLog(@"Open tour %@", buttonTitle);
      if (![buttonTitle isEqualToString:parkData.currentTourName]) {
        [parkData setCurrentTourName:buttonTitle];
      }
      [self updateViewValues:0.0 enableScroll:NO];  // falls es über löschen aufgerufen wurde
      /* ToDo: } else {
       Problem mit Übergabe der ausgewählten Tour
       UIAlertView *dialog = [[UIAlertView alloc]
       initWithTitle:NSLocalizedString(@"tour.track.close.title", nil)
       message:NSLocalizedString(@"tour.track.close.text", nil)
       delegate:self
       cancelButtonTitle:NSLocalizedString(@"no", nil)
       otherButtonTitles:NSLocalizedString(@"yes", nil), nil];
       dialog.tag = TourViewControllerActionSheetOpenTour;
       [dialog show];
       [dialog release];
       }*/
    }
  }
}

#pragma mark -
#pragma mark Facebook delegate

static ImagesSelectionViewController *imagesSelectionViewController = nil;
static int indexOfPhotosToPublishAtFacebook = 0;
static NSString *facebookAlbumId = nil;

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  [super dismissModalViewControllerAnimated:animated];
  if (imagesSelectionViewController != nil && !imagesSelectionViewController.canceled) {
    facebook = [[Facebook alloc] initWithAppId:@"218295878229334" andDelegate:self];
    if (![facebook isSessionValid]) [facebook authorize:[NSArray arrayWithObjects:@"publish_stream", nil]];
    /*Attraction *attraction = [Attraction getAttraction:@"dphl" attractionId:@"a01"];
     ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"https://graph.facebook.com/me/feed"]];
     [request setPostValue:@"Phantasialand Tour am 02.09.2011" forKey:@"message"];
     [request setPostValue:attraction.stringAttractionName forKey:@"name"];
     [request setPostValue:[NSString stringWithFormat:@"...im %@ (%@)", parkName, city] forKey:@"caption"];
     [request setPostValue:@"Von 09:54 Uhr bis 10:33 Uhr war ich in dieser Attraktion.\nMeine Bewertung: ★★★★ (4 von 5)" forKey:@"description"];
     [request setPostValue:@"http://www.inpark.info" forKey:@"link"];
     [request setPostValue:@"http://www.inpark.info/data/dphl/a01/dphl - a01 - maus au chocolat.jpg" forKey:@"picture"];
     [request setPostValue:facebook.accessToken forKey:@"access_token"];*/
    //[request setDidFinishSelector:@selector(postToWallFinished:)];
  } else if (viewInitialized) {
    [tourTableView reloadData];
  }
}

-(void)fbDidLogin {
  if (facebook.accessToken != nil) NSLog(@"did log in at Facebook with valid access token");
  else NSLog(@"missing Facebook access token");
  // Create photo album
  indexOfPhotosToPublishAtFacebook = 0;
  ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"https://graph.facebook.com/me/albums"]];
  [request setPostValue:imagesSelectionViewController.titleName forKey:@"name"];
  [request setPostValue:imagesSelectionViewController.description forKey:@"description"];
  [request setPostValue:imagesSelectionViewController.location forKey:@"location"];
  [request setPostValue:facebook.accessToken forKey:@"access_token"];
  [request setDidFinishSelector:@selector(sendPhotosToFacebookAlbum:)];
  [request setDelegate:self];
  //[request setTimeOutSeconds:240];
  [request startAsynchronous];
}

-(void)fbDidNotLogin:(BOOL)cancelled {
  UIAlertView *dialog = [[UIAlertView alloc]
                         initWithTitle:NSLocalizedString(@"error", nil)
                         message:NSLocalizedString(@"facebook.login.failed", nil)
                         delegate:nil
                         cancelButtonTitle:NSLocalizedString(@"ok", nil)
                         otherButtonTitles:nil];
  [dialog show];
  [dialog release];
}

-(void)fbDidLogout {
}

// Facebook
-(void)publishTrackAtFacebook:(TrackData *)trackData {
  double completedDistance = 0.0;
  NSDate *startTrack = nil;
  NSDate *endTrack = nil;
  NSArray *attractionsOnTrack = [trackData getAllAttractionsFromGPXFile:&completedDistance start:&startTrack end:&endTrack];

  /*NSMutableArray *attractionsOnTrack2 = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
  NSMutableArray *trackList = [[[NSMutableArray alloc] initWithCapacity:20] autorelease];
  [attractionsOnTrack2 addObjectsFromArray:attractionsOnTrack];
  for (int i = 1;; ++i) {
    NSString *s = [NSString stringWithFormat:@"%@ - %d", trackData.trackName, i];
    ParkData *parkData = [ParkData getParkData:parkId];
    TrackData *trackData2 = [parkData getTrackData:s];
    if (trackData2 == nil) break;
    double completedDistance2 = 0.0;
    NSDate *startTrack2 = nil;
    NSDate *endTrack2 = nil;
    NSArray *attractionsOnTrack3 = [trackData2 getAllAttractionsFromGPXFile:&completedDistance2 start:&startTrack2 end:&endTrack2];
    NSLog(@"completed:%f start:%@ end:%@, attractionsOnTrack3=%@", completedDistance2, startTrack2, endTrack2, attractionsOnTrack3);
    completedDistance += completedDistance2;
    [trackList addObject:trackData2];
    endTrack = endTrack2;
    [attractionsOnTrack2 addObjectsFromArray:attractionsOnTrack3];
  }
  attractionsOnTrack = attractionsOnTrack2;*/
  
  //attractionsOnTrack = [NSArray arrayWithObjects:[Attraction getAttraction:parkId attractionId:@"a42"], [Attraction getAttraction:parkId attractionId:@"a27"], [Attraction getAttraction:parkId attractionId:@"a25"], [Attraction getAttraction:parkId attractionId:@"a34"], [Attraction getAttraction:parkId attractionId:@"a35"], [Attraction getAttraction:parkId attractionId:@"a12"], [Attraction getAttraction:parkId attractionId:@"a13"], nil];
  int countAttractions = (int)[attractionsOnTrack count];
  if (countAttractions == 0) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"info", nil)
                           message:NSLocalizedString(@"facebook.no.attraction.visited", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
    return;
  }
  SettingsData *settings = [SettingsData getSettingsData];
  NSDictionary *details = [MenuData getParkDetails:parkId cache:YES];
  NSString *parkName = [details objectForKey:@"Parkname"];
  NSString *city = [details objectForKey:@"Stadt"];
  NSString *country = [MenuData objectForKey:@"Land" at:details];
  NSString *distance = distanceToString([settings isMetricMeasure], completedDistance);
  NSString *name = [NSString stringWithFormat:NSLocalizedString(@"facebook.albums.name", nil), parkName, [CalendarData stringFromDate:startTrack considerTimeZoneAbbreviation:nil], distance];
  NSString *location = [NSString stringWithFormat:@"%@, %@, %@", parkName, city, country];
  NSString *description = NSLocalizedString(@"facebook.albums.description", nil);
  NSString *fileName = [trackData gpxFilePath];
  NSError *error = nil;
  NSString *content = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];
  if (error != nil) NSLog(@"Error to read file '%@' (%@)", fileName, [error localizedDescription]);
  NSMutableArray *information = [[NSMutableArray alloc] initWithCapacity:countAttractions];
  ParkData *parkData = [ParkData getParkData:parkId];
  NSDate *start = nil;
  NSDate *end = nil;
  BOOL trainEntry = YES;
  //int idx = -1;
  for (Attraction *attraction in attractionsOnTrack) {
    start = nil;
    NSString *attractionInformation = nil;
    [trackData timeframeAtAttraction:attraction afterTime:end fromGPXContentsOfFile:content start:&start end:&end];
    /*if (start == nil && end == nil && ++idx < trackList.count) {
      trackData = [trackList objectAtIndex:idx];
      fileName = [trackData gpxFilePath];
      [content release];
      content = [[NSString alloc] initWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];
      if (error != nil) NSLog(@"Error to read file '%@' (%@)", fileName, [error localizedDescription]);
      [trackData timeframeAtAttraction:attraction afterTime:end fromGPXContentsOfFile:content start:&start end:&end];
    }*/
    if ([attraction isTrain]) {
      if (trainEntry) attractionInformation = [NSString stringWithFormat:NSLocalizedString(@"facebook.attraction.information.train.entry", nil), attraction.stringAttractionName, [CalendarData stringFromTimeLong:start considerTimeZoneAbbreviation:nil]];
      else attractionInformation = [NSString stringWithFormat:NSLocalizedString(@"facebook.attraction.information.train.exit", nil), attraction.stringAttractionName, [CalendarData stringFromTimeLong:start considerTimeZoneAbbreviation:nil]];
      trainEntry = !trainEntry;
    } else if (end == nil) {
      attractionInformation = [NSString stringWithFormat:NSLocalizedString(@"facebook.attraction.information.train.entry", nil), attraction.stringAttractionName, [CalendarData stringFromTimeLong:start considerTimeZoneAbbreviation:nil]];
      trainEntry = YES;
    } else {
      attractionInformation = [NSString stringWithFormat:NSLocalizedString(@"facebook.attraction.information", nil), [CalendarData stringFromTimeLong:start considerTimeZoneAbbreviation:nil], [CalendarData stringFromTimeLong:end considerTimeZoneAbbreviation:nil], attraction.stringAttractionName];
      trainEntry = YES;
    }
    NSString *rating = [parkData getPersonalRatingAsStars:attraction.attractionId];
    if (rating != nil) {
      if (attractionInformation == nil) attractionInformation = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"rating.rating", nil), rating];
      else attractionInformation = [NSString stringWithFormat:@"%@. %@ %@", attractionInformation, NSLocalizedString(@"rating.rating", nil), rating];
    }
    if (attractionInformation != nil) [information addObject:attractionInformation];
  }
  [content release];
  description = [description stringByReplacingOccurrencesOfString:@"%PARKNAME%" withString:parkName];
  description = [NSString stringWithFormat:description, [CalendarData stringFromTimeLong:startTrack considerTimeZoneAbbreviation:nil], [CalendarData stringFromTimeLong:endTrack considerTimeZoneAbbreviation:nil], countAttractions, distance];
  imagesSelectionViewController = [[ImagesSelectionViewController alloc] initWithNibName:@"ImagesSelectionView" owner:self parkId:parkId attractions:attractionsOnTrack titleName:name location:location description:description information:information];
  [self presentViewController:imagesSelectionViewController animated:YES completion:nil];
  [information release];
  //[controller release];
}

-(void)resendPhotosToFacebookAlbum:(ASIHTTPRequest *)request {
  NSLog(@"request failed: %@", [request.error localizedDescription]);
  if (indexOfPhotosToPublishAtFacebook > 0) {
    --indexOfPhotosToPublishAtFacebook;
    NSLog(@"resend photo for '%s' to album", [imagesSelectionViewController attractionNameAtIndex:indexOfPhotosToPublishAtFacebook]);
    [self sendPhotosToFacebookAlbum:request];
  }
}

-(void)sendPhotosToFacebookAlbum:(ASIHTTPRequest *)request {
  if (indexOfPhotosToPublishAtFacebook < [imagesSelectionViewController.imagePathes count]) {
    if (indexOfPhotosToPublishAtFacebook == 0 && facebookAlbumId == nil) {
      NSString *responseString = [request responseString];
      NSMutableDictionary *responseJSON = [responseString JSONValue];
      facebookAlbumId = [[responseJSON objectForKey:@"id"] retain];
      NSLog(@"photo album id is: %@", facebookAlbumId);
    }
    //NSString *message = [NSString stringWithFormat:@"Von 09:54 Uhr bis 10:33 Uhr war ich in der Attraktion \"%@\".\nMeine Bewertung: ★★★★ (4 von 5)", attraction.stringAttractionName];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/photos", facebookAlbumId]];
    ASIFormDataRequest *newRequest = [ASIFormDataRequest requestWithURL:url];
    NSString *imagePath = [imagesSelectionViewController.imagePathes objectAtIndex:indexOfPhotosToPublishAtFacebook];
    NSLog(@"add photo '%s' to album", [imagesSelectionViewController attractionNameAtIndex:indexOfPhotosToPublishAtFacebook]);
    [newRequest addFile:imagePath forKey:@"file"];
    [newRequest setPostValue:[NSString stringWithFormat:@"%@\n%@", imagesSelectionViewController.description, [imagesSelectionViewController.information objectAtIndex:indexOfPhotosToPublishAtFacebook]] forKey:@"name"];
    [newRequest setPostValue:facebook.accessToken forKey:@"access_token"];
    [newRequest setDidFinishSelector:@selector(sendPhotosToFacebookAlbum:)];
    [newRequest setDidFailSelector:@selector(resendPhotosToFacebookAlbum:)];
    //[newRequest setDidFinishSelector:@selector(sendToPhotosFinished:)];
    [newRequest setDelegate:self];
    [newRequest setTimeOutSeconds:240];
    [newRequest startAsynchronous];
    ++indexOfPhotosToPublishAtFacebook;
  } else {
    [imagesSelectionViewController release];
    imagesSelectionViewController = nil;
    [facebookAlbumId release];
    facebookAlbumId = nil;
    indexOfPhotosToPublishAtFacebook = 0;
  }
}

  /*-(void)sendToPhotosFinished:(ASIHTTPRequest *)request {
   NSString *responseString = [request responseString];
   NSMutableDictionary *responseJSON = [responseString JSONValue];
   NSString *photoId = [responseJSON objectForKey:@"id"];
   NSLog(@"Photo id is: %@", photoId);
   NSString *urlString = [NSString stringWithFormat:
   @"https://graph.facebook.com/%@?access_token=%@", photoId, 
   [_accessToken stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
   ASIHTTPRequest *newRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
   [newRequest setDidFinishSelector:@selector(getFacebookPhotoFinished:)];
   [newRequest setDelegate:self];
   [newRequest startAsynchronous];
   }
   
   - (void)getFacebookPhotoFinished:(ASIHTTPRequest *)request
   {
   NSString *responseString = [request responseString];
   NSLog(@"Got Facebook Photo: %@", responseString);
   
   NSMutableDictionary *responseJSON = [responseString JSONValue];   
   
   NSString *link = [responseJSON objectForKey:@"link"];
   if (link == nil) return;   
   NSLog(@"Link to photo: %@", link);
   
   NSURL *url = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
   ASIFormDataRequest *newRequest = [ASIFormDataRequest requestWithURL:url];
   [newRequest setPostValue:@"I'm learning how to post to Facebook from an iPhone app!" forKey:@"message"];
   [newRequest setPostValue:@"Check out the tutorial!" forKey:@"name"];
   [newRequest setPostValue:@"This tutorial shows you how to post to Facebook using the new Open Graph API." forKey:@"caption"];
   [newRequest setPostValue:@"From Ray Wenderlich's blog - an blog about iPhone and iOS development." forKey:@"description"];
   [newRequest setPostValue:@"http://www.raywenderlich.com" forKey:@"link"];
   [newRequest setPostValue:link forKey:@"picture"];
   [newRequest setPostValue:_accessToken forKey:@"access_token"];
   //[newRequest setDidFinishSelector:@selector(postToWallFinished:)];
   [newRequest setDelegate:self];
   [newRequest startAsynchronous];
   }*/
   
#pragma mark -
#pragma mark Waiting time data delegate

-(void)waitingTimeDataUpdated {
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [parkData getTourData:parkData.currentTourName];
  [tourData updateTourData:[now timeIntervalSince1970]];
  [parkData save:NO];
  [tourTableView reloadData];
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  viewInitialized = NO;
}

-(void)viewDidUnload {
  [super viewDidUnload];
  viewInitialized = NO;
  /*parkId = nil;
  now = nil;
  routeViews = nil;*/
  overlay = nil;
  originalDistanceLabelColor = nil;
  highLightTableCell = nil;
  topNavigationBar = nil;
  navigationTitle = nil;
  tourTableView = nil;
  startActivityIndicator = nil;
  totalTourLabel = nil;
  helpButton = nil;
  locationButton = nil;
  bottomToolbar = nil;
  editBottomToolbar = nil;
  doneBottomToolbar = nil;
  timePickerBottomToolbar = nil;
  tourStartButton = nil;
  tourMapButton = nil;
  tourCompletedButton = nil;
  tourButton = nil;
  addButton = nil;
  tourItemsButton = nil;
  editButton = nil;
  timePickerClearButton = nil;
  timePickerDoneButton = nil;
  cellOwner = nil;
  backgroundTimePicker = nil;
  timePicker = nil;
  mapView = nil;
  copyrightLabel = nil;
  accuracyLabel = nil;
}

-(void)dealloc {
  /*[parkId release];
  [now release];
  [routeViews release];*/
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  ParkData *parkData = [ParkData getParkData:parkId];
  WaitingTimeData *waitingTimeData = [parkData getWaitingTimeData];
  [waitingTimeData unregisterViewController];
  [facebook release];
  facebook = nil;
  [overlay release];
  [originalDistanceLabelColor release];
  [highLightTableCell release];
  [topNavigationBar release];
  [navigationTitle release];
  [tourTableView release];
  [startActivityIndicator release];
  [totalTourLabel release];
  [helpButton release];
  [locationButton release];
  [bottomToolbar release];
  [editBottomToolbar release];
  [doneBottomToolbar release];
  [timePickerBottomToolbar release];
  [tourStartButton release];
  [tourMapButton release];
  [tourCompletedButton release];
  [tourButton release];
  [addButton release];
  [tourItemsButton release];
  [editButton release];
  [timePickerClearButton release];
  [timePickerDoneButton release];
  [cellOwner release];
  [backgroundTimePicker release];
  [timePicker release];
  [mapView release];
  mapView = nil;
  [copyrightLabel release];
  [accuracyLabel release];
  [super dealloc];
}

@end
