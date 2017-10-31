//
//  SearchSettingsViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 25.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchData.h"

@interface SearchSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  id delegate;
  int numberOfCountries;
  SearchData *searchData;
  NSMutableArray *parkIds;
  NSDictionary *countries;
  NSArray *attributeIds;
	UIImage *selectedImage;
	UIImage *unselectedImage;
  
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UISegmentedControl *searchCriteriaSections;
  IBOutlet UISegmentedControl *searchAccuracy;
  IBOutlet UILabel *accuracyLabel;
  IBOutlet UITableView *theTableView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner searchData:(SearchData *)searchData;

-(IBAction)searchCriteriaSectionsControlValueChanged:(id)sender;
-(IBAction)loadBackView:(id)sender;

@property (nonatomic, retain) UINavigationBar *topNavigationBar;
@property (nonatomic, retain) UINavigationItem *titleNavigationItem;
@property (nonatomic, retain) UISegmentedControl *searchCriteriaSections;
@property (nonatomic, retain) UISegmentedControl *searchAccuracy;
@property (nonatomic, retain) UILabel *accuracyLabel;
@property (nonatomic, retain) UITableView *theTableView;

@end
