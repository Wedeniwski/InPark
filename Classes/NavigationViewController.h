//
//  NavigationViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 03.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "TourData.h"
#import "LocationData.h"
#import "ParkOverlayView.h"
#import "MapPin.h"
#import "RouteView.h"
#import "CellOwner.h"
#import "WildcardGestureRecognizer.h"
#import "CategoriesSelectionViewController.h"

@interface NavigationViewController : UIViewController <MKMapViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate, UITextFieldDelegate, LocationDataDelegate, CategoriesSelectionDelegate> {
@private
	id delegate;

  MKMapRect lastGoodMapRect;
  BOOL manuallyChangingMapRect;
  BOOL refreshRoute;
  MKZoomScale previousZoomScale;

#ifdef DEBUG_MAP
  NSString *adjustStartAttractionId;
  NSString *adjustEndAttractionId;
  NSString *addNewInternalId;
#endif
  ParkOverlayView *overlay;
  WildcardGestureRecognizer *tapInterceptor;

@public
  IBOutlet MKMapView *mapView;
  IBOutlet UILabel *copyrightLabel;
  IBOutlet UILabel *accuracyLabel;

  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *navigationTitle;
  IBOutlet UIButton *helpButton;
  IBOutlet CellOwner *cellOwner;

  // Develop UI:
  IBOutlet UIButton *minusLatitude;
  IBOutlet UIButton *minusminusLatitude;
  IBOutlet UIButton *plusLatitude;
  IBOutlet UIButton *plusplusLatitude;
  IBOutlet UIButton *minusLongitude;
  IBOutlet UIButton *minusminusLongitude;
  IBOutlet UIButton *plusLongitude;
  IBOutlet UIButton *plusplusLongitude;
  IBOutlet UIButton *reloadButton;
  IBOutlet UIButton *viewAllRoutesButton;
  IBOutlet UIButton *connectRoutesButton;
  IBOutlet UIButton *deleteRouteButton;
  IBOutlet UIButton *addNewInternalButton;
  IBOutlet UIButton *addPointButton;
  IBOutlet UIButton *renameButton;
  IBOutlet UISlider *routeIndexSlider;
  IBOutlet UIButton *sendDataButton;
  IBOutlet UIButton *locationButton;
  IBOutlet UIButton *startStopRecordingButton;
  IBOutlet UIButton *addAttractionButton;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId;

-(void)setupSelectedCategoriesWithMenuId:(NSString *)menuId;
-(void)updateMapView;

-(IBAction)loadBackView:(id)sender;
-(IBAction)categoriesView:(id)sender;
-(IBAction)helpView:(id)sender;
-(IBAction)viewLocation:(id)sender;
-(IBAction)viewSettings:(id)sender;
-(IBAction)reloadData:(id)sender;
-(IBAction)minusLatitude:(id)sender;
-(IBAction)minusminusLatitude:(id)sender;
-(IBAction)plusLatitude:(id)sender;
-(IBAction)plusplusLatitude:(id)sender;
-(IBAction)minusLongitude:(id)sender;
-(IBAction)minusminusLongitude:(id)sender;
-(IBAction)plusLongitude:(id)sender;
-(IBAction)plusplusLongitude:(id)sender;
-(IBAction)viewAllRoutes:(id)sender;
-(IBAction)connectRoutes:(id)sender;
-(IBAction)deleteRoute:(id)sender;
-(IBAction)newInternal:(id)sender;
-(IBAction)addPoint:(id)sender;
-(IBAction)renameAttractionId:(id)sender;
-(IBAction)valueChangeRouteIndexSlider:(id)sender;
-(IBAction)startStopRecording:(id)sender;
-(IBAction)addAttraction:(id)sender;
-(IBAction)sendData:(id)sender;

@property (readonly) id delegate;
@property (readonly, nonatomic) ParkOverlayView *overlay;
@property (retain, nonatomic) MKMapView *mapView;
@property (retain, nonatomic) UILabel *copyrightLabel;
@property (retain, nonatomic) UILabel *accuracyLabel;
@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *navigationTitle;
@property (retain, nonatomic) UIButton *helpButton;
@property (retain, nonatomic) CellOwner *cellOwner;

@property (retain, nonatomic) UIButton *minusLatitude;
@property (retain, nonatomic) UIButton *minusminusLatitude;
@property (retain, nonatomic) UIButton *plusLatitude;
@property (retain, nonatomic) UIButton *plusplusLatitude;
@property (retain, nonatomic) UIButton *minusLongitude;
@property (retain, nonatomic) UIButton *minusminusLongitude;
@property (retain, nonatomic) UIButton *plusLongitude;
@property (retain, nonatomic) UIButton *plusplusLongitude;
@property (retain, nonatomic) UIButton *reloadButton;
@property (retain, nonatomic) UIButton *viewAllRoutesButton;
@property (retain, nonatomic) UIButton *connectRoutesButton;
@property (retain, nonatomic) UIButton *deleteRouteButton;
@property (retain, nonatomic) UIButton *addNewInternalButton;
@property (retain, nonatomic) UIButton *addPointButton;
@property (retain, nonatomic) UIButton *renameButton;
@property (retain, nonatomic) UISlider *routeIndexSlider;
@property (retain, nonatomic) UIButton *sendDataButton;
@property (retain, nonatomic) UIButton *locationButton;
@property (retain, nonatomic) UIButton *startStopRecordingButton;
@property (retain, nonatomic) UIButton *addAttractionButton;

@end
