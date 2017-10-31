//
//  AttractionRouteViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 09.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "LocationData.h"
#import "ParkOverlayView.h"

#define ROUTE_REFRESH_WITHOUT_HIDING -2.0

@interface AttractionRouteViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UIActionSheetDelegate, LocationDataDelegate> {
	id delegate;
  NSArray *detailedTourDescription;
  NSString *tourDistance;
  NSString *walkingTime;
  CGRect originalPathTableViewFrame;
  ParkOverlayView *overlay;
  MKMapRect lastGoodMapRect;
  BOOL manuallyChangingMapRect;
  BOOL satelliteMap;
  BOOL refreshRoute;
  MKZoomScale previousZoomScale;

  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet MKMapView *mapView;
  IBOutlet UILabel *copyrightLabel;
  IBOutlet UILabel *accuracyLabel;
  IBOutlet UIButton *locationButton;
  IBOutlet UITableView *pathTableView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractionId:(NSString *)aId;

-(IBAction)loadBackView:(id)sender;
//-(IBAction)helpView:(id)sender;
-(IBAction)routeView:(id)sender;
-(IBAction)viewLocation:(id)sender;
-(IBAction)viewSettings:(id)sender;

+(MKCoordinateSpan)coordinateSpanWithMapView:(MKMapView *)map centerCoordinate:(CLLocationCoordinate2D)centerCoordinate andZoomLevel:(double)zoomLevel;
+(BOOL)setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate onMapView:(MKMapView *)mapView zoomLevel:(double)zoomLevel animated:(BOOL)animated;

@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleNavigationItem;
@property (retain, nonatomic) MKMapView *mapView;
@property (retain, nonatomic) UILabel *copyrightLabel;
@property (retain, nonatomic) UILabel *accuracyLabel;
@property (retain, nonatomic) UIButton *locationButton;
@property (retain, nonatomic) UITableView *pathTableView;

@end
