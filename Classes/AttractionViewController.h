//
//  AttractionViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.05.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Attraction.h"
#import "Update.h"
#import "LocationData.h"
#import "CustomBadge.h"
#import "CoverFlowView.h"

@interface AttractionViewController : UIViewController<UIWebViewDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, UpdateDelegate, LocationDataDelegate, CoverFlowViewDelegate, CoverFlowViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate> {
@private
	id delegate;
  NSString *currentDistance;
  NSDictionary *localImageData;

@public
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UIBarButtonItem *addToTourButtonItem;
  IBOutlet UIButton *helpButton;
  IBOutlet UIImageView *favoriteView;
  IBOutlet UIImageView *closedView;
  IBOutlet UILabel *closedLabel;
  IBOutlet UILabel *copyrightLabel;
  IBOutlet UISegmentedControl *informationControl;
  IBOutlet UIWebView *webView;
  IBOutlet UITableView *actionsTable;
  IBOutlet UIButton *allPicturesButton;
  IBOutlet CoverFlowView *viewAllPicturesView;
  IBOutlet UIActivityIndicatorView *prepAllPicturesWaitView;
  CustomBadge *updatesBadge;
  NSArray *allImages;

  NSString *imageCopyright;
  BOOL enableAddToTour;
  BOOL enableWalkToAttraction;
  BOOL enableViewAllPicturesButton;
  BOOL enableViewOnMap;
  BOOL enableWaitTime;
  int tourCount;
  int selectedTourItemIndex;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner attraction:(Attraction *)attraction parkId:(NSString *)pId;
-(void)setSelectedDate:(NSDate *)newSelectedDate;
-(void)updateTourCount:(int)tCount;

-(IBAction)updateDetailView:(id)sender;
-(IBAction)loadBackView:(id)sender;
-(IBAction)helpView:(id)sender;
-(IBAction)addToTour:(id)sender;
-(IBAction)walkToAttraction:(id)sender;
-(IBAction)viewOnMap:(id)sender;
-(IBAction)waitTime:(id)sender;
-(IBAction)favorites:(id)sender;
-(IBAction)rating:(id)sender;
-(IBAction)viewAllPictures:(id)sender;
-(IBAction)deleteUserImage:(id)sender;

@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleNavigationItem;
@property (retain, nonatomic) UIBarButtonItem *addToTourButtonItem;
@property (retain, nonatomic) UIButton *helpButton;
@property (retain, nonatomic) UIImageView *favoriteView;
@property (retain, nonatomic) UIImageView *closedView;
@property (retain, nonatomic) UILabel *closedLabel;
@property (retain, nonatomic) UILabel *copyrightLabel;
@property (retain, nonatomic) UISegmentedControl *informationControl;
@property (retain, nonatomic) UIWebView *webView;
@property (retain, nonatomic) UITableView *actionsTable;
@property (retain, nonatomic) UIButton *allPicturesButton;
@property BOOL enableAddToTour;
@property BOOL enableWalkToAttraction;
@property BOOL enableViewAllPicturesButton;
@property BOOL enableViewOnMap;
@property BOOL enableWaitTime;
@property int tourCount;
@property int selectedTourItemIndex;
@property (retain, nonatomic) CoverFlowView *viewAllPicturesView;
@property (retain, nonatomic) UIActivityIndicatorView *prepAllPicturesWaitView;

@end
