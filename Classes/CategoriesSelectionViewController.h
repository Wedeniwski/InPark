//
//  CategoriesSelectionViewController.h
//  InPark
//
//  Created by Sebastian Wedeniwski on 07.04.11.
//  Copyright 2011 InPark GbR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CategoriesSelectionDelegate
@required
-(void)dismissModalViewControllerAnimated:(BOOL)animated;
@optional
-(void)updateMapView;
@end


@interface CategoriesSelectionViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  UIViewController<CategoriesSelectionDelegate> *delegate;
  BOOL favoriteMode;
  NSString *parkId;
  NSMutableArray *categoryNames;
  NSMutableDictionary *selectedCategories;
	UIImage *selectedImage;
	UIImage *unselectedImage;
  
  IBOutlet UINavigationBar *topNavigationBar;
  IBOutlet UINavigationItem *titleNavigationItem;
  IBOutlet UITableView *theTableView;
}

-(id)initWithNibName:(NSString *)nibNameOrNil owner:(UIViewController<CategoriesSelectionDelegate> *)owner parkId:(NSString *)pId;
-(void)setCategoryNames:(NSArray *)names;

-(IBAction)loadBackView:(id)sender;

@property (retain, nonatomic) NSMutableDictionary *selectedCategories;
@property (retain, nonatomic) UINavigationBar *topNavigationBar;
@property (retain, nonatomic) UINavigationItem *titleNavigationItem;
@property (retain, nonatomic) UITableView *theTableView;

@end
