//
//  UpdateViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.01.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Update.h"

@interface UpdateViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIWebViewDelegate, UpdateDelegate> {
  id delegate;
  BOOL errorPopUps;
  BOOL firstUpdateCheck;
  BOOL checkVersionInfo;
  NSArray *mustUpdateParkGroupIds;
  int downloadPos;
  Update *activeUpdate;
  NSArray *availableUpdates;
  NSMutableArray *mustUpdates;
  NSMutableArray *selectedUpdates;
  NSMutableArray *unselectableUpdates;
	UIImage *selectedImage;
	UIImage *unselectedImage;
  NSArray *originalBottomToolbar;
  NSString *selectedParkId; // for HD selection
  NSArray *namesKindOfs;
  NSMutableDictionary *availableKindOfUpdates;
  NSMutableDictionary *selectedKindOfs;
  NSSet *availableImageDataChanges;
  NSString *lastDownloadError;

  UIBarButtonItem *leftButton;
  UIBarButtonItem *downloadButton;
  UIBarButtonItem *selectAllButton;
  IBOutlet UIToolbar *bottomToolbar;
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UITableView *theTableView;
  IBOutlet UIActivityIndicatorView *downloadIndicator;
  IBOutlet UIActivityIndicatorView *initIndicator;
  IBOutlet UIProgressView *downloadProgress;
  IBOutlet UILabel *downloadStatus;
  IBOutlet UILabel *downloadedSize;
}

-(int)posUpdates:(int)section row:(int)row;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner;

-(IBAction)loadBackView:(id)sender;
-(IBAction)download:(id)sender;
-(IBAction)selectAllItems:(id)sender;

@property BOOL checkVersionInfo;
@property (nonatomic, retain) NSArray *mustUpdateParkGroupIds;
@property (nonatomic, retain) UIToolbar *bottomToolbar;
@property (nonatomic, retain) UINavigationBar *topNavigationBar;
@property (nonatomic, retain) UINavigationItem *titleNavigationItem;
@property (nonatomic, retain) UITableView *theTableView;
@property (nonatomic, retain) UIActivityIndicatorView *downloadIndicator;
@property (nonatomic, retain) UIActivityIndicatorView *initIndicator;
@property (nonatomic, retain) UIProgressView *downloadProgress;
@property (nonatomic, retain) UILabel *downloadStatus;
@property (nonatomic, retain) UILabel *downloadedSize;

@end
