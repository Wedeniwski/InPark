//
//  WaitTimeOverviewViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.04.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellOwner.h"
#import "CustomBadge.h"
#import "WaitingTimeItem.h"

@interface WaitTimeOverviewViewController : UIViewController<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource> {
@private
	id delegate;
  WaitingTimeItem *waitingTimeItem;
  
@public
  IBOutlet CellOwner *cellOwner;
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UILabel *recentWaitTimesLabel;
  IBOutlet UITableView *recentWaitTimesTable;
  IBOutlet UILabel *localTimeLabel;
  IBOutlet UILabel *currentWaitTimeLabel;
  IBOutlet CustomBadge *currentWaitTimeBadge;
  IBOutlet UIImageView *closedImageView;
  IBOutlet UIButton *confirmButton;
  IBOutlet UIButton *submitButton;
  IBOutlet UILabel *userNameLabel;
  IBOutlet UITextField *userNameTextField;
  IBOutlet UIPickerView *waitingTimePickerView;
  IBOutlet UIButton *cancelButton;
  IBOutlet UIButton *submitWaitTimeButton;
  IBOutlet UIButton *rulesButton;
  IBOutlet UIActivityIndicatorView *activityIndicatorView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId attractionId:(NSString *)aId;

-(IBAction)loadBackView:(id)sender;
-(IBAction)confirmWaitTime:(id)sender;
-(IBAction)submitWaitTime:(id)sender;
-(IBAction)cancelWaitingTimeChange:(id)sender;
-(IBAction)submitWaitingTimeChange:(id)sender;
-(IBAction)rulesForComments:(id)sender;

@property (retain, nonatomic) CellOwner *cellOwner;
@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleNavigationItem;
@property (retain, nonatomic) UILabel *recentWaitTimesLabel;
@property (retain, nonatomic) UITableView *recentWaitTimesTable;
@property (retain, nonatomic) UILabel *localTimeLabel;
@property (retain, nonatomic) UILabel *currentWaitTimeLabel;
@property (retain, nonatomic) UIImageView *closedImageView;
@property (retain, nonatomic) CustomBadge *currentWaitTimeBadge;
@property (retain, nonatomic) UIButton *confirmButton;
@property (retain, nonatomic) UIButton *submitButton;
@property (retain, nonatomic) UILabel *userNameLabel;
@property (retain, nonatomic) UITextField *userNameTextField;
@property (retain, nonatomic) UIPickerView *waitingTimePickerView;
@property (retain, nonatomic) UIButton *cancelButton;
@property (retain, nonatomic) UIButton *submitWaitTimeButton;
@property (retain, nonatomic) UIButton *rulesButton;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;

@end
