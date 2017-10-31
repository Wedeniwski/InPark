//
//  ParkMainMenuViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 16.07.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationData.h"
#import "CustomBadge.h"
#import "CoverFlowView.h"
#import "CustomSwitch.h"

typedef enum {
  ParkModusNotSelected,
  ParkModusInformation,
  ParkModusVisit
} ParkModus;

@interface ParkMainMenuViewController : UIViewController <UINavigationBarDelegate, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, LocationDataDelegate, CoverFlowViewDelegate, CoverFlowViewDataSource, CustomSwitchDelegate> {
@private
  id delegate;
  NSDictionary *localImageData;
  UIBarButtonItem *backButton;
  CustomBadge *newsBadge;
  CustomBadge *fitsToProfileBadge;
  NSMutableArray *menuButtons;
  NSMutableArray *menuLabels;
  CoverFlowView *logoImageView;
  UIButton *switchViewButton;
  UIButton *waitingTimeOverviewButton;
  UILabel *openFlowLeftTitleLabel;
  UILabel *openFlowTitleLabel;
  UILabel *openFlowRightTitleLabel;
  CoverFlowView *coverFlowView;
  CustomSwitch *summerWinterSwitch;
  UILabel *winterLabel;
  UILabel *summerLabel;
  UILabel *interestingTitleLabel;

@public
  IBOutlet UIImageView *backgroundView;
  IBOutlet UITableView *theTableView;
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleOfTable;
  IBOutlet UIActivityIndicatorView *loadDataActivityIndicator;
  IBOutlet UIButton *helpButton;
  IBOutlet UIToolbar *bottomToolbar;
  IBOutlet UILabel *interestingLabel;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId;

-(void)updateParksData;
-(void)buttonViewModus:(BOOL)initBottomToolbar;
-(ParkModus)currentParkModus;

-(IBAction)loadBackView:(id)sender;
-(IBAction)backView:(id)sender;
-(IBAction)backView:(id)sender animated:(BOOL)animated;
-(IBAction)helpView:(id)sender;
-(IBAction)switchView:(id)sender;
-(IBAction)tourView:(id)sender;
-(IBAction)mapView:(id)sender;
-(IBAction)parkingView:(id)sender;
-(IBAction)recommendationView:(id)sender;
-(void)showTableView:(BOOL)animated;
-(IBAction)attractionsView:(id)sender;
-(IBAction)themeAreasView:(id)sender;
-(IBAction)restroomView:(id)sender;
-(IBAction)serviceView:(id)sender;
-(IBAction)shopsView:(id)sender;
-(IBAction)cateringView:(id)sender;
-(IBAction)calendarView:(id)sender;
-(IBAction)generalView:(id)sender;
-(IBAction)waitingTimeOverview:(id)sender;

@property (readonly) id delegate;
@property (retain, nonatomic) UIImageView *backgroundView;
@property (retain, nonatomic) UITableView *theTableView;
@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleOfTable;
@property (retain, nonatomic) UIActivityIndicatorView *loadDataActivityIndicator;
@property (retain, nonatomic) UIButton *helpButton;
@property (retain, nonatomic) UIToolbar *bottomToolbar;
@property (retain, nonatomic) UILabel *interestingLabel;

@end
