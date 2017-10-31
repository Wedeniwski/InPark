//
//  GeneralInfoListViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 20.03.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HelpData.h"

@interface GeneralInfoListViewController : UIViewController {
	id delegate;
  NSString *titleName;
  HelpData *helpData;
  
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UITableView *newsTableView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner helpData:(HelpData *)hData title:(NSString *)tName;

-(IBAction)loadBackView:(id)sender;

@property (nonatomic, retain) UINavigationBar *topNavigationBar;
@property (nonatomic, retain) UINavigationItem *titleNavigationItem;
@property (nonatomic, retain) UITableView *newsTableView;

@end
