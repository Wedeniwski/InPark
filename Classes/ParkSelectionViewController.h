//
//  ParkSelectionViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 21.05.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "CustomBadge.h"

@interface ParkSelectionViewController : UIViewController <UINavigationBarDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate> {
@private
  BOOL checkDataOnlyFirstCall;
  int numberOfAvailableUpdates;
  CustomBadge *customBadge;
  UIButton *facebookButton;
  UIWebView *facebookWebView;
  UIImage *indicatorImage;
  UIImage *blankImage;

@public
  IBOutlet UITableView *theTableView;
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleOfTable;
  IBOutlet UIActivityIndicatorView *loadDataActivityIndicator;
  IBOutlet UIButton *helpButton;
  IBOutlet UIToolbar *bottomToolbar;
  IBOutlet UILabel *noDataLabel;
}

-(id)initWithNibName:(NSString *)nibNameOrNil;

-(void)updateParksData;

-(IBAction)searchView:(id)sender;
-(IBAction)helpView:(id)sender;
-(IBAction)updateView:(id)sender;
-(IBAction)settingsView:(id)sender;
-(IBAction)aboutPage:(id)sender;

-(void)sendFeedback;
-(void)facebookLike;

@property (retain, nonatomic) UITableView *theTableView;
@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleOfTable;
@property (retain, nonatomic) UIActivityIndicatorView *loadDataActivityIndicator;
@property (retain, nonatomic) UIButton *helpButton;
@property (retain, nonatomic) UIToolbar *bottomToolbar;
@property (retain, nonatomic) UILabel *noDataLabel;

@end
