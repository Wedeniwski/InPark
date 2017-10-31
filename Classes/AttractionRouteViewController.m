//
//  AttractionRouteViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 09.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "AttractionRouteViewController.h"
#import "GeneralInfoViewController.h"
#import "AttractionViewController.h"
#import "AttractionAnnotation.h"
#import "RouteAnnotation.h"
#import "Attraction.h"
#import "RouteView.h"
#import "MapPin.h"
#import "ParkData.h"
#import "TourData.h"
#import "MenuData.h"
#import "IPadHelper.h"
#import "SettingsData.h"
#import "HelpData.h"
#import "ImageData.h"
#import "Conversions.h"
#import "Colors.h"

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395

@implementation AttractionRouteViewController

static NSString *parkId = nil;
static NSString *attractionId = nil;

@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize mapView;
@synthesize copyrightLabel, accuracyLabel;
@synthesize locationButton;
@synthesize pathTableView;

-(BOOL)addAllForAttractionId:(NSString *)attractionId  setCenter:(BOOL)setCenter {
  ParkData *parkData = [ParkData getParkData:parkId];
  NSArray *allAtrractionIds = [parkData allAttractionRelatedLocationIdsOf:attractionId];
  for (NSString *aId in allAtrractionIds) {
    MapPin *pin = [[MapPin alloc] initWithAttractionId:aId parkId:parkId];
    [mapView addAnnotation:pin];
    if (setCenter) {
      if (![AttractionRouteViewController setCenterCoordinate:pin.coordinate onMapView:mapView zoomLevel:17 animated:NO]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
      setCenter = NO;
    }
    [pin release];
  }
  return !setCenter;
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
    if (user != nil) [[user superview] bringSubviewToFront:user];
  }
}

-(MKCoordinateRegion)addRouteViewPathFrom:(NSString *)startAttractionId to:(NSString *)endAttractionId {
  ParkData *parkData = [ParkData getParkData:parkId];
  TourData *tourData = [[TourData alloc] initWithParkId:parkId tourName:@""];
  TourItem *tourItem = [[TourItem alloc] initWithAttractionId:endAttractionId entry:endAttractionId exit:startAttractionId];
  [tourData add:tourItem startTime:0.0];
  [tourItem release];
  NSMutableArray *attractionIdsOfDescription = [[NSMutableArray alloc] initWithCapacity:50];
  detailedTourDescription = [[tourData createRouteDescriptionFrom:startAttractionId currentPosition:NO to:endAttractionId attractionIdsOfDescription:attractionIdsOfDescription] retain];
  [tourDistance release];
  NSArray *path = nil;
  double distance = [parkData distance:startAttractionId fromAll:NO toAttractionId:endAttractionId toAll:YES path:&path];
  SettingsData *settings = [SettingsData getSettingsData];
  tourDistance = [distanceToString([settings isMetricMeasure], distance) retain];
  [walkingTime release];
  walkingTime = [[tourData getFormat:[tourData getWalkingTime:distance]] retain];
  [pathTableView reloadData];
  [tourData release];
  [mapView removeAnnotations:mapView.annotations];
  [self addAllForAttractionId:attractionId setCenter:NO];
  NSLog(@"Route from startAttractionId: %@", startAttractionId);
  if (path == nil) NSLog(@"Error! Missing path between %@ and %@", startAttractionId, endAttractionId);
  int startAttractionIdx = -1;
  for (NSNumber *nIdx in path) {
    int aIdx = [nIdx intValue];
    if (startAttractionIdx >= 0 && aIdx >= 0) {
      //NSLog(@"path: %@ (%d) - %@ (%d)", startAttractionId, startAttractionIdx, aId, aIdx);
      TrackSegmentIdOrdered *segmentId = [TrackSegment getTrackSegmentId:startAttractionIdx toAttractionIdx:aIdx];
      TrackSegment *t = [parkData.trackSegments objectForKey:segmentId];
      if (t == nil) NSLog(@"Error! Missing track segment between %@ and %@", [parkData.allAttractionIds objectAtIndex:startAttractionIdx], [parkData.allAttractionIds objectAtIndex:aIdx]);
      else {
        RouteAnnotation *routeAnnotation = [[RouteAnnotation alloc] initWithTrackSegment:t];
        [mapView addAnnotation:routeAnnotation];
        [routeAnnotation release];
      }
    }
    startAttractionIdx = aIdx;
  }
  double minLat = 0.0;
  double maxLat = 0.0;
  double minLon = 0.0;
  double maxLon = 0.0;
  int i = 0;
  int l = (int)path.count;
  BOOL first = YES;
  for (NSString *aId in attractionIdsOfDescription) {
    TrackPoint *p = [parkData getAttractionLocation:[parkData firstEntryAttractionIdOf:aId]];
    double d = p.latitude;
    if (minLat == 0.0) minLat = maxLat = d;
    else if (d < minLat) minLat = d;
    else if (d > maxLat) maxLat = d;
    d = p.longitude;
    if (minLon == 0.0) minLon = maxLon = d;
    else if (d < minLon) minLon = d;
    else if (d > maxLon) maxLon = d;
    if (![aId isEqualToString:attractionId]) {
      if (first) {
        first = NO;
      } else {
        while (i < l) {
          NSString *bId = [parkData.allAttractionIds objectAtIndex:[[path objectAtIndex:i] intValue]];
          NSString *cId = [Attraction getShortAttractionId:bId];
          if ([cId isEqualToString:aId]) {
            aId = bId;
            ++i;
            break;
          }
          ++i;
        }
      }
      MapPin *pin = [[MapPin alloc] initWithAttractionId:aId parkId:parkId];
      if ([pin hasImage]) {
        [mapView addAnnotation:pin];
        //if ([aId isEqualToString:attractionId]) {
        //  MKAnnotationView *v = [mapView viewForAnnotation:pin];
        //}
      }
      [pin release];
    }
  }
  [attractionIdsOfDescription release];
  MKCoordinateRegion r;
  r.center.latitude = (minLat+maxLat)/2;
  r.center.longitude = (minLon+maxLon)/2;
  r.span.latitudeDelta = maxLat-minLat;
  r.span.longitudeDelta = maxLon-minLon;
  return r;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractionId:(NSString *)aId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    [parkId release];
    parkId = [pId retain];
    [attractionId release];
    attractionId = [aId retain];
  }
  return self;
}

-(void)viewWillAppear:(BOOL)animated {
  originalPathTableViewFrame = pathTableView.frame;
  if (detailedTourDescription == nil || detailedTourDescription.count <= 2) {
    //pathTableView.hidden = YES;
    SettingsData *settings = [SettingsData getSettingsData];
    BOOL isPortraitScreen = [settings isPortraitScreen];
    CGRect r = [[UIScreen mainScreen] bounds];
    float height = (isPortraitScreen)? r.size.height : r.size.width;
    height -= mapView.frame.origin.y;
    locationButton.frame = CGRectMake(locationButton.frame.origin.x, height-locationButton.frame.size.height, locationButton.frame.size.width, locationButton.frame.size.height);
    copyrightLabel.frame = CGRectMake(copyrightLabel.frame.origin.x, height-copyrightLabel.frame.size.height, copyrightLabel.frame.size.width, copyrightLabel.frame.size.height);
    float h = pathTableView.rowHeight;
    mapView.frame = CGRectMake(mapView.frame.origin.x, mapView.frame.origin.y, mapView.frame.size.width, height-h);
    pathTableView.frame = CGRectMake(originalPathTableViewFrame.origin.x, originalPathTableViewFrame.origin.y+originalPathTableViewFrame.size.height-h, originalPathTableViewFrame.size.width, h);
  } else {
    locationButton.frame = CGRectMake(locationButton.frame.origin.x, originalPathTableViewFrame.origin.y-locationButton.frame.size.height, locationButton.frame.size.width, locationButton.frame.size.height);
    copyrightLabel.frame = CGRectMake(copyrightLabel.frame.origin.x, originalPathTableViewFrame.origin.y-copyrightLabel.frame.size.height, copyrightLabel.frame.size.width, copyrightLabel.frame.size.height);
    mapView.frame = CGRectMake(mapView.frame.origin.x, mapView.frame.origin.y, mapView.frame.size.width, pathTableView.frame.origin.y-topNavigationBar.frame.origin.y-topNavigationBar.frame.size.height);
    [pathTableView reloadData];
  }
}

-(void)setMapType {
  if (overlay != nil) {
    [overlay release];
    overlay = nil;
    [mapView removeOverlays:mapView.overlays];
  }
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
    ParkData *parkData = [ParkData getParkData:parkId];
    copyrightLabel.text = (parkData.mapCopyright != nil)? parkData.mapCopyright : NSLocalizedString(@"copyright", nil);
  }
}

-(void)viewDidLoad {
  [super viewDidLoad];
  topNavigationBar.tintColor = [Colors darkBlue];
  ParkData *parkData = [ParkData getParkData:parkId];
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  pathTableView.backgroundColor = [Colors lightBlue];
  pathTableView.backgroundView = nil;
  pathTableView.rowHeight = 14.0f;
  mapView.delegate = self;
  manuallyChangingMapRect = YES;
  MKCoordinateRegion region = [parkData getParkRegion];
  [mapView setRegion:region animated:NO];
  //[mapView regionThatFits:region];
  lastGoodMapRect = mapView.visibleMapRect;
  manuallyChangingMapRect = NO;
  refreshRoute = YES;
  previousZoomScale = 0.0;
  overlay = nil;
  [self setMapType];
  locationButton.selected = NO;
  //[locationButton setImage:[ImageData makeBackgroundImage:[locationButton imageForState:UIControlStateNormal]] forState:UIControlStateSelected];
  if ([LocationData isLocationDataStarted]) {
    LocationData *locData = [LocationData getLocationData];
    [locData registerViewController:self];
    mapView.showsUserLocation = YES;
    locationButton.hidden = NO;
  } else {
    locationButton.hidden = YES;
  }
  titleNavigationItem.rightBarButtonItem = nil;
  [LocationData setAccuracyLabel:accuracyLabel forParkData:parkData addTime:YES];
  //if (PATHES_EDITION != nil) {
  titleNavigationItem.title = NSLocalizedString(@"attraction.route", nil);
  [self routeView:self];
  /*} else {
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:attractionId];
    if (attraction != nil) titleNavigationItem.title = attraction.stringAttractionName;
    if (![self addAllForAttractionId:attractionId setCenter:YES]) mapView.region = [parkData getParkRegion];
  }*/
}

-(void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  NSArray *selected = mapView.selectedAnnotations;
  if (selected == nil || [selected count] == 0) {
    for (id p in mapView.annotations) {
      if ([p isKindOfClass:[MapPin class]]) {
        MapPin *pin = (MapPin *)p;
        if ([pin.attractionId isEqualToString:attractionId]) {
          [mapView selectAnnotation:pin animated:NO];
          break;
        }
      }
    }
  }
  if (mapView.showsUserLocation && mapView.userLocation != nil) {
    UIView *user = [mapView viewForAnnotation:mapView.userLocation];
    if (user != nil) [mapView.superview bringSubviewToFront:user];
  }
}

-(void)didUpdateLocationData {
  ParkData *parkData = [ParkData getParkData:parkId];
  [LocationData setAccuracyLabel:accuracyLabel forParkData:parkData addTime:YES];
  //if (!titleNavigationItem.rightBarButtonItem.enabled && PATHES_EDITION == nil) titleNavigationItem.rightBarButtonItem.enabled = YES;
  if (locationButton.selected) {
#ifdef FAKE_CORE_LOCATION
    LocationData *locData = [LocationData getLocationData];
    CLLocationCoordinate2D coordinate = locData.locationManager.location.coordinate;
#else
    CLLocationCoordinate2D coordinate = mapView.userLocation.coordinate;
#endif
#ifdef DEBUG_MAP
    if (CLLocationCoordinate2DIsValid(coordinate)) {
      previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
      [mapView setCenterCoordinate:coordinate animated:YES];
    }
#else
    MKCoordinateRegion region = (overlay == nil)? [[ParkData getParkData:parkId] getParkRegion] : MKCoordinateRegionForMapRect(overlay.boundingMapRect);
    if (CLLocationCoordinate2DIsValid(coordinate) && [ParkOverlayView coordinate:coordinate isInside:region]) {
      previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
      [mapView setCenterCoordinate:coordinate animated:YES];
    }
#endif
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

#pragma mark -
#pragma mark Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return (tableView.frame.origin.y == originalPathTableViewFrame.origin.y)? [detailedTourDescription count] : 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"RouteCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
    cell.textLabel.font = [UIFont systemFontOfSize:10.0];
    cell.textLabel.textColor = [Colors hilightText];
  }
  int j = (int)indexPath.row;
  if (j == 0) {
    cell.textLabel.textAlignment = UITextAlignmentCenter;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
  } else {
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  if (tableView.frame.origin.y == originalPathTableViewFrame.origin.y) {
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
  } else {
    cell.textLabel.text = (detailedTourDescription == nil || detailedTourDescription.count == 0)? @"" : [NSString stringWithFormat:NSLocalizedString(@"tour.cell.route.text", nil), tourDistance, walkingTime];
  }
  return cell;
}

#pragma mark -
#pragma mark Table view delegate

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  int row = (int)indexPath.row;
  if (detailedTourDescription.count <= row) return 14.0f;
  NSString *t = [detailedTourDescription objectAtIndex:row];
  CGSize w0 = [t sizeWithFont:[UIFont systemFontOfSize:10.0f]];
  SettingsData *settings = [SettingsData getSettingsData];
  float w1 = [settings isPortraitScreen]? tableView.frame.size.width : [[UIScreen mainScreen] bounds].size.height;
  return (w0.width > w1-15.0f)? 28.0 : 14.0;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  return (indexPath.row > 0 || detailedTourDescription == nil || detailedTourDescription.count == 0)? nil : indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.7];
  if (tableView.frame.origin.y == originalPathTableViewFrame.origin.y) {
    float h = [self tableView:tableView heightForRowAtIndexPath:indexPath];
    tableView.frame = CGRectMake(originalPathTableViewFrame.origin.x, originalPathTableViewFrame.origin.y+originalPathTableViewFrame.size.height-h, originalPathTableViewFrame.size.width, h);
  } else {
    tableView.frame = originalPathTableViewFrame;
  }
  mapView.frame = CGRectMake(mapView.frame.origin.x, mapView.frame.origin.y, mapView.frame.size.width, tableView.frame.origin.y-topNavigationBar.frame.origin.y-topNavigationBar.frame.size.height);
  locationButton.frame = CGRectMake(locationButton.frame.origin.x, tableView.frame.origin.y-locationButton.frame.size.height, locationButton.frame.size.width, locationButton.frame.size.height);
  copyrightLabel.frame = CGRectMake(copyrightLabel.frame.origin.x, tableView.frame.origin.y-copyrightLabel.frame.size.height, copyrightLabel.frame.size.width, copyrightLabel.frame.size.height);
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  [UIView commitAnimations];
  [tableView reloadData];
}

#pragma mark -
#pragma mark Action sheet delegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
  SettingsData *settings = [SettingsData getSettingsData];
  NSArray *root = [MenuData getRootKey:@"PreferenceSpecifiers"];
  for (NSDictionary *entry in root) {
    NSString *identifier = [entry objectForKey:@"Key"];
    if ([identifier isEqualToString:@"MAP_TYPE"]) {
      NSArray *titles = [entry objectForKey:@"Titles"];
      int l = (int)[titles count];
      for (int i = 0; i < l; ++i) {
        NSString *title = [titles objectAtIndex:i];
        if ([title isEqualToString:buttonTitle]) {
          NSArray *values = [entry objectForKey:@"Values"];
          if (values != nil && i < [values count]) {
            NSString *value = [values objectAtIndex:i];
            if ([value length] > 0 && [settings setMapType:[value characterAtIndex:0]]) [self setMapType];
          }
        }
      }
      break;
    }
  }
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  //[mapView removeAnnotations:mapView.annotations];
  mapView.delegate = nil;  // map might still sending messages to the delegate
  if ([LocationData isLocationDataInitialized]) {
    LocationData *locData = [LocationData getLocationData];
    [locData unregisterViewController];
  }
  [delegate dismissModalViewControllerAnimated:YES];
}

-(IBAction)routeView:(id)sender {
  ParkData *parkData = [ParkData getParkData:parkId];
  TrackPoint *trackPoint = nil;
  if ([parkData isCurrentlyInsidePark]) {
    LocationData *locData = [LocationData getLocationData];
    CLLocation *location = locData.lastUpdatedLocation;
    trackPoint = [[TrackPoint alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
  }
  if (trackPoint == nil) trackPoint = [[parkData getAttractionLocation:[parkData getEntryOfPark:nil]] retain];
  TrackSegment *closestTrackSegment = [parkData closestTrackSegmentForTrackPoint:trackPoint];
  if (closestTrackSegment == nil) closestTrackSegment = [parkData closestTrackSegmentForTrackPoint:[parkData getAttractionLocation:[parkData getEntryOfPark:nil]]];
  if (closestTrackSegment != nil) {
    NSArray *path = [parkData getMinPathFrom:closestTrackSegment.from fromAll:NO toAllAttractionId:attractionId];
    NSString *startAttractionId = [path containsObject:closestTrackSegment.from]? closestTrackSegment.from : closestTrackSegment.to;
    MKCoordinateSpan span;
    MKCoordinateRegion pathRegion = [self addRouteViewPathFrom:startAttractionId to:attractionId];
    MapPin *pin = [[MapPin alloc] initWithAttractionId:startAttractionId parkId:parkId];
    double zoomLevel = 17.2;
    do {
      zoomLevel -= 0.2;
      span = [AttractionRouteViewController coordinateSpanWithMapView:mapView centerCoordinate:pin.coordinate andZoomLevel:zoomLevel];
      //NSLog(@"zoom level %f - lat %f / %f - lon %f / %f", zoomLevel, span.latitudeDelta, pathRegion.span.latitudeDelta, span.longitudeDelta, pathRegion.span.longitudeDelta);
    } while (zoomLevel > 15.6 && (span.latitudeDelta < pathRegion.span.latitudeDelta || span.longitudeDelta < pathRegion.span.longitudeDelta));
    if (![AttractionRouteViewController setCenterCoordinate:(zoomLevel > 15.5)? pathRegion.center : pin.coordinate onMapView:mapView zoomLevel:zoomLevel animated:NO]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
    [pin release];
  }
  [trackPoint release];
}

-(IBAction)viewLocation:(id)sender {
  locationButton.selected = !locationButton.selected;
  if (mapView.showsUserLocation && mapView.userLocation != nil) {
    UIView *user = [mapView viewForAnnotation:mapView.userLocation];
    //NSLog(@"DEBUG: %@", user);
    if (user != nil) [mapView.superview bringSubviewToFront:user];
  }
  [self didUpdateLocationData];
}

-(IBAction)viewSettings:(id)sender {
  NSArray *root = [MenuData getRootKey:@"PreferenceSpecifiers"];
  for (NSDictionary *entry in root) {
    NSString *identifier = [entry objectForKey:@"Key"];
    if ([identifier isEqualToString:@"MAP_TYPE"]) {
      UIActionSheet *sheet = [[UIActionSheet alloc]
                              initWithTitle:[entry objectForKey:@"Title"]
                              delegate:self
                              cancelButtonTitle:nil //NSLocalizedString(@"cancel", nil)
                              destructiveButtonTitle:nil
                              otherButtonTitles:nil];
      for (NSString *title in [entry objectForKey:@"Titles"]) {
        [sheet addButtonWithTitle:title];
      }
      sheet.cancelButtonIndex = [sheet addButtonWithTitle:NSLocalizedString(@"cancel", nil)];  // bug in iOS 4.2
      [sheet showInView:self.view];
      UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, sheet.bounds.size.width, sheet.bounds.size.height)];
      backgroundView.backgroundColor = [Colors darkBlue];
      backgroundView.opaque = NO;
      backgroundView.alpha = 0.5;
      [sheet insertSubview:backgroundView atIndex:0];
      [backgroundView release];
      [sheet release];
      break;
    }
  }
}

#pragma mark -
#pragma mark Map conversion methods

+(double)longitudeToPixelSpaceX:(double)longitude {
  return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

+(double)latitudeToPixelSpaceY:(double)latitude {
  return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
}

+(double)pixelSpaceXToLongitude:(double)pixelX {
  return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

+(double)pixelSpaceYToLatitude:(double)pixelY {
  return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
}

#pragma mark -
#pragma mark Helper methods

+(MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)map centerCoordinate:(CLLocationCoordinate2D)centerCoordinate andZoomLevel:(double)zoomLevel {
  // convert center coordiate to pixel space
  double centerPixelX = [AttractionRouteViewController longitudeToPixelSpaceX:centerCoordinate.longitude];
  double centerPixelY = [AttractionRouteViewController latitudeToPixelSpaceY:centerCoordinate.latitude];
  
  // determine the scale value from the zoom level
  double zoomScale = pow(2.0, fabs(20.0-zoomLevel));
  
  // scale the map’s size in pixel space
  CGSize mapSizeInPixels = map.bounds.size;
  double scaledMapWidth = mapSizeInPixels.width * zoomScale;
  double scaledMapHeight = mapSizeInPixels.height * zoomScale;
  
  // figure out the position of the top-left pixel
  double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
  double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);
  
  // find delta between left and right longitudes
  CLLocationDegrees minLng = [AttractionRouteViewController pixelSpaceXToLongitude:topLeftPixelX];
  CLLocationDegrees maxLng = [AttractionRouteViewController pixelSpaceXToLongitude:topLeftPixelX + scaledMapWidth];
  
  // find delta between top and bottom latitudes
  CLLocationDegrees minLat = [AttractionRouteViewController pixelSpaceYToLatitude:topLeftPixelY];
  CLLocationDegrees maxLat = [AttractionRouteViewController pixelSpaceYToLatitude:topLeftPixelY + scaledMapHeight];
  
  // create and return the lat/lng span
  return MKCoordinateSpanMake(minLat-maxLat, maxLng-minLng);
}

#pragma mark -
#pragma mark Route view

+(BOOL)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate onMapView:(MKMapView *)mapView zoomLevel:(double)zoomLevel animated:(BOOL)animated {
  if (zoomLevel > 20) zoomLevel = 20;
  MKCoordinateSpan currentSpan = mapView.region.span;
  MKCoordinateSpan span = [AttractionRouteViewController coordinateSpanWithMapView:mapView centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
  [mapView setRegion:MKCoordinateRegionMake(centerCoordinate, span) animated:animated];
  return (span.latitudeDelta != currentSpan.latitudeDelta || span.longitudeDelta != currentSpan.longitudeDelta);
}

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

-(void)mapView:(MKMapView *)map regionWillChangeAnimated:(BOOL)animated {
  if (manuallyChangingMapRect) return;
  if (previousZoomScale != ROUTE_REFRESH_WITHOUT_HIDING) {
    for (id annotation in mapView.annotations) {
      if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        RouteView *routeView = (RouteView *)[mapView viewForAnnotation:annotation];
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
  /*for (RouteView *routeView in routeViews) {
    routeView.hidden = NO;
    [routeView regionChanged];
  }*/
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
    pin.leftCalloutAccessoryView = nil;
    pin.rightCalloutAccessoryView = nil;
    [pin updateImage:4.0f/([ParkOverlayView zoomLevelForMap:map]-14.0f)];
    MapPin *mapPin = (MapPin *)annotation;
    UIImage *image = [mapPin getImage];
    if (image != nil) {
      UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
      imgView.bounds = CGRectMake(0.0, 0.0, 30.0, 30.0);
      pin.leftCalloutAccessoryView = imgView;
      //CGRect frame = pin.leftCalloutAccessoryView.frame;
      //pin.leftCalloutAccessoryView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 60.0);
      [imgView release];
    }
    pin.alpha = 1.0f;
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

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
  [self orderAnnotationsViews];
}

-(void)mapView:(MKMapView *)map didDeselectAnnotationView:(MKAnnotationView *)view {
  [self orderAnnotationsViews];
}

-(void)mapView:(MKMapView *)map annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
  MapPin *pin = (MapPin *)view.annotation;
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:pin.attractionId];
  AttractionViewController *controller = [[AttractionViewController alloc] initWithNibName:@"AttractionView" owner:self attraction:attraction parkId:parkId];
  controller.enableViewOnMap = NO;
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

#pragma mark -
#pragma mark Memory Management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc. that aren't in use.
}

-(void)viewDidUnload {
  [super viewDidUnload];
  topNavigationBar = nil;
  titleNavigationItem = nil;
  mapView = nil;
  copyrightLabel = nil;
  accuracyLabel = nil;
  locationButton = nil;
  pathTableView = nil;
}

-(void)dealloc {
  [topNavigationBar release];
  [titleNavigationItem release];
  [mapView release];
  [copyrightLabel release];
  [accuracyLabel release];
  [locationButton release];
  [pathTableView release];
  [tourDistance release];
  tourDistance = nil;
  [walkingTime release];
  walkingTime = nil;
  [overlay release];
  overlay = nil;
  [detailedTourDescription release];
  detailedTourDescription = nil;
  [super dealloc];
}

@end
