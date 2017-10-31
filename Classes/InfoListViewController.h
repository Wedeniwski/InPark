//
//  InfoListViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 28.02.12.
//  Copyright (c) 2012 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoListViewController : UIViewController {
  id delegate;
  
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UITableView *infoTableView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(id)owner;

-(IBAction)loadBackView:(id)sender;

@property (nonatomic, retain) UINavigationBar *topNavigationBar;
@property (nonatomic, retain) UINavigationItem *titleNavigationItem;
@property (nonatomic, retain) UITableView *infoTableView;

@end
