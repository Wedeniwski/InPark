//
//  AttractionListViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 12.09.10.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellOwner.h"
#import "AttractionViewController.h"
#import "LocationData.h"

@interface AttractionListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, LocationDataDelegate> {
@private
	id delegate;
  UIImage *indicatorImage;

@public
  IBOutlet UITableView *theTableView;
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleOfTable;
  IBOutlet UIToolbar *bottomToolbar;
  IBOutlet CellOwner *cellOwner;
}

-(void)setListOfAttractionIds:(NSArray *)newListOfAttractionIds;
-(void)setSubtitleName:(NSString *)newSubtitleName;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkId:(NSString *)pId category:(NSString *)cat title:(NSString *)tName;
-(void)addToTour:(int)row target:(AttractionViewController *)controller;

-(IBAction)loadBackView:(id)sender;
-(IBAction)mainMenuView:(id)sender;
-(IBAction)tourView:(id)sender;
-(IBAction)mapView:(id)sender;
-(IBAction)generalView:(id)sender;
-(IBAction)addAllToTour:(id)sender;

@property (readonly) id delegate;
@property (retain, nonatomic) UITableView *theTableView;
@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleOfTable;
@property (retain, nonatomic) UIToolbar *bottomToolbar;
@property (retain, nonatomic) CellOwner *cellOwner;

@end
