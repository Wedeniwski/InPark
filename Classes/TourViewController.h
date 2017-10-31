//
//  TourViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.08.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "TourData.h"
#import "LocationData.h"
#import "WaitingTimeData.h"
#import "CellOwner.h"
#import "RouteViewHighLightTableCell.h"
#import "ParkOverlayView.h"
#import "Facebook.h"

@interface TourViewController : UIViewController <MKMapViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITableViewDelegate, UITextFieldDelegate, MFMailComposeViewControllerDelegate, LocationDataDelegate, WaitingTimeDataDelegate, FBSessionDelegate> {
@private
	id delegate;
  Facebook *facebook;
  BOOL canMoveRow;
  BOOL viewAlsoDone;
  ParkOverlayView *overlay;
  MKMapRect lastGoodMapRect;
  BOOL manuallyChangingMapRect;
  BOOL refreshRoute;
  MKZoomScale previousZoomScale;
  UIColor *originalDistanceLabelColor;
  RouteViewHighLightTableCell *highLightTableCell;
  
@public
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *navigationTitle;
  IBOutlet UITableView *tourTableView;
  IBOutlet UIActivityIndicatorView *startActivityIndicator;
  IBOutlet UILabel *totalTourLabel;
  IBOutlet UIButton *helpButton;
  IBOutlet UIButton *locationButton;
  IBOutlet UIToolbar *bottomToolbar;
  IBOutlet UIToolbar *editBottomToolbar;
  IBOutlet UIToolbar *doneBottomToolbar;
  IBOutlet UIToolbar *timePickerBottomToolbar;
  IBOutlet UIBarButtonItem *tourStartButton;
  IBOutlet UIBarButtonItem *tourMapButton;
  IBOutlet UIBarButtonItem *tourCompletedButton;
  IBOutlet UIBarButtonItem *tourButton;
  IBOutlet UIBarButtonItem *addButton;
  IBOutlet UIBarButtonItem *tourItemsButton;
  IBOutlet UIBarButtonItem *editButton;
  IBOutlet UIBarButtonItem *timePickerClearButton;
  IBOutlet UIBarButtonItem *timePickerDoneButton;
  IBOutlet CellOwner *cellOwner;
  IBOutlet UIView *backgroundTimePicker;
  IBOutlet UIDatePicker *timePicker;
  IBOutlet MKMapView *mapView;
  IBOutlet UILabel *copyrightLabel;
  IBOutlet UILabel *accuracyLabel;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)delegate parkId:(NSString *)pId;

-(NSArray *)attractionIdsWhichFits:(NSArray *)attractionIds;
-(void)addAttractionIds:(NSArray *)attractionIds;

-(void)addRouteViewPath:(NSArray *)path;
-(void)updateMapView;
-(void)updateViewValues:(double)nowOptimized enableScroll:(BOOL)enableScroll;
-(void)updateTourData;
-(void)switchAttractionDone:(int)row closed:(BOOL)closed toTourItem:(BOOL)toTourItem;
-(void)askIfTourOptimizing;

-(IBAction)loadBackView:(id)sender;
-(void)startUpdateLocationData;
-(IBAction)startTour:(id)sender;
-(IBAction)mapViewAction:(id)sender;
-(IBAction)tourCompletedAction:(id)sender;
-(IBAction)helpView:(id)sender;
-(IBAction)tourAction:(id)sender;
-(IBAction)addAction:(id)sender;
-(IBAction)tourItemsAction:(id)sender;
-(IBAction)editAction:(id)sender;
-(IBAction)viewLocation:(id)sender;
-(void)displayComposerSheet:(TrackData *)trackData;
-(IBAction)clearPreferredTime:(id)sender;
-(IBAction)setPreferredTime:(id)sender;
-(IBAction)timePickerValueChanged:(id)sender;

-(void)publishTrackAtFacebook:(TrackData *)trackData;

@property (readonly) id delegate;
@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *navigationTitle;
@property (retain, nonatomic) UITableView *tourTableView;
@property (retain, nonatomic) UIActivityIndicatorView *startActivityIndicator;
@property (retain, nonatomic) UILabel *totalTourLabel;
@property (retain, nonatomic) UIButton *helpButton;
@property (retain, nonatomic) UIButton *locationButton;
@property (retain, nonatomic) UIToolbar *bottomToolbar;
@property (retain, nonatomic) UIToolbar *editBottomToolbar;
@property (retain, nonatomic) UIToolbar *doneBottomToolbar;
@property (retain, nonatomic) UIToolbar *timePickerBottomToolbar;
@property (retain, nonatomic) UIBarButtonItem *tourStartButton;
@property (retain, nonatomic) UIBarButtonItem *tourMapButton;
@property (retain, nonatomic) UIBarButtonItem *tourCompletedButton;
@property (retain, nonatomic) UIBarButtonItem *tourButton;
@property (retain, nonatomic) UIBarButtonItem *addButton;
@property (retain, nonatomic) UIBarButtonItem *tourItemsButton;
@property (retain, nonatomic) UIBarButtonItem *editButton;
@property (retain, nonatomic) UIBarButtonItem *timePickerClearButton;
@property (retain, nonatomic) UIBarButtonItem *timePickerDoneButton;
@property (retain, nonatomic) CellOwner *cellOwner;
@property (retain, nonatomic) UIView *backgroundTimePicker;
@property (retain, nonatomic) UIDatePicker *timePicker;
@property (retain, nonatomic) MKMapView *mapView;
@property (retain, nonatomic) UILabel *copyrightLabel;
@property (retain, nonatomic) UILabel *accuracyLabel;

@end
