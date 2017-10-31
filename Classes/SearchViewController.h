//
//  SearchViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 23.05.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchData.h"
#import "CellOwner.h"

@interface SearchViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource> {
  id delegate;
  BOOL searchEnabled;
  UIImage *indicatorImage;
  NSDictionary *allParkDetails;

  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UISearchBar *theSearchBar;
  IBOutlet UITableView *theTableView;
  IBOutlet UIActivityIndicatorView *searchIndicator;
  IBOutlet CellOwner *cellOwner;
}

+(void)clearResultList;

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner parkDetails:(NSDictionary *)parkDetails;

-(IBAction)loadBackView:(id)sender;
-(IBAction)helpView:(id)sender;
-(IBAction)settingsView:(id)sender;

@property (nonatomic, retain) UINavigationBar *topNavigationBar;
@property (nonatomic, retain) UINavigationItem *titleNavigationItem;
@property (nonatomic, retain) UISearchBar *theSearchBar;
@property (nonatomic, retain) UITableView *theTableView;
@property (nonatomic, retain) UIActivityIndicatorView *searchIndicator;
@property (retain, nonatomic) CellOwner *cellOwner;

@end
