//
//  ParkingViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 07.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "LocationData.h"
#import "ParkOverlayView.h"

@interface ParkingViewController : UIViewController <LocationDataDelegate, UITextFieldDelegate, MKMapViewDelegate, UIActionSheetDelegate> {
	id delegate;
  BOOL locationRegistered;
  NSString *titleName;
  NSString *parkId;
  ParkOverlayView *overlay;
  MKMapRect lastGoodMapRect;
  BOOL manuallyChangingMapRect;
  MKZoomScale previousZoomScale;

  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UITextView *notesView;
  IBOutlet MKMapView *mapView;
  IBOutlet UILabel *copyrightLabel;
  IBOutlet UILabel *accuracyLabel;
  IBOutlet UILabel *accuracyValueLabel;
  IBOutlet UIButton *helpButton;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner title:(NSString *)tName parkId:(NSString *)pId;

-(void)startUpdateLocationData;
-(void)didUpdateLocationData;
  
-(IBAction)loadBackView:(id)sender;
-(IBAction)helpView:(id)sender;
-(IBAction)allView:(id)sender;
-(IBAction)markLocation:(id)sender;
-(IBAction)viewSettings:(id)sender;

@property (readonly) id delegate;
@property (nonatomic, retain) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleNavigationItem;
@property (retain, nonatomic) UITextView *notesView;
@property (retain, nonatomic) MKMapView *mapView;
@property (retain, nonatomic) UILabel *copyrightLabel;
@property (retain, nonatomic) UILabel *accuracyLabel;
@property (retain, nonatomic) UILabel *accuracyValueLabel;
@property (retain, nonatomic) UIButton *helpButton;

@end
