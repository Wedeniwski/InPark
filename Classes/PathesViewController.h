//
//  PathesViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.02.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellOwner.h"
#import "PathesCell.h"
#import "LocationData.h"
#import "WaitingTimeData.h"
#import "CustomBadge.h"
#import "TutorialView.h"
#import "CategoriesSelectionViewController.h"
#import "ODRefreshControl.h"

@interface PathesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, PathesCellDelegate, LocationDataDelegate, WaitingTimeDataDelegate, CalendarDataDelegate, CategoriesSelectionDelegate, TutorialViewDelegate> {
	id delegate;
  UIImage *indicatorImage;
  UIImage *favoriteStarImage;
  UIImage *favoriteStarFrameImage;
  UIImage *blankImage;
  CustomBadge *updatesBadge;
  ODRefreshControl *refreshControl;
  TutorialView *tutorialView;
  UIView *indexSelectorView;
  UIButton *updatesBadgeButton;
  BOOL scrollTablePosition;
  int previousContentSelection;
  int numberOfAvailableUpdates;
  BOOL checkDataOnlyFirstCall;
  NSArray *parkDataList;
  NSMutableArray *parkNames;
  NSMutableArray *parkLogos;
  BOOL enableWalkToAttraction;

  IBOutlet UIImageView *backgroundView;
  IBOutlet UISegmentedControl *contentController;
  IBOutlet UIImageView *parkLogoImageView;
  IBOutlet UILabel *parkNameLabel;
  IBOutlet UILabel *parkOpeningLabel;
  IBOutlet UILabel *parkSelectionLabel;
  IBOutlet UIButton *parkSelectionButton;
  IBOutlet UITableView *theTableView;
  IBOutlet CellOwner *cellOwner;
  IBOutlet UILabel *moreInfoLabel;
  IBOutlet UIToolbar *bottomToolbar;
  IBOutlet UIButton *calendarButton;
  IBOutlet UIBarButtonItem *moreInfoButton;
  IBOutlet UIButton *refreshButton;
  IBOutlet UIActivityIndicatorView *activityIndicatorView;
  IBOutlet UILabel *noDataLabel;
  IBOutlet UILabel *accuracyLabel;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkGroupId:(NSString *)pId;

-(void)showBackgroundImage:(UIImage *)image;
-(void)changingWaitingTimeForAttractionId:(NSString *)attractionId;

-(IBAction)loadBackView:(id)sender;
-(IBAction)options:(id)sender;
-(IBAction)changePark:(id)sender;
-(IBAction)moreInfo:(id)sender;
-(IBAction)calendar:(id)sender;
-(IBAction)refresh:(id)sender;
-(IBAction)contentControllerValueChanged:(id)sender;

@property (readonly) id delegate;
@property (retain, nonatomic) UIImageView *backgroundView;
@property (retain, nonatomic) UISegmentedControl *contentController;
@property (retain, nonatomic) UIImageView *parkLogoImageView;
@property (retain, nonatomic) UILabel *parkNameLabel;
@property (retain, nonatomic) UILabel *parkOpeningLabel;
@property (retain, nonatomic) UILabel *parkSelectionLabel;
@property (retain, nonatomic) UIButton *parkSelectionButton;
@property (retain, nonatomic) UITableView *theTableView;
@property (retain, nonatomic) CellOwner *cellOwner;
@property (retain, nonatomic) UILabel *moreInfoLabel;
@property (retain, nonatomic) UIToolbar *bottomToolbar;
@property (retain, nonatomic) UIButton *calendarButton;
@property (retain, nonatomic) UIBarButtonItem *moreInfoButton;
@property (retain, nonatomic) UIButton *refreshButton;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (retain, nonatomic) UILabel *noDataLabel;
@property (retain, nonatomic) UILabel *accuracyLabel;
@property BOOL enableWalkToAttraction;

@end
