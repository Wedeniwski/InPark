//
//  ParkingViewController.m
//  InPark
//
//  Created by Sebastian Wedeniwski on 07.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import "ParkingViewController.h"
#import "AttractionViewController.h"
#import "AttractionRouteViewController.h"
#import "GeneralInfoViewController.h"
#import "AttractionAnnotation.h"
#import "RouteAnnotation.h"
#import "RouteView.h"
#import "MapPin.h"
#import "ParkData.h"
#import "TrackData.h"
#import "SettingsData.h"
#import "HelpData.h"
#import "MenuData.h"
#import "Conversions.h"
#import "Colors.h"

@interface ParkingAnnotation : NSObject<MKAnnotation> {
  CLLocationCoordinate2D coordinate;
  NSString *mTitle;
  NSString *mSubTitle;
}
@end

@implementation ParkingAnnotation

@synthesize coordinate;

-(NSString *)subtitle {
  return @"";
}

-(NSString *)title {
  return @"Parking";
}

-(id)initWithCoordinate:(CLLocationCoordinate2D)c {
  coordinate = c;
  return self;
}
@end


@implementation ParkingViewController

@synthesize delegate;
@synthesize topNavigationBar;
@synthesize titleNavigationItem;
@synthesize notesView;
@synthesize mapView;
@synthesize copyrightLabel, accuracyLabel, accuracyValueLabel;
@synthesize helpButton;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner title:(NSString *)tName parkId:(NSString *)pId {
  self = [super initWithNibName:nibNameOrNil bundle:nil];
  if (self != nil) {
    delegate = owner;
    locationRegistered = NO;
    titleName = [tName retain];
    parkId = [pId retain];
  }
  return self;
}

-(void)trackNameInput {
  ParkData *parkData = [ParkData getParkData:parkId];
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
  dialog.tag = 1;
  [dialog show];
  //[textField selectAll:self];
  [dialog release];
}

-(void)threadTrackNameInput {
  [self performSelectorOnMainThread:@selector(trackNameInput) withObject:nil waitUntilDone:NO];
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
    overlay = [[ParkOverlayView alloc] initWithRegion:lastGoodMapRect parkId:parkId];
    [mapView addOverlay:overlay];
    ParkData *parkData = [ParkData getParkData:parkId];
    copyrightLabel.text = (parkData.mapCopyright != nil)? parkData.mapCopyright : NSLocalizedString(@"copyright", nil);
  }
}

-(void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [Colors darkBlue];
  ParkData *parkData = [ParkData getParkData:parkId];
  topNavigationBar.tintColor = [Colors darkBlue];
  titleNavigationItem.leftBarButtonItem.title = NSLocalizedString(@"back", nil);
  titleNavigationItem.title = titleName;
  titleNavigationItem.rightBarButtonItem.title = NSLocalizedString(@"parking.mark", nil);
  titleNavigationItem.rightBarButtonItem.enabled = NO;
  notesView.backgroundColor = [UIColor clearColor];
  if (parkData.currentTrackData == nil || parkData.currentTrackData.parkingNotes == nil) {
    if (parkData.lastParkingNotes == nil) {
      notesView.text = NSLocalizedString(@"parking.notes", nil);
    } else {
      notesView.text = [NSString stringWithFormat:NSLocalizedString(@"parking.last.notes", nil), parkData.lastParkingNotes];
    }
    notesView.textColor = [UIColor lightGrayColor];
  } else {
    notesView.text = parkData.currentTrackData.parkingNotes;
  }
  [notesView resignFirstResponder];
  accuracyLabel.text = NSLocalizedString(@"parking.accuracy", nil);
  accuracyLabel.textColor = [Colors lightText];
  accuracyLabel.backgroundColor = [UIColor clearColor];

  BOOL trackRegistered = NO;
  if ([LocationData isLocationDataActive]) {
    LocationData *locData = [LocationData getLocationData];
    [locData registerViewController:self];
    trackRegistered = [locData isDataPoolRegistered:parkId];
    mapView.showsUserLocation = YES;
  }
  manuallyChangingMapRect = NO;
  MKCoordinateRegion region = [parkData getParkRegion];
  [mapView setRegion:region animated:NO];
  overlay = nil;
  [self setMapType];
  if (parkData.currentTrackData == nil || (!trackRegistered && [parkData.currentTrackData.trackSegments count] == 0)) {
    mapView.region = [parkData getParkRegion];
    if (parkData.currentTrackData == nil || (!trackRegistered && ([parkData.currentTrackData.currentTrackPoints count] == 0 || ![parkData.currentTrackData.fromAttractionId isEqualToString:PARKING_ATTRACTION_ID]))) {
      if (parkData.lastTrackFromParking != nil && [parkData.lastTrackFromParking.trackPoints count] > 0) {
        TrackPoint *t = [parkData.lastTrackFromParking.trackPoints objectAtIndex:0];
        CLLocationCoordinate2D c = (CLLocationCoordinate2D){ t.latitude, t.longitude };
        ParkingAnnotation *annotation = [[ParkingAnnotation alloc] initWithCoordinate:c];
        [mapView addAnnotation:annotation];
        [annotation release];
        if (![AttractionRouteViewController setCenterCoordinate:c onMapView:mapView zoomLevel:16 animated:YES]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
        titleNavigationItem.rightBarButtonItem.enabled = YES;
      } else {
        TrackPoint *trackPoint = [parkData getAttractionLocation:[parkData getEntryOfPark:nil]];
        if (trackPoint != nil) {
          CLLocationCoordinate2D c = (CLLocationCoordinate2D){ trackPoint.latitude, trackPoint.longitude };
          if (![AttractionRouteViewController setCenterCoordinate:c onMapView:mapView zoomLevel:15 animated:YES]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
        } else {
          if (![AttractionRouteViewController setCenterCoordinate:mapView.region.center onMapView:mapView zoomLevel:15 animated:YES]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
        }
        [self performSelectorInBackground:@selector(threadTrackNameInput) withObject:nil];
      }
    } else {
      TrackPoint *t = [parkData.currentTrackData.currentTrackPoints objectAtIndex:0];
      CLLocationCoordinate2D c = (CLLocationCoordinate2D){ t.latitude, t.longitude };
      ParkingAnnotation *annotation = [[ParkingAnnotation alloc] initWithCoordinate:c];
      //[mapView removeAnnotations:mapView.annotations];
      [mapView addAnnotation:annotation];
      [annotation release];
      if (![AttractionRouteViewController setCenterCoordinate:c onMapView:mapView zoomLevel:16 animated:YES]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
      titleNavigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
      [self startUpdateLocationData];
    }
  } else {
    titleNavigationItem.rightBarButtonItem = nil;
    TrackSegment *trackSegment = [parkData.currentTrackData getTrackSegmentFromParking];
    if (trackSegment == nil && parkData.lastTrackFromParking != nil) {
      trackSegment = parkData.lastTrackFromParking;
    }
    if (trackSegment != nil) {
      RouteAnnotation *routeAnnotation = [[RouteAnnotation alloc] initWithTrackSegment:trackSegment];
      [mapView addAnnotation:routeAnnotation];
      mapView.region = [routeAnnotation getRegion];
      if ([trackSegment.trackPoints count] > 0) {
        TrackPoint *t = [trackSegment.trackPoints objectAtIndex:0];
        CLLocationCoordinate2D c = (CLLocationCoordinate2D){ t.latitude, t.longitude };
        if (![AttractionRouteViewController setCenterCoordinate:c onMapView:mapView zoomLevel:16 animated:YES]) previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
      }
      [routeAnnotation release];
    }
  }
  if (mapView.showsUserLocation && mapView.userLocation != nil) {
    UIView *user = [mapView viewForAnnotation:mapView.userLocation];
    if (user != nil) [mapView.superview bringSubviewToFront:user];
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

-(void)startUpdateLocationData {
  ParkData *parkData = [ParkData getParkData:parkId];
  LocationData *locData = [LocationData getLocationData];
  [locData registerDataPool:parkData.currentTrackData parkId:parkId];
  [locData registerViewController:self];
  [locData start];
  locationRegistered = YES;
  mapView.showsUserLocation = YES;
  if (mapView.userLocation != nil) {
    UIView *user = [mapView viewForAnnotation:mapView.userLocation];
    if (user != nil) [mapView.superview bringSubviewToFront:user];
  }
}

-(void)didUpdateLocationData {
  LocationData *locData = [LocationData getLocationData];
  double distanceToPark = 0.0;
  if (titleNavigationItem.rightBarButtonItem != nil && !titleNavigationItem.rightBarButtonItem.enabled) {
    BOOL enabled = NO;
    if (locData.lastUpdatedLocation != nil) {
      mapView.centerCoordinate = locData.lastUpdatedLocation.coordinate;
      ParkData *parkData = [ParkData getParkData:parkId];
      MKCoordinateRegion region = [parkData getParkRegion];
      TrackPoint *t1 = [[TrackPoint alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude];
      TrackPoint *t2 = [[TrackPoint alloc] initWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude];
      distanceToPark = [t1 distanceTo:t2];
      enabled = (distanceToPark < 10000.0); // Parkplatz merken ist nur innerhalb 10km vom Park möglich
      [t1 release];
      [t2 release];
    }
    titleNavigationItem.rightBarButtonItem.enabled = enabled;
  }
  if (locData.lastUpdatedLocation != nil) {
    double accuracy = locData.lastUpdatedLocation.horizontalAccuracy;
    if (accuracy < 0.0) {
      accuracyValueLabel.text = @"?";
    } else {
      NSString *t = nil;
      SettingsData *settings = [SettingsData getSettingsData];
      BOOL metric = [settings isMetricMeasure];
      t = distanceToString(metric, accuracy);
      ParkData *parkData = [ParkData getParkData:parkId];
      if (![parkData isCurrentlyInsidePark]) {
        if (distanceToPark > 0.0) {
          t = [t stringByAppendingFormat:NSLocalizedString(@"parking.accuracy.distance.to.park", nil), distanceToString(metric, distanceToPark)];
        } else {
          t = [t stringByAppendingString:NSLocalizedString(@"parking.accuracy.not.inside.park", nil)];
        }
        accuracyValueLabel.textColor = [Colors midWaitingTime];
      } else {
        accuracyValueLabel.textColor = [Colors lightText];
      }
      accuracyValueLabel.text = t;
    }
  }
}

#pragma mark -
#pragma mark Actions

-(IBAction)loadBackView:(id)sender {
  mapView.delegate = nil;  // map might still sending messages to the delegate
  ParkData *parkData = [ParkData getParkData:parkId];
  [parkData save:NO];
  if ([LocationData isLocationDataInitialized]) {
    LocationData *locData = [LocationData getLocationData];
    [locData unregisterViewController];
  }
  /*if (locationRegistered) {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"parking.accuracy.continue.location.title", nil)
                           message:NSLocalizedString(@"parking.accuracy.continue.location.text", nil)
                           delegate:self
                           cancelButtonTitle:NSLocalizedString(@"yes", nil)
                           otherButtonTitles:NSLocalizedString(@"no", nil), nil];
    dialog.tag = 2;
    [dialog show];
    [dialog release];
  } else {*/
  [delegate dismissModalViewControllerAnimated:(sender != nil)];
  //}
}

-(IBAction)helpView:(id)sender {
  [notesView resignFirstResponder];
  HelpData *helpData = [HelpData getHelpData];
  NSString *page = [helpData.pages objectForKey:@"MENU_PARKING"];
  NSString *title = [helpData.titles objectForKey:@"MENU_PARKING"];
  if (title != nil && page != nil) {
    GeneralInfoViewController *controller = [[GeneralInfoViewController alloc] initWithNibName:@"GeneralInfoView" owner:self fileName:nil title:title];
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    controller.content = page;
    [self presentViewController:controller animated:YES completion:nil];
    [controller release];
  }
}

-(IBAction)allView:(id)sender {
  titleNavigationItem.rightBarButtonItem = nil;
  ParkData *parkData = [ParkData getParkData:parkId];
  if (parkData.currentTrackData != nil) {
    [mapView removeAnnotations:mapView.annotations];
    for (TrackSegment *s in parkData.currentTrackData.trackSegments) {
      Attraction *a = [Attraction getAttraction:parkId attractionId:s.toAttractionId];
      if (a != nil) {
        MapPin *pin = [[MapPin alloc] initWithAttractionId:s.fromAttractionId parkId:parkId];
        [mapView addAnnotation:pin];
        [pin release];
      }
      RouteAnnotation *routeAnnotation = [[RouteAnnotation alloc] initWithTrackSegment:s];
      [mapView addAnnotation:routeAnnotation];
      [routeAnnotation release];
    }
  }
}

-(IBAction)markLocation:(id)sender {
  ParkData *parkData = [ParkData getParkData:parkId];
  if ([LocationData isLocationDataActive]) {
    TrackPoint *t = [parkData.currentTrackData deleteCurrentTrackExceptLastPoint];
    CLLocationCoordinate2D c = (CLLocationCoordinate2D){ t.latitude, t.longitude };
    ParkingAnnotation *annotation = [[ParkingAnnotation alloc] initWithCoordinate:c];
    [mapView removeAnnotations:mapView.annotations];
    [mapView addAnnotation:annotation];
    [annotation release];
    [parkData save:NO];  // ToDo: nur gpx Datei speichern, d.h. [parkData.currentTourData saveData];
    titleNavigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
    [notesView resignFirstResponder];
  } else if (parkData.currentTrackData == nil) {
    titleNavigationItem.rightBarButtonItem.enabled = NO;
    [self performSelectorInBackground:@selector(threadTrackNameInput) withObject:nil];
  } else {
    UIAlertView *dialog = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"parking.accuracy.location.title", nil)
                           message:NSLocalizedString(@"parking.accuracy.location.text", nil)
                           delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"ok", nil)
                           otherButtonTitles:nil];
    [dialog show];
    [dialog release];
  }
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
#pragma mark Text view delegate

-(void)textViewDidBeginEditing:(UITextView *)textView {
  ParkData *parkData = [ParkData getParkData:parkId];
  if (parkData.currentTrackData.parkingNotes == nil) {
    notesView.text = @"";
    notesView.textColor = [Colors lightText];
  }
}

-(void)textViewDidEndEditing:(UITextView *)textView {
  ParkData *parkData = [ParkData getParkData:parkId];
  if (parkData.currentTrackData.parkingNotes == nil) {
    notesView.text = (parkData.lastParkingNotes == nil)? NSLocalizedString(@"parking.notes", nil) : [NSString stringWithFormat:NSLocalizedString(@"parking.last.notes", nil), parkData.lastParkingNotes];
    notesView.textColor = [UIColor lightGrayColor];
  }
}

-(void)textViewDidChange:(UITextView *)textView {
  if ([notesView.text hasSuffix:@"\n"]) {
    notesView.text = [notesView.text substringToIndex:[notesView.text length]-1];
    [notesView resignFirstResponder];
    return;
  }
  ParkData *parkData = [ParkData getParkData:parkId];
  parkData.currentTrackData.parkingNotes = ([notesView.text length] == 0)? nil : notesView.text;
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
#pragma mark Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView.tag == 1) {
    // start Track
    UITextField *textField = [alertView textFieldAtIndex:0];
    NSString *trackNameInput = (textField != nil)? [textField.text retain] : nil;
    ParkData *parkData = [ParkData getParkData:parkId];
    if (trackNameInput == nil) trackNameInput = [parkData.currentTourName retain];
    TrackData *trackData = [[TrackData alloc] initWithTrackName:trackNameInput parkId:parkId fromAttractionId:PARKING_ATTRACTION_ID];
    parkData.currentTrackData = trackData;
    [trackData release];
    [self startUpdateLocationData];
    [trackNameInput release];
  } else if (alertView.tag == 2) {
    if (buttonIndex == 1) {
      LocationData *locData = [LocationData getLocationData];
      [locData stop];
    }
    [delegate dismissModalViewControllerAnimated:YES];
  }
}

#pragma mark -
#pragma mark Map view delegate

-(MKOverlayView *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)olay {
  return (ParkOverlayView *)olay;
}

-(void)mapView:(MKMapView *)map regionWillChangeAnimated:(BOOL)animated {
  if (manuallyChangingMapRect) return;
  for (id annotation in mapView.annotations) {
    if ([annotation isKindOfClass:[RouteAnnotation class]]) {
      RouteView *routeView = (RouteView *)[mapView viewForAnnotation:annotation];
      routeView.hidden = YES;
    }
  }
}

-(void)mapView:(MKMapView *)map regionDidChangeAnimated:(BOOL)animated {
  if (manuallyChangingMapRect) return; //prevents possible infinite recursion when we call setVisibleMapRect below
  int zoomLevel = [ParkOverlayView zoomLevelForMap:map];
  //NSLog(@"ZOOM Level: %d", zoomLevel);
  if ((overlay != nil && !MKMapRectIntersectsRect(overlay.boundingMapRect, map.visibleMapRect)) || zoomLevel < 15) {
    manuallyChangingMapRect = YES;
    [mapView setVisibleMapRect:lastGoodMapRect animated:YES];
    manuallyChangingMapRect = NO;
  }   
  BOOL refreshRoute = (previousZoomScale != (CGFloat)(map.bounds.size.width / map.visibleMapRect.size.width));
  if (refreshRoute) {
    NSMutableArray *annotations = [[NSMutableArray alloc] initWithCapacity:[mapView.annotations count]];
    for (id annotation in mapView.annotations) {
      if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        [annotations addObject:annotation];
      }
    }
    [mapView removeAnnotations:annotations];
    [mapView addAnnotations:annotations];
    [annotations release];
  } else {
    for (id annotation in mapView.annotations) {
      if ([annotation isKindOfClass:[RouteAnnotation class]]) {
        RouteView *routeView = (RouteView *)[mapView viewForAnnotation:annotation];
        routeView.hidden = NO;
      }
    }
  }
  lastGoodMapRect = mapView.visibleMapRect;
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
    pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [pin updateImage:4.0f/([ParkOverlayView zoomLevelForMap:map]-14.0f)];
    return pin;
  } else if ([annotation isKindOfClass:[ParkingAnnotation class]]) {
    MKPinAnnotationView *pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"ParkingLoc"];
    if (pin == nil) {
      pin = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ParkingLoc"] autorelease];
      pin.pinColor = MKPinAnnotationColorRed;
      pin.animatesDrop = YES;
      pin.canShowCallout = NO;
    }
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
    previousZoomScale = ROUTE_REFRESH_WITHOUT_HIDING;
    [mapView setCenterCoordinate:mapPin.coordinate animated:YES];
    [pool release];
  }
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
  if ([view isKindOfClass:[AttractionAnnotation class]]) {
    MapPin *mapPin = (MapPin *)view.annotation;
    view.alpha = (mapPin.overlap)? 0.7f : 1.0f;
    view.leftCalloutAccessoryView = nil;
  }
}

-(void)mapView:(MKMapView *)map annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
  MapPin *p = (MapPin *)view.annotation;
  AttractionViewController *controller = [[AttractionViewController alloc] initWithNibName:@"AttractionView" owner:self attraction:[Attraction getAttraction:parkId attractionId:p.attractionId] parkId:parkId];
  controller.enableViewOnMap = NO;
  controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentViewController:controller animated:YES completion:nil];
  [controller release];
}

#pragma mark -
#pragma mark Memory management

-(void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
   
  // Release any cached data, images, etc. that aren't in use.
}

-(void)viewDidUnload {
  [super viewDidUnload];
  titleName = nil;
  parkId = nil;
  overlay = nil;
  topNavigationBar = nil;
  titleNavigationItem = nil;
  notesView = nil;
  mapView = nil;
  copyrightLabel = nil;
  accuracyLabel = nil;
  accuracyValueLabel = nil;
  helpButton = nil;
}

-(void)dealloc {
  [titleName release];
  [parkId release];
  [overlay release];
  [topNavigationBar release];
  [titleNavigationItem release];
  [notesView release];
  [mapView release];
  [copyrightLabel release];
  [accuracyLabel release];
  [accuracyValueLabel release];
  [helpButton release];
  [super dealloc];
}

@end
