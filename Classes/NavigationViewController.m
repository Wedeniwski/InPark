//
//  NavigationViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "NavigationViewController.h"
#import "Attraction.h"
#import "Categories.h"
#import "ParkData.h"
#import "TourData.h"
#import "MenuData.h"
#import "HelpData.h"
#import "SettingsData.h"
#import "AttractionViewController.h"
#import "GeneralInfoViewController.h"
#import "CategoriesSelectionViewController.h"
#import "AttractionRouteViewController.h"
#import "AttractionAnnotation.h"
#import "RouteAnnotation.h"
#import "TrackSegment.h"
#import "InParkAppDelegate.h"
#import "IPadHelper.h"
#import "Conversions.h"
#import "Colors.h"
#import "Update.h"

#ifdef FAKE_CORE_LOCATION
#import "FTLocationSimulator.h"
#endif

#define DELTA_LATLON 0.000005


@implementation NavigationViewController

static NSString *parkId = nil;
static NSArray *categoryNames = nil;
static NSMutableDictionary *selectedCategories = nil;
static MapPin *selectedPin = nil;
static RouteAnnotation *selectedRoute = nil;
static BOOL viewInitialized = NO;

@synthesize delegate;
@synthesize overlay;
@synthesize mapView;
@synthesize copyrightLabel, accuracyLabel;
@synthesize topNavigationBar;
@synthesize navigationTitle;
@synthesize helpButton;
@synthesize cellOwner;
@synthesize minusLatitude, minusminusLatitude, plusLatitude, plusplusLatitude, minusLongitude, minusminusLongitude, plusLongitude, plusplusLongitude, reloadButton, viewAllRoutesButton, connectRoutesButton, deleteRouteButton, addNewInternalButton, addPointButton, renameButton, sendDataButton, locationButton, startStopRecordingButton, addAttractionButton;
@synthesize routeIndexSlider;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    [parkId release];
    parkId = [pId retain];
    [selectedPin release];
    selectedPin = nil;
    [selectedRoute release];
    selectedRoute = nil;
    // displayed attraction marks of selected categories
    [categoryNames release];
    categoryNames = [[Attraction categoriesForParkId:parkId] retain];
    [selectedCategories release];
    selectedCategories = [[NSMutableDictionary alloc] initWithCapacity:categoryNames.count+2];
    NSNumber *defaultValue = [NSNumber numberWithBool:YES];
    [selectedCategories setObject:defaultValue forKey:ALL_WITH_WAIT_TIME];
    for (NSString *categoryName in categoryNames) {
      [selectedCategories setObject:defaultValue forKey:categoryName];
      [selectedCategories setObject:defaultValue forKey:[PREFIX_FAVORITES stringByAppendingString:categoryName]];
    }
  }
  return self;
}

-(void)setupSelectedCategoriesWithMenuId:(NSString *)menuId {
  if (menuId != nil) {
    Categories *categories = [Categories getCategories];
    NSNumber *newValue = [NSNumber numberWithBool:NO];
    [selectedCategories setObject:newValue forKey:ALL_WITH_WAIT_TIME];
    if ([menuId isEqualToString:@"MENU_ATTRACTION"]) {
      for (NSString *categoryName in categoryNames) {
        if ([categories isExcludingCategoryName:categoryName]) {
          [selectedCategories setObject:newValue forKey:categoryName];
          [selectedCategories setObject:newValue forKey:[PREFIX_FAVORITES stringByAppendingString:categoryName]];
        }
      }
    } else {
      NSString *selectedCategory = [categories getCategoryNamefForMenuId:menuId];
      if (selectedCategory != nil) {
        for (NSString *categoryName in categoryNames) {
          if (![selectedCategory isEqualToString:categoryName]) {
            [selectedCategories setObject:newValue forKey:categoryName];
            [selectedCategories setObject:newValue forKey:[PREFIX_FAVORITES stringByAppendingString:categoryName]];
          }
        }
      }
    }
  }
}

#ifdef DEBUG_MAP
-(void)addRouteViewPathFrom:(NSString *)startAttractionId to:(NSString *)endAttractionId {
  ParkData *parkData = [ParkData getParkData:parkId];
  if ([parkData isPathInverse:startAttractionId toAttractionId:endAttractionId]) {
    NSString *t = startAttractionId;
    startAttractionId = endAttractionId;
    endAttractionId = t;
  }
  NSLog(@"Route from startAttractionId: %@", startAttractionId);
  NSArray *path = nil;
  [parkData distance:startAttractionId fromAll:NO toAttractionId:endAttractionId toAll:NO path:&path];
  if (path == nil) NSLog(@"Error! Missing path between %@ and %@", startAttractionId, endAttractionId);
  int startAttractionIdx = -1;
  for (NSNumber *nIdx in path) {
    int aIdx = [nIdx intValue];
    if (startAttractionIdx >= 0 && aIdx >= 0) {
      NSLog(@"via: %@", [parkData.allAttractionIds objectAtIndex:aIdx]);
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
}
#endif

-(void)updateMapView {
  [mapView removeAnnotations:mapView.annotations];
  ParkData *parkData = [ParkData getParkData:parkId];
  NSMutableArray *allPins = [[NSMutableArray alloc] initWithCapacity:1000];
  __block Categories *categories = [Categories getCategories];
  const int n = [categories numberOfTypes];
  NSMutableSet *relevantTypeIDs = [[NSMutableSet alloc] initWithCapacity:n];
  NSMutableSet *relevantFavoriteTypeIDs = [[NSMutableSet alloc] initWithCapacity:n];
  [selectedCategories enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    if (object != nil && [object boolValue]) {
      if ([key hasPrefix:PREFIX_FAVORITES]) [relevantFavoriteTypeIDs addObjectsFromArray:[categories getTypeIds:[categories getCategoryId:[key substringFromIndex:[PREFIX_FAVORITES length]]]]];
      else [relevantTypeIDs addObjectsFromArray:[categories getTypeIds:[categories getCategoryId:key]]];
    }
  }];
  BOOL allWithWaitingTime = [[selectedCategories objectForKey:ALL_WITH_WAIT_TIME] boolValue];
  [parkData.parkAttractionLocations enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSString *aId = key;
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:aId];
#ifdef DEBUG_MAP
    BOOL display = YES;
#else
    BOOL display = NO;
#endif
    if (attraction != nil && ![attraction isClosed:parkId]) {
      if (!display) display = (allWithWaitingTime && attraction.waiting);
      if (!display) display = [relevantTypeIDs containsObject:attraction.typeId];
      if (!display && [parkData isFavorite:aId]) display = [relevantFavoriteTypeIDs containsObject:attraction.typeId];
    }
    if (display) {
      TrackPoint *t = object;
      MapPin *pin = [[MapPin alloc] initWithAttractionId:aId parkId:parkId];
      if (![allPins containsObject:pin]) {
        pin.coordinate = (CLLocationCoordinate2D){ t.latitude, t.longitude };
        [allPins addObject:pin];
        [mapView addAnnotation:pin];
      }
      [pin release];
    }
  }];
  [parkData.sameAttractionIds enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSString *aId = key;
    Attraction *attraction = [Attraction getAttraction:parkId attractionId:aId];
#ifdef DEBUG_MAP
    BOOL display = YES;
#else
    BOOL display = NO;
#endif
    if (attraction != nil && ![attraction isClosed:parkId]) {
      if (!display) display = (allWithWaitingTime && attraction.waiting);
      if (!display) display = [relevantTypeIDs containsObject:attraction.typeId];
      if (!display && [parkData isFavorite:aId]) display = [relevantFavoriteTypeIDs containsObject:attraction.typeId];
    }
    if (display) {
      TrackPoint *t = [parkData.parkAttractionLocations objectForKey:object];
      MapPin *pin = [[MapPin alloc] initWithAttractionId:aId parkId:parkId];
      if (![allPins containsObject:pin]) {
        pin.coordinate = (CLLocationCoordinate2D){ t.latitude, t.longitude };
        [allPins addObject:pin];
        [mapView addAnnotation:pin];
      }
      [pin release];
    }
  }];
  [relevantFavoriteTypeIDs release];
  [relevantTypeIDs release];
  [allPins sortUsingSelector:@selector(compare:)];
  MapPin *previousPin = nil;
  const double shift2m = 0.000005;
  for (MapPin *pin in allPins) {
    if (previousPin != nil && pin.coordinate.latitude == previousPin.coordinate.latitude && pin.coordinate.longitude == previousPin.coordinate.longitude) {
      previousPin.overlap = YES;
      previousPin.coordinate = (CLLocationCoordinate2D){ previousPin.coordinate.latitude-shift2m, previousPin.coordinate.longitude-shift2m };
      pin.overlap = YES;
      pin.coordinate = (CLLocationCoordinate2D){ pin.coordinate.latitude+shift2m, pin.coordinate.longitude+shift2m };
    }
    previousPin = pin;
  }
  [allPins release];
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
    ParkData *parkData = [ParkData getParkData:parkId];
    copyrightLabel.text = (parkData.mapCopyright != nil)? parkData.mapCopyright : NSLocalizedString(@"copyright", nil);
    overlay = [[ParkOverlayView alloc] initWithRegion:lastGoodMapRect parkId:parkId];
    [mapView addOverlay:overlay];
    mapView.userInteractionEnabled = YES;
  }
}

-(void)viewDidLoad {
  [super viewDidLoad];
  viewInitialized = YES;
  topNavigationBar.tintColor = [Colors darkBlue];
  navigationTitle.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  navigationTitle.rightBarButtonItem.title = NSLocalizedString(@"navigation.button.categories", nil);
  // go to park
  ParkData *parkData = [ParkData getParkData:parkId];
  MKCoordinateRegion region = [parkData getParkRegion];
  refreshRoute = YES;
  previousZoomScale = 0.0;
  manuallyChangingMapRect = YES;
  [mapView setRegion:region animated:NO];
  lastGoodMapRect = mapView.visibleMapRect;
  manuallyChangingMapRect = NO;
  overlay = nil;
  [self setMapType];
  //[mapView setRegion:region animated:NO];
  if ([LocationData isLocationDataActive]) {
    LocationData *locData = [LocationData getLocationData];
    [locData registerViewController:self];
    mapView.showsUserLocation = YES;
    locationButton.hidden = NO;
    locationButton.selected = NO;
    if (mapView.userLocation.location.horizontalAccuracy >= 0 && [ParkOverlayView coordinate:mapView.userLocation.coordinate isInside:region]) {
      //NSLog(@"User location  lat %f - long %f", mapView.userLocation.coordinate.latitude, mapView.userLocation.coordinate.longitude);
      if (![AttractionRouteViewController setCenterCoordinate:mapView.userLocation.coordinate onMapView:mapView zoomLevel:17 animated:NO]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
    } else {
      if (![AttractionRouteViewController setCenterCoordinate:region.center onMapView:mapView zoomLevel:17 animated:NO]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
    }
    [self didUpdateLocationData];
  } else {
    locationButton.hidden = YES;
    if (![AttractionRouteViewController setCenterCoordinate:region.center onMapView:mapView zoomLevel:17 animated:NO]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
  }
#ifdef DEBUG_MAP
  addNewInternalId = nil;
  tapInterceptor = [[WildcardGestureRecognizer alloc] init];
  tapInterceptor.touchesBeganCallback = ^(NSSet *touches, UIEvent *event) {
    [self touchesBegan:touches withEvent:event];
  };
  [mapView addGestureRecognizer:tapInterceptor];
  connectRoutesButton.hidden = NO;
  reloadButton.hidden = NO;
  sendDataButton.hidden = NO;
  viewAllRoutesButton.hidden = NO;
  deleteRouteButton.hidden = NO;
  addNewInternalButton.hidden = NO;
  addPointButton.hidden = NO;
  renameButton.hidden = NO;
  startStopRecordingButton.hidden = NO;
  addAttractionButton.hidden = NO;
  locationButton.hidden = YES;
  [startStopRecordingButton setTitle:[LocationData isLocationDataActive]? @"Stop" : @"Start" forState:UIControlStateNormal];
  if (parkData.currentTrackData != nil) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:@"Active track"
                           message:[NSString stringWithFormat:@"%@ with %d entries", parkData.currentTrackData.trackName, (int)[parkData.currentTrackData.trackSegments count]]
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  }
#if TARGET_IPHONE_SIMULATOR
#else
  mapView.showsUserLocation = YES;
  locationButton.hidden = NO;
  locationButton.alpha = 0.4f;
  locationButton.selected = NO;
#endif

#endif
  if (mapView.showsUserLocation && mapView.userLocation != nil) {
    UIView *user = [mapView viewForAnnotation:mapView.userLocation];
    if (user != nil) [mapView bringSubviewToFront:user];
  }
  [self updateMapView];
}

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
  [super dismissModalViewControllerAnimated:animated];
  // Achtung: kritisch, wenn Memory-Warnungen im modalen Fenster aufgetreten sind
  if (viewInitialized) {
    [self updateMapView];
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
#pragma mark Responders management

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
#ifdef DEBUG_MAP
  if (addNewInternalId != nil) {
    ParkData *parkData = [ParkData getParkData:parkId];
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:mapView];
    CLLocationCoordinate2D touchMapCoordinate = [mapView convertPoint:touchPoint toCoordinateFromView:mapView];
    navigationTitle.title = @"";
    if (selectedPin != nil && adjustStartAttractionId != nil) {
      [addNewInternalButton setTitle:@"New" forState:UIControlStateNormal];
      [adjustStartAttractionId release];
      adjustStartAttractionId = nil;
      [adjustEndAttractionId release];
      adjustEndAttractionId = nil;
      [selectedPin setCoordinate:touchMapCoordinate];
      [parkData setAttractionLocation:selectedPin.attractionId latitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
      [parkData writeGPX:parkId];
      [self updateMapView];
    } else {
      TrackPoint *t1 = [[TrackPoint alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
      [parkData addAttractionId:addNewInternalId atLocation:t1];
      NSLog(@"New internal %@ at lat:%f lon:%f", addNewInternalId, t1.latitude, t1.longitude);
      [t1 release];
      //[self addToPlistAttractionName:attractionName ofType:@"Intern"];
      [parkData writeGPX:parkId];
      navigationTitle.title = @"Reload data necessary!";
      //[self reloadData:self];
    }
    [addNewInternalId release];
    addNewInternalId = nil;
    return;
  }
  if (overlay != nil) {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:mapView];
    CLLocationCoordinate2D touchMapCoordinate = [mapView convertPoint:touchPoint toCoordinateFromView:mapView];
    NSString *tileName = [overlay getTileFileNameContainsPoint:MKMapPointForCoordinate(touchMapCoordinate)];
    if (tileName != nil) {
      NSString *mapPath = [[[MenuData parkDataPath:parkId] stringByAppendingPathComponent:@"maps"] stringByAppendingPathComponent:tileName];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      if ([fileManager fileExistsAtPath:mapPath]) {
        NSLog(@"Selected tile %@", tileName);
        overlay.selectedTile = tileName;
        NSString *title = [deleteRouteButton titleForState:UIControlStateNormal];
        if ([title isEqualToString:@"Tiles"]) {
          NSError *error = nil;
          //[mapView removeOverlay:overlay];
          [fileManager removeItemAtPath:mapPath error:&error];
          [overlay setNeedsDisplayInMapRect:[overlay getRectForTileFileName:tileName]];//mapView.visibleMapRect];
          //[mapView addOverlay:overlay];
          if (error == nil) {
            navigationTitle.title = [NSString stringWithFormat:@"%@ removed", overlay.selectedTile];
          }
        } else {
          //[overlay setNeedsLayout];
          [mapView removeOverlay:overlay];
          [mapView addOverlay:overlay];
          navigationTitle.title = tileName;
        }
      } else {
        NSLog(@"Tile %@ does not exist", tileName);
        overlay.selectedTile = nil;
      }
    } else {
      overlay.selectedTile = nil;
    }
  }
#endif
}

#pragma mark -
#pragma mark Map View Delegate methods

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
        RouteView *routeView = (RouteView *)[mapView viewForAnnotation:annotation];
        routeView.hidden = YES;
      }
    }
  }
  previousZoomScale = (CGFloat)(map.bounds.size.width / map.visibleMapRect.size.width);
#ifdef DEBUG_MAP
  lastGoodMapRect = mapView.visibleMapRect;
#else
  if ([self intersectsMapRect:mapView.visibleMapRect]) {
    lastGoodMapRect = mapView.visibleMapRect;
  } else {
    [mapView setVisibleMapRect:lastGoodMapRect animated:YES];
  }
#endif
}

-(void)mapView:(MKMapView *)map regionDidChangeAnimated:(BOOL)animated {
  if (manuallyChangingMapRect) return; //prevents possible infinite recursion when we call setVisibleMapRect below
  NSUInteger zoomLevel = [ParkOverlayView zoomLevelForMap:map];
  //NSLog(@"ZOOM Level: %d (%f)", zoomLevel, (map.bounds.size.width / map.visibleMapRect.size.width));
#ifndef DEBUG_MAP
  //NSLog(@"overlay rect: %f - %f - %f - %f", overlay.boundingMapRect.origin.x, overlay.boundingMapRect.origin.y, overlay.boundingMapRect.size.width, overlay.boundingMapRect.size.height);
  //NSLog(@"visible rect: %f - %f - %f - %f", map.visibleMapRect.origin.x, map.visibleMapRect.origin.y, map.visibleMapRect.size.width, map.visibleMapRect.size.height);
  if ((overlay != nil && !MKMapRectIntersectsRect(overlay.boundingMapRect, map.visibleMapRect)) || zoomLevel < 15) {
    manuallyChangingMapRect = YES;
    [mapView setVisibleMapRect:lastGoodMapRect animated:YES];
    manuallyChangingMapRect = NO;
  }
  //[overlay setNeedsDisplayInMapRect:map.visibleMapRect];
#endif
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
    for (id annotation in map.annotations) {
      if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        RouteView *routeView = (RouteView *)[mapView viewForAnnotation:annotation];
        routeView.hidden = NO;
      }
    }
  }
}

-(void) mapView:(MKMapView *)aMapView didAddAnnotationViews:(NSArray *)views {
  for (MKAnnotationView *view in views) {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
      [view.superview bringSubviewToFront:view];
    } else {
      [view.superview sendSubviewToBack:view];
    }
  }
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
/*#else
  if ([annotation isMemberOfClass:[MKUserLocation class]]) {
    NSLog(@"MKUserLocation");
    return annotation;
  }*/
#endif
	if ([annotation isKindOfClass:[MapPin class]]) {
    AttractionAnnotation *pin = (AttractionAnnotation *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"AttractionAnnotation"];
    if (pin == nil) {
      pin = [[[AttractionAnnotation alloc] initWithAnnotation:annotation reuseIdentifier:@"AttractionAnnotation"] autorelease];
      //pin.animatesDrop = NO;
      pin.canShowCallout = (annotation.title != nil);
      pin.enabled = YES;
    } else {
      pin.annotation = annotation;
    }
    pin.leftCalloutAccessoryView = nil;
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [pin updateImage:4.0f/([ParkOverlayView zoomLevelForMap:map]-14.0f)];
    return pin;
  } else if ([annotation isKindOfClass:[RouteAnnotation class]]) {
    RouteView *routeView = [[[RouteView alloc] initWithAnnotation:annotation reuseIdentifier:@"RouteViewAnnotation"] autorelease];
    routeView.canShowCallout = NO;
#ifdef DEBUG_MAP
    routeView.enabled = YES;
#else
    routeView.enabled = NO;
#endif
    routeView.mapView = mapView;
    return routeView;
  }
  return nil;
}

-(void)mapView:(MKMapView *)map annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
  MapPin *p = (MapPin *)view.annotation;
  Attraction *attraction = [Attraction getAttraction:parkId attractionId:p.attractionId];
  if (attraction != nil) {
    AttractionViewController *controller = [[AttractionViewController alloc] initWithNibName:@"AttractionView" owner:self attraction:attraction parkId:parkId];
    controller.enableViewOnMap = NO;
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(void)mapView:(MKMapView *)map didSelectAnnotationView:(MKAnnotationView *)view {
  if ([view isKindOfClass:[AttractionAnnotation class]]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    MapPin *mapPin = (MapPin *)view.annotation;
    view.alpha = 1.0f;
    UIImage *image = [mapPin getImage];
    if (image != nil) {
      UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
      imgView.bounds = CGRectMake(0.0, 0.0, 30.0, 30.0);
      view.leftCalloutAccessoryView = imgView;
      [imgView release];
    } else {
      view.leftCalloutAccessoryView = nil;
    }
    [pool release];
  }
#ifdef DEBUG_MAP
    minusLatitude.hidden = NO;
    plusLatitude.hidden = NO;
    minusLongitude.hidden = NO;
    plusLongitude.hidden = NO;
    minusminusLatitude.hidden = NO;
    plusplusLatitude.hidden = NO;
    minusminusLongitude.hidden = NO;
    plusplusLongitude.hidden = NO;
    viewAllRoutesButton.hidden = NO;
    sendDataButton.hidden = NO;
    if ([view.annotation isKindOfClass:[MapPin class]]) {
      [selectedRoute release];
      selectedRoute = nil;
      //deleteRouteButton.hidden = YES;
      routeIndexSlider.hidden = YES;
      [selectedPin release];
      selectedPin = [(MapPin *)view.annotation retain];
      navigationTitle.title = [NSString stringWithFormat:@"Selected pin coordinates (%@): lat=\"%.6f\" lon=\"%.6f\"", selectedPin.attractionId, selectedPin.coordinate.latitude, selectedPin.coordinate.longitude];
      NSLog(@"Selected pin coordinates (%@): lat=\"%.6f\" lon=\"%.6f\"", selectedPin.attractionId, selectedPin.coordinate.latitude, selectedPin.coordinate.longitude);
      if (adjustStartAttractionId == nil) {
        ParkData *parkData = [ParkData getParkData:parkId];
        NSString *attractionId = [parkData getRootAttractionId:selectedPin.attractionId];
        adjustStartAttractionId = [attractionId retain];
        navigationTitle.title = [NSString stringWithFormat:@"from %@", adjustStartAttractionId];
        Attraction *a = [Attraction getAttraction:parkId attractionId:adjustStartAttractionId];
        if (a == nil && ![Attraction isInternalId:attractionId]) {
          NSLog(@"Attraction ID %@ does not exist!", selectedPin.attractionId);
          //[adjustStartAttractionId release];
          //adjustStartAttractionId = nil;
          //return;
        }
        if (adjustStartAttractionId != nil) [addNewInternalButton setTitle:@"Move" forState:UIControlStateNormal];
        //tourDistanceValueLabel.text = a.stringAttractionName;
      } else if (adjustEndAttractionId == nil) {
        ParkData *parkData = [ParkData getParkData:parkId];
        NSString *attractionId = [parkData getRootAttractionId:selectedPin.attractionId];
        adjustEndAttractionId = [attractionId retain];
        TrackSegment *trackSegment = [parkData getTrackSegment:adjustStartAttractionId toAttractionId:adjustEndAttractionId];
        navigationTitle.title = [NSString stringWithFormat:@"from %@ to %@ (%d)", adjustStartAttractionId, adjustEndAttractionId, (int)[trackSegment.trackPoints count]];
        Attraction *a = [Attraction getAttraction:parkId attractionId:adjustEndAttractionId];
        if (a == nil && ![Attraction isInternalId:attractionId]) {
          NSLog(@"Attraction ID %@ does not exist!", selectedPin.attractionId);
          //[adjustEndAttractionId release];
          //adjustEndAttractionId = nil;
          //return;
        } else NSLog(@"Selected end attraction (%@) %s", a.attractionId, a.attractionName);
        //tourDurationValueLabel.text = a.stringAttractionName;
        [self addRouteViewPathFrom:adjustStartAttractionId to:adjustEndAttractionId];
        previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
        [mapView setCenterCoordinate:selectedPin.coordinate];
      } else {
        ParkData *parkData = [ParkData getParkData:parkId];
        NSString *attractionId = [parkData getRootAttractionId:selectedPin.attractionId];
        [adjustStartAttractionId release];
        adjustStartAttractionId = [attractionId retain];
        Attraction *a = [Attraction getAttraction:parkId attractionId:adjustStartAttractionId];
        NSLog(@"Selected start attraction (%@) %s", a.attractionId, a.attractionName);
        //tourDistanceValueLabel.text = a.stringAttractionName;
        [adjustEndAttractionId release];
        adjustEndAttractionId = nil;
        //tourDurationValueLabel.text = @"";
        for (id routeAnnotation in mapView.annotations) {
          if ([routeAnnotation isKindOfClass:[RouteAnnotation class]]) [mapView removeAnnotation:routeAnnotation];
        }
      }
    } else if ([view isKindOfClass:[RouteView class]]) {
      [selectedPin release];
      selectedPin = nil;
      [addNewInternalButton setTitle:@"New" forState:UIControlStateNormal];
      [selectedRoute release];
      selectedRoute = [((RouteView *)view).annotation retain];
      navigationTitle.title = [NSString stringWithFormat:@"route %@ - %@", selectedRoute.trackSegment.from, selectedRoute.trackSegment.to];
      //deleteRouteButton.hidden = NO;
      routeIndexSlider.continuous = YES;
      routeIndexSlider.minimumValue = 1.0;
      routeIndexSlider.maximumValue = [selectedRoute.trackSegment.trackPoints count]-1.0;
      routeIndexSlider.value = 1.0;
      routeIndexSlider.hidden = (routeIndexSlider.maximumValue <= 1.0);
      navigationTitle.title = [NSString stringWithFormat:@"Selected track point on route: lat=\"%.6f\" lon=\"%.6f\"", selectedRoute.coordinate.latitude, selectedRoute.coordinate.longitude];
      NSLog(@"Selected track point on route: lat=\"%.6f\" lon=\"%.6f\"", selectedRoute.coordinate.latitude, selectedRoute.coordinate.longitude);
    }
#endif
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
#ifdef DEBUG_MAP
  if (adjustStartAttractionId == nil && adjustEndAttractionId == nil) navigationTitle.title = @"";
#endif
  if ([view isKindOfClass:[AttractionAnnotation class]]) {
    MapPin *mapPin = (MapPin *)view.annotation;
    view.alpha = (mapPin.overlap)? 0.7f : 1.0f;
    view.leftCalloutAccessoryView = nil;
  }
}

/*-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
    NSString *urlstr = [[request URL] fragment];
    int page = 1;
    for (NSString *pageKey in helpData.keys) { // ToDo
      if ([pageKey isEqualToString:urlstr]) break;
      ++page;
    }
    if (page >= [routeDescriptions count]) page = 0;
    pageControl.currentPage = page;
    [self changePage:nil];
    return NO;
  }
  return YES;
}*/

-(void)mapView:(MKMapView *)map didUpdateUserLocation:(MKUserLocation *)userLocation {
  UIView *user = [map viewForAnnotation:userLocation];
  if (user != nil) [map bringSubviewToFront:user];
}

-(void)startUpdateLocationData {
  ParkData *parkData = [ParkData getParkData:parkId];
  LocationData *locData = [LocationData getLocationData];
  [locData registerDataPool:parkData.currentTrackData parkId:parkId];
  [locData registerViewController:self];
  [locData start];
}

#pragma mark -
#pragma mark Action sheet delegate

#ifdef DEBUG_MAP
-(void)addToPlistAttractionName:(NSString *)attractionName ofType:(NSString *)type {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  ParkData *parkData = [ParkData getParkData:parkId];
  NSString *attractionId = [NSString stringWithFormat:@"WP%d", (int)[parkData.currentTrackData.trackSegments count]];
  NSString *path = [NSString stringWithFormat:@"%@/%@.plist", [MenuData documentPath], parkData.currentTrackData.trackName];
  NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
  if (plist != nil) {
    NSString *parkGroup = [plist objectForKey:@"Parkgruppe"];
    if (![parkGroup isEqualToString:parkData.currentTrackData.trackName]) {
      [plist release];
      plist = nil;
    }
  }
  if (plist == nil) {
    plist = [[NSMutableDictionary alloc] initWithCapacity:20];
    [plist setObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"", @"", nil] forKeys:[NSArray arrayWithObjects:@"en", @"de", nil]] forKey:@"Land"];
    [plist setObject:@"" forKey:@"Stadt"];
    [plist setObject:@"" forKey:@"Time_zone"];
    [plist setObject:[NSString stringWithFormat:@"%@ - logo.jpg", parkData.currentTrackData.trackName] forKey:@"Logo"];
    [plist setObject:[NSString stringWithFormat:@"%@ - background.jpg", parkData.currentTrackData.trackName] forKey:@"Hintergrund"];
    [plist setObject:[NSString stringWithFormat:@"%@ - icon_attraktionen.jpg", parkData.currentTrackData.trackName] forKey:@"Icon_Attraktionen"];
    [plist setObject:[NSString stringWithFormat:@"%@ - icon_gastro.jpg", parkData.currentTrackData.trackName] forKey:@"Icon_Gastro"];
    [plist setObject:[NSString stringWithFormat:@"%@ - icon_service.jpg", parkData.currentTrackData.trackName] forKey:@"Icon_Service"];
    [plist setObject:[NSString stringWithFormat:@"%@ - icon_shops.jpg", parkData.currentTrackData.trackName] forKey:@"Icon_Shops"];
    [plist setObject:[NSString stringWithFormat:@"%@ - icon_wc.jpg", parkData.currentTrackData.trackName] forKey:@"Icon_WC"];
    [plist setObject:[NSString stringWithFormat:@"%@ - icon_themenbereiche.jpg", parkData.currentTrackData.trackName] forKey:@"Icon_Themenbereiche"];
    [plist setObject:[NSNumber numberWithInt:18] forKey:@"Adult_age"];
    [plist setObject:@"" forKey:@"Fast_lane"];
    [plist setObject:@"" forKey:@"Included_dining"];
    [plist setObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:40], [NSNumber numberWithInt:20], [NSNumber numberWithInt:0], nil] forKeys:[NSArray arrayWithObjects:@"3", @"2", @"1", nil]] forKey:@"Wartezeiten"];
    [plist setObject:[NSDictionary dictionary] forKey:@"IDs"];
    [plist setObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray array], [NSArray array], [NSArray array], nil] forKeys:[NSArray arrayWithObjects:@"Thrill-Tour", @"Kids-Tour", @"Relax-Tour", nil]] forKey:@"MENU_TOUR"];
    [plist setObject:@"" forKey:@"Parkname"];
    [plist setObject:parkData.currentTrackData.trackName forKey:@"Parkgruppe"];
    [plist setObject:[NSNumber numberWithInt:1] forKey:@"Rang"];
    [plist setObject:parkData.currentTrackData.trackName forKey:@"Company"];
    [plist setObject:@"THEME_PARK" forKey:@"Type"];
    [plist setObject:@"http://" forKey:@"Website"];
    [plist setObject:@"© 2010 - 2014 InPark GbR, Tilman Rau and Sebastian Wedeniwski. All rights reserved." forKey:@"Copyright"];
  }
  NSMutableDictionary *attraction = [[NSMutableDictionary alloc] initWithCapacity:20];
  [attraction setObject:attractionId forKey:@"WP"];
  if ([type isEqualToString:@"Intern"]) {
    [attraction setObject:[NSString stringWithFormat:@"%@ - INTERN", attractionName] forKey:@"Name"];
    attractionId = [NSString stringWithFormat:@"%@ - INTERN", attractionId];
  } else {
    [attraction setObject:@"" forKey:@"Themenbereich"];
    [attraction setObject:@"" forKey:@"Bild"];
    [attraction setObject:[NSNumber numberWithBool:YES] forKey:@"Tourpoint"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Indoor"];
    [attraction setObject:[NSNumber numberWithBool:YES] forKey:@"Behindertengerecht"];
    [attraction setObject:[NSNumber numberWithBool:YES] forKey:@"Rollstuhlgerecht"];
    [attraction setObject:@"" forKey:@"Type"];
    //[attraction setObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"", @"", nil] forKeys:[NSArray arrayWithObjects:@"en", @"de", nil]] forKey:@"Kategorie"];
    [attraction setObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"", @"", nil] forKeys:[NSArray arrayWithObjects:@"en", @"de", nil]] forKey:@"Kurzbeschreibung"];
  }
  if ([type isEqualToString:@"Attraktion"]) {
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Wasser-Faktor"];
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Familien-Faktor"];
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Thrill-Faktor"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Zusatzkosten"];
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Attraktionsdauer"];
    [attraction setObject:@"" forKey:@"Altersbegrenzung"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Winter"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Zusatzkosten"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Warten"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Fast_lane"];
    [attraction setObject:@"" forKey:@"Größe"];
    [attraction setObject:attractionName forKey:@"Name"];
  } else if ([type isEqualToString:@"Figuren / Arcade"]) {
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Wasser-Faktor"];
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Familien-Faktor"];
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Thrill-Faktor"];
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Attraktionsdauer"];
    [attraction setObject:@"" forKey:@"Altersbegrenzung"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Winter"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Zusatzkosten"];
    [attraction setObject:@"" forKey:@"Größe"];
    [attraction setObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"", attractionName, nil] forKeys:[NSArray arrayWithObjects:@"en", @"de", nil]] forKey:@"Name"];
  } else if ([type isEqualToString:@"Zug"]) {
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Wasser-Faktor"];
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Familien-Faktor"];
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Thrill-Faktor"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Zusatzkosten"];
    [attraction setObject:[NSNumber numberWithInt:0] forKey:@"Attraktionsdauer"];
    [attraction setObject:@"" forKey:@"Altersbegrenzung"];
    [attraction setObject:@"" forKey:@"nächste Station"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Winter"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Zusatzkosten"];
    [attraction setObject:@"" forKey:@"Größe"];
    [attraction setObject:attractionName forKey:@"Name"];
  } else if ([type isEqualToString:@"Shop"]) {
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Pin"];
    [attraction setObject:attractionName forKey:@"Name"];
  } else if ([type isEqualToString:@"Gastro"]) {
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Character"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Table"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Counter"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Buffet"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Booth"];
    [attraction setObject:[NSNumber numberWithBool:YES] forKey:@"Breakfast"];
    [attraction setObject:[NSNumber numberWithBool:YES] forKey:@"Lunch"];
    [attraction setObject:[NSNumber numberWithBool:YES] forKey:@"Dinner"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Snacks"];
    [attraction setObject:[NSNumber numberWithBool:NO] forKey:@"Reservation"];
    [attraction setObject:@"" forKey:@"Service"];
    [attraction setObject:attractionName forKey:@"Name"];
  } else if ([type isEqualToString:@"Service"]) {
    [attraction setObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"", attractionName, nil] forKeys:[NSArray arrayWithObjects:@"en", @"de", nil]] forKey:@"Name"];
  }
  NSMutableDictionary *ids = [[NSMutableDictionary alloc] initWithDictionary:[plist objectForKey:@"IDs"]];
  [ids setObject:attraction forKey:attractionId];
  [plist setObject:ids forKey:@"IDs"];
  [ids release];
  [attraction release];
  [plist writeToFile:path atomically:YES];
  [plist release];
  [pool release];
}
#endif

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (actionSheet.tag == 2) {
#ifdef DEBUG_MAP
    if (buttonIndex < 0) buttonIndex = 6; // if no button is selected
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *attractionName = actionSheet.title;
    NSRange range = [attractionName rangeOfString:@": "];
    if (range.length > 0) attractionName = [attractionName substringFromIndex:range.location+2];
    [self addToPlistAttractionName:attractionName ofType:buttonTitle];
#endif
  } else if (actionSheet.tag == 1 && buttonIndex >= 0) {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    SettingsData *settings = [SettingsData getSettingsData];
    NSArray *root = [MenuData getRootKey:@"PreferenceSpecifiers"];
    for (NSDictionary *entry in root) {
      NSString *identifier = [entry objectForKey:@"Key"];
      if ([identifier isEqualToString:@"MAP_TYPE"]) {
        NSArray *titles = [entry objectForKey:@"Titles"];
        NSUInteger l = [titles count];
        for (NSUInteger i = 0; i < l; ++i) {
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
}

#pragma mark -
#pragma mark Alert view delegate

#ifdef DEBUG_MAP
-(void)addType:(NSArray *)args {
  UIActionSheet *sheet = [[UIActionSheet alloc]
                          initWithTitle:[NSString stringWithFormat:@"%@: %@", [args objectAtIndex:0], [args objectAtIndex:1]]
                          delegate:self
                          cancelButtonTitle:nil
                          destructiveButtonTitle:nil
                          otherButtonTitles:@"Attraktion", @"Zug", @"Figuren / Arcade", @"Shop", @"Gastro", @"Service", @"Intern", nil];
  sheet.tag = 2;
  [sheet showInView:self.view];
  [sheet release];
}
#endif

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
#ifdef DEBUG_MAP
  NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
  if ([buttonTitle isEqualToString:NSLocalizedString(@"ok", nil)]) {
    UITextField *textField = [alertView textFieldAtIndex:0];
    NSString *changedTextInput = (textField != nil)? [textField.text retain] : nil;
    if (changedTextInput != nil) {
      if (adjustStartAttractionId != nil || adjustEndAttractionId != nil) {
        if (alertView.tag == 1) {
          // Attraction locations
          ParkData *parkData = [ParkData getParkData:parkId];
          double lat,lon;
          TrackPoint *t1 = (adjustStartAttractionId != nil)? [parkData getAttractionLocation:adjustStartAttractionId] : nil;
          TrackPoint *t2 = (adjustEndAttractionId != nil)? [parkData getAttractionLocation:adjustEndAttractionId] : nil;
          if (t1 != nil) {
            if (t2 != nil) {
              lat = (t1.latitude+t2.latitude)/2;
              lon = (t1.longitude+t2.longitude)/2;
            } else {
              lat = t1.latitude;
              lon = t1.longitude;
            }
          } else {
            lat = t2.latitude;
            lon = t2.longitude;
          }
          t1 = [[TrackPoint alloc] initWithLatitude:lat longitude:lon];
          [parkData addAttractionId:changedTextInput atLocation:t1];
          [t1 release];
          [parkData writeGPX:parkId];
        } else if (alertView.tag == 2) {
          Attraction *attraction = [Attraction getAttraction:parkId attractionId:(adjustEndAttractionId != nil)? adjustEndAttractionId : adjustStartAttractionId];
          if (attraction != nil && (adjustStartAttractionId == attraction.attractionId || adjustEndAttractionId == attraction.attractionId)) {
            UIAlertView *dialog = [[UIAlertView alloc]
                                   initWithTitle:@"Error: Already exist"
                                   message:[NSString stringWithFormat:@"Attraction ID %@ already exist", attraction.attractionId]
                                   delegate:nil
                                   cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                   otherButtonTitles:nil];
            [dialog show];
            [dialog release];
            return;
          }
          ParkData *parkData = [ParkData getParkData:parkId];
          if (adjustEndAttractionId != nil) [parkData renameAttractionId:adjustEndAttractionId to:changedTextInput];
          else [parkData renameAttractionId:adjustStartAttractionId to:changedTextInput];
          [parkData writeGPX:parkId];
        }
      }
    }
    if (alertView.tag == 3) {
      ParkData *parkData = [ParkData getParkData:parkId];
      if (changedTextInput == nil) changedTextInput = [parkData.currentTourName retain];
      parkData.currentTrackData = [[TrackData alloc] initWithTrackName:changedTextInput parkId:parkId fromAttractionId:UNKNOWN_ATTRACTION_ID];
      // check if a plist with this name already exist!
      NSString *path = [NSString stringWithFormat:@"%@/%@.plist", [MenuData documentPath], changedTextInput];
      NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
      if (plist != nil) {
        // add dummy track points to reuse
        NSDictionary *ids = [plist objectForKey:@"IDs"];
        NSString *name = @"";
        int i = 1;
        while (YES) {
          NSString *wp = [NSString stringWithFormat:@"WP%d", i];
          NSDictionary* attraction = [ids objectForKey:wp];
          if (attraction == nil) {
            wp = [NSString stringWithFormat:@"WP%d - INTERN", i];
            attraction = [ids objectForKey:wp];
          }
          if (attraction == nil) break;
          name = [attraction objectForKey:@"Name"];
          NSLog(@"dummy for %@: %@", wp, name);
          CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:0.0 longitude:0.0];
          [parkData.currentTrackData addTrackPoint:newLocation];
          [newLocation release];
          [parkData.currentTrackData addAttractionId:wp toTourItem:NO fromExitAttractionId:nil];
          ++i;
        }
        [parkData save:NO];
        [parkData.currentTrackData saveData];
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:@"plist exist"
                               message:[NSString stringWithFormat:@"%d dummy IDs to new plist added (last name: %@)", i-1, name]
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
        path = [NSString stringWithFormat:@"%@/%@.plist", [MenuData documentPath], parkData.currentTrackData.trackName];
        NSMutableDictionary *plist2 = [[NSMutableDictionary alloc] initWithDictionary:plist];
        [plist2 setObject:parkData.currentTrackData.trackName forKey:@"Parkgruppe"];
        [plist2 writeToFile:path atomically:YES];
        [plist2 release];
      }
      [self startUpdateLocationData];
    } else if (alertView.tag == 4) {
      ParkData *parkData = [ParkData getParkData:parkId];
      const int n = (int)[parkData.currentTrackData.trackSegments count];
      /*if (n == 0) {
        UIAlertView *dialog = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"warning", nil)
                               message:@"new track"
                               delegate:nil
                               cancelButtonTitle:NSLocalizedString(@"ok", nil)
                               otherButtonTitles:nil];
        [dialog show];
        [dialog release];
      }*/
      NSString *wp = [NSString stringWithFormat:@"WP%d", n+1];
      [parkData.currentTrackData addAttractionId:wp toTourItem:NO fromExitAttractionId:nil];
      [parkData save:NO];
      [parkData.currentTrackData saveData];
      [self performSelector:@selector(addType:) withObject:[NSArray arrayWithObjects:wp, changedTextInput, nil] afterDelay:0.4];
    }
  } else if (alertView.tag == 5) {
    if ([buttonTitle isEqualToString:@"route"]) {
      ParkData *parkData = [ParkData getParkData:parkId];
      int fromAttractionIdx = [MenuData binarySearch:adjustStartAttractionId inside:parkData.allAttractionIds];
      int toAttractionIdx = [MenuData binarySearch:adjustEndAttractionId inside:parkData.allAttractionIds];
      if (fromAttractionIdx < 0 || toAttractionIdx < 0) {
        NSLog(@"Internal error: attractions %@ (%d) - %@ (%d) unknown", adjustStartAttractionId, fromAttractionIdx, adjustEndAttractionId, toAttractionIdx);
      } else {
        TrackSegmentId *segmentId = [TrackSegment getTrackSegmentId:fromAttractionIdx toAttractionIdx:toAttractionIdx];
        [parkData.trackSegments removeObjectForKey:segmentId];
        [parkData writeGPX:parkId];
        navigationTitle.title = [NSString stringWithFormat:@"Segment from %@ to %@ deleted", adjustStartAttractionId, adjustEndAttractionId];
        NSLog(@"Segment from %@ to %@ deleted", adjustStartAttractionId, adjustEndAttractionId);
      }
    } else if ([buttonTitle isEqualToString:adjustStartAttractionId]) {
      ParkData *parkData = [ParkData getParkData:parkId];
      [parkData removeAttractionLocation:adjustStartAttractionId];
      [parkData writeGPX:parkId];
    } else if ([buttonTitle isEqualToString:adjustEndAttractionId]) {
      ParkData *parkData = [ParkData getParkData:parkId];
      [parkData removeAttractionLocation:adjustEndAttractionId];
      [parkData writeGPX:parkId];
    }
  }
#endif
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  mapView.delegate = nil;  // map might still sending messages to the delegate
  if ([LocationData isLocationDataInitialized]) {
    LocationData *locData = [LocationData getLocationData];
    [locData unregisterViewController];
  }
  [delegate dismissModalViewControllerAnimated:(sender != nil)];
}

-(IBAction)categoriesView:(id)sender {
  CategoriesSelectionViewController *controller = [[CategoriesSelectionViewController alloc] initWithNibName:@"CategoriesSelectionView" owner:self parkId:parkId];
  controller.categoryNames = categoryNames;
  controller.selectedCategories = selectedCategories;
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

-(IBAction)helpView:(id)sender {
  HelpData *helpData = [HelpData getHelpData];
  NSString *page = [helpData.pages objectForKey:@"MENU_MAP"];
  NSString *title = [helpData.titles objectForKey:@"MENU_MAP"];
  if (title != nil && page != nil) {
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    controller.content = page;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(void)didUpdateLocationData {
  /* Compass
   [mapView setTransform:CGAffineTransformMakeRotation(-1 * currentHeading.magneticHeading * 3.14159 / 180)];
   for (MKAnnotation *annotation in self.mapView.annotations) {
   MKAnnotationView *annotationView = [self.mapView viewForAnnotation:annotation]; 
   [annotationView setTransform:CGAffineTransformMakeRotation(currentHeading.magneticHeading * 3.14159 / 180)];
   }*/
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
      //MKCoordinateRegion region = mapView.region;
      //region.center = coordinate;
      //NSLog(@"New user location lat %f  - long %f", region.center.latitude, region.center.longitude);
      //[mapView setRegion:region animated:YES];
      previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
      [mapView setCenterCoordinate:coordinate animated:YES];
    }
#endif
  }
  if ([LocationData isLocationDataActive]) {
    NSString *accuracyText = nil;
    ParkData *parkData = [ParkData getParkData:parkId];
    LocationData *locData = [LocationData getLocationData];
    if (locData.lastUpdatedLocation != nil) {
      double accuracy = locData.lastUpdatedLocation.horizontalAccuracy;
      if (accuracy < 0.0) {
        accuracyText = NSLocalizedString(@"tour.accuracy.invalid", nil);
        accuracyLabel.textColor = [UIColor redColor];
#ifndef DEBUG_MAP
      } else if (![parkData isCurrentlyInsidePark]) {
        accuracyText = NSLocalizedString(@"tour.accuracy.not.inside.park", nil);
        accuracyLabel.textColor = [UIColor redColor];
#endif
      } else {
        SettingsData *settings = [SettingsData getSettingsData];
        if ([settings isMetricMeasure]) {
          accuracyText = [NSString stringWithFormat:NSLocalizedString(@"tour.accuracy", nil), (int)accuracy];
        } else {
          accuracyLabel.text = [NSString stringWithFormat:NSLocalizedString(@"tour.accuracy.imperial", nil), (int)convertMetersToFeet(accuracy)];
        }
        accuracyLabel.textColor = [UIColor blueColor];
      }
    }
#ifdef DEBUG_MAP
    if (selectedPin != nil) {
      TrackPoint *t1 = [[TrackPoint alloc] initWithLatitude:locData.lastUpdatedLocation.coordinate.latitude longitude:locData.lastUpdatedLocation.coordinate.longitude];
      TrackPoint *t2 = [[TrackPoint alloc] initWithLatitude:selectedPin.coordinate.latitude longitude:selectedPin.coordinate.longitude];
      accuracyText = [NSString stringWithFormat:@"%@ - %.2f", accuracyText, [t1 distanceTo:t2]];
      [t1 release];
      [t2 release];
    }
    accuracyText = [NSString stringWithFormat:@"%@ (%d)", accuracyText, (int)[parkData.currentTrackData.currentTrackPoints count]];
#endif
    accuracyLabel.hidden = NO;
    accuracyLabel.text = accuracyText;
  } else {
    accuracyLabel.hidden = YES;
  }
  /*if (mapView.showsUserLocation && mapView.userLocation != nil) {
    UIView *user = [mapView viewForAnnotation:mapView.userLocation];
    if (user != nil) [mapView bringSubviewToFront:user];
  }*/
}

-(IBAction)viewLocation:(id)sender {
  locationButton.selected = !locationButton.selected;
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
      sheet.tag = 1;
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

/*NSString *runCommand(NSString *commandToRun) {
  NSTask *task = [[NSTask alloc] init];
  [task setLaunchPath: @"/bin/sh"];
  NSArray *arguments = [NSArray arrayWithObjects:@"-c" , [NSString stringWithFormat:@"%@", commandToRun], nil];
  NSLog(@"run command: %@",commandToRun);
  [task setArguments: arguments];
  NSPipe *pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];
  NSFileHandle *file = [pipe fileHandleForReading];
  [task launch];
  NSData *data = [file readDataToEndOfFile];
  [task release];
  return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}*/

/*void runSystemCommand(NSString *cmd) {
  [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:@[@"-c", cmd]] waitUntilExit];
}*/

-(IBAction)reloadData:(id)sender {
#ifdef DEBUG_MAP
/*#if TARGET_IPHONE_SIMULATOR
  NSMutableString *output = [[NSMutableString alloc] initWithCapacity:1000];
  NSString *command = [NSString stringWithFormat:@"cd \"/Users/Wedeniwski/Documents/iPhone Projects/InPark/GPS\";java -jar GPS.jar %@", parkId];
  //const char* command = "cd \"/Users/Wedeniwski/Documents/iPhone Projects/InPark/GPS\";java -jar GPS.jar " + parkId;
  FILE *cmd = popen([command UTF8String], "r");
  char tmp[256] = {0x0};
  while (fgets(tmp, sizeof(tmp), cmd) != NULL) {
    [output appendFormat:@"%s", tmp];
  }
  pclose(cmd);
  NSLog(@"cmd: %@\n%@", command, output);
  [output release];
#endif*/
  ParkData *parkData = [ParkData getParkData:parkId reload:YES];
  [parkData setupData];
  [mapView removeAnnotations:mapView.annotations];
  navigationTitle.title = @"";
  [self updateMapView];
  //[self viewAllRoutes:self];
#endif
}

#ifdef DEBUG_MAP
-(void)refreshRoute {
  if (selectedRoute != nil) {
    /*NSMutableArray *annotations = [[NSMutableArray alloc] initWithCapacity:10];
    for (id routeAnnotation in mapView.annotations) {
      if ([routeAnnotation isKindOfClass:[RouteAnnotation class]]) [annotations addObject:routeAnnotation];
    }
    [mapView removeAnnotations:annotations];
    [mapView addAnnotations:annotations];
    for (RouteAnnotation *annotation in annotations) [annotation resetRegion];
    [annotations release];*/
    [selectedRoute resetRegion];
    [mapView removeAnnotation:selectedRoute];
    [mapView addAnnotation:selectedRoute];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData writeGPX:parkId];
  }
}
#endif

-(IBAction)minusLatitude:(id)sender {
#ifdef DEBUG_MAP
  if (selectedPin != nil) {
    [selectedPin addLatitude:-DELTA_LATLON];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData changeAttractionLocation:selectedPin.attractionId latitudeDelta:-DELTA_LATLON longitudeDelta:0.0];
    [parkData writeGPX:parkId];
  } else if (selectedRoute != nil) {
    [selectedRoute addLatitude:-DELTA_LATLON atIndex:(int)routeIndexSlider.value];
    [self refreshRoute];
  }
#endif
}

-(IBAction)minusminusLatitude:(id)sender {
#ifdef DEBUG_MAP
  if (selectedPin != nil) {
    [selectedPin addLatitude:-5*DELTA_LATLON];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData changeAttractionLocation:selectedPin.attractionId latitudeDelta:-5*DELTA_LATLON longitudeDelta:0.0];
    [parkData writeGPX:parkId];
  } else if (selectedRoute != nil) {
    [selectedRoute addLatitude:-5*DELTA_LATLON atIndex:(int)routeIndexSlider.value];
    [self refreshRoute];
  }
#endif
}

-(IBAction)plusLatitude:(id)sender {
#ifdef DEBUG_MAP
  if (selectedPin != nil) {
    [selectedPin addLatitude:DELTA_LATLON];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData changeAttractionLocation:selectedPin.attractionId latitudeDelta:DELTA_LATLON longitudeDelta:0.0];
    [parkData writeGPX:parkId];
  } else if (selectedRoute != nil) {
    [selectedRoute addLatitude:DELTA_LATLON atIndex:(int)routeIndexSlider.value];
    [self refreshRoute];
  }
#endif
}

-(IBAction)plusplusLatitude:(id)sender {
#ifdef DEBUG_MAP
  if (selectedPin != nil) {
    [selectedPin addLatitude:5*DELTA_LATLON];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData changeAttractionLocation:selectedPin.attractionId latitudeDelta:5*DELTA_LATLON longitudeDelta:0.0];
    [parkData writeGPX:parkId];
  } else if (selectedRoute != nil) {
    [selectedRoute addLatitude:5*DELTA_LATLON atIndex:(int)routeIndexSlider.value];
    [self refreshRoute];
  }
#endif
}

-(IBAction)minusLongitude:(id)sender {
#ifdef DEBUG_MAP
  if (selectedPin != nil) {
    [selectedPin addLongitude:-DELTA_LATLON];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData changeAttractionLocation:selectedPin.attractionId latitudeDelta:0.0 longitudeDelta:-DELTA_LATLON];
    [parkData writeGPX:parkId];
  } else if (selectedRoute != nil) {
    [selectedRoute addLongitude:-DELTA_LATLON atIndex:(int)routeIndexSlider.value];
    [self refreshRoute];
  }
#endif
}

-(IBAction)minusminusLongitude:(id)sender {
#ifdef DEBUG_MAP
  if (selectedPin != nil) {
    [selectedPin addLongitude:-5*DELTA_LATLON];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData changeAttractionLocation:selectedPin.attractionId latitudeDelta:0.0 longitudeDelta:-5*DELTA_LATLON];
    [parkData writeGPX:parkId];
  } else if (selectedRoute != nil) {
    [selectedRoute addLongitude:-5*DELTA_LATLON atIndex:(int)routeIndexSlider.value];
    [self refreshRoute];
  }
#endif
}

-(IBAction)plusLongitude:(id)sender {
#ifdef DEBUG_MAP
  if (selectedPin != nil) {
    [selectedPin addLongitude:DELTA_LATLON];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData changeAttractionLocation:selectedPin.attractionId latitudeDelta:0.0 longitudeDelta:DELTA_LATLON];
    [parkData writeGPX:parkId];
  } else if (selectedRoute != nil) {
    [selectedRoute addLongitude:DELTA_LATLON atIndex:(int)routeIndexSlider.value];
    [self refreshRoute];
  }
#endif
}

-(IBAction)plusplusLongitude:(id)sender {
#ifdef DEBUG_MAP
  if (selectedPin != nil) {
    [selectedPin addLongitude:5*DELTA_LATLON];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData changeAttractionLocation:selectedPin.attractionId latitudeDelta:0.0 longitudeDelta:5*DELTA_LATLON];
    [parkData writeGPX:parkId];
  } else if (selectedRoute != nil) {
    [selectedRoute addLongitude:5*DELTA_LATLON atIndex:(int)routeIndexSlider.value];
    [self refreshRoute];
  }
#endif
}

-(IBAction)connectRoutes:(id)sender {
#ifdef DEBUG_MAP
  if (adjustStartAttractionId != nil && adjustEndAttractionId != nil) {
    ParkData *parkData = [ParkData getParkData:parkId];
    int fromAttractionIdx = [MenuData binarySearch:adjustStartAttractionId inside:parkData.allAttractionIds];
    int toAttractionIdx = [MenuData binarySearch:adjustEndAttractionId inside:parkData.allAttractionIds];
    if (fromAttractionIdx < 0 || toAttractionIdx < 0) {
      NSLog(@"Internal error: attractions %@ (%d) - %@ (%d) unknown", adjustStartAttractionId, fromAttractionIdx, adjustEndAttractionId, toAttractionIdx);
    } else {
      TrackPoint *startTrackPoint = [parkData getAttractionLocation:adjustStartAttractionId];
      TrackPoint *endTrackPoint = [parkData getAttractionLocation:adjustEndAttractionId];
      TrackSegment *segment = [[TrackSegment alloc] initWithFromAttractionId:adjustStartAttractionId toAttractionId:adjustEndAttractionId trackPoints:[NSArray arrayWithObjects:startTrackPoint, endTrackPoint, nil] isTrackToTourItem:NO];
      [parkData.trackSegments setObject:segment forKey:[TrackSegment getTrackSegmentId:fromAttractionIdx toAttractionIdx:toAttractionIdx]];
      [segment release];
      navigationTitle.title = [NSString stringWithFormat:@"Segment from %@ to %@ added", adjustStartAttractionId, adjustEndAttractionId];
      NSLog(@"Segment from %@ to %@ added", adjustStartAttractionId, adjustEndAttractionId);
      [parkData writeGPX:parkId];
    }
  }
#endif
}

-(IBAction)viewAllRoutes:(id)sender {
#ifdef DEBUG_MAP
  for (id<MKAnnotation> annotation in mapView.selectedAnnotations) {
    [mapView deselectAnnotation:annotation animated:NO];
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  if (adjustStartAttractionId != nil) [addNewInternalButton setTitle:@"New" forState:UIControlStateNormal];
  [adjustStartAttractionId release];
  adjustStartAttractionId = nil;
  //tourDistanceValueLabel.text = @"";
  [adjustEndAttractionId release];
  adjustEndAttractionId = nil;
  //tourDurationValueLabel.text = @"";
  int n = 0;
  for (id routeAnnotation in mapView.annotations) {
    if ([routeAnnotation isKindOfClass:[RouteAnnotation class]]) {
      [mapView removeAnnotation:routeAnnotation];
      ++n;
    }
  }
  if (n > 0) {
    NSLog(@"All viewed routes (%d) removed", n);
  } else {
    NSEnumerator *i = [parkData.trackSegments objectEnumerator];
    while (TRUE) {
      TrackSegment *segment = [i nextObject];
      if (segment == nil) break;
      RouteAnnotation *routeAnnotation = [[RouteAnnotation alloc] initWithTrackSegment:segment];
      [mapView addAnnotation:routeAnnotation];
      [routeAnnotation release];
    }
    NSLog(@"%d routes are viewed", (int)[parkData.trackSegments count]);
  }
#endif
}

-(IBAction)deleteRoute:(id)sender {
  if (overlay != nil) {
    NSString *title = [deleteRouteButton titleForState:UIControlStateNormal];
    if ([title isEqualToString:@"Tiles"]) {
      [deleteRouteButton setTitle:@"Del" forState:UIControlStateNormal];
      return;
    } else if (overlay.selectedTile != nil) {
      [deleteRouteButton setTitle:@"Tiles" forState:UIControlStateNormal];
      NSString *mapPath = [[[MenuData parkDataPath:parkId] stringByAppendingPathComponent:@"maps"] stringByAppendingPathComponent:overlay.selectedTile];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSError *error = nil;
      //[mapView removeOverlay:overlay];
      [fileManager removeItemAtPath:mapPath error:&error];
      [overlay setNeedsDisplayInMapRect:[overlay getRectForTileFileName:overlay.selectedTile]];//mapView.visibleMapRect];
      //[mapView addOverlay:overlay];
      if (error == nil) {
        navigationTitle.title = [NSString stringWithFormat:@"%@ removed", overlay.selectedTile];
      }
      return;
    }
  }
#ifdef DEBUG_MAP
  if (selectedRoute != nil) {
    [selectedRoute deleteTrackPointAtIndex:(int)routeIndexSlider.value];
    RouteView *routeView = (RouteView *)[mapView viewForAnnotation:selectedRoute];
    [routeView setNeedsDisplay];
    routeIndexSlider.maximumValue = [selectedRoute.trackSegment.trackPoints count];
    if (routeIndexSlider.value > routeIndexSlider.maximumValue) routeIndexSlider.value = routeIndexSlider.maximumValue;
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData writeGPX:parkId];
  } else if (adjustStartAttractionId != nil) {
    ParkData *parkData = [ParkData getParkData:parkId];
    int n1 = 0;
    for (TrackSegmentId *segmentId in parkData.trackSegments) {
      TrackSegment *segment = [parkData.trackSegments objectForKey:segmentId];
      if ([[segment fromAttractionId] isEqualToString:adjustStartAttractionId] || [[segment toAttractionId] isEqualToString:adjustStartAttractionId]) ++n1;
    }
    if (adjustEndAttractionId != nil) {
      int n2 = 0;
      for (TrackSegmentId *segmentId in parkData.trackSegments) {
        TrackSegment *segment = [parkData.trackSegments objectForKey:segmentId];
        if ([[segment fromAttractionId] isEqualToString:adjustEndAttractionId] || [[segment toAttractionId] isEqualToString:adjustEndAttractionId]) ++n2;
      }
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:@"Delete attraction ID or route"
                             message:[NSString stringWithFormat:@"Delete %@ (%d) or %@ (%d) or route between them", adjustStartAttractionId, n1, adjustEndAttractionId, n2]
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                             otherButtonTitles:adjustStartAttractionId, adjustEndAttractionId, @"route", nil];
      dialog.tag = 5;
      [dialog show];
      [dialog release];
    } else {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:@"Delete attraction ID"
                             message:[NSString stringWithFormat:@"Delete %@ (%d)", adjustStartAttractionId, n1]
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                             otherButtonTitles:adjustStartAttractionId, nil];
      dialog.tag = 5;
      [dialog show];
      [dialog release];
    }
  }
#endif
}

-(IBAction)newInternal:(id)sender {
#ifdef DEBUG_MAP
  addNewInternalId = nil;
  __block NSString *highestInternalPoint = nil;
  ParkData *parkData = [ParkData getParkData:parkId];
  [parkData.parkAttractionLocations enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
    NSString *attractionId = key;
    if ([Attraction isInternalId:attractionId]) {
      if (highestInternalPoint == nil || [highestInternalPoint length] < [attractionId length] || ([highestInternalPoint length] == [attractionId length] &&[highestInternalPoint compare:attractionId] < 0)) {
        highestInternalPoint = attractionId;
      }
    }
  }];
  if (highestInternalPoint == nil) highestInternalPoint = @"i00";
  if (highestInternalPoint != nil && [highestInternalPoint length] > 1) {
    NSLog(@"Internal points are defined up to %@ (including)", highestInternalPoint);
    int i = [[highestInternalPoint substringFromIndex:1] intValue];
    addNewInternalId = [[NSString alloc] initWithFormat:@"i%02d", i+1];
    navigationTitle.title = [NSString stringWithFormat:@"Select location to add %@", addNewInternalId];
  }
#endif
}

-(IBAction)addPoint:(id)sender {
#ifdef DEBUG_MAP
  if (selectedRoute != nil) {
    [selectedRoute insertCenterTrackPointAtIndex:(int)routeIndexSlider.value];
    RouteView *routeView = (RouteView *)[mapView viewForAnnotation:selectedRoute];
    [routeView setNeedsDisplay];
    routeIndexSlider.hidden = NO;
    routeIndexSlider.maximumValue = [selectedRoute.trackSegment.trackPoints count];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData writeGPX:parkId];
  } else if (adjustStartAttractionId != nil || adjustEndAttractionId != nil) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:@"Add new attraction ID"
                           message:@"Attraction ID name"
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                           otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
    dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [dialog textFieldAtIndex:0];
    textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.text = (adjustStartAttractionId != nil)? adjustStartAttractionId : adjustEndAttractionId;
    dialog.tag = 1;
    [dialog show];
    [dialog release];
  }
#endif
}

-(IBAction)renameAttractionId:(id)sender {
#ifdef DEBUG_MAP
  if (adjustStartAttractionId != nil || adjustEndAttractionId != nil) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:@"Rename attraction ID"
                           message:@"Attraction ID name"
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                           otherButtonTitles:NSLocalizedString(@"ok", nil), nil];
    dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [dialog textFieldAtIndex:0];
    textField.keyboardAppearance = UIKeyboardAppearanceAlert;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.text = (adjustEndAttractionId != nil)? adjustEndAttractionId : adjustStartAttractionId;
    dialog.tag = 2;
    [dialog show];
    [dialog release];
  }
#endif
}

-(IBAction)valueChangeRouteIndexSlider:(id)sender {
  double v = routeIndexSlider.value;
  double r = round(v);
  if (v != r) {
    routeIndexSlider.value = r;
    RouteView *routeView = (RouteView *)[mapView viewForAnnotation:selectedRoute];
    if (routeView != nil) {
      routeView.selectedTrackPointIndex = (int)r;
      [routeView setNeedsDisplay];
    }
  }
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
	[self dismissModalViewControllerAnimated:YES];
}

-(IBAction)startStopRecording:(id)sender {
#ifdef DEBUG_MAP
  if ([LocationData isLocationDataActive]) {
    [startStopRecordingButton setTitle:@"Start" forState:UIControlStateNormal];
    LocationData *locData = [LocationData getLocationData];
    [locData unregisterViewController];
    [locData stop];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData save:NO];
  } else {
    [startStopRecordingButton setTitle:@"Stop" forState:UIControlStateNormal];
    ParkData *parkData = [ParkData getParkData:parkId];
    if (parkData.currentTrackData == nil) {
      UIAlertView *dialog = [[UIAlertView alloc]
                             initWithTitle:NSLocalizedString(@"track.name", nil)
                             message:@""
                             delegate:self
                             cancelButtonTitle:NSLocalizedString(@"ok", nil)
                             otherButtonTitles:nil];
      dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
      UITextField *textField = [dialog textFieldAtIndex:0];
      textField.autocorrectionType = UITextAutocorrectionTypeNo;
      textField.keyboardAppearance = UIKeyboardAppearanceAlert;
      textField.text = @"";
      dialog.tag = 3;
      [dialog show];
      [dialog release];
    } else {
      [self startUpdateLocationData];
    }
  }
#endif
}

-(IBAction)addAttraction:(id)sender {
#ifdef DEBUG_MAP
  if (![LocationData isLocationDataActive]) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:@"Location data error!"
                           message:@"Attractions can only be added if location data is active."
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
    return;
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  NSString *wp = [NSString stringWithFormat:@"WP%d", (int)[parkData.currentTrackData.trackSegments count]+1];
  UIAlertView *dialog = [[UIAlertView alloc]
                         initWithTitle:[NSString stringWithFormat:@"Attraction Name (%@)", wp]
                         message:wp
                         delegate:self
                         cancelButtonTitle:NSLocalizedString(@"ok", nil)
                         otherButtonTitles:nil];
  dialog.alertViewStyle = UIAlertViewStylePlainTextInput;
  UITextField *textField = [dialog textFieldAtIndex:0];
  textField.autocorrectionType = UITextAutocorrectionTypeNo;
  textField.keyboardAppearance = UIKeyboardAppearanceAlert;
  textField.text = wp;
  dialog.tag = 4;
  [dialog show];
  //[UIMenuController sharedMenuController].menuVisible = NO;
  //[textField selectAll:self];
  [dialog release];
#endif
}

//#define TRACK_NAME @"ukatst"
-(IBAction)sendData:(id)sender {
#ifdef DEBUG_MAP
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if ([MFMailComposeViewController canSendMail]) {
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;
#ifdef TRACK_NAME
    [mailController setToRecipients:[NSArray arrayWithObjects:@"wedeniwski@inpark.info", nil]];
    NSString *trackName = TRACK_NAME;
    [mailController setSubject:trackName];
    NSString *documentPath = [MenuData documentPath];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentPath error:&error];
    if (error != nil) {
      NSLog(@"Error get content of data path %@  (%@)", documentPath, [error localizedDescription]);
      error = nil;
    } else {
      NSString *suffix = [NSString stringWithFormat:@"_%@.gpx", parkId];
      for (NSString *path in files) {
        NSRange r = [path rangeOfString:trackName];
        if ([path hasSuffix:suffix] || (r.length > 0 && [path hasSuffix:@".plist"])) {
          NSString *fullPath = [documentPath stringByAppendingPathComponent:path];
          NSData *gpxData = [NSData dataWithContentsOfFile:fullPath];
          [mailController addAttachmentData:gpxData mimeType:@"text/xml" fileName:path];
        }
      }
    }
#else
    [mailController setToRecipients:[NSArray arrayWithObjects:@"wedeniwski@inpark.info", @"rau@inpark.info", nil]];
    ParkData *parkData = [ParkData getParkData:parkId];
    [parkData save:NO];
    [parkData.currentTrackData saveData];
    NSString *trackName = parkData.currentTrackData.trackName;
    [mailController setSubject:trackName];
    NSString *path = [NSString stringWithFormat:@"%@/%@.plist", [MenuData documentPath], trackName];
    NSMutableString *s = [[NSMutableString alloc] initWithCapacity:10000];
    NSData *plistData = [NSData dataWithContentsOfFile:path];
    if (plistData != nil) {
      [mailController addAttachmentData:plistData mimeType:@"text/xml" fileName:[NSString stringWithFormat:@"%@.plist", trackName]];
      NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:path];
      if (plist != nil) {
        plist = [plist objectForKey:@"IDs"];
        //NSLog(@"plist ID keys: %@", [plist allKeys]);
        for (int i = 1;; ++i) {
          NSString *attractionId = [NSString stringWithFormat:@"WP%d", i];
          NSString *aId = attractionId;
          NSDictionary *attraction = [plist objectForKey:attractionId];
          if (attraction == nil) {
            NSString *attractionId2 = [NSString stringWithFormat:@"WP%d - INTERN", i];
            attraction = [plist objectForKey:attractionId2];
            if (attraction != nil) attractionId = attractionId2;
          }
          if (attraction == nil) {
            NSString *attractionId2 = [NSString stringWithFormat:@"WP%d", ++i];
            attraction = [plist objectForKey:attractionId2];
            if (attraction == nil) break;
            [s appendString:attractionId];
            [s appendString:@" ?\n"];
            attractionId = attractionId2;
          }
          TrackSegment *segmentToAttraction = nil;
          for (TrackSegment *s in parkData.currentTrackData.trackSegments) {
            if ([[s toAttractionId] isEqualToString:attractionId] || [[s toAttractionId] isEqualToString:aId]) {
              segmentToAttraction = s;
              break;
            }
          }
          if (segmentToAttraction != nil) {
            ExtendedTrackPoint *t = (ExtendedTrackPoint *)[segmentToAttraction toTrackPoint];
            [s appendString:[CalendarData stringFromTime:[NSDate dateWithTimeIntervalSince1970:t.recordTime] considerTimeZoneAbbreviation:nil]];
            [s appendString:@" "];
          }
          [s appendString:attractionId];
          id name = [attraction objectForKey:@"Name"];
          if (name != nil && [name isKindOfClass:[NSDictionary class]]) name = [name objectForKey:@"de"];
          if (name != nil) {
            [s appendString:@": "];
            [s appendString:name];
            if (segmentToAttraction != nil) {
              ExtendedTrackPoint *t = (ExtendedTrackPoint *)[segmentToAttraction toTrackPoint];
              [s appendFormat:@" (%.6f,%6f", t.latitude, t.longitude];
              TrackPoint *l = [parkData getAttractionLocation:name];
              if (l != nil) [s appendFormat:@" - %.2f", [l distanceTo:t]];
              [s appendString:@")"];
            }
          }
          [s appendString:@"\n"];
        }
      }
    }
    NSData *gpxData = [NSData dataWithContentsOfFile:[parkData.currentTrackData gpxFilePath]];
    if (gpxData != nil) {
      [s appendFormat:@"gpx file size %@\n", [Update sizeToString:[gpxData length]]];
      [mailController addAttachmentData:gpxData mimeType:@"text/xml" fileName:[NSString stringWithFormat:@"%@.gpx", trackName]];
    }
    [mailController setMessageBody:s isHTML:NO];
    [s release];
#endif
    [self presentViewController:mailController animated:YES completion:nil];
    [mailController release];
  }
  [pool release];
#endif
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  NSLog(@"Memory waring at Navigation View Controller");
  viewInitialized = NO;
}

-(void)viewDidUnload {
  [super viewDidUnload];
  viewInitialized = NO;
  mapView = nil;
  copyrightLabel = nil;
  accuracyLabel = nil;
  topNavigationBar = nil;
  navigationTitle = nil;
  helpButton = nil;
  cellOwner = nil;
  minusLatitude = nil;
  minusminusLatitude = nil;
  plusLatitude = nil;
  plusplusLatitude = nil;
  minusLongitude = nil;
  minusminusLongitude = nil;
  plusLongitude = nil;
  plusplusLongitude = nil;
  reloadButton = nil;
  viewAllRoutesButton = nil;
  connectRoutesButton = nil;
  deleteRouteButton = nil;
  addNewInternalButton = nil;
  addPointButton = nil;
  renameButton = nil;
  routeIndexSlider = nil;
  sendDataButton = nil;
  locationButton = nil;
  startStopRecordingButton = nil;
  addAttractionButton = nil;
}

-(void)dealloc {
  if (overlay != nil) {
    [mapView removeOverlay:overlay];
    [overlay release];
    overlay = nil;
  }
#ifdef DEBUG_MAP
  [addNewInternalId release];
  addNewInternalId = nil;
#endif
  [tapInterceptor release];
  [mapView release];
  [copyrightLabel release];
  [accuracyLabel release];
  [topNavigationBar release];
  [navigationTitle release];
  [helpButton release];
  [cellOwner release];
  [minusLatitude release];
  [minusminusLatitude release];
  [plusLatitude release];
  [plusplusLatitude release];
  [minusLongitude release];
  [minusminusLongitude release];
  [plusLongitude release];
  [plusplusLongitude release];
  [reloadButton release];
  [viewAllRoutesButton release];
  [connectRoutesButton release];
  [deleteRouteButton release];
  [addNewInternalButton release];
  [addPointButton release];
  [renameButton release];
  [routeIndexSlider release];
  [sendDataButton release];
  [locationButton release];
  [startStopRecordingButton release];
  [addAttractionButton release];
  [super dealloc];
}

@end
