//
//  InAppSettingsViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 05.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InAppSettingsTableCell.h"
#import "ParkData.h"
#import "CustomBadge.h"
#import "CustomSwitch.h"

@interface InAppSettingsViewController : UIViewController <CustomSwitchDelegate> {
	id delegate;
  BOOL viewOptionalSettings;
  BOOL viewChildPane;
  int availableUpdates;
  ParkData *parkData;
  NSString *file;
  NSString *preferenceTitle;
  NSString *preferenceSpecifiers;
  NSMutableArray *headers, *displayHeaders;
  NSMutableDictionary *settings;
  CustomBadge *updatesBadge;
  CustomSwitch *summerWinterSwitch;
  UILabel *winterLabel;
  UILabel *summerLabel;
  IBOutlet UITableView *theTableView;
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleOfTable;
  IBOutlet UIButton *helpButton;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner;
-(IBAction)loadBackView:(id)sender;
-(IBAction)helpView:(id)sender;
-(void)controlEditingDidBeginAction:(UIControl *)control;

@property (assign, nonatomic) id delegate;
@property BOOL viewOptionalSettings;
@property BOOL viewChildPane;
@property int availableUpdates;
@property (retain, nonatomic) ParkData *parkData;
@property (retain, nonatomic) NSString *file;
@property (retain, nonatomic) NSString *preferenceTitle;
@property (retain, nonatomic) NSString *preferenceSpecifiers;
@property (retain, nonatomic) UITableView *theTableView;
@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleOfTable;
@property (retain, nonatomic) UIButton *helpButton;

@end